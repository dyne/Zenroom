// Zenroom ECP module
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

#include <zen_ecp_bls383.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <zen_big.h>
#include <zen_fp12.h>
#include <zen_memory.h>
#include <lua_functions.h>

static char *big2strhex(char *str, BIG a) {
	BIG b;
	int i,len;
	int modby2 = modbytes<<1;
	len=BIG_nbits(a);
	int lendiv4 = len>>2;
	if (len%4==0) len=lendiv4;
	else {
		len=lendiv4;
		len++;
	}
	if (len<modby2) len=modby2;
	int c = 0;
	for (i=len-1; i>=0; i--) {
		BIG_copy(b,a);
		BIG_shr(b,i<<2);
		sprintf(str+c,"%01x",(unsigned int) b[0]&15);
		c++;
	}
	return str;
}

ecp* ecp_new(lua_State *L) {
	ecp *e = (ecp *)lua_newuserdata(L, sizeof(ecp));
	if(!e) {
		lerror(L, "Error allocating new ecp in %s",__func__);
		return NULL; }
	strcpy(e->curve,"bls383");
	strcpy(e->type,"weierstrass");
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

/***
    Create a new ECP point from two X,Y @{BIG} arguments. If no X,Y arguments are specified then the ECP points to the curve's @{generator} coordinates. If the first argument is an X coordinate on the curve and Y is just a number 0 or 1 then Y is calculated from the curve equation according to the given sign (plus or minus).

    @param[opt=BIG] X a BIG number on the curve
    @param[opt=BIG] Y a BIG number on the curve, 0 or 1 to calculate it
    @return a new ECP point on the curve at X,Y coordinates or Infinity
    @function new(X,Y)
    @see BIG:new
*/
static int lua_new_ecp(lua_State *L) {
	if(lua_isnoneornil(L, 1)) { // no args: set to generator
		ecp *e = ecp_new(L); SAFE(e);
		if(!ECP_set(&e->val,
		            (chunk*)CURVE_Gx, (chunk*)CURVE_Gy)) {
			lerror(L,"ECP generator value out of curve (stack corruption)");
			return 0; }
		return 1; }

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
	lerror(L, "ECP.new() expected zenroom.big arguments or none");
	return 0;
}

/***
    Returns the generator of the curve: an ECP point to its X and Y coordinates.

    @function generator()
    @return ECP coordinates of the curve's generator.
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

/// Instance Methods
// @type ecp

/***
    Make an existing ECP point affine with its curve
    @function affine()
*/
static int ecp_affine(lua_State *L) {
	ecp *in = ecp_arg(L,1); SAFE(in);
	ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_affine(&out->val);
	return 1;
}
/***
    Gives a new infinity point that is definitely not on the curve.
    @function infinity()
    @return ECP pointing to infinity out of the curve.
*/
static int ecp_get_infinity(lua_State *L) {
	ecp *e = ecp_new(L); SAFE(e);
	ECP_inf(&e->val);
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
    Map an @{OCTET} to a point of the curve, where the OCTET should be the output of some hash function.

    @param OCTET resulting from an hash function
    @function mapit(OCTET)
*/
static int ecp_mapit(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	ecp *e = ecp_new(L); SAFE(e);
	ECP_mapit(&e->val, o);
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
    Multiply an ECP point a number of times, indicated by an arbitrary ordinal number. Can be made using the overloaded operator `*` between an ECP object and an integer number.

    @function mul(ecp,num)
    @param ecp point on the elliptic curve to be multiplied
    @param number indicating how many times it should be multiplied
    @return new ecp point resulting from the multiplication
*/
static int ecp_mul(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	ecp *out = ecp_dup(L,e); SAFE(out);
	// implicitly convert scalar numbers to BIG
	int tn;
	lua_Number n = lua_tonumberx(L, 2, &tn);
	if(tn) {
		func(L,"G1mul argument is a scalar number");
		BIG bn;
		BIG_zero(bn);
		BIG_inc(bn,(int)n);
		BIG_norm(bn);
	    PAIR_G1mul(&out->val,bn);
		return 1; }
	big *b = big_arg(L,2); SAFE(b);
	func(L,"G1mul argument is a %s number",
		(b->doublesize)?"double BIG":"BIG");
	PAIR_G1mul(&out->val,(b->doublesize)?b->dval:b->val);
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

/***
    Sets or returns an octet containing a @{BIG} number composed by both x,y coordinates of an ECP point on the curve. It can be used to port the value of an ECP point into @{OCTET:hex} or @{OCTET:base64} encapsulation, to be later set again into an ECP point using this same call.

    @param ecp[opt=octet] the octet to be imported, none if to be exported
    @function octet(ecp)
*/
static int ecp_octet(lua_State *L) {
	void *ud;
	ecp *e = ecp_arg(L,1); SAFE(e);
	if((ud = luaL_testudata(L, 2, "zenroom.octet"))) {
		octet *o = (octet*)ud; SAFE(o);
		if(! ECP_fromOctet(&e->val, o) )
			lerror(L,"Octet doesn't contains a valid ECP");
		return 0;
	}
	octet *o = o_new(L,(modbytes<<1)+1);
	SAFE(o);
	ECP_toOctet(o, &e->val);
	return 1;
}

/***
    Gives the order of the curve, a BIG number contained in an octet.

    @function order()
    @return a BIG containing the curve's order
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

static int ecp_output(lua_State *L) {
	ecp *e = ecp_arg(L, 1); SAFE(e);
	ECP *P = &e->val;
	if (ECP_isinf(P)) {
		lua_pushstring(L,"Infinity");
		return 1; }
	BIG x;
	char xs[256];
	char out[512];
	ECP_affine(P);
	BIG y;
	char ys[256];
	FP_redc(x,&(P->x));
	FP_redc(y,&(P->y));
	snprintf(out, 511,
"{ \"curve\": \"%s\",\n"
"  \"encoding\": \"hex\",\n"
"  \"zenroom\": \"%s\",\n"
"  \"x\": \"%s\",\n"
"  \"y\": \"%s\" }",
	         e->curve, VERSION,
	         big2strhex(xs,x), big2strhex(ys,y));
	lua_pushstring(L,out);
	return 1;
}


int luaopen_ecp(lua_State *L) {
	const struct luaL_Reg ecp_class[] = {
		{"new",lua_new_ecp},
		{"inf",ecp_get_infinity},
		{"infinity",ecp_get_infinity},
		{"order",ecp_order},
		{"mapit",ecp_mapit},
		{"generator",ecp_generator},
		{"G",ecp_generator},
		{"add",ecp_add},
		{"sub",ecp_sub},
		{"mul",ecp_mul},
		{NULL,NULL}};
	const struct luaL_Reg ecp_methods[] = {
		{"affine",ecp_affine},
		{"negative",ecp_negative},
		{"double",ecp_double},
		{"isinf",ecp_isinf},
		{"isinfinity",ecp_isinf},
		{"octet",ecp_octet},
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
