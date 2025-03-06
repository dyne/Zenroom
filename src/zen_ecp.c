/*
 * This file is part of zenroom
 * 
 * Copyright (C) 2017-2021 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 * 
 * Last modified by Denis Roio
 * on Monday, 9th August 2021
 */


/// <h1>Elliptic Curve Point Arithmetic (ECP)</h1>
//
//  Base arithmetical operations on elliptic curve point coordinates.
//
//  ECP arithmetic operations are provided to implement existing and
//  new encryption schemes: they are elliptic curve cryptographic
//  primitives and work the same across different curves.
//
//  It is possible to create ECP points instances using the @{new}
//  method. The values of each coordinate can be imported using @{BIG}
//  methods `BIG.hex()` or `BIG.base64()`.
//
//  Once ECP numbers are created this way, the arithmetic operations
//  of addition, subtraction and multiplication can be executed
//  normally using overloaded operators (+ - *).
//
//  @module ECP
//  @author Denis "Jaromil" Roio
//  @license AGPLv3
//  @copyright Dyne.org foundation 2017-2019


#include <zenroom.h>

#include <zen_error.h>
#include <zen_ecp.h>
#include <zen_ecp_factory.h>

#include <zen_big.h>
#include <zen_fp12.h>
#include <lua_functions.h>

extern int _octet_to_big(lua_State *L, big *dst, const octet *src);

static const char* _ecp_from_octet(ecp *e, const octet *o) {
	// protect well this entrypoint since parsing any input is at
	// risk: Milagro's _fromOctet() uses ECP_BLS_set(ECP_BLS *P,
	// BIG x) then converts the BIG to an FP modulo using
	// FP_BLS_nres.
	const char *err_octsmall =
		"ECP total length too small to contain Octet";
	const char *err_invalid =
		"Octet is not a valid ECP (point is not on this curve)";
	const char *err_notfound =
		"Octet doesn't contains a valid ECP";
	if(o->len > e->totlen) // buffer safety not checked by Milagro
		return err_octsmall;
	if(o->len == 2 && o->val[0] == SCHAR_MAX
	   && o->val[1] == SCHAR_MAX) {
		ECP_inf(&e->val);
		return NULL; } // tolerated as ECP Infinity
	if(ECP_validate((octet*)o) < 0)
		// test in Milagro's ecdh_*.h ECP_*_PUBLIC_KEY_VALIDATE
		return err_invalid;
	if(! ECP_fromOctet(&e->val, (octet*)o) )
		return err_notfound;
	// success
	return NULL;
}

ecp* ecp_new(lua_State *L) {
	ecp *e = (ecp *)lua_newuserdata(L, sizeof(ecp));
	if(HEDLEY_UNLIKELY(e==NULL)) {
		zerror(L, "Error allocating new ecp in %s", __func__);
		return NULL; }
	e->halflen = sizeof(BIG);
	e->totlen = (MODBYTES*2)+1; // length of ECP.new(rng:modbig(o), 0):octet()
	luaL_getmetatable(L, "zenroom.ecp");
	lua_setmetatable(L, -2);
	e->ref = 1;
	return(e);
}

void ecp_free(lua_State *L, const ecp* e) {
	(void)L;
	if(HEDLEY_UNLIKELY(e==NULL)) return;
	ecp *t = (ecp*)e;
	t->ref--;
	if(t->ref>0) return;
	free((void*)t);
}

const ecp* ecp_arg(lua_State *L, int n) {
	Z(L);
	ecp *res;
	void *ud = luaL_testudata(L, n, "zenroom.ecp");
	if(ud) {
		res = (ecp*)ud;
		res->ref++;
		return(res);
	}
	// octet first class citizen
	const octet *o = o_arg(L,n);
	if(o) {
		// check if input is zcash compressed
		unsigned char m_byte = o->val[0] & 0xE0;
		if(m_byte == 0x20 || m_byte == 0x60 || m_byte == 0xE0) {
			zerror(L, "ECP arg %u is zcash compressed",n);
			o_free(L,o);
			return NULL;
		}
		res = malloc(sizeof(ecp));
		res->totlen = (MODBYTES*2)+1;
		_ecp_from_octet(res, o);
		res->ref = 1;
		o_free(L,o);
		return(res);
	}
	zerror(L, "invalid ECP in argument");
	return NULL;
}

