/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

// For now, the only supported curve is BLS383 type WEIERSTRASS


/// <h1>Twisted Elliptic Curve Point Arithmetic (ECP2)</h1>
//
//  Base arithmetical operations on twisted elliptic curve point
//  coordinates.
//
//  ECP2 arithmetic operations are provided to implement existing and
//  new encryption schemes: they are elliptic curve cryptographic
//  primitives and work only on curves supporting twisting and
//  pairing.
//
//  It is possible to create ECP2 points instances using the @{new}
//  method. The values of each coordinate can be imported using @{BIG}
//  methods from `BIG.hex()` or `BIG.base64()`.
//
//  Once ECP2 points are created this way, the arithmetic operations
//  of addition, subtraction and multiplication can be executed
//  normally using overloaded operators (+ - *).
//
//  @module ECP2
//  @author Denis "Jaromil" Roio
//  @license AGPLv3
//  @copyright Dyne.org foundation 2017-2019


#include <zenroom.h>

#include <zen_error.h>
#include <zen_ecp_factory.h>

#include <zen_octet.h>
#include <zen_ecp.h>
#include <zen_big.h>
#include <zen_fp12.h>
#include <lua_functions.h>

extern int _octet_to_big(lua_State *L, big *dst, const octet *src);

// use shared internally with octet o_arg()
int _ecp2_to_octet(octet *o, const ecp2 *e) {
	ECP2_toOctet(o, (ECP2*)&e->val);
	return(1);
}

void ecp2_free(lua_State *L, const ecp2 *e) {
	(void)L;
	if(HEDLEY_UNLIKELY(e==NULL)) return;
	ecp2 *t = (ecp2*)e;
	t->ref--;
	if(t->ref>0) return;
	free((void*)t);
}

ecp2* ecp2_new(lua_State *L) {
	ecp2 *e = (ecp2 *)lua_newuserdata(L, sizeof(ecp2));
	if(HEDLEY_UNLIKELY(e==NULL)) {
		zerror(L, "Cannot create ECP2, lua_newuserdata failure");
		return NULL; }
	e->halflen = sizeof(BIG)*2;
	e->totlen = (MODBYTES*4)+1;
	luaL_getmetatable(L, "zenroom.ecp2");
	lua_setmetatable(L, -2);
	e->ref = 1;
	return(e);
}

const ecp2* ecp2_arg(lua_State *L, int n) {
	Z(L);
	ecp2 *res;
	void *ud = luaL_testudata(L, n, "zenroom.ecp2");
	if(ud) {
		res = (ecp2*)ud;
		res->ref++;
		return(res);
	}
	const octet *o = o_arg(L,n);
	if(!o) return NULL;
	// check if input is zcash compressed
	// TODO: use zcash compression by default
	unsigned char m_byte = o->val[0] & 0xE0;
	if(m_byte == 0x20 || m_byte == 0x60 || m_byte == 0xE0)
		zerror(L, "ECP2 arg %u is zcash compressed",n);
	o_free(L,o);
	return NULL;
}

ecp2* ecp2_dup(lua_State *L, const ecp2* in) {
	ecp2 *e = ecp2_new(L);
	if(e == NULL) {
		zerror(L, "Error duplicating ecp2 in %s", __func__);
		return NULL;
	}
	ECP2_copy(&e->val, (ECP2*)&in->val);
	return(e);
}

int ecp2_destroy(lua_State *L) {
	BEGIN();
	(void)L;
	END(0);
}

/// Global ECP2 functions
// @section ECP2.globals

