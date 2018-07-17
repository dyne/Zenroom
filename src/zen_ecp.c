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
//  Base arithmetical operations on big number point coordinates on elliptic curves.
//
//  ECP arithmetic operations are provided to implement existing and
//  new encryption schemes: they are elliptic curve cryptographic
//  primitives and work the same across different curves. The ECP
//  primitive functions need this extension to be required explicitly:
//
//  <code>ecp = require'ecp'</code>
//
//  After requiring the extension it is possible to create ECP points
//  instances using the new() method, taking two arguments (the x and
//  y coordinates):
//
//  The values of each coordinate can be imported using octet methods
//  from hex or base64. These values (also called vectors) are very
//  big numbers whose representation is difficult without marshaling
//  them into such formats. Zenroom provides ECP tests based on the
//  BLS383 curve which come valid point coordinates on the curve.
//
//  Once ECP numbers are created this way, the arithmetic operations
//  of addition, subtraction and multiplication can be executed
//  normally using overloaded operators (+ - *).
//
//  @module ecp
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
#include <lua_functions.h>

typedef struct {
	char curve[16];
	char type[16];
	ECP *data;
} ecp;

void oct2big(big b, const octet *o) {
	big_zero(b);
	big_fromBytesLen(b,o->val,o->len);
}
void int2big(big b, int n) {
	big_zero(b);
	big_inc(b, n);
	big_norm(b);
}
char *big2strhex(char *str, big a) {
	big b;
	int i,len;
	int modby2 = modbytes<<1;
	len=big_nbits(a);
	int lendiv4 = len>>2;
	if (len%4==0) len=lendiv4;
	else {
		len=lendiv4;
		len++;
	}
	if (len<modby2) len=modby2;
	int c = 0;
	for (i=len-1; i>=0; i--) {
		big_copy(b,a);
		big_shr(b,i<<2);
		sprintf(str+c,"%01x",(unsigned int) b[0]&15);
		c++;
	}
	return str;
}