ecp* ecp_dup(lua_State *L, const ecp* in) {
	ecp *e = ecp_new(L);
	if(e == NULL) {
		zerror(L, "Error duplicating ECP in %s", __func__);
		return NULL;
	}
	ECP_copy(&e->val, (ECP*)&in->val);
	return(e);
}

int ecp_destroy(lua_State *L) {
	(void)L;
	return 0;
}

int _fp_to_big(big *dst, FP *src) {
	FP_redc(dst->val, src);
	return 1;
}
/***
    Create a new ECP point from an @{OCTET} argument containing its coordinates.

    @param[@{OCTET}] coordinates of the point on the elliptic curve
    @return a new ECP point on the curve
    @function new(octet)
    @see ECP:octet
*/
static int lua_new_ecp(lua_State *L) {
	BEGIN();
	// unsafe parsing into BIG, only necessary for tests
	// deactivate when not running tests
	void *tx;
	const char *failed_msg = NULL;
	const octet *o = NULL;
	tx = luaL_testudata(L, 1, "zenroom.big");
	void *ty = luaL_testudata(L, 2, "zenroom.big");
	if(tx && ty) {
		ecp *e = ecp_new(L);
		big *x = NULL, *y = NULL;
		if(!e) {
			failed_msg = "Could not create ECP";
			goto end_big_big;
		}
		x = big_arg(L, 1);
		y = big_arg(L, 2);
		if(!x || !y) {
			failed_msg = "Could not create BIGs";
			goto end_big_big;
		}
		if(!ECP_set(&e->val, x->val, y->val))
			warning(L, "new ECP value out of curve (points to infinity)");
end_big_big:
		big_free(L,y);
		big_free(L,x);
		goto end;
	}
#ifdef DEBUG
	// If x is on the curve then y is calculated from the curve equation.
	int tn;
	lua_Number n = lua_tonumberx(L, 2, &tn);
	if(tx && tn) {
		big *x = NULL;
		ecp *e = ecp_new(L);
		if(!e) {
			failed_msg = "Could not create ECP";
			goto end_big_number;
		}
		x = big_arg(L, 1);
		if(!x) {
			failed_msg = "Could not create BIG";
			goto end_big_number;
		}
		if(!ECP_setx(&e->val, x->val, (int)n))
			warning(L, "new ECP value out of curve (points to infinity)");
end_big_number:
		big_free(L,x);
		goto end;
	}
#endif
	tx = luaL_testudata(L, 1, "zenroom.big");
	if(tx) {
		ecp *e = ecp_new(L);
		big *x = NULL;
		if(!e) {
			failed_msg = "Could not create ECP";
			goto end_big;
		}
		x = big_arg(L, 1);
		if(!x) {
			failed_msg = "Could not create BIG";
			goto end_big;
		}
		if(!ECP_setx(&e->val, x->val, 0))
			warning(L, "new ECP value out of curve (points to infinity)");
end_big:
		big_free(L,x);
		goto end;
	}
	// We protect well this entrypoint since parsing any input is at risk
	// Milagro's _fromOctet() uses ECP_BLS_set(ECP_BLS *P, BIG x)
	// then converts the BIG to an FP modulo using FP_BLS_nres.
	o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate octet";
		goto end;
	}
	ecp *e = ecp_new(L);
	if(o->len > e->totlen) { // double safety
		lua_pop(L, 1);
		zerror(L, "%s: octet length %u instead of %u bytes", __func__, o->len, e->totlen);
		goto end;
	}
	failed_msg = _ecp_from_octet(e, o);
	if(failed_msg) {
		lua_pop(L, 1);
	}
