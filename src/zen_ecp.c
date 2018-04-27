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

// only supported curve is ED25519 type EDWARDS

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <ecp_ED25519.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <zen_ecp.h>
#include <lua_functions.h>

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
	memcpy(e->ed25519,in->ed25519,sizeof(ECP_ED25519));
	return(e);
}
void oct2big(BIG_256_29 b, const octet *o) {
	BIG_256_29_zero(b);
	BIG_256_29_fromBytesLen(b,o->val,o->len);
}
ecp* ecp_set(lua_State *L, ecp *e, int idx) {
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

octet *ecp2o_new(lua_State *L, ecp *e) {
	// TODO: find out max size for ECP_ED25519
	octet *o = o_new(L,1024); SAFE(o);
	ECP_ED25519_toOctet(o, e->ed25519);
	return o;
}
ecp   *o2ecp_new(lua_State *L, octet *o) {
	ecp *e = ecp_new(L); SAFE(e);
	ECP_ED25519_fromOctet(e->ed25519, o);
	return e;
}

static int lua_set_ecp(lua_State *L) {
	ecp *e = ecp_arg(L, 1); SAFE(e);
	// takes x,y big numbers from octets as arguments
	e = ecp_set(L, e, 2);
	return 0;
}

static int lua_new_ecp(lua_State *L) {
	ecp *e = ecp_new(L); SAFE(e);
	func(L,"new ecp curve %s type %s", e->curve, e->type);
	void *ud = luaL_testudata(L, 1, "zenroom.octet");
	if(ud) e = ecp_set(L, e, 1);
	return 1;
}


static int ecp_affine(lua_State *L) {
	ecp *e = ecp_arg(L,1); SAFE(e);
	ECP_ED25519_affine(e->ed25519);
	return 0;
}

// assumes curve type is EDWARDS

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
	ECP_ED25519_affine(p->ed25519);
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

int luaopen_ecp(lua_State *L) {
	const struct luaL_Reg ecp_class[] = {
		{"new",lua_new_ecp},
		{"set",lua_set_ecp},
		{NULL,NULL}};
	const struct luaL_Reg ecp_methods[] = {
		{"affine",ecp_affine},
		{"__add",ecp_add},
		{"__sub",ecp_sub},
		{"__eq", ecp_eq},
		{"__gc",ecp_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "ecp", ecp_class, ecp_methods);
	return 1;
}
