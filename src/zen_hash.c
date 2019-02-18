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

/// <h1>Cryptographic hash functions</h1>
//
// An hash is also known as 'message digest', 'digital fingerprint',
// 'digest' or 'checksum'.
//
// HASH objects can be generated from a number of implemented
// algorithms: `sha256` and `sha512`.
//
// objects are instantiated using @{HASH:new} and then provide the
// method @{HASH:process} that takes an input @{OCTET} and then
// returns another fixed-size octet that is uniquely matched to the
// original data. The process is not reversible (the original data
// cannot be retrieved from an hash).
//
// @module HASH
// @author Denis "Jaromil" Roio
// @license GPLv3
// @copyright Dyne.org foundation 2017-2018

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <lua_functions.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_memory.h>
#include <zen_big.h>
#include <zen_hash.h>


/**
   Create a new hash object of a selected algorithm (sha256 or
   sha512). The resulting object can then process any @{OCTET} into
   its hashed equivalent.

   @param string indicating the type of hash algorithm
   @function HASH.new(string)
   @return a new hash object ready to process data.
   @see process
*/

hash* hash_new(lua_State *L, const char *hashtype) {
	HEREs(hashtype);
	hash *h = lua_newuserdata(L, sizeof(hash));
	if(!h) {
		lerror(L, "Error allocating new hash generator in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.hash");
	lua_setmetatable(L, -2);
	char ht[16];
	h->sha256 = NULL; h->sha384 = NULL; h->sha512 = NULL;
	if(hashtype) strncpy(ht,hashtype,15);
	else         strncpy(ht,"sha256",15);
	if(strcasecmp(hashtype,"sha256") == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 32;
		h->algo = _SHA256;
		h->sha256 = zen_memory_alloc(sizeof(hash256));
		HASH256_init(h->sha256);
	} else if(strcasecmp(hashtype,"sha512") == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 64;
		h->algo = _SHA512;
		h->sha512 = zen_memory_alloc(sizeof(hash512));
		HASH512_init(h->sha512);
	} // ... TODO: other hashes
	else {
		lerror(L, "Hash algorithm not known: %s", hashtype);
		return NULL; }
	return(h);
}

hash* hash_arg(lua_State *L, int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.hash");
	luaL_argcheck(L, ud != NULL, n, "hash class expected");
	hash *h = (hash*)ud;
	return(h);
}

int hash_destroy(lua_State *L) {
	hash *h = hash_arg(L,1); SAFE(h);
	HEREs(h->name);
	if(h->algo == _SHA256)
		zen_memory_free(h->sha256);
	else if (h->algo == _SHA512)
		zen_memory_free(h->sha512);
	return 0;
}

static int lua_new_hash(lua_State *L) {
	const char *hashtype = luaL_optstring(L,1,"sha256");
	hash *h = hash_new(L, hashtype); SAFE(h);
	if(h) func(L,"new hash type %s",hashtype);
	return 1;
}


/**
   Hash an octet into a new octet. Use the configured hash function to
   hash an octet string and return a new one containing its hash.

   @param data octet containing the data to be hashed
   @function hash:process(data)
   @return a new octet containing the hash of the data
*/
static int hash_process(lua_State *L) {
	hash *h = hash_arg(L,1); SAFE(h);
	octet *o = o_arg(L,2); SAFE(o);
	HEREs(h->name);
	if(h->algo == _SHA256) {
		int i; octet *res = o_new(L,33); SAFE(res);
		for(i=0;i<o->len;i++) HASH256_process(h->sha256,o->val[i]);
		HASH256_hash(h->sha256,res->val);
		res->len = h->len;
	} else if(h->algo == _SHA512) {
		int i; octet *res = o_new(L,65); SAFE(res);
		for(i=0;i<o->len;i++) HASH512_process(h->sha512,o->val[i]);
		HASH512_hash(h->sha512,res->val);
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