end:
	o_free(L,o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Returns the generator of the curve: an ECP point that is multiplied by any @{BIG} number to obtain a correspondent point on the curve.

    @function generator()
    @return ECP point of the curve's generator.
*/
static int ecp_generator(lua_State *L) {
	BEGIN();
	ecp *e = ecp_new(L);
/*     if(!ECP_set(&e->val,
       (chunk*)CURVE_Gx, (chunk*)CURVE_Gy)) {
              lerror(L, "ECP generator value out of curve (stack corruption)");
              return 0; }
*/
	ECP_generator(&e->val);
	END(1);
}

/***
    Returns a new ECP infinity point that is definitely not on the curve.

    @function infinity()
    @return ECP pointing to infinity (out of the curve).
*/
static int ecp_get_infinity(lua_State *L) {
	BEGIN();
	ecp *e = ecp_new(L);
	if(e) {
		ECP_inf(&e->val);
	} else {
		THROW("Could not create ECP");
	}
	END(1);
}


/***
    Gives the order of the curve, a @{BIG} number contained in an octet.

    @function order()
    @return a @{BIG} number containing the curve's order
*/
static int ecp_order(lua_State *L) {
	BEGIN();
	big *res = big_new(L);
	if(res) {
		big_init(L,res);
		// BIG is an array of int32_t on chunk 32 (see rom_curve)

		// curve order is ready-only so we need a copy for norm() to work
		BIG_copy(res->val, (chunk*)CURVE_Order);
	} else {
		THROW("Could not create BIG");
	}
	END(1);
}


/***
    Map an @{OCTET} of exactly 64 bytes length to a point on the curve: the OCTET should be the output of an hash function.

    @param OCTET resulting from an hash function
    @function mapit(OCTET)
    @return an ECP that is univocally linked to the input OCTET
*/
static int ecp_mapit(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L, 1);
	if(!o) {
		lerror(L, "Could not allocate ecp point");
		lua_pushnil(L);
	} else if(o->len != 64) {
		o_free(L, o);
		zerror(L, "octet length is %u instead of 64 (need to use sha512)", o->len);
		lerror(L, "Invalid argument to ECP.mapit(), not an hash");
		lua_pushnil(L);
	} else {
		ecp *e = ecp_new(L);
		func(L, "mapit on o->len %u", o->len);
		ECP_mapit(&e->val, (octet*)o);
		o_free(L, o);
	}
	END(1);
}

/***
    Verify that an @{OCTET} really corresponds to an ECP point on the curve.

    @param OCTET point to be validated
    @function validate(OCTET)
    @return bool value: true if valid, false if not valid
*/
static int ecp_validate(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L, 1);
	if(o) {
		int res = ECP_validate((octet*)o);
		lua_pushboolean(L, res>=0);
		o_free(L, o);
	} else {
		THROW("Could not allocate ECP point");
	}
	END(1);
}


/// Instance Methods
// @type ecp

