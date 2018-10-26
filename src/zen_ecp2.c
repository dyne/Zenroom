// Zenroom ECP2 module
//
// (c) Copyright 2017-2018 Dyne.org foundation
// designed, written and maintained by Denis Roio <jaromil@dyne.org>
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// version 3 as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.

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
//  @license GPLv3
//  @copyright Dyne.org foundation 2017-2018


#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_ecp_bls383.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <zen_big.h>
#include <zen_fp12.h>
#include <zen_memory.h>
#include <lua_functions.h>


typedef struct {
	char curve[16];
	char type[16];
	BIG  order;
	ECP2  val;
	// TODO: the values above make it necessary to propagate the
	// visibility on the specific curve point types to the rest of the
	// code. To abstract these and have get/set functions may save a
	// lot of boilerplate when implementing support for multiple
	// curves ECP.
} ecp2;


ecp2* ecp2_new(lua_State *L) {
	ecp2 *e = (ecp2 *)lua_newuserdata(L, sizeof(ecp2));
	if(!e) {
		lerror(L, "Error allocating new ecp2 in %s",__func__);
		return NULL; }
	strcpy(e->curve,"bls383");
	strcpy(e->type,"weierstrass");
	BIG_copy(e->order, (chunk*)CURVE_Order);
	luaL_getmetatable(L, "zenroom.ecp2");
	lua_setmetatable(L, -2);
	return(e);
}
ecp2* ecp2_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.ecp2");
	luaL_argcheck(L, ud != NULL, n, "ecp2 class expected");
	ecp2 *e = (ecp2*)ud;
	return(e);
}
ecp2* ecp2_dup(lua_State *L, ecp2* in) {
	ecp2 *e = ecp2_new(L); SAFE(e);
	ECP2_copy(&e->val, &in->val);
	return(e);
}
int ecp2_destroy(lua_State *L) {
	HERE();
	ecp2 *e = ecp2_arg(L,1);
	SAFE(e);
	return 0;
}

/// Global ECP2 functions
// @section ECP2.globals

/***
Create a new ECP2 point from four X,Xi,Y,Yi @{BIG} arguments.

If no arguments are specified then the ECP points to the curve's **generator** coordinates.

If only the first two arguments are provided (X and Xi), then Y and Yi are calculated from them.

    @param X a BIG number on the curve
    @param Xi imaginary part of the X (BIG number)
    @param Y a BIG number on the curve
    @param Yi imaginary part of the Y (BIG number)
    @return a new ECP2 point on the curve at X,Xi,Y,Yi coordinates or the curve's Generator
    @function ECP2.new(X,Xi,Y,Yi)
*/
static int lua_new_ecp2(lua_State *L) {
	if(lua_isnoneornil(L, 1)) { // no args: set to generator
		ecp2 *e = ecp2_new(L); SAFE(e);
		FP2 x, y;
		FP2_from_BIGs(&x,(chunk*)CURVE_G2xa,(chunk*)CURVE_G2xb);
		FP2_from_BIGs(&y,(chunk*)CURVE_G2ya,(chunk*)CURVE_G2yb);

		if(!ECP2_set(&e->val,&x,&y)) {
			lerror(L,"ECP2 generator value out of curve (stack corruption)");
			return 0; }
		return 1; }

	void *tx  = luaL_testudata(L, 1, "zenroom.big");
	void *txi = luaL_testudata(L, 2, "zenroom.big");
	void *ty  = luaL_testudata(L, 3, "zenroom.big");
	void *tyi = luaL_testudata(L, 4, "zenroom.big");

	if(tx && txi && ty && tyi) {
		ecp2 *e = ecp2_new(L); SAFE(e);
		big *x, *xi, *y, *yi;
		x  = big_arg(L, 1); SAFE(x);
		xi = big_arg(L, 2); SAFE(xi);
		y  = big_arg(L, 3); SAFE(y);
		yi = big_arg(L, 4); SAFE(yi);
		FP2 fx, fy;
		FP2_from_BIGs(&fx,x->val,xi->val);
		FP2_from_BIGs(&fy,y->val,yi->val);
		if(!ECP2_set(&e->val, &fx, &fy))
			warning(L,"new ECP2 value out of curve (points to infinity)");
		return 1; }
	// If x is on the curve then y is calculated from the curve equation.
	if(tx && txi) {
		ecp2 *e = ecp2_new(L); SAFE(e);
		big *x, *xi;
		x  = big_arg(L, 1); SAFE(x);
		xi = big_arg(L, 2); SAFE(xi);
		FP2 fx;
		FP2_from_BIGs(&fx,x->val,xi->val);
		if(!ECP2_setx(&e->val, &fx))
			warning(L,"new ECP2 value out of curve (points to infinity)");
		return 1; }
	lerror(L, "ECP2.new() expected zenroom.big arguments or none");
	return 0;
}

