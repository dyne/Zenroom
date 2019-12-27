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
// algorithms: `sha256` and `sha512` are stable and pass NIST vector
// tests. There are also `sha384`, `sha3_256` and `sha3_512` with
// experimental implementations that aren't passing NIST vector tests.
//
// objects are instantiated using @{HASH:new} and then provide the
// method @{HASH:process} that takes an input @{OCTET} and then
// returns another fixed-size octet that is uniquely matched to the
// original data. The process is not reversible (the original data
// cannot be retrieved from an hash).
//
// @module HASH
// @author Denis "Jaromil" Roio
// @license AGPLv3
// @copyright Dyne.org foundation 2017-2019

#include <ecdh_support.h>

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
	if(strncasecmp(hashtype,"sha256",6) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 32;
		h->algo = _SHA256;
		h->sha256 = (hash256*)zen_memory_alloc(sizeof(hash256));
		HASH256_init(h->sha256);
	} else if(strncasecmp(hashtype,"sha384",6) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 48;
		h->algo = _SHA384;
		h->sha384 = (hash384*)zen_memory_alloc(sizeof(hash384));
		HASH384_init(h->sha384);
	} else if(strncasecmp(hashtype,"sha512",6) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 64;
		h->algo = _SHA512;
		h->sha512 = (hash512*)zen_memory_alloc(sizeof(hash512));
		HASH512_init(h->sha512);
	} else if(strncasecmp(hashtype,"sha3_256",7) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 32;
		h->algo = _SHA3_256;
		h->sha3_256 = (sha3*)zen_memory_alloc(sizeof(sha3));
		SHA3_init(h->sha3_256, h->len);
	} else if(strncasecmp(hashtype,"sha3_512",7) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 64;
		h->algo = _SHA3_512;
		h->sha3_512 = (sha3*)zen_memory_alloc(sizeof(sha3));
		SHA3_init(h->sha3_512, h->len);

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
		int i; octet *res = o_new(L,h->len); SAFE(res);
		for(i=0;i<o->len;i++) HASH256_process(h->sha256,o->val[i]);
		HASH256_hash(h->sha256,res->val);
		res->len = h->len;
	} else if(h->algo == _SHA384) {
		int i; octet *res = o_new(L,h->len); SAFE(res);
		for(i=0;i<o->len;i++) HASH384_process(h->sha384,o->val[i]);
		HASH384_hash(h->sha384,res->val);
		res->len = h->len;
	} else if(h->algo == _SHA512) {
		int i; octet *res = o_new(L,h->len); SAFE(res);
		for(i=0;i<o->len;i++) HASH512_process(h->sha512,o->val[i]);
		HASH512_hash(h->sha512,res->val);
		res->len = h->len;
	} else if(h->algo == _SHA3_256) {
		int i; octet *res = o_new(L,h->len); SAFE(res);
		for(i=0;i<o->len;i++) SHA3_process(h->sha3_256,o->val[i]);
		SHA3_hash(h->sha3_256,res->val);
		res->len = h->len;
	} else if(h->algo == _SHA3_512) {
		int i; octet *res = o_new(L,h->len); SAFE(res);
		for(i=0;i<o->len;i++) SHA3_process(h->sha3_512,o->val[i]);
		SHA3_hash(h->sha3_512,res->val);
		res->len = h->len;
	} else {
		lerror(L,"Error in HASH object configuration: algo not found");
		return 0; }
	return 1;
}

