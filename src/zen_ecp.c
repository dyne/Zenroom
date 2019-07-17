/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2019 Dyne.org foundation
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
//  @license GPLv3
//  @copyright Dyne.org foundation 2017-2018


#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_ecp.h>
#include <zen_ecp_bls383.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <zen_big.h>
#include <zen_fp12.h>
#include <zen_memory.h>
#include <lua_functions.h>

ecp* ecp_new(lua_State *L) {
	ecp *e = (ecp *)lua_newuserdata(L, sizeof(ecp));
	if(!e) {
		lerror(L, "Error allocating new ecp in %s",__func__);
		return NULL; }
	strcpy(e->curve,"bls383");
	strcpy(e->type,"weierstrass");
	e->biglen = sizeof(BIG);
	e->totlen = (MODBYTES*2)+1; // length of ECP.new(rng:modbig(o),0):octet()
	BIG_copy(e->order, (chunk*)CURVE_Order);
	luaL_getmetatable(L, "zenroom.ecp");
	lua_setmetatable(L, -2);
	return(e);
}
ecp* ecp_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.ecp");
	luaL_argcheck(L, ud != NULL, n, "ecp class expected");
	ecp *e = (ecp*)ud;
	return(e);
}
ecp* ecp_dup(lua_State *L, ecp* in) {
    ecp *e = ecp_new(L); SAFE(e);
	ECP_copy(&e->val, &in->val);
	return(e);
}
int ecp_destroy(lua_State *L) {
	HERE();
	ecp *e = ecp_arg(L,1);
	SAFE(e);
	return 0;
}

int _fp_to_big(big *dst, FP *src) {
	FP_reduce(src);
	FP_redc(dst->val,src);
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

	// unsafe parsing into BIG, only necessary for tests
	// deactivate when not running tests
#ifdef DEBUG
	void *tx = luaL_testudata(L, 1, "zenroom.big");
	void *ty = luaL_testudata(L, 2, "zenroom.big");
	if(tx && ty) {
		ecp *e = ecp_new(L); SAFE(e);
		big *x, *y;
		x = big_arg(L, 1); SAFE(x);
		y = big_arg(L, 2); SAFE(y);
		if(!ECP_set(&e->val, x->val, y->val))
			warning(L,"new ECP value out of curve (points to infinity)");
		return 1; }
	// If x is on the curve then y is calculated from the curve equation.
	int tn;
	lua_Number n = lua_tonumberx(L, 2, &tn);
	if(tx && tn) {
		ecp *e = ecp_new(L); SAFE(e);
		big *x = big_arg(L, 1); SAFE(x);
		if(!ECP_setx(&e->val, x->val, (int)n))
			warning(L,"new ECP value out of curve (points to infinity)");
		return 1; }
#endif

	// Support string argument for the representation of "Infinity"
	size_t linf;
	char *inf = lua_tolstring(L, 1, &linf);
	if(inf && linf==8) // strlen("Infinity")
		if(strcmp(inf, "Infinity")==0) {
			ecp *e = ecp_new(L); SAFE(e);
			ECP_inf(&e->val);
			return 1;
		}
	// We protect well this entrypoint since parsing any input is at risk
	// Milagro's _fromOctet() uses ECP_BLS383_set(ECP_BLS383 *P,BIG_384_29 x)
	// then converts the BIG to an FP modulo using FP_BLS383_nres.
	octet *o = o_arg(L,1); SAFE(o);
	ecp *e = ecp_new(L); SAFE(e);
	if(o->len > e->totlen) { // quick and dirty safety
		lua_pop(L,1);
		error(L,"Octet length %u instead of %u bytes",o->len,e->totlen);
		lerror(L,"Invalid octet length to parse an ECP point");
		return 0; }
	int res = ECP_validate(o);
	if(res<0) { // test in Milagro's ecdh_*.h ECP_*_PUBLIC_KEY_VALIDATE
		lua_pop(L,1);
		error(L,"ECP point validation returns %i",res);
		lerror(L,"Octet is not a valid public key (point is not on this curve)");
		return 0; }
	if(! ECP_fromOctet(&e->val, o) ) {
		lua_pop(L,1);
		lerror(L,"Octet doesn't contains a valid ECP");
		return 0; }
	return 1;
}

/***
    Returns the generator of the curve: an ECP point that is multiplied by any @{BIG} number to obtain a correspondent point on the curve.

    @function generator()
    @return ECP point of the curve's generator.
*/
static int ecp_generator(lua_State *L) {
	ecp *e = ecp_new(L); SAFE(e);
/* 	if(!ECP_set(&e->val,
	    (chunk*)CURVE_Gx, (chunk*)CURVE_Gy)) {
		lerror(L,"ECP generator value out of curve (stack corruption)");
		return 0; }
 */
	ECP_generator(&e->val);
	return 1;
}