/***
    Returns the generator of the twisted curve: an ECP2 point to its X and Y coordinates.

    @function generator()
    @return ECP2 coordinates of the curve's generator.
*/
static int ecp2_generator(lua_State *L) {
	ecp2 *e = ecp2_new(L); SAFE(e);
/* 	FP2 x, y;
	FP2_from_BIGs(&x,(chunk*)CURVE_G2xa,(chunk*)CURVE_G2xb);
	FP2_from_BIGs(&y,(chunk*)CURVE_G2ya,(chunk*)CURVE_G2yb);
	if(!ECP2_set(&e->val,&x,&y)) {
		lerror(L,"ECP2 generator value out of curve (stack corruption)");
		return 0; }
 */
	ECP2_generator(&e->val);
	return 1;
}


static int ecp2_millerloop(lua_State *L) {
	fp12 *f = fp12_new(L);   SAFE(f);
	ecp2 *x = ecp2_arg(L,1); SAFE(x);
	ecp  *y = ecp_arg(L,2);  SAFE(y);
	ECP2_affine(&x->val);
	ECP_affine(&y->val);
	PAIR_ate(&f->val,&x->val,&y->val);
	PAIR_fexp(&f->val);
	return 1;
}

/// Class methods
// @type ecp2

/***
    Make an existing ECP2 point affine with the curve
    @function ecp2:affine()
    @return affine version of the ECP2 point
*/
static int ecp2_affine(lua_State *L) {
	ecp2 *in = ecp2_arg(L,1); SAFE(in);
	ecp2 *out = ecp2_dup(L,in); SAFE(out);
	ECP2_affine(&out->val);
	return 1;
}

/***
    Returns true if an ECP2 coordinate points to infinity (out of the curve) and false otherwise.

    @function isinf()
    @return false if point is on curve, true if its off curve into infinity.
*/
static int ecp2_isinf(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	lua_pushboolean(L,ECP2_isinf(&e->val));
	return 1;
}

/***
    Add two ECP2 points to each other (commutative and associative operation). Can be made using the overloaded operator `+` between two ECP2 objects just like they would be numbers.

    @param first ECP2 point to be summed
    @param second ECP2 point to be summed
    @function add(first,second)
    @return sum resulting from the addition
*/
static int ecp2_add(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	ecp2 *q = ecp2_arg(L,2); SAFE(q);
	ecp2 *p = ecp2_dup(L, e); // push
	SAFE(p);
	ECP2_add(&p->val,&q->val);
	return 1;
}


/***
    Subtract an ECP2 point from another (commutative and associative operation). Can be made using the overloaded operator `-` between two ECP2 objects just like they would be numbers.

    @param first ECP2 point from which the second should be subtracted
    @param second ECP2 point to use in the subtraction
    @function sub(first,second)
    @return new ECP2 point resulting from the subtraction
*/
static int ecp2_sub(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	ecp2 *q = ecp2_arg(L,2); SAFE(q);
	ecp2 *p = ecp2_dup(L, e); // push
	SAFE(p);
	ECP2_sub(&p->val,&q->val);
	return 1;
}

/***
    Transforms an ECP2 point into its equivalent negative point on the elliptic curve.

    @function negative()
*/
static int ecp2_negative(lua_State *L) {
	ecp2 *in = ecp2_arg(L,1); SAFE(in);
	ecp2 *out = ecp2_dup(L,in); SAFE(out);
	ECP2_neg(&out->val);
	return 1;
}


/***
    Compares two ECP2 points and returns true if they indicate the same point on the curve (they are equal) or false otherwise. It can also be executed by using the `==` overloaded operator.

    @param first ECP2 point to be compared
    @param second ECP2 point to be compared
    @function eq(first,second)
    @return bool value: true if equal, false if not equal
*/
static int ecp2_eq(lua_State *L) {
	ecp2 *p = ecp2_arg(L,1); SAFE(p);
	ecp2 *q = ecp2_arg(L,2); SAFE(q);
// TODO: is affine rly needed?
	ECP2_affine(&p->val);
	ECP2_affine(&q->val);
	lua_pushboolean(L,ECP2_equals(
		                &p->val, &q->val));
	return 1;
}

