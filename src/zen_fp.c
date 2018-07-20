/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_memory.h>
#include <zen_fp.h>


fp* fp_new(lua_State *L) {
	fp *c = (fp *)lua_newuserdata(L, sizeof(fp));
	if(!c) {
		lerror(L, "Error allocating new fp in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.fp");
	lua_setmetatable(L, -2);
	strcpy(c->name,"fp384");
	c->len = sizeof(FP);
	c->chunk = CHUNK;
	func(L, "new fp (%u bytes)",c->len);
	return(c);
}

fp* fp_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.fp");
	luaL_argcheck(L, ud != NULL, n, "fp class expected");
	fp *o = (fp*)ud;
	if(o->len != sizeof(FP)) {
		lerror(L, "%s: fp size mismatch (%u != %u)",__func__,o->len, sizeof(FP));
		return NULL; }
	if(o->chunk != CHUNK) {
		lerror(L, "%s: fp chunk size mismatch (%u != %u)",__func__,o->chunk, CHUNK);
		return NULL; }
	return(o);
}

// allocates a new fp in LUA, duplicating the one in arg
fp *fp_dup(lua_State *L, fp *s) {
	SAFE(s);
	fp *n = fp_new(L);
	FP_copy(&n->val,&s->val);
	return(n);
}

int fp_destroy(lua_State *L) {
	HERE();
	fp *c = fp_arg(L,1);
	SAFE(c);
	return 0;
}

static int newfp(lua_State *L) {
	HERE();
	int res = lua_isnoneornil(L, 1);
	fp *c = fp_new(L); SAFE(L);
	// argument if present must be an octet
	if(res) {
		FP_zero(&c->val);
	} else {
		void *ud = luaL_testudata(L, 1, "zenroom.big");
		luaL_argcheck(L, ud != NULL, 1, "big argument expected");		
		big *b = (big*)ud;
		FP_fromBig(&c->val,b->val);
	}
	return 1;
}

static int fp_from_big(lua_State *L) {
	big *b = big_arg(L,1); SAFE(b);
	fp *f = fp_new(L); SAFE(f);
	BIG_norm(b->val);
	FP_fromBig(&f->val,b->val);
	return 1;
}

static int fp_to_big(lua_State *L) {
	fp *f = fp_arg(L,1); SAFE(f);
	big *b = big_new(L); SAFE(b);
	FP_toBig(b->val, &f->val);
	return 1;
}

// static int fp_from_octet(lua_State *L) {
// 	octet *o = o_arg(L,1); SAFE(o);
// 	fp *c = fp_new(L); SAFE(c);
// 	BIG_fromBytesLen(c->val, o->val, o->len);
// 	return 1;
// }

// static int fp_to_octet(lua_State *L) {
// 	fp *c = fp_arg(L,1); SAFE(c);
// 	BIG_norm(c->val);
// 	octet *o = o_new(L, c->len+2); SAFE(o);
// 	BIG_toBytes(o->val, c->val);
// 	o->len = modbytes;
// 	return 1;
// }

static int fp_eq(lua_State *L) {
	fp *l = fp_arg(L,1); SAFE(l);
	fp *r = fp_arg(L,2); SAFE(r);
	int res = FP_eq(&l->val,&r->val);
	lua_pushboolean(L, res);
	return 1;
}

static int fp_add(lua_State *L) {
	fp *l = fp_arg(L,1); SAFE(l);
	fp *r = fp_arg(L,2); SAFE(r);
	fp *d = fp_new(L); SAFE(d);
	FP_add(&d->val, &l->val, &r->val);
	return 1;
}

static int fp_sub(lua_State *L) {
	fp *l = fp_arg(L,1); SAFE(l);
	fp *r = fp_arg(L,2); SAFE(r);
	fp *d = fp_new(L); SAFE(d);
	FP_sub(&d->val, &l->val, &r->val);
	return 1;
}

static int fp_mul(lua_State *L) {
	fp *l = fp_arg(L,1); SAFE(l);
	fp *r = fp_arg(L,2); SAFE(r);
	fp *d = fp_new(L); SAFE(d);
	FP_mul(&d->val,&l->val,&r->val);
	return 1;
}

// static int fp_imul(lua_State *L) {
// 	fp *l = fp_arg(L,1); SAFE(l);
// 	fp *r = fp_arg(L,2); SAFE(r);
// 	fp *d = fp_new(L); SAFE(d);
// 	FP_imul(&d->val,&l->val,&r->val);
// 	return 1;
// }

static int fp_sqr(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_sqr(&d->val,&s->val);
	return 1;
}

static int fp_sqrt(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_sqrt(&d->val,&s->val);
	return 1;
}

static int fp_div2(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_div2(&d->val,&s->val);
	return 1;
}

static int fp_pow(lua_State *L) {
	fp *l = fp_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	fp *d = fp_new(L); SAFE(d);
	FP_pow(&d->val,&l->val,r->val);
	return 1;
}

static int fp_neg(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_neg(&d->val,&s->val);
	return 1;
}

static int fp_inv(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_inv(&d->val,&s->val);
	return 1;
}

static int fp_reduce(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_reduce(&d->val);
	return 1;
}

static int fp_norm(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_norm(&d->val);
	return 1;
}

static int fp_qr(lua_State *L) {
	fp *s = fp_arg(L,1); SAFE(s);
	fp *d = fp_dup(L,s); SAFE(d);
	FP_qr(&d->val);
	return 1;
}

#define fp_common_methods \
	    {"eq",fp_eq}, \
	    {"add",fp_add}, \
	    {"sub",fp_sub}, \
		{"mul",fp_mul}, \
		{"sqr",fp_sqr}, \
		{"sqrt",fp_sqrt}, \
		{"div2",fp_div2}, \
		{"pow",fp_pow}, \
		{"neg",fp_neg}, \
		{"inv",fp_inv}, \
		{"reduce",fp_reduce}, \
		{"norm",fp_norm}, \
		{"qr",fp_qr}

int luaopen_fp(lua_State *L) {
	const struct luaL_Reg fp_class[] = {
		{"new",newfp},
		{"big",fp_from_big},
		fp_common_methods,
		{NULL,NULL}
	};
	const struct luaL_Reg fp_methods[] = {
		// idiomatic operators
		fp_common_methods,
		{"big",fp_to_big},
		{"__add",fp_add},
		{"__sub",fp_sub},
		{"__mul",fp_mul},
		{"__eq",fp_eq},
		{"__gc", fp_destroy},
//		{"__tostring",fp_to_hex},
		{NULL,NULL}
	};
	zen_add_class(L, "fp", fp_class, fp_methods);
	return 1;
}