/***
    Returns a new ECP infinity point that is definitely not on the curve.

    @function infinity()
    @return ECP pointing to infinity (out of the curve).
*/
static int ecp_get_infinity(lua_State *L) {
	ecp *e = ecp_new(L); SAFE(e);
	ECP_inf(&e->val);
	return 1;
}


/***
    Gives the order of the curve, a @{BIG} number contained in an octet.

    @function order()
    @return a @{BIG} number containing the curve's order
*/
static int ecp_order(lua_State *L) {
	big *res = big_new(L); SAFE(res);
	big_init(res);
	// BIG is an array of int32_t on chunk 32 (see rom_curve)

	// curve order is ready-only so we need a copy for norm() to work
	BIG_copy(res->val,(chunk*)CURVE_Order);
	return 1;
}


/***
    Map an @{OCTET} of exactly 64 bytes length to a point on the curve: the OCTET should be the output of an hash function.

    @param OCTET resulting from an hash function
    @function mapit(OCTET)
    @return an ECP that is univocally linked to the input OCTET
*/
static int ecp_mapit(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	if(o->len != 64) {
		error(L,"octet length is %u instead of 64 (need to use sha512)",o->len);
		lerror(L,"Invalid argument to ECP.mapit(), not an hash");
		return 0; }
	ecp *e = ecp_new(L); SAFE(e);
	func(L,"mapit on o->len %u",o->len);
	ECP_mapit(&e->val, o);
	return 1;
}

/***
    Verify that an @{OCTET} really corresponds to an ECP point on the curve.

    @param OCTET point to be validated
    @function validate(OCTET)
    @return bool value: true if valid, false if not valid
*/
static int ecp_validate(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	int res = ECP_validate(o);
	lua_pushboolean(L,res>=0);
	return 1;
}


/// Instance Methods
// @type ecp

/***
    Make an existing ECP point affine with its curve
    @function affine()
    @return ECP point made affine
*/
static int ecp_affine(lua_State *L) {
	ecp *in = ecp_arg(L,1); SAFE(in);
	ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_affine(&out->val);
	return 1;
}
/***
    Returns true if an ECP coordinate points to infinity (out of the curve) and false otherwise.

    @function isinf()
    @return false if point is on curve, true if its off curve into infinity.
*/
static int ecp_isinf(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	lua_pushboolean(L,ECP_isinf(&e->val));
	return 1;
}

/***
    Add two ECP points to each other (commutative and associative operation). Can be made using the overloaded operator `+` between two ECP objects just like the would be numbers.

    @param first number to be summed
    @param second number to be summed
    @function add(first,second)
    @return sum resulting from the addition
*/
static int ecp_add(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	ecp *q = ecp_arg(L,2); SAFE(q);
	ecp *p = ecp_dup(L, e); // push
	SAFE(p);
	ECP_add(&p->val,&q->val);
	return 1;
}

/***
    Subtract an ECP point from another (commutative and associative operation). Can be made using the overloaded operator `-` between two ECP objects just like the would be numbers.

    @param first number from which the second should be subtracted
    @param second number to use in the subtraction
    @function sub(first,second)
    @return new ECP point resulting from the subtraction
*/
static int ecp_sub(lua_State *L) {
    ecp *e = ecp_arg(L,1); SAFE(e);
    ecp *q = ecp_arg(L,2); SAFE(q);
	ecp *p = ecp_dup(L, e); // push
	SAFE(p);
	ECP_sub(&p->val,&q->val);
	return 1;
}

/***
    Transforms an ECP point into its equivalent negative point on the elliptic curve.

    @function negative()
*/
static int ecp_negative(lua_State *L) {
	ecp *in = ecp_arg(L,1); SAFE(in);
	ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_neg(&out->val);
	return 1;
}

/***
    Transforms an ECP pointo into the double of its value, multiplying it by two. This works faster than multiplying it an arbitrary number of times.

    @function double()
*/
static int ecp_double(lua_State *L) {
	ecp *in = ecp_arg(L,1); SAFE(in);
	ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_dbl(&out->val);
	return 1;
}

/***
    Multiply an ECP point by a @{BIG} number. Can be made using the overloaded operator `*`

    @function mul(ecp,num)
    @param ecp point on the elliptic curve to be multiplied
    @param number indicating how many times it should be multiplied
    @return new ecp point resulting from the multiplication
*/
static int ecp_mul(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	big *b = big_arg(L,2); SAFE(b);
	if(b->doublesize) {
		lerror(L,"cannot multiply ECP point with double BIG numbers, need modulo");
		return 0; }
	ecp *out = ecp_dup(L,e); SAFE(out);
	PAIR_G1mul(&out->val,b->val);
	return 1;
}