/***
Create a new ECP2 point from four X, Xi, Y, Yi @{BIG} arguments.

If no arguments are specified then the ECP points to the curve's **generator** coordinates.

If only the first two arguments are provided (X and Xi), then Y and Yi are calculated from them.

    @param X a BIG number on the curve
    @param Xi imaginary part of the X (BIG number)
    @param Y a BIG number on the curve
    @param Yi imaginary part of the Y (BIG number)
    @return a new ECP2 point on the curve at X, Xi, Y, Yi coordinates or the curve's Generator
    @function ECP2.new(X, Xi, Y, Yi)
*/
static int lua_new_ecp2(lua_State *L) {
	// WARNING: each if implement his own try-catch with gotos
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = NULL;
// TODO: unsafe and only needed when running tests
#ifdef DEBUG
	void *tx  = luaL_testudata(L, 1, "zenroom.big");
	void *txi = luaL_testudata(L, 2, "zenroom.big");
	void *ty  = luaL_testudata(L, 3, "zenroom.big");
	void *tyi = luaL_testudata(L, 4, "zenroom.big");

	if(tx && txi && ty && tyi) {
		ecp2 *e = ecp2_new(L);
		big *x, *xi, *y, *yi;
		x  = big_arg(L, 1);
		xi = big_arg(L, 2);
		y  = big_arg(L, 3);
		yi = big_arg(L, 4);
		if(!x || !y || !xi || !yi) {
			failed_msg = "Could not create BIG";
			goto end_big_big_big_big;
		}
		FP2 fx, fy;
		FP2_from_BIGs(&fx, x->val, xi->val);
		FP2_from_BIGs(&fy, y->val, yi->val);
		if(!ECP2_set(&e->val, &fx, &fy)) {
			warning(L, "new ECP2 value out of curve (points to infinity)");
			goto end_big_big_big_big;
		}
end_big_big_big_big:
		big_free(L,yi);
		big_free(L,y);
		big_free(L,xi);
		big_free(L,x);
		goto end;
	}
	// If x is on the curve then y is calculated from the curve equation.
	if(tx && txi) {
		ecp2 *e = ecp2_new(L);
		big *x, *xi;
		x  = big_arg(L, 1);
		xi = big_arg(L, 2);
		if(!x || !xi) {
			failed_msg = "Could not create BIG";
			goto end_big_big;
		}
		FP2 fx;
		FP2_from_BIGs(&fx, x->val, xi->val);
		if(!ECP2_setx(&e->val, &fx)) {
			warning(L, "new ECP2 value out of curve (points to infinity)");
			goto end_big_big;
		}
end_big_big:
		big_free(L,xi);
		big_free(L,x);
		goto end;
	}
#endif
	o = o_arg(L, 1); SAFE_GOTO(o, ALLOCATE_OCT_ERR);
	ecp2 *e = ecp2_new(L); SAFE_GOTO(e, CREATE_ECP2_ERR);
	SAFE_GOTO(ECP2_fromOctet(&e->val, (octet*)o), "Octet doesn't contains a valid ECP2");
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Returns the generator of the twisted curve:
    an ECP2 point to its X and Y coordinates.

    @function generator()
    @return ECP2 coordinates of the curve's generator.
*/
static int ecp2_generator(lua_State *L) {
	BEGIN();
	ecp2 *e = ecp2_new(L); SAFE(e, CREATE_ECP2_ERR);
	/* 	FP2 x, y;
	FP2_from_BIGs(&x, (chunk*)CURVE_G2xa, (chunk*)CURVE_G2xb);
	FP2_from_BIGs(&y, (chunk*)CURVE_G2ya, (chunk*)CURVE_G2yb);
	if(!ECP2_set(&e->val, &x, &y)) {
		lerror(L, "ECP2 generator value out of curve (stack corruption)");
		return 0; }
 */
	ECP2_generator(&e->val);
	END(1);
}


static int ecp2_millerloop(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *x = NULL;
	const ecp *y = NULL;
	x = ecp2_arg(L, 1); SAFE_GOTO(x, ALLOCATE_ECP2_ERR);
	y = ecp_arg(L, 2); SAFE_GOTO(y, ALLOCATE_ECP_ERR);
	fp12 *f = fp12_new(L); SAFE_GOTO(f, CREATE_FP12_ERR);
	ECP2_affine((ECP2*)&x->val);
	ECP_affine((ECP*)&y->val);
	PAIR_ate(&f->val, (ECP2*)&x->val, (ECP*)&y->val);
	PAIR_fexp(&f->val);
end:
	ecp_free(L, y);
	ecp2_free(L, x);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/// Class methods
// @type ecp2

/***
    Make an existing ECP2 point affine with the curve
    @function ecp2:affine()
    @return affine version of the ECP2 point
*/
static int ecp2_affine(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *in = ecp2_arg(L, 1); SAFE_GOTO(in, ALLOCATE_ECP2_ERR);
	ecp2 *out = ecp2_dup(L, in); SAFE_GOTO(out, DUPLICATE_ECP2_ERR);
	ECP2_affine(&out->val);
end:
	ecp2_free(L, in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Returns a new ECP2 infinity point that is definitely not on the curve.

    @function infinity()
    @return ECP2 pointing to infinity (out of the curve).
*/
static int ecp2_get_infinity(lua_State *L) {
	BEGIN();
	ecp2 *e = ecp2_new(L); SAFE(e, CREATE_ECP2_ERR);
	ECP2_inf(&e->val);
	END(1);
}

/***
    Returns true if an ECP2 coordinate points to infinity (out of the curve) and false otherwise.

    @function isinf()
    @return false if point is on curve, true if its off curve into infinity.
*/
static int ecp2_isinf(lua_State *L) {
	BEGIN();
	const ecp2 *e = ecp2_arg(L, 1); SAFE(e, ALLOCATE_ECP2_ERR);
	lua_pushboolean(L, ECP2_isinf((ECP2*)&e->val));
	ecp2_free(L, e);
	END(1);
}

/***
    Add two ECP2 points to each other (commutative and associative operation).
    Can be made using the overloaded operator `+` between two ECP2 objects
    just like they would be numbers.

    @param first ECP2 point to be summed
    @param second ECP2 point to be summed
    @function add(first, second)
    @return sum resulting from the addition
*/
static int ecp2_add(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1);
	const ecp2 *q = ecp2_arg(L, 2);
	SAFE_GOTO(e && q, ALLOCATE_ECP2_ERR);
	ecp2 *p = ecp2_dup(L, e); SAFE_GOTO(p, DUPLICATE_ECP2_ERR);
	ECP2_add(&p->val, (ECP2*)&q->val);
end:
	ecp2_free(L, e);
	ecp2_free(L, q);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
    Subtract an ECP2 point from another (commutative and associative operation).
    Can be made using the overloaded operator `-` between two ECP2 objects
    just like they would be numbers.

    @param first ECP2 point from which the second should be subtracted
    @param second ECP2 point to use in the subtraction
    @function sub(first, second)
    @return new ECP2 point resulting from the subtraction
*/
static int ecp2_sub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1);
	const ecp2 *q = ecp2_arg(L, 2);
	SAFE_GOTO(e && q, ALLOCATE_ECP2_ERR);
	ecp2 *p = ecp2_dup(L, e); SAFE_GOTO(p, DUPLICATE_ECP2_ERR);
	ECP2_sub(&p->val, (ECP2*)&q->val);
end:
	ecp2_free(L, e);
	ecp2_free(L, q);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Transforms an ECP2 point into its equivalent negative point on the elliptic curve.

    @function negative()
*/
static int ecp2_negative(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *in = ecp2_arg(L, 1); SAFE_GOTO(in, ALLOCATE_ECP2_ERR);
	ecp2 *out = ecp2_dup(L, in); SAFE_GOTO(out, DUPLICATE_ECP2_ERR);
	ECP2_neg(&out->val);
end:
	ecp2_free(L, in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
    Compares two ECP2 points and returns true if they indicate the same
    point on the curve (they are equal) or false otherwise.
    It can also be executed by using the `==` overloaded operator.

    @param first ECP2 point to be compared
    @param second ECP2 point to be compared
    @function eq(first, second)
    @return bool value: true if equal, false if not equal
*/
static int ecp2_eq(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *p = ecp2_arg(L, 1);
	const ecp2 *q = ecp2_arg(L, 2);
	SAFE_GOTO(p && q, ALLOCATE_ECP2_ERR);
// TODO: is affine rly needed?
	ECP2_affine((ECP2*)&p->val);
	ECP2_affine((ECP2*)&q->val);
	lua_pushboolean(L, ECP2_equals((ECP2*)&p->val, (ECP2*)&q->val));
end:
	ecp2_free(L, p);
	ecp2_free(L, q);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
    Returns an octet containing all serialized @{BIG} number coordinates
    of an ECP2 point on the curve. It can be used to port the value of an
    ECP2 point into @{OCTET:hex} or @{OCTET:base64} encapsulation,
    to be later set again into an ECP2 point using @{ECP2:new}.

    @function octet()
    @return an OCTET sequence
*/
static int ecp2_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	octet *o = o_new(L, (MODBYTES<<2)+1); SAFE_GOTO(o, CREATE_OCT_ERR);
	ECP2_toOctet(o, (ECP2*)&e->val);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int ecp2_mul(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *b = NULL;
	const ecp2 *p = ecp2_arg(L, 1); SAFE_GOTO(p, ALLOCATE_ECP2_ERR);
	b = big_arg(L, 2); SAFE_GOTO(b, ALLOCATE_BIG_ERR);
	ecp2 *r = ecp2_dup(L, p); SAFE_GOTO(r, DUPLICATE_ECP2_ERR);
	PAIR_G2mul(&r->val, b->val);
end:
	big_free(L, b);
	ecp2_free(L, p);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
    Map a @{BIG} number to a point of the curve,
    where the BIG number should be the output of some hash function.

    @param BIG number resulting from an hash function
    @function mapit(BIG)
*/
static int ecp2_mapit(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1); SAFE_GOTO(o, ALLOCATE_OCT_ERR);
	SAFE_GOTO(o->len == 64, "Invalid argument, octet must be 64 bytes");
	ecp2 *e = ecp2_new(L); SAFE_GOTO(e, CREATE_ECP2_ERR);
	ECP2_mapit(&e->val, (octet*)o);
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// get the x coordinate real part as BIG
static int ecp2_get_xr(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	big *xa = big_new(L); SAFE_GOTO(xa, CREATE_BIG_ERR);
	big_init(L,xa);
	FP fx;
	FP_copy(&fx, (FP*)&e->val.x.a);
	FP_reduce(&fx); FP_redc(xa->val, &fx);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
// get the x coordinate imaginary part as BIG
static int ecp2_get_xi(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	big *xb = big_new(L); SAFE_GOTO(xb, CREATE_BIG_ERR);
	big_init(L,xb);
	FP fx;
	FP_copy(&fx, (FP*)&e->val.x.b);
	FP_reduce(&fx); FP_redc(xb->val, &fx);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// get the y coordinate real part as BIG
static int ecp2_get_yr(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	big *ya = big_new(L); SAFE_GOTO(ya, CREATE_BIG_ERR);
	big_init(L,ya);
	FP fy;
	FP_copy(&fy, (FP*)&e->val.y.a);
	FP_reduce(&fy); FP_redc(ya->val, &fy);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int ecp2_get_yi(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	big *yb = big_new(L); SAFE_GOTO(yb, CREATE_BIG_ERR);
	big_init(L,yb);
	FP fy;
	FP_copy(&fy, (FP*)&e->val.y.b);
	FP_reduce(&fy); FP_redc(yb->val, &fy);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int ecp2_get_zr(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	big *za = big_new(L); SAFE_GOTO(za, CREATE_BIG_ERR);
	big_init(L,za);
	FP fz;
	FP_copy(&fz, (FP*)&e->val.z.a);
	FP_reduce(&fz); FP_redc(za->val, &fz);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int ecp2_get_zi(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	big *zb = big_new(L); SAFE_GOTO(zb, CREATE_BIG_ERR);
	big_init(L,zb);
	FP fz;
	FP_copy(&fz, (FP*)&e->val.z.b);
	FP_reduce(&fz); FP_redc(zb->val, &fz);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int ecp2_output(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	if (ECP2_isinf((ECP2*)&e->val)) { // Infinity
		octet *o = o_new(L, 3); SAFE_GOTO(o, CREATE_OCT_ERR);
		o->val[0] = SCHAR_MAX; o->val[1] = SCHAR_MAX;
		o->val[3] = 0x0; o->len = 2;
		goto end;
	}
	octet *o = o_new(L, e->totlen + 0x0f); SAFE_GOTO(o, CREATE_OCT_ERR);
	_ecp2_to_octet(o, e);
	push_octet_to_hex_string(L, o);
end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

char gf2_sign(BIG y0, BIG y1){

	if (BIG_iszilch(y1)) {
		return gf_sign(y0);
	}

	BIG p;
	BIG_rcopy(p, CURVE_Prime);
	BIG_dec(p, 1);
	BIG_norm(p);
	BIG_shr(p, 1);
	if(BIG_comp(y1, p) == 1){
		return 1;
	} else {
		return 0;
	}
}

static int ecp2_zcash_export(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const ecp2 *e = ecp2_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP2_ERR);
	octet *o = o_new(L, 96); SAFE_GOTO(o, CREATE_OCT_ERR);
	if(ECP2_isinf((ECP2*)&e->val)) {
		o->len = 96;
		o->val[0] = (char)0xc0;
		memset(o->val+1, 0, 95);
	} else {
		FP2 x,y;
		const char c_bit = 1;
		const char i_bit = 0;

		ECP2_get(&x, &y, (ECP2*)&e->val);

		BIG bx0,bx1,by0,by1;
		FP2_reduce(&x);
		FP_redc(bx0,&(x.a));
		FP_redc(bx1,&(x.b));

		FP2_reduce(&y);
		FP_redc(by0,&(y.a));
		FP_redc(by1,&(y.b));

		const char s_bit = gf2_sign(by0, by1);
		char m_byte = (char)((c_bit << 7)+(i_bit << 6)+(s_bit << 5));

		BIG_toBytes(o->val+48, bx0);
		BIG_toBytes(o->val, bx1);
		o->len = 96;


		o->val[0] |= m_byte;
	}

end:
	ecp2_free(L, e);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// TODO: remove if not used
//static int sign_gf(const big* x0, const big* x1) {
//	BIG p = CURVE_Prime;
//
//}


// See the generalised version commented inside zen_octec.c
// TODO: remove magic numbers
// TODO: implement import for non compressed octets
static int ecp2_zcash_import(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *x0 = NULL, *x1 = NULL;
	const octet *o = o_arg(L, 1); SAFE_GOTO(o, ALLOCATE_OCT_ERR);
	ecp2 *e = ecp2_new(L); SAFE_GOTO(e, CREATE_ECP2_ERR);
	register unsigned char m_byte = o->val[0] & 0xE0;
	bool c_bit;
	bool i_bit;
	bool s_bit;
	SAFE_GOTO(m_byte != 0x20 && m_byte != 0x60 && m_byte != 0xE0, "Invalid octet header");
	c_bit = ((m_byte & 0x80) == 0x80);
	i_bit = ((m_byte & 0x40) == 0x40);
	s_bit = ((m_byte & 0x20) == 0x20);

	if(c_bit) {
		SAFE_GOTO(o->len == 96, "Invalid octet length for compressed point");
	} else {
		SAFE_GOTO(o->len == 192, "Invalid octet length for uncompressed point");
	}

	if(i_bit) {
		// TODO: check o->val is all 0
		ECP2_inf(&e->val);
		goto end;
	}

	if(c_bit) {
		FP2 fx, fy;
		x0 = o_alloc(L,48); SAFE_GOTO(x0, ALLOCATE_OCT_ERR);
		memcpy(x0->val,o->val,48);
		x0->val[0] = x0->val[0] & 0x1F;
		x0->len = 48;
		x1 = o_alloc(L,48); SAFE_GOTO(x1, ALLOCATE_OCT_ERR);
		memcpy(x1->val,o->val+48,48);
		x1->val[0] = x1->val[0] & 0x1F;
		x1->len = 48;
		big* bigx0 = big_new(L); SAFE_GOTO(bigx0, CREATE_BIG_ERR);
		big* bigx1 = big_new(L); SAFE_GOTO(bigx1, CREATE_BIG_ERR);
		SAFE_GOTO(_octet_to_big(L, bigx0, x0), "Could not create BIG from OCTET");
		SAFE_GOTO(_octet_to_big(L, bigx1, x1), "Could not create BIG from OCTET");
		FP2_from_BIGs(&fx, bigx1->val, bigx0->val);
		SAFE_GOTO(ECP2_setx(&e->val, &fx), "Invalid input octet: not a point on the curve");
		ECP2_get(&fx, &fy, &e->val);

		BIG by0,by1;
		FP2_reduce(&fy);
		FP_redc(by0,&(fy.a));
		FP_redc(by1,&(fy.b));

		if(gf2_sign(by0, by1) != s_bit) {
			ECP2_neg(&e->val);
		}
		lua_pop(L,1); // bigx0
		lua_pop(L,1); // bigx1
	} else {
		failed_msg = "Not yet implemented";
		goto end;
	}

end:
	o_free(L, x0);
	o_free(L, x1);
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_ecp2(lua_State *L) {
	(void)L;
	const struct luaL_Reg ecp2_class[] = {
		{"new", lua_new_ecp2},
		{"generator", ecp2_generator},
		{"G", ecp2_generator},
		{"mapit", ecp2_mapit},
		{"inf", ecp2_get_infinity},
		{"infinity", ecp2_get_infinity},
		{"from_zcash", ecp2_zcash_import},
		// basic pairing function & aliases
		{"pair", ecp2_millerloop},
		{"loop", ecp2_millerloop},
		{"miller", ecp2_millerloop},
		{"ate", ecp2_millerloop},
		{NULL, NULL}};
	const struct luaL_Reg ecp2_methods[] = {
		{"affine", ecp2_affine},
		{"negative", ecp2_negative},
		{"isinf", ecp2_isinf},
		{"isinfinity", ecp2_isinf},
		{"octet", ecp2_octet},
		{"xr", ecp2_get_xr},
		{"xi", ecp2_get_xi},
		{"yr", ecp2_get_yr},
		{"yi", ecp2_get_yi},
		{"zr", ecp2_get_zr},
		{"zi", ecp2_get_zi},
		{"add", ecp2_add},
		{"__add", ecp2_add},
		{"sub", ecp2_sub},
		{"__sub", ecp2_sub},
		{"eq", ecp2_eq},
		{"__eq", ecp2_eq},
		{"mul", ecp2_mul},
		{"__mul", ecp2_mul},
		{"__gc", ecp2_destroy},
		{"__tostring", ecp2_output},
		{"to_zcash", ecp2_zcash_export},
		{NULL, NULL}
	};
	zen_add_class(L, "ecp2", ecp2_class, ecp2_methods);
	return 1;
}
