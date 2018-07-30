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
#include <zen_big.h>

#define _SHA256 2
#define _SHA384 3
#define _SHA512 5
#define _SHA3_224 3224
#define _SHA3_256 3256
#define _SHA3_384 3384
#define _SHA3_512 3512

typedef struct {
	char name[16];
	int algo;
	int len;
	hash256 *sha256;
	hash384 *sha384;
	hash512 *sha512;
	// ...
} HASH;

HASH* hash_new(lua_State *L, const char *hashtype) {
	HEREs(hashtype);
	HASH *hash = (HASH*)lua_newuserdata(L, sizeof(HASH));
	if(!hash) {
		lerror(L, "Error allocating new hash generator in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.hash");
	lua_setmetatable(L, -2);
	char ht[16];
	if(hashtype) snprintf(ht,15,hashtype);
	else         snprintf(ht,15,"sha256");
	if(strcasecmp(hashtype,"sha256") == 0) {
		strncpy(hash->name,hashtype,15);
		hash->len = 32;
		hash->algo = _SHA256;
		hash->sha256 = zen_memory_alloc(sizeof(hash256));
		HASH256_init(hash->sha256);
	} // ... TODO: other hashes
	else {
		lerror(L, "Hash algorithm not known: %s", hashtype);
		return NULL; }
	return(hash);
}

HASH* hash_arg(lua_State *L, int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.hash");
	luaL_argcheck(L, ud != NULL, n, "hash class expected");
	HASH *h = (HASH*)ud;
	return(h);
}

int hash_destroy(lua_State *L) {
	HASH *h = hash_arg(L,1); SAFE(h);
	HEREs(h->name);
	if(h->algo == _SHA256)
		zen_memory_free(h->sha256);
	return 0;
}

static int lua_new_hash(lua_State *L) {
	const char *hashtype = luaL_optstring(L,1,"sha256");
	HASH *h = hash_new(L, hashtype); SAFE(h);
	if(h) func(L,"new hash type %s",hashtype);
	return 1;
}

static int hash_process(lua_State *L) {
	HASH *h = hash_arg(L,1); SAFE(h);
	octet *o = o_arg(L,2); SAFE(o);
	HEREs(h->name);
	if(h->algo == _SHA256) {
		int i; octet *res = o_new(L,33); SAFE(res);
		for(i=0;i<o->len;i++) HASH256_process(h->sha256,o->val[i]);
		HASH256_hash(h->sha256,res->val);
		res->len = h->len;
	}
	return 1;
}
		
int luaopen_hash(lua_State *L) {
	const struct luaL_Reg hash_class[] = {
		{"new",lua_new_hash},
		{NULL,NULL}};
	const struct luaL_Reg hash_methods[] = {
		{"process",hash_process},
		{"do",hash_process},
		{"__gc", hash_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "hash", hash_class, hash_methods);
	return 1;
}
