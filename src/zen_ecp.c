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

// For now, the only supported curve is ED25519 type EDWARDS

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <ecp_ED25519.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <zen_ecp.h>
#include <lua_functions.h>

void oct2big(BIG_256_29 b, const octet *o) {
	BIG_256_29_zero(b);
	BIG_256_29_fromBytesLen(b,o->val,o->len);
}
void int2big(BIG_256_29 b, int n) {
	BIG_256_29_zero(b);
	BIG_256_29_inc(b, n);
	BIG_256_29_norm(b);
}
char *big2strhex(char *str, BIG_256_29 a) {
	BIG_256_29 b;
	int i,len;
	int modby2 = MODBYTES_256_29<<1;
	len=BIG_256_29_nbits(a);
	int lendiv4 = len>>2;
	if (len%4==0) len=lendiv4;
	else {
		len=lendiv4;
		len++;
	}
	if (len<modby2) len=modby2;
	int c = 0;
	for (i=len-1; i>=0; i--) {
		BIG_256_29_copy(b,a);
		BIG_256_29_shr(b,i<<2);
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
	e->ed25519 = malloc(sizeof(ECP_ED25519));
	strcpy(e->curve,"ed25519");
#if CURVETYPE_ED25519==MONTGOMERY
	strcpy(e->type,"montgomery");
#elif CURVETYPE_ED25519==WEIERSTRASS
	strcpy(e->type,"weierstrass");
#elif CURVETYPE_ED25519==EDWARDS
	strcpy(e->type,"edwards");
#else
	strcpy(e->type,"unknown");
#endif
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
	ECP_ED25519_copy(e->ed25519, in->ed25519);
	return(e);
}
ecp* ecp_set_big_xy(lua_State *L, ecp *e, int idx) {
	SAFE(e);
	octet *o;
	o = o_arg(L, idx); SAFE(o);
	BIG_256_29 x;
	oct2big(x, o);
#if CURVETYPE_ED25519==MONTGOMERY
	ECP_ED25519_set(e->ed25519, x);
#else
	o = o_arg(L, idx+1); SAFE(o);
	BIG_256_29 y;
	oct2big(y, o);
	ECP_ED25519_set(e->ed25519, x, y);
#endif
	return e;
}
int ecp_destroy(lua_State *L) {
	HERE();
	ecp *e = ecp_arg(L,1);
	SAFE(e);
	FREE(e->ed25519);
	return 0;
}
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

static int ecp_affine(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	ECP_ED25519_affine(e->ed25519);
	return 0;
}

// assumes curve type is EDWARDS
static int ecp_isinf(lua_State *L) {
	const ecp *e = ecp_arg(L,1); SAFE(e);
	lua_pushboolean(L,ECP_ED25519_isinf(e->ed25519));
	return 1;
}

static int ecp_mapit(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	if(o->len < MODBYTES_256_29) {
		lerror(L, "%s: octet too short (min %u bytes)",
		       __func__, MODBYTES_256_29);
		return 0; }
	const ecp *e = ecp_new(L); SAFE(e);
	ECP_ED25519_mapit(e->ed25519, o);
	return 1;
}

static int ecp_add(lua_State *L) {
	const ecp *e = ecp_arg(L,1); SAFE(e);
	const ecp *q = ecp_arg(L,2); SAFE(q);
	ecp *p = ecp_dup(L, e); // push
	SAFE(p);
	ECP_ED25519_add(p->ed25519,q->ed25519);
	return 1;
}

static int ecp_sub(lua_State *L) {
	const ecp *e = ecp_arg(L,1); SAFE(e);
	const ecp *q = ecp_arg(L,2); SAFE(q);
	ecp *p = ecp_dup(L, e); // push
	SAFE(p);
	ECP_ED25519_sub(p->ed25519,q->ed25519);
	return 1;
}

static int ecp_negative(lua_State *L) {
	const ecp *in = ecp_arg(L,1); SAFE(in);
	const ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_ED25519_neg(out->ed25519);
	return 1;
}

static int ecp_double(lua_State *L) {
	const ecp *in = ecp_arg(L,1); SAFE(in);
	const ecp *out = ecp_dup(L,in); SAFE(out);
	ECP_ED25519_dbl(out->ed25519);
	return 1;
}

static int ecp_mul(lua_State *L) {
	BIG_256_29 big;
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
	ECP_ED25519_mul(out->ed25519,big);
	return 1;
}

static int ecp_eq(lua_State *L) {
	const ecp *p = ecp_arg(L,1); SAFE(p);
	const ecp *q = ecp_arg(L,2); SAFE(q);
// TODO: is affine rly needed?
	ECP_ED25519_affine(p->ed25519);
	ECP_ED25519_affine(q->ed25519);
	lua_pushboolean(L,ECP_ED25519_equals(
		                p->ed25519, q->ed25519));
	return 1;
}

static int ecp_octet(lua_State *L) {
	void *ud;
	ecp *e = ecp_arg(L,1); SAFE(e);
	if((ud = luaL_testudata(L, 2, "zenroom.octet"))) {
		octet *o = (octet*)ud; SAFE(o);
		if(! ECP_ED25519_fromOctet(e->ed25519, o) )
			lerror(L,"Octet doesn't contains a valid ECP");
		return 0;
	}
	octet *o = o_new(L,(MODBYTES_256_29<<1)+1);
	SAFE(o);
	ECP_ED25519_toOctet(o, e->ed25519);
	return 1;
}

static int ecp_output(lua_State *L) {
	const ecp *e = ecp_arg(L, 1); SAFE(e);
	ECP_ED25519 *P = e->ed25519;
	if (ECP_ED25519_isinf(P)) {
		lua_pushstring(L,"Infinity");
		return 1; }
	BIG_256_29 x;
	char xs[256];
	char out[512];
	ECP_ED25519_affine(P);
#if CURVETYPE_ED25519==MONTGOMERY
	FP_25519_redc(x,&(P->x));
	snprintf(out,511,
	         "{ \"curve\": \"%s\",\n"
	         "  \"type\": \"%s\",\n"
	         "  \"encoding\": \"hex\",\n"
	         "  \"vm\": \"%s\",\n"
	         "  \"x\": \"%s\" }",
	         e->curve, e->type, VERSION,
	         big2strhex(xs,x));
#else
	BIG_256_29 y;
	char ys[256];
	FP_25519_redc(x,&(P->x));
	FP_25519_redc(y,&(P->y));
	snprintf(out, 511,
"{ \"curve\": \"%s\",\n"
"  \"type\": \"%s\",\n"
"  \"encoding\": \"hex\",\n"
"  \"vm\": \"%s\",\n"
"  \"x\": \"%s\",\n"
"  \"y\": \"%s\" }",
	         e->curve, e->type, VERSION,
	         big2strhex(xs,x), big2strhex(ys,y));
#endif
	lua_pushstring(L,out);
	return 1;
}

int luaopen_ecp(lua_State *L) {
	const struct luaL_Reg ecp_class[] = {
		{"new",lua_new_ecp},
		{"set",lua_set_ecp},
		{NULL,NULL}};
	const struct luaL_Reg ecp_methods[] = {
		{"affine",ecp_affine},
		{"negative",ecp_negative},
		{"double",ecp_double},
		{"isinf",ecp_isinf},
		{"mapit",ecp_mapit},
		{"octet",ecp_octet},
		{"__add",ecp_add},
		{"__sub",ecp_sub},
		{"__mul",ecp_mul},
		{"__eq", ecp_eq},
		{"__gc",ecp_destroy},
		{"__tostring",ecp_output},
		{NULL,NULL}
	};
	zen_add_class(L, "ecp", ecp_class, ecp_methods);
	return 1;
}