/***
    Make an existing ECP point affine with its curve
    @function affine()
    @return ECP point made affine
*/
static int ecp_affine(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ecp *out = NULL;
	const ecp *in = ecp_arg(L, 1);
	if(!in) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	out = ecp_dup(L, in);
	if(!out) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	ECP_affine(&out->val);
end:
	ecp_free(L,in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
/***
    Returns true if an ECP coordinate points to infinity (out of the curve) and false otherwise.

    @function isinf()
    @return false if point is on curve, true if its off curve into infinity.
*/
static int ecp_isinf(lua_State *L) {
	BEGIN();
	const ecp *e = ecp_arg(L, 1);
	if(e) {
		lua_pushboolean(L, ECP_isinf((ECP*)&e->val));
		ecp_free(L,e);
	} else {
		THROW("Could not create ECP");
	}
	END(1);
}

/***
    Add two ECP points to each other (commutative and associative operation). Can be made using the overloaded operator `+` between two ECP objects just like the would be numbers.

    @param first number to be summed
    @param second number to be summed
    @function add(first, second)
    @return sum resulting from the addition
*/
static int ecp_add(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp *e = ecp_arg(L, 1);
	const ecp *q = ecp_arg(L, 2);
	if(!e || !q) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	ecp *p = ecp_dup(L, e); // push
	if(!p) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	ECP_add(&p->val, (ECP*)&q->val);
end:
	ecp_free(L,q);
	ecp_free(L,e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Subtract an ECP point from another (commutative and associative operation). Can be made using the overloaded operator `-` between two ECP objects just like the would be numbers.

    @param first number from which the second should be subtracted
    @param second number to use in the subtraction
    @function sub(first, second)
    @return new ECP point resulting from the subtraction
*/
static int ecp_sub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp *e = ecp_arg(L, 1);
	const ecp *q = ecp_arg(L, 2);
	if(!e || !q) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	ecp *p = ecp_dup(L, e); // push
	if(!p) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	ECP_sub(&p->val, (ECP*)&q->val);
end:
	ecp_free(L,q);
	ecp_free(L,e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Transforms an ECP point into its equivalent negative point on the elliptic curve.

    @function negative()
*/
static int ecp_negative(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ecp *out = NULL;
	const ecp *in = ecp_arg(L, 1);
	if(!in) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	out = ecp_dup(L, in);
	if(!out) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	ECP_neg(&out->val);
end:
	ecp_free(L,in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Transforms an ECP pointo into the double of its value, multiplying it by two. This works faster than multiplying it an arbitrary number of times.

    @function double()
*/
static int ecp_double(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ecp *out = NULL;
	const ecp *in = ecp_arg(L, 1);
	if(!in) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	out = ecp_dup(L, in);
	if(!out) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	ECP_dbl(&out->val);
end:
	ecp_free(L,in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Multiply an ECP point by a @{BIG} number. Can be made using the overloaded operator `*`

    @function mul(ecp, num)
    @param ecp point on the elliptic curve to be multiplied
    @param number indicating how many times it should be multiplied
    @return new ecp point resulting from the multiplication
*/
static int ecp_mul(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp *e = NULL;
	const big *b = NULL;
	ecp *out = NULL;
	uint8_t ecpos, bigpos = 0;
	ecpos = luaL_testudata(L, 1, "zenroom.ecp") ? 1 : 0;
	if(!ecpos) ecpos = luaL_testudata(L, 2, "zenroom.ecp") ? 2 : 0;
	if(!ecpos) {
		failed_msg = "ECP not found among multiplication arguments";
		goto end;
	}
	bigpos = luaL_testudata(L, 1, "zenroom.big") ? 1 : 0;
	if(!bigpos) bigpos = luaL_testudata(L, 2, "zenroom.big") ? 2 : 0;
	if(!bigpos) {
		failed_msg = "BIG not found among multiplication arguments";
		goto end;
	}
	e = ecp_arg(L, ecpos);
	b = big_arg(L, bigpos);
	if(!e || !b) {
		failed_msg = "Could not instantiate input";
		goto end;
	}
	if(b->doublesize) {
		failed_msg = "cannot multiply ECP point with double BIG numbers, need modulo";
		goto end;
	}
	out = ecp_dup(L, e);
	if(!out) {
		failed_msg = "Could not create ECP";
		goto end;
	}
	PAIR_G1mul(&out->val, b->val);
end:
	ecp_free(L,e);
	big_free(L,b);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Compares two ECP objects and returns true if they indicate the same point on the curve (they are equal) or false otherwise. It can also be executed by using the `==` overloaded operator.

    @param first ecp point to be compared
    @param second ecp point to be compared
    @function eq(first, second)
    @return bool value: true if equal, false if not equal
*/
static int ecp_eq(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp *p = ecp_arg(L, 1);
	const ecp *q = ecp_arg(L, 2);
	if(!p || !q) {
		failed_msg = "Could not allocate ECP point";
		goto end;
	}
	// TODO: is affine rly needed?
	ECP_affine((ECP*)&p->val);
	ECP_affine((ECP*)&q->val);
	lua_pushboolean(L, ECP_equals((ECP*)&p->val, (ECP*)&q->val));
end:
	ecp_free(L,p);
	ecp_free(L,q);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


// use shared internally with octet o_arg()
int _ecp_to_octet(octet *o, const ecp *e) {
	if (ECP_isinf((ECP*)&e->val)) { // Infinity
		o->val[0] = SCHAR_MAX; o->val[1] = SCHAR_MAX;
		o->val[3] = 0x0; o->len = 2;
	} else
		ECP_toOctet(o, (ECP*)&e->val, 1);
	return(1);
}
/***
    Returns an octet containing the coordinate of an ECP point on the curve. It can be used to export the value of an ECP point into a string, using @{OCTET:hex} or @{OCTET:base64} encapsulation. It can be decoded back to an ECP point using @{ECP:new}.

    @function octet()
    @return the ECP point as an OCTET sequence
*/
static int ecp_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *o = NULL;
	const ecp *e = ecp_arg(L, 1);
	if(!e) {
		failed_msg = "Could not instantiate ECP";
		goto end;
	}
	o = o_new(L, e->totlen + 0x0f);
	if(!o) {
		failed_msg = "Could not instantiate ECP";
		goto end;
	}
	_ecp_to_octet(o, e);
end:
	ecp_free(L,e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Gives the X coordinate of the ECP point as a single @{BIG} number.

    @function x()
    @return a BIG number indicating the X coordinate of the point on curve.
*/
static int ecp_get_x(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp *e = ecp_arg(L, 1);
	if(!e) {
		failed_msg = "Could not read ECP";
		goto end;
	}
	ECP_affine((ECP*)&e->val);
	big *x = big_new(L);
	if(!x) {
		failed_msg = "Could not read BIG";
		goto end;
	}
	big_init(L,x);
	_fp_to_big(x, (FP*)&e->val.x);
end:
	ecp_free(L,e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Gives the Y coordinate of the ECP point as a single @{BIG} number.

    @function y()
    @return a BIG number indicating the Y coordinate of the point on curve.
*/
static int ecp_get_y(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *y = NULL;
	const ecp *e = ecp_arg(L, 1);
	if(!e) {
		failed_msg = "Could not read ECP";
		goto end;
	}
	ECP_affine((ECP*)&e->val);
	y = big_new(L);
	if(!y) {
		failed_msg = "Could not read BIG";
		goto end;
	}
	big_init(L,y);
	_fp_to_big(y, (FP*)&e->val.y);
end:
	ecp_free(L,e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int ecp_prime(lua_State *L) {
	BEGIN();
	big *p = big_new(L); big_init(L,p);
	BIG_rcopy(p->val, CURVE_Prime);
	END(1);
}

static int ecp_output(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp *e = ecp_arg(L, 1);
	if(!e) {
		failed_msg = "Could not read ECP";
		goto end;
	}
	if (ECP_isinf((ECP*)&e->val)) { // Infinity
		octet *o = o_new(L, 3);
		if(!o) {
			failed_msg = "Could not read OCTET";
			goto end;
		}
		o->val[0] = SCHAR_MAX; o->val[1] = SCHAR_MAX;
		o->val[3] = 0x0; o->len = 2;
		goto end;
	}
	octet *o = o_new(L, e->totlen + 0x0f);
	if(!o) {
		failed_msg = "Could not read OCTET";
		goto end;
	}
	_ecp_to_octet(o, e);
	push_octet_to_hex_string(L, o);
end:
	ecp_free(L,e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

char gf_sign(BIG y) {
	BIG p;
	BIG_rcopy(p, CURVE_Prime);
	BIG_dec(p, 1);
	BIG_norm(p);
	BIG_shr(p, 1);
	if(BIG_comp(y, p) == 1)
		return 1;
	else
		return 0;
}

static int ecp_zcash_export(lua_State *L) {
	BEGIN();
	const char *failed_msg = NULL;
	const ecp *e = ecp_arg(L, 1);
	if(e == NULL) {
		THROW("Could not create ECP point");
		return 0;
	}

	octet *o = o_new(L, 48); // TODO: make this value adapt to ECP
				 // curve configured at build time
	if(o == NULL) {
		failed_msg = "Could not allocate ECP point";
		goto end;
	}

	if(ECP_isinf((ECP*)&e->val)) {
		o->len = 48; // TODO
		o->val[0] = (char)0xc0;
		memset(o->val+1, 0, 47); // TODO
	} else {
		BIG x, y;
		const char c_bit = 1;
		const char i_bit = 0;

		ECP_get(x, y, (ECP*)&e->val);

		const char s_bit = gf_sign(y);
		char m_byte = (char)((c_bit << 7)+(i_bit << 6)+(s_bit << 5));

		BIG_toBytes(o->val, x);
		o->len = 48; // TODO

		o->val[0] |= m_byte;
	}

end:
	ecp_free(L, e); // TODO: this crashes, still unsure why
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// See the generalised version commented inside zen_octet.c
static int ecp_zcash_import(lua_State *L){
	BEGIN();
	char *failed_msg = NULL;
	ecp *e = NULL;
	const octet *o = o_arg(L, 1);
	if(o == NULL) {
		THROW("Could not allocate octet");
		END(0);
	}
	unsigned char m_byte = o->val[0] & 0xE0;
	bool c_bit;
	bool i_bit;
	bool s_bit;
	if(m_byte == 0x20 || m_byte == 0x60 || m_byte == 0xE0) {
		o_free(L,o);
		THROW("Invalid octet header");
		END(0);
	}
	c_bit = ((m_byte & 0x80) == 0x80);
	i_bit = ((m_byte & 0x40) == 0x40);
	s_bit = ((m_byte & 0x20) == 0x20);

	if(c_bit) {
		if(o->len != 48) {
			o_free(L,o);
			THROW("Invalid octet header");
			END(0);
		}
	} else {
		if(o->len != 96) {
			o_free(L,o);
			THROW("Invalid octet header");
			END(0);
		}
	}
	e = ecp_new(L);
	if(!e) {
		o_free(L,o);
		THROW("Could not create ECP2 point");
		END(0);
	}

	if(i_bit) {
		// TODO: check o->val is all 0
		ECP_inf(&e->val);
		goto end;
	} else if(c_bit) {
		BIG xpoint, ypoint;
		big* bigx = big_new(L);
		// temp octet to write first byte
		octet *ot = o_alloc(L,48);
		memcpy(ot->val, o->val, 48);
		ot->val[0] = ot->val[0] & 0x1F;
		ot->len = 48;
		_octet_to_big(L, bigx, ot);
		o_free(L,ot);
		if(!ECP_setx(&e->val, bigx->val, 0)) {
			failed_msg = "Invalid input octet: not a point on the curve";
			goto end;
		}

		ECP_get(xpoint, ypoint, &e->val);
		if(gf_sign(ypoint) != s_bit)
			ECP_neg(&e->val);
		lua_pop(L,1); // big_new bigx
	} else {
		failed_msg = "Not yet implemented";
		goto end;
	}
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int ecp_rhs(lua_State *L){
	BEGIN();
	char *failed_msg = NULL;
	big *rhs = NULL;
	big *x = big_arg(L, 1);
	if(!x) {
		failed_msg = "Could not read BIG";
		goto end;
	}
	FP X, Y;
	FP_nres(&X , x->val);
	ECP_rhs(&Y, &X);
	rhs = big_new(L);
	if(!rhs) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,rhs);
	_fp_to_big(rhs, &Y);
end:
	big_free(L,x);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_ecp(lua_State *L) {
	(void)L;
	const struct luaL_Reg ecp_class[] = {
		{"new", lua_new_ecp},
		{"inf", ecp_get_infinity},
		{"infinity", ecp_get_infinity},
		{"isinf", ecp_isinf},
		{"order", ecp_order},
		{"mapit", ecp_mapit},
		{"generator", ecp_generator},
		{"G", ecp_generator},
		{"add", ecp_add},
		{"sub", ecp_sub},
		{"mul", ecp_mul},
		{"validate", ecp_validate},
		{"prime", ecp_prime},
		{"rhs", ecp_rhs},
		{"to_zcash", ecp_zcash_export},
		{"from_zcash", ecp_zcash_import},
		{NULL, NULL}};
	const struct luaL_Reg ecp_methods[] = {
		{"affine", ecp_affine},
		{"negative", ecp_negative},
		{"double", ecp_double},
		{"isinf", ecp_isinf},
		{"isinfinity", ecp_isinf},
		{"octet", ecp_octet},
		{"add", ecp_add},
		{"x", ecp_get_x},
		{"y", ecp_get_y},
		{"__add", ecp_add},
		{"sub", ecp_sub},
		{"__sub", ecp_sub},
		{"mul", ecp_mul},
		{"__mul", ecp_mul},
                {"eq", ecp_eq},
		{"__eq", ecp_eq},
		{"__gc", ecp_destroy},
		{"__tostring", ecp_output},
		{"to_zcash", ecp_zcash_export},
		{NULL, NULL}
	};
	zen_add_class(L, "ecp", ecp_class, ecp_methods);
	
	act(L, "ECP curve is %s", ECP_CURVE_NAME);

	return 1;
}