/**
   Compute the HMAC of a message using a key. This method takes any
   data and any key material to comput an HMAC of the same length of
   the hash bytes of the keyring. This function works in accordance with
   RFC2104.

   @param key an octet containing the key to compute the HMAC
   @param data an octet containing the message to compute the HMAC
   @function keyring:hmac(key, data)
   @return a new octet containing the computed HMAC or false on failure
*/
static int hash_hmac(lua_State *L) {
	hash *h   = hash_arg(L,1); SAFE(h);
	octet *k  = o_arg(L, 2);     SAFE(k);
	octet *in = o_arg(L, 3);    SAFE(in);
	// length defaults to hash bytes (SHA256 = 32 = sha256)
	octet *out;
	if(h->algo == _SHA256) {
		out = o_new(L, SHA256+1); SAFE(out);
		//       hash    m   k  outlen  out
		if(!HMAC(SHA256, in, k, SHA256, out)) {
			error(L, "%s: hmac (%u bytes) failed.", SHA256);
			lua_pop(L, 1);
			lua_pushboolean(L,0);
		}
	} else if(h->algo == _SHA512) {
		out = o_new(L, SHA512+1); SAFE(out);
		//       hash    m   k  outlen  out
		if(!HMAC(SHA512, in, k, SHA512, out)) {
			error(L, "%s: hmac (%u bytes) failed.", SHA512);
			lua_pop(L, 1);
			lua_pushboolean(L,0);
		}
	} else {
		lerror(L, "HMAC is only supported for hash SHA256 or SHA512");
		return 0;
	}
	return 1;
}


/**
   Key Derivation Function (KDF2). Key derivation is used to
   strengthen keys against bruteforcing: they impose a number of
   costly computations to be iterated on the key. This function
   generates a new key from an existing key applying an octet of key
   derivation parameters.

   @param hash initialized @{HASH} or @{ECDH} object
   @param key octet of the key to be transformed
   @function keyring:kdf2(key)
   @return a new octet containing the derived key
*/

static int hash_kdf2(lua_State *L) {
	hash *h = hash_arg(L,1); SAFE(h);
	octet *in = o_arg(L, 2); SAFE(in);
	// output keylen is length of hash
	octet *out = o_new(L, h->len+0x0f); SAFE(out);
	KDF2(h->len, in, NULL , h->len, out);
	return 1;
}


/**
   Password Based Key Derivation Function (PBKDF2). This function
   generates a new key from an existing key applying a salt and number
   of iterations.

   @param key octet of the key to be transformed
   @param salt octet containing a salt to be used in transformation
   @param iterations[opt=1000] number of iterations to be applied
   @param length[opt=key length] integer indicating the new length (default same as input key)
   @function keyring:pbkdf2(key, salt, iterations, length)
   @return a new octet containing the derived key

   @see keyring:kdf2
*/

static int hash_pbkdf2(lua_State *L) {
	hash *h = hash_arg(L,1); SAFE(h);
	octet *k = o_arg(L, 2); SAFE(k);
	int iter, keylen;
	octet *s;
	// take a table as argument with salt, iterations and length parameters
	if(lua_type(L, 3) == LUA_TTABLE) {
		lua_getfield(L, 3, "salt");
		lua_getfield(L, 3, "iterations");
		lua_getfield(L, 3, "length"); // -3
		s = o_arg(L,-3); SAFE(s);
		// default iterations 5000
		iter = luaL_optinteger(L,-2, 5000);
		keylen = luaL_optinteger(L,-1,k->len);
	} else {
		s = o_arg(L, 3); SAFE(s);
		iter = luaL_optinteger(L, 4, 5000);
		// keylen is length of input key
		keylen = luaL_optinteger(L, 5, k->len);
	}
	octet *out = o_new(L, keylen); SAFE(out);

	// TODO: OPTIMIZATION: reuse the initialized hash* structure in
	// hmac->ehashit instead of milagro's
        // TODO: according to RFC2898, s should have a size of 8
        // c should be a positive integer
	PBKDF2(h->len, k, s, iter, keylen, out);
	return 1;
}
		
int luaopen_hash(lua_State *L) {
	const struct luaL_Reg hash_class[] = {
		{"new",lua_new_hash},
		{"hmac",hash_hmac},
		{"kdf2", hash_kdf2},
		{"kdf", hash_kdf2},
		{"pbkdf2", hash_pbkdf2},
		{"pbkdf", hash_pbkdf2},
		{NULL,NULL}};
	const struct luaL_Reg hash_methods[] = {
		{"process",hash_process},
		{"do",hash_process},
		{"hmac",hash_hmac},
		{"kdf2", hash_kdf2},
		{"kdf", hash_kdf2},
		{"pbkdf2", hash_pbkdf2},
		{"pbkdf", hash_pbkdf2},
		{"__gc", hash_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "hash", hash_class, hash_methods);
	return 1;
}