/***
    Create a new ECP point from two x,y octet arguments.

    Supported curve: bls383

    @param X octet of a big number
    @param Y octet of a big number
    @return a new ECP point on the curve at X,Y coordinates
    @function new(X,Y)
*/
ecp* ecp_new(lua_State *L) {
	ecp *e = (ecp *)lua_newuserdata(L, sizeof(ecp));
	if(!e) {
		lerror(L, "Error allocating new ecp in %s",__func__);
		return NULL; }
	e->data = malloc(sizeof(ECP_BLS383));
	strcpy(e->curve,"bls383");
	strcpy(e->type,"weierstrass");
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
ecp* ecp_dup(lua_State *L, const ecp* in) {
	ecp *e = ecp_new(L); SAFE(e);
	ECP_copy(e->data, in->data);
	return(e);
}
ecp* ecp_set_big_xy(lua_State *L, ecp *e, int idx) {
	SAFE(e);
	octet *o;
	o = o_arg(L, idx); SAFE(o);
	big x;
	oct2big(x, o);
	o = o_arg(L, idx+1); SAFE(o);
	big y;
	oct2big(y, o);
	ECP_set(e->data, x, y);
	return e;
}
int ecp_destroy(lua_State *L) {
	HERE();
	ecp *e = ecp_arg(L,1);
	SAFE(e);
	FREE(e->data);
	return 0;
}
/***
    Set an existing ECP point with two new x,y octet arguments.

    @param X octet of a big number
    @param Y octet of a big number
    @return a new ECP point on the curve at X,Y coordinates
    @function set(X,Y)
*/
static int lua_set_ecp(lua_State *L) {
	ecp *e = ecp_arg(L, 1); SAFE(e);
	// takes x,y big numbers from octets as arguments
	e = ecp_set_big_xy(L, e, 2);
	return 0;
}

static int lua_new_ecp(lua_State *L) {
	ecp *e = ecp_new(L); SAFE(e);
	func(L,"new ecp curve %s type %s", e->curve, e->type);
	void *x = luaL_testudata(L, 1, "zenroom.octet");
	void *y = luaL_testudata(L, 2, "zenroom.octet");
	if(x && y) e = ecp_set_big_xy(L, e, 1);
	return 1;
}

/***
    Make an existing ECP point affine with the curve
    @function affine()
*/
static int ecp_affine(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	ECP_affine(e->data);
	return 0;
}
/***
    Gives a new infinity point on the curve.
    @function infinity()
    @return elliptic curve point into infinity.
*/
static int ecp_get_infinity(lua_State *L) {
	ecp *e = ecp_new(L); SAFE(e);
	ECP_inf(e->data);
	return 1;
}

/***
    Returns true if an ECP coordinate points to infinity (out of the curve) and false otherwise.

    @function isinf()
    @return false if point is on curve, true if its off curve into infinity.
*/
static int ecp_isinf(lua_State *L) {
	const ecp *e = ecp_arg(L,1); SAFE(e);
	lua_pushboolean(L,ECP_isinf(e->data));
	return 1;
}

/***
    Map a BIG number to a point of the curve, the BIG number should be the output of some hash function.

    @param big octet of a BIG number
    @function mapit(big)
*/
static int ecp_mapit(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	if(o->len < modbytes) {
		lerror(L, "%s: octet too short (min %u bytes)",
		       __func__, modbytes);
		return 0; }
	const ecp *e = ecp_new(L); SAFE(e);
	ECP_mapit(e->data, o);
	return 1;
}

/***
    Add two ECP points to each other (commutative and associative operation). Can be made using the overloaded operator "+" between two ECP objects just like the would be numbers.

    @param first number to be summed
    @param second number to be summed
    @function add(first,second)
    @return sum resulting from the addition
*/
static int ecp_add(lua_State *L) {
	const ecp *e = ecp_arg(L,1); SAFE(e);
	const ecp *q = ecp_arg(L,2); SAFE(q);
	ecp *p = ecp_dup(L, e); // push
	SAFE(p);
	ECP_add(p->data,q->data);
	return 1;
}

/***
    Subtract an ECP point from another (commutative and associative operation). Can be made using the overloaded operator "-" between two ECP objects just like the would be numbers.

    @param first number from which the second should be subtracted
    @param second number to use in the subtraction
    @function sub(first,second)
    @return new ECP point resulting from the subtraction
*/
static int ecp_sub(lua_State *L) {
	const ecp *e = ecp_arg(L,1); SAFE(e);
	const ecp *q = ecp_arg(L,2); SAFE(q);
	ecp *p = ecp_dup(L, e); // push
	SAFE(p);
	ECP_sub(p->data,q->data);
	return 1;
}

/***
    Transforms an ECP point into its equivalent negative point on the elliptic curve.

    @function negative()
*/
static int ecp_negative(lua_State *L) {
	const ecp *in = ecp_arg(L,1); SAFE(in);
	const ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_neg(out->data);
	return 1;
}

/***
    Transforms an ECP pointo into the double of its value, multiplying it by two. This works faster than multiplying it an arbitrary number of times.

    @function double()
*/
static int ecp_double(lua_State *L) {
	const ecp *in = ecp_arg(L,1); SAFE(in);
	const ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_dbl(out->data);
	return 1;
}

/***
    Multiply an ECP point a number of times, indicated by an arbitrary ordinal number. Can be made using the overloaded operator "*" between an ECP object and an integer number.


    @function mul(ecp,num)
    @param ecp point on the elliptic curve to be multiplied
    @param number indicating how many times it should be multiplied
    @return new ecp point resulting from the multiplication
*/
static int ecp_mul(lua_State *L) {
	big big;
	void *ud;
	ecp *e = ecp_arg(L,1); SAFE(e);
	if(lua_isnumber(L,2)) {
		lua_Number num = lua_tonumber(L,2);
		int2big(big, (int)num);
	} else if((ud = luaL_testudata(L, 2, "zenroom.octet"))) {
		octet *o = (octet*)ud; SAFE(o);
		oct2big(big,o);
	}
	// TODO: check parsing errors
	const ecp *out = ecp_dup(L,e); SAFE(out);
	ECP_mul(out->data,big);
	return 1;
}

/***
    Compares two ECP objects and returns true if they indicate the same point on the curve (they are equal) or false otherwise. It can also be executed by using the '==' overloaded operators.

    @param first ecp point to be compared
    @param second ecp point to be compared
    @function eq(first,second)
    @return bool value: true if equal, false if not equal
*/
static int ecp_eq(lua_State *L) {
	const ecp *p = ecp_arg(L,1); SAFE(p);
	const ecp *q = ecp_arg(L,2); SAFE(q);
// TODO: is affine rly needed?
	ECP_affine(p->data);
	ECP_affine(q->data);
	lua_pushboolean(L,ECP_equals(
		                p->data, q->data));
	return 1;
}

/***
    Sets or returns an octet containing a BIG number composed by both x,y coordinates of an ECP point on the curve. It can be used to port the value of an ECP point into hex or base64 encapsulation, to be later set again into an ECP point using this same call.

    @param ecp[opt=octet] the octet to be imported, none if to be exported
    @function octet(ecp)
*/
static int ecp_octet(lua_State *L) {
	void *ud;
	ecp *e = ecp_arg(L,1); SAFE(e);
	if((ud = luaL_testudata(L, 2, "zenroom.octet"))) {
		octet *o = (octet*)ud; SAFE(o);
		if(! ECP_fromOctet(e->data, o) )
			lerror(L,"Octet doesn't contains a valid ECP");
		return 0;
	}
	octet *o = o_new(L,(modbytes<<1)+1);
	SAFE(o);
	ECP_toOctet(o, e->data);
	return 1;
}

/***
    Gives the order of the curve, a BIG number contained in an octet.

    @function order()
    @return an octet containing the curve's order
*/
static int ecp_order(lua_State *L) {
	octet *o = o_new(L, modbytes+1); SAFE(o);
	// big is an array of int32_t on chunk 32 (see rom_curve)
	o->len = modbytes;
	big c;
	// curve order is ready-only so we need a copy for norm() to work
	big_copy(c,(chunk*)CURVE_Order_BLS383);
	big_toBytes(o->val, c);
	return 1;
}

static int ecp_output(lua_State *L) {
	const ecp *e = ecp_arg(L, 1); SAFE(e);
	ECP_BLS383 *P = e->data;
	if (ECP_isinf(P)) {
		lua_pushstring(L,"Infinity");
		return 1; }
	big x;
	char xs[256];
	char out[512];
	ECP_affine(P);
	big y;
	char ys[256];
	FP_BLS383_redc(x,&(P->x));
	FP_BLS383_redc(y,&(P->y));
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
		{"set",lua_set_ecp},
		{"inf",ecp_get_infinity},
		{"infinity",ecp_get_infinity},
		{"order",ecp_order},
		{NULL,NULL}};
	const struct luaL_Reg ecp_methods[] = {
		{"affine",ecp_affine},
		{"negative",ecp_negative},
		{"double",ecp_double},
		{"isinf",ecp_isinf},
		{"mapit",ecp_mapit},
		{"octet",ecp_octet},
		{"add",ecp_add},
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
