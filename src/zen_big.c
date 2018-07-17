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

#define BIGSIZE 384
#include <zen_big_types.h>

typedef struct {
	char name[16];
	int  len;
	int  chunksize;
	BIG  data;
} big;


big* big_new(lua_State *L) {
	big *c = (big *)lua_newuserdata(L, sizeof(big));
	if(!c) {
		lerror(L, "Error allocating new big in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.big");
	lua_setmetatable(L, -2);
	strcpy(c->name,"big384");
	c->len = modbytes;
	c->chunksize = CHUNK;
	func(L, "new big (%u bytes)",modbytes);
	return(c);
}

big* big_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.big");
	luaL_argcheck(L, ud != NULL, n, "big class expected");
	big *o = (big*)ud;
	if(o->len != modbytes) {
		lerror(L, "%s: big modbytes mismatch (%u != %u)",__func__,o->len, modbytes);
		return NULL; }
	if(o->chunksize != CHUNK) {
		lerror(L, "%s: big chunk size mismatch (%u != %u)",__func__,o->chunksize, CHUNK);
		return NULL; }
	return(o);
}

// allocates a new big in LUA, duplicating the one in arg
big *big_dup(lua_State *L, big *s) {
	SAFE(s);
	big *n = big_new(L);
	BIG_rcopy(n->data,s->data);
	return(n);
}

int big_destroy(lua_State *L) {
	HERE();
	big *c = big_arg(L,1);
	SAFE(c);
	return 0;
}

static int newbig(lua_State *L) {
	big *c = big_new(L); SAFE(L);
	BIG_zero(c->data);
	return 1;
}

static int big_from_octet(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	big *c = big_new(L); SAFE(c);
	BIG_fromBytesLen(c->data, o->val, o->len);
	return 1;
}

static int big_to_octet(lua_State *L) {
	big *c = big_arg(L,1); SAFE(c);
	BIG_norm(c->data);
	octet *o = o_new(L, c->len+2); SAFE(o);
	BIG_toBytes(o->val, c->data);
	o->len = modbytes;
	return 1;
}

// useful to double-check big_to_octet():hex()
// this function is known to return good results
static int big_to_hex(lua_State *L) {
	BIG b;
	int i,len;
	char str[MAX_STRING]; // TODO:
	int modby2 = modbytes<<1;
	big *a = big_arg(L,1); SAFE(a);
	len = BIG_nbits(a->data);
	int lendiv4 = len>>2;
	if (len%4==0) len=lendiv4;
	else {
		len=lendiv4;
		len++;
	}
	if (len<modby2) len=modby2;
	int c = 0;
	for (i=len-1; i>=0; i--) {
		BIG_copy(b,a->data);
		BIG_shr(b,i<<2);
		sprintf(str+c,"%01x",(unsigned int) b[0]&15);
		c++;
	}
	lua_pushstring(L,str);
	return 1;
}

static int big_eq(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	// BIG_comp requires external normalization
	BIG_norm(l->data);
	BIG_norm(r->data);
	int res = BIG_comp(l->data,r->data);
	lua_pushboolean(L, (res==0)?1:0);
	return 1;
}

static int big_add(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_new(L); SAFE(d);
	BIG_add(d->data, l->data, r->data);
	return 1;
}

static int big_sub(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_new(L); SAFE(d);
	BIG_sub(d->data, l->data, r->data);
	return 1;
}

static int big_mul(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_new(L); SAFE(d);
	BIG_mul(d->data,l->data,r->data);
	return 1;
}

static int big_mod(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_dup(L,l); SAFE(d);
	BIG_mod(d->data,r->data);
	return 1;
}

static int big_div(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_dup(L,l); SAFE(d);
	BIG_div(d->data,r->data);
	return 1;
}

static int big_modmul(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *z = big_arg(L, 2); SAFE(z);
	big *n = big_arg(L, 3); SAFE(n);
	big *x = big_new(L); SAFE(x);
	BIG_modmul(x->data, y->data, z->data, n->data);
	return 1;
}
static int big_moddiv(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *z = big_arg(L, 2); SAFE(z);
	big *n = big_arg(L, 3); SAFE(n);
	big *x = big_new(L); SAFE(x);
	BIG_moddiv(x->data, y->data, z->data, n->data);
	return 1;
}
static int big_modsqr(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *n = big_arg(L, 2); SAFE(n);
	big *x = big_new(L); SAFE(x);
	BIG_modsqr(x->data, y->data, n->data);
	return 1;
}
static int big_modneg(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *n = big_arg(L, 2); SAFE(n);
	big *x = big_new(L); SAFE(x);
	BIG_modneg(x->data, y->data, n->data);
	return 1;
}
static int big_jacobi(lua_State *L) {
	big *x = big_arg(L, 1); SAFE(x);
	big *y = big_arg(L, 2); SAFE(y);
	lua_pushinteger(L, BIG_jacobi(x->data, y->data));
	return 1;
}

int luaopen_big(lua_State *L) {
	const struct luaL_Reg big_class[] = {
		{"new",newbig},
		{"eq",big_eq},
		{"add",big_add},
		{"sub",big_sub},
		{"mul",big_mul},
		{"mod",big_mod},
		{"div",big_div},
		{"modmul",big_modmul},
		{"moddiv",big_moddiv},
		{"modsqr",big_modsqr},
		{"modneg",big_modneg},
		{"jacobi",big_jacobi},
		{"from_octet",big_from_octet},
		{NULL,NULL}
	};
	const struct luaL_Reg big_methods[] = {
		// idiomatic operators
		{"octet",big_to_octet},
		{"hex",big_to_hex},
		{"add",  big_add},
		{"__add",big_add},
		{"sub",  big_sub},
		{"__sub",big_sub},
		{"mul",  big_mul},
		{"__mul",big_mul},
		{"mod",  big_mod},
		{"__mod",big_mod},
		{"div",  big_div},
		{"__div",big_div},
		{"eq",  big_eq},
		{"__eq",big_eq},
		{"modmul",big_modmul},
		{"moddiv",big_moddiv},
		{"modsqr",big_modsqr},
		{"modneg",big_modneg},
		{"jacobi",big_jacobi},
		{"__gc", big_destroy},
		{"__tostring",big_to_hex},
		{NULL,NULL}
	};
	zen_add_class(L, "big", big_class, big_methods);
	return 1;
}
