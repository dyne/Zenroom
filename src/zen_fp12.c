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

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_memory.h>
#include <zen_fp12.h>


fp12* fp12_new(lua_State *L) {
	fp12 *c = (fp12 *)lua_newuserdata(L, sizeof(fp12));
	if(!c) {
		lerror(L, "Error allocating new fp12 in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.fp12");
	lua_setmetatable(L, -2);
	strcpy(c->name,"BLS383");
	c->len = sizeof(FP12);
	c->chunk = CHUNK;
	func(L, "new fp12 (%u bytes)",c->len);
	return(c);
}

fp12* fp12_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.fp12");
	luaL_argcheck(L, ud != NULL, n, "fp12 class expected");
	fp12 *o = (fp12*)ud;
	if(o->len != sizeof(FP12)) {
		lerror(L, "%s: fp12 size mismatch (%u != %u)",__func__,o->len, sizeof(FP12));
		return NULL; }
	if(o->chunk != CHUNK) {
		lerror(L, "%s: fp12 chunk size mismatch (%u != %u)",__func__,o->chunk, CHUNK);
		return NULL; }
	return(o);
}

// allocates a new fp in LUA, duplicating the one in arg
fp12 *fp12_dup(lua_State *L, fp12 *s) {
	SAFE(s);
	fp12 *n = fp12_new(L);
	FP12_copy(&n->val,&s->val);
	return(n);
}

int fp12_destroy(lua_State *L) {
	HERE();
	fp12 *c = fp12_arg(L,1);
	SAFE(c);

	return 0;
}

static int fp12_from_octet(lua_State *L) {
    octet *o = o_arg(L,1); SAFE(o);
	fp12 *f = fp12_new(L); SAFE(f);
	FP12_fromOctet(&f->val,o);
	return 1;
}

static int fp12_to_octet(lua_State *L) {
	fp12 *f = fp12_arg(L,1); SAFE(f);
	octet *o = o_new(L, sizeof(FP12)); SAFE(o);
	FP12_toOctet(o, &f->val);
	return 1;
}

static int fp12_eq(lua_State *L) {
	fp12 *l = fp12_arg(L,1); SAFE(l);
	fp12 *r = fp12_arg(L,2); SAFE(r);
	int res = FP12_eq(&l->val,&r->val);
	lua_pushboolean(L, res);
	return 1;
}

static int fp12_mul(lua_State *L) {
	fp12 *x = fp12_arg(L,1); SAFE(x);
	fp12 *y = fp12_arg(L,2); SAFE(y);
	fp12 *d = fp12_dup(L,x); SAFE(d);
	FP12_mul(&d->val,&y->val);
	return 1;
}

static int fp12_pow(lua_State *L) {
	fp12 *x = fp12_arg(L,1); SAFE(x);
	big  *b = big_arg(L,2); SAFE(b);
	fp12 *r = fp12_dup(L,x); SAFE(r);
	FP12_GTpow(&r->val,b->val);
	return 1;
}

static int fp12_sqr(lua_State *L) {
	fp12 *s = fp12_arg(L,1); SAFE(s);
	fp12 *d = fp12_dup(L,s); SAFE(d);
	FP12_sqr(&d->val,&s->val);
	return 1;
}
static int fp12_inv(lua_State *L) {
	fp12 *s = fp12_arg(L,1); SAFE(s);
	fp12 *d = fp12_dup(L,s); SAFE(d);
	FP12_inv(&d->val,&s->val);
	return 1;
}

#define fp12_common_methods \
	    {"eq",fp12_eq}, \
		{"mul",fp12_mul}, \
		{"sqr",fp12_sqr}, \
		{"inv",fp12_inv}

int luaopen_fp12(lua_State *L) {
		(void)L;
	const struct luaL_Reg fp12_class[] = {
		{"new",fp12_from_octet},
		{"octet",fp12_from_octet},
		fp12_common_methods,
		{NULL,NULL}
	};
	const struct luaL_Reg fp12_methods[] = {
		// idiomatic operators
		fp12_common_methods,
		{"octet",fp12_to_octet},
		{"pow",fp12_pow},
		{"__mul",fp12_mul},
		{"__eq",fp12_eq},
		{"__gc", fp12_destroy},
		{"__pow", fp12_pow},
		{NULL,NULL}
	};
	zen_add_class(L, "fp12", fp12_class, fp12_methods);
	return 1;
}