static int ecp2_mul(lua_State *L) {
	ecp2 *p = ecp2_arg(L,1); SAFE(p);
	big  *b = big_arg(L,2); SAFE(b);
	ecp2 *r = ecp2_dup(L, p); SAFE(r);	
	PAIR_G2mul(&r->val,b->val);
	return 1;
}


/***
    Map a @{BIG} number to a point of the curve, where the BIG number should be the output of some hash function.

    @param BIG number resulting from an hash function
    @function mapit(BIG)
*/
static int ecp2_mapit(lua_State *L) {
	big *b = big_arg(L,1); SAFE(b);
	ecp2 *e = ecp2_new(L); SAFE(e);
	// this has to convert a big into an octet
	// https://github.com/milagro-crypto/milagro-crypto-c/pull/286
	BIG_norm(b->val);
	octet *o = o_new(L,b->len); SAFE(o);
	lua_pop(L, 1); // pop the new temporary octet
	BIG_toBytes(o->val,b->val);
	o->len = b->len;
	ECP2_mapit(&e->val,o);
	return 1;
}

// get the x coordinate real part as BIG
static int ecp2_get_xr(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	FP fx;
	big *xa = big_new(L); big_init(xa); SAFE(xa);
	FP_copy(&fx,&e->val.x.a);
	FP_reduce(&fx); FP_redc(xa->val, &fx);
	return 1;
}
// get the x coordinate imaginary part as BIG
static int ecp2_get_xi(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	FP fx;
	big *xb = big_new(L); big_init(xb); SAFE(xb);
	FP_copy(&fx,&e->val.x.b);
	FP_reduce(&fx); FP_redc(xb->val, &fx);
	return 1;
}

// get the y coordinate real part as BIG
static int ecp2_get_yr(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	FP fy;
	big *ya = big_new(L); big_init(ya); SAFE(ya);
	FP_copy(&fy,&e->val.y.a);
	FP_reduce(&fy); FP_redc(ya->val, &fy);
	return 1;
}
static int ecp2_get_yi(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	FP fy;
	big *yb = big_new(L); big_init(yb); SAFE(yb);
	FP_copy(&fy,&e->val.y.b);
	FP_reduce(&fy); FP_redc(yb->val, &fy);
	return 1;
}
static int ecp2_get_zr(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	FP fz;
	big *za = big_new(L); big_init(za); SAFE(za);
	FP_copy(&fz,&e->val.z.a);
	FP_reduce(&fz); FP_redc(za->val, &fz);
	return 1;
}
static int ecp2_get_zi(lua_State *L) {
	ecp2 *e = ecp2_arg(L,1); SAFE(e);
	FP fz;
	big *zb = big_new(L); big_init(zb); SAFE(zb);
	FP_copy(&fz,&e->val.z.b);
	FP_reduce(&fz); FP_redc(zb->val, &fz);
	return 1;
}

int luaopen_ecp2(lua_State *L) {
	const struct luaL_Reg ecp2_class[] = {
		{"new",lua_new_ecp2},
		{"generator",ecp2_generator},
		{"G",ecp2_generator},
		{"mapit",ecp2_mapit},
		// basic pairing function & aliases
		{"pair",ecp2_millerloop},
		{"loop",ecp2_millerloop},
		{"miller",ecp2_millerloop},
		{"ate",ecp2_millerloop},
		{NULL,NULL}};
	const struct luaL_Reg ecp2_methods[] = {
		{"affine",ecp2_affine},
		{"negative",ecp2_negative},
		{"isinf",ecp2_isinf},
		{"isinfinity",ecp2_isinf},
		{"xr",ecp2_get_xr},
		{"xi",ecp2_get_xi},
		{"yr",ecp2_get_yr},
		{"yi",ecp2_get_yi},
		{"zr",ecp2_get_zr},
		{"zi",ecp2_get_zi},
		{"add",ecp2_add},
		{"__add",ecp2_add},
		{"sub",ecp2_sub},
		{"__sub",ecp2_sub},
		{"eq",ecp2_eq},
		{"__eq", ecp2_eq},
		{"mul",ecp2_mul},
		{"__mul",ecp2_mul},
		{NULL,NULL}
	};
	zen_add_class(L, "ecp2", ecp2_class, ecp2_methods);
	return 1;
}