/***
    Compares two ECP objects and returns true if they indicate the same point on the curve (they are equal) or false otherwise. It can also be executed by using the `==` overloaded operator.

    @param first ecp point to be compared
    @param second ecp point to be compared
    @function eq(first,second)
    @return bool value: true if equal, false if not equal
*/
static int ecp_eq(lua_State *L) {
	ecp *p = ecp_arg(L,1); SAFE(p);
    ecp *q = ecp_arg(L,2); SAFE(q);
// TODO: is affine rly needed?
	ECP_affine(&p->val);
	ECP_affine(&q->val);
	lua_pushboolean(L,ECP_equals(
		                &p->val, &q->val));
	return 1;
}


// use shared internally with octet o_arg()
int _ecp_to_octet(octet *o, ecp *e) {
	ECP_toOctet(o, &e->val);
	return(1);
}
/***
    Returns an octet containing the coordinate of an ECP point on the curve. It can be used to export the value of an ECP point into a string, using @{OCTET:hex} or @{OCTET:base64} encapsulation. It can be decoded back to an ECP point using @{ECP:new}.

    @function octet()
    @return the ECP point as an OCTET sequence
*/
static int ecp_octet(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	octet *o = o_new(L,e->totlen + 0x0f); SAFE(o);
	_ecp_to_octet(o,e);
	return 1;
}

/***
    Gives the X coordinate of the ECP point as a single @{BIG} number.

    @function x()
    @return a BIG number indicating the X coordinate of the point on curve.
*/
static int ecp_get_x(lua_State *L) {
	ecp *e = ecp_arg(L, 1); SAFE(e);
	FP fx;
	big *x = big_new(L);
	big_init(x);
	FP_copy(&fx, &e->val.x);
	FP_reduce(&fx);
	FP_redc(x->val,&fx);
	return 1;
}

/***
    Gives the Y coordinate of the ECP point as a single @{BIG} number.

    @function y()
    @return a BIG number indicating the Y coordinate of the point on curve.
*/
static int ecp_get_y(lua_State *L) {
	ecp *e = ecp_arg(L, 1); SAFE(e);
	FP fy;
	big *y = big_new(L);
	big_init(y);
	FP_copy(&fy, &e->val.y);
	FP_reduce(&fy);
	FP_redc(y->val,&fy);
	return 1;
}

static int ecp_table(lua_State *L) {
	ecp *e = ecp_arg(L, 1); SAFE(e);
	octet *o;
	ECP_affine(&e->val);
	lua_newtable(L);
	lua_pushstring(L,e->curve);
	lua_setfield(L,2,"curve");
	lua_pushstring(L,"hex");
	lua_setfield(L,2,"encoding");
	lua_pushstring(L,VERSION);
	lua_setfield(L,2,"zenroom");
	big *x,*y;
	x = big_new(L); big_init(x);
	lua_pop(L,1); _fp_to_big(x, &e->val.x);
	o = new_octet_from_big(L,x);
	lua_pop(L,1);
	push_octet_to_hex_string(o);
	lua_setfield(L,2,"x");
	// y
	y = big_new(L); big_init(y);
	lua_pop(L,1); _fp_to_big(y, &e->val.y);
	o = new_octet_from_big(L,y);
	lua_pop(L,1);
	push_octet_to_hex_string(o);
	lua_setfield(L,2,"y");
	return 1;
}

static int ecp_output(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	if (ECP_isinf(&e->val)) {
		lua_pushstring(L,"Infinity");
		return 1; }
	octet *o = o_new(L,e->totlen + 0x0f);
	SAFE(o); lua_pop(L,1);
	_ecp_to_octet(o,e);
	push_octet_to_hex_string(o);
	return 1;
}

int luaopen_ecp(lua_State *L) {
	const struct luaL_Reg ecp_class[] = {
		{"new",lua_new_ecp},
		{"inf",ecp_get_infinity},
		{"infinity",ecp_get_infinity},
		{"isinf",ecp_isinf},
		{"order",ecp_order},
		{"mapit",ecp_mapit},
		{"generator",ecp_generator},
		{"G",ecp_generator},
		{"add",ecp_add},
		{"sub",ecp_sub},
		{"mul",ecp_mul},
		{"validate",ecp_validate},
		{NULL,NULL}};
	const struct luaL_Reg ecp_methods[] = {
		{"affine",ecp_affine},
		{"negative",ecp_negative},
		{"double",ecp_double},
		{"isinf",ecp_isinf},
		{"isinfinity",ecp_isinf},
		{"octet",ecp_octet},
		{"table",ecp_table},
		{"add",ecp_add},
		{"x",ecp_get_x},
		{"y",ecp_get_y},
		{"__add",ecp_add},
		{"sub",ecp_sub},
		{"__sub",ecp_sub},
		{"mul",ecp_mul},
		{"__mul",ecp_mul},
        {"eq",ecp_eq},
		{"__eq", ecp_eq},
		{"__gc",ecp_destroy},
		{"__tostring",ecp_output},
		{NULL,NULL}
	};
	zen_add_class(L, "ecp", ecp_class, ecp_methods);
	return 1;
}
