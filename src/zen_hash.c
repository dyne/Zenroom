/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
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
// Objects are instantiated using @{HASH.new} and then provide the
// method @{HASH:process} that takes an input @{OCTET} and then
// returns another fixed-size octet that is uniquely matched to the
// original data. The process is not reversible (the original data
// cannot be retrieved from an hash).
//
// @module HASH
// @author Denis "Jaromil" Roio
// @license AGPLv3
// @copyright Dyne.org foundation 2017-2019

#include <strings.h>

#include <ecdh_support.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <zen_octet.h>
#include <zen_big.h>
#include <zen_hash.h>

#include <zenroom.h>

// somehow not found in headers
extern size_t strnlen(const char *s, size_t maxlen);

// From rmd160.c
extern void RMD160_init(dword *MDbuf);
extern void RMD160_process(dword *MDbuf, byte *message, dword length);
extern void RMD160_hash(dword *MDbuf, byte *hashcode);


hash* hash_new(lua_State *L, const char *hashtype) {
	hash *h = lua_newuserdata(L, sizeof(hash));
	if(HEDLEY_UNLIKELY(h==NULL)) {
		zerror(L, "Error allocating new hash generator in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.hash");
	lua_setmetatable(L, -2);
	char ht[16];
	h->sha256 = NULL; h->sha384 = NULL; h->sha512 = NULL;
	h->rng = NULL;
	if(hashtype) strncpy(ht,hashtype,15);
	// TODO: change default to empty random (waiting for seed)
	else         strncpy(ht,"sha256",15);
	if(strncasecmp(hashtype,"sha256",6) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 32;
		h->algo = _SHA256;
		h->sha256 = (hash256*)malloc(sizeof(hash256));
		HASH256_init(h->sha256);
	} else if(strncasecmp(hashtype,"sha384",6) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 48;
		h->algo = _SHA384;
		h->sha384 = (hash384*)malloc(sizeof(hash384));
		HASH384_init(h->sha384);
	} else if(strncasecmp(hashtype,"sha512",6) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 64;
		h->algo = _SHA512;
		h->sha512 = (hash512*)malloc(sizeof(hash512));
		HASH512_init(h->sha512);
	} else if(strncasecmp(hashtype,"sha3_256",8) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 32;
		h->algo = _SHA3_256;
		h->sha3_256 = (sha3*)malloc(sizeof(sha3));
		SHA3_init(h->sha3_256, h->len);
	} else if(strncasecmp(hashtype,"sha3_512",8) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 64;
		h->algo = _SHA3_512;
		h->sha3_512 = (sha3*)malloc(sizeof(sha3));
		SHA3_init(h->sha3_512, h->len);
	} else if(strncasecmp(hashtype,"shake256",8) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 32;
		h->algo = _SHAKE256;
		h->shake256 = (sha3*)malloc(sizeof(sha3));
		SHA3_init(h->shake256, h->len);
	} else if(strncasecmp(hashtype,"keccak256",9) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 32;
		h->algo = _KECCAK256;
		h->keccak256 = (sha3*)malloc(sizeof(sha3));
		SHA3_init(h->keccak256, h->len);
	} else if(strncasecmp(hashtype,"ripemd160",9) == 0) {
		strncpy(h->name,hashtype,15);
		h->len = 20;
		h->algo = _RMD160;
		h->rmd160 = (dword*)malloc((160/32)+0x0f);
		RMD160_init(h->rmd160);
	} // ... TODO: other hashes
	else {
		zerror(L, "Hash algorithm not known: %s", hashtype);
		return NULL; }
	h->ref = 1;
	return(h);
}

void hash_free(lua_State *L, const hash *ch) {
	(void)L;
	if(!ch) return;
	hash *h = (hash*)ch;
	h->ref--;
	if(h->ref>0) return;
	if(h->rng) free(h->rng);
	switch(h->algo) {
	case _SHA256: free(h->sha256); break;
	case _SHA384: free(h->sha384); break;
	case _SHA512: free(h->sha512); break;
	case _SHA3_256: free(h->sha3_256); break;
	case _SHA3_512: free(h->sha3_512); break;
	case _SHAKE256: free(h->shake256); break;
	case _KECCAK256: free(h->keccak256); break;
	case _RMD160: free(h->rmd160); break;
	}
	free(h);
}

const hash* hash_arg(lua_State *L, int n) {
	void *ud = luaL_testudata(L, n, "zenroom.hash");
	if(HEDLEY_UNLIKELY(ud==NULL)) {
		zerror(L, "invalid hash in argument");
		return NULL;
	}
	hash* res = (hash*)ud;
	res->ref++;
	return(res);
}

/// Global Hash Functions
// @section Hash

/**
   Create a new hash object of a selected algorithm (e.g.sha256 or
   sha512). The resulting object can then process any @{OCTET} into
   its hashed equivalent. It is a C function.

   @param string indicating the type of hash algorithm (default "sha256")
   @function HASH.new
   @return a new hash object ready to process data via :process() method
   @see process
*/
static int lua_new_hash(lua_State *L) {
	BEGIN();
	const char *hashtype = luaL_optstring(L,1,"sha256");
	hash *h = hash_new(L, hashtype); SAFE(h, CREATE_HASH_ERR);
	func(L,"new hash type %s",hashtype);
	END(1);
}

// Taken from https://github.com/trezor/trezor-firmware/blob/master/crypto/bip39.c

#define BIP39_PBKDF2_ROUNDS 2048
// passphrase must be at most 256 characters otherwise it would be truncated

/**
	Convert a mnemonic phrase (used in cryptocurrency wallets) into a seed using the PBKDF2 (Password-Based Key Derivation Function 2) 
	*algorithm with HMAC-SHA512. This is commonly used in standards like BIP-39. 

	@function HASH.mnemonic_seed
	@param str1 a mnemonic phrase
	@param str2 a passphrase
	@return the derived seed as an octet object

 */
static int mnemonic_to_seed(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const char *mnemonic = lua_tostring(L, 1);
	luaL_argcheck(L, mnemonic != NULL, 1, "string expected");

	const char *passphrase = lua_tostring(L, 2);
	luaL_argcheck(L, passphrase != NULL, 2, "string expected");

	int mnemoniclen = strlen(mnemonic);
	int passphraselen = strnlen(passphrase, 256);

	uint8_t salt[8 + 256] = {0};
	memcpy(salt, "mnemonic", 8);
	memcpy(salt + 8, passphrase, passphraselen);

	// PBDKF2 inputs have to be octets
	octet omnemonic, osalt;
	omnemonic.val = (char*)malloc(mnemoniclen); SAFE_GOTO(omnemonic.val, MALLOC_ERROR);
	memcpy(omnemonic.val, mnemonic, mnemoniclen);
	omnemonic.max = mnemoniclen;
	omnemonic.len = mnemoniclen;

	// There must be the space to concat a 4 byte integer
	// (look at the source code of PBKDF2)
	osalt.val = (char*)malloc(passphraselen+8+4); SAFE_GOTO(osalt.val, MALLOC_ERROR);
	memcpy(osalt.val, salt, passphraselen+8+4);
	osalt.len = passphraselen+8;
	osalt.max = passphraselen+8+4;

	/*octet omnemonic = { mnemoniclen, mnemoniclen, (char*)mnemonic };
	  octet osalt = {passphraselen+8, passphraselen+8+4, (char*)salt};*/

	octet *okey = o_new(L, 512 / 8); SAFE_GOTO(okey, CREATE_OCT_ERR);
	PBKDF2(SHA512, &omnemonic, &osalt, BIP39_PBKDF2_ROUNDS, 512 / 8, okey);
	okey->len = 512 / 8;
end:
	free(omnemonic.val);
	free(osalt.val);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/// Object Methods
// @type Hash

/*** Decrement the reference count of an hash object and free its memory when no more references exist.
 	*It ensures proper memory management to prevent leaks. 

	@function hash:__gc
	@param hash an hash object
	@return no values are returned 

 */
int hash_destroy(lua_State *L) {
	BEGIN();
	hash *h = (hash*)luaL_testudata(L, 1, "zenroom.hash");
	if(HEDLEY_UNLIKELY(h==NULL)) return(0);
	h->ref--;
	if(h->ref>0) return(0);
	if(h->rng) free(h->rng);
	switch(h->algo) {
	case _SHA256: free(h->sha256); break;
	case _SHA384: free(h->sha384); break;
	case _SHA512: free(h->sha512); break;
	case _SHA3_256: free(h->sha3_256); break;
	case _SHA3_512: free(h->sha3_512); break;
	case _SHAKE256: free(h->shake256); break;
	case _KECCAK256: free(h->keccak256); break;
	case _RMD160: free(h->rmd160); break;
	}
	END(0);
}


// internal use to feed bytes into the hash structure
static void _feed(const hash *h, const octet *o) {
	register int i;
	switch(h->algo) {
	case _SHA256: for(i=0;i<o->len;i++) HASH256_process(h->sha256,o->val[i]); break;
	case _SHA384: for(i=0;i<o->len;i++) HASH384_process(h->sha384,o->val[i]); break;
	case _SHA512: for(i=0;i<o->len;i++) HASH512_process(h->sha512,o->val[i]); break;
	case _SHA3_256: for(i=0;i<o->len;i++) SHA3_process(h->sha3_256,o->val[i]); break;
	case _SHA3_512: for(i=0;i<o->len;i++) SHA3_process(h->sha3_512,o->val[i]); break;
	case _SHAKE256: for(i=0;i<o->len;i++) SHA3_process(h->shake256,o->val[i]); break;
	case _KECCAK256: for(i=0;i<o->len;i++) SHA3_process(h->keccak256,o->val[i]); break;
	case _RMD160: RMD160_process(h->rmd160, (unsigned char*)o->val, o->len); break;
	}
}

// internal use to yeld a result from the hash structure
static void _yeld(const hash *h, octet *o) {
	switch(h->algo) {
	case _SHA256: HASH256_hash(h->sha256,o->val); break;
	case _SHA384: HASH384_hash(h->sha384,o->val); break;
	case _SHA512: HASH512_hash(h->sha512,o->val); break;
	case _SHA3_256: SHA3_hash(h->sha3_256,o->val); break;
	case _SHA3_512: SHA3_hash(h->sha3_512,o->val); break;
	case _KECCAK256: KECCAK_hash(h->keccak256,o->val); break;
	case _RMD160: RMD160_hash(h->rmd160, (unsigned char*)o->val); break;
	}
}

static void _yeld_len(const hash *h, octet *o, int len) {
	switch(h->algo) {
	case _SHAKE256:
	  SHA3_shake(h->shake256,o->val, len);
	  SHA3_init(h->shake256, h->len);
	  break;
	}
}

/*** Convert an hash object into an octet object. It retrieves the hash object from the Lua stack, creates a new octet object of the same length, copies the hash data into the octet, and returns the octet object to Lua. 
 	*If any step fails, it throws an error.

	@function hash:octet
	@return the newly created octet object
	@usage 
	--define a "sha256" hash object
	h1 = HASH.new()
	--trasform h1 in hex-octet
	print(h1:octet():hex())
	--print: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
 */
static int hash_to_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *res = NULL;
	const hash *h = hash_arg(L,1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	res = o_new(L,h->len); SAFE_GOTO(res, CREATE_OCT_ERR);
	_yeld(h, res);
	res->len = h->len;
end:
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/**
	Hash an octet into a new octet. Use the configured hash function to
    *hash an octet string and return a new one containing its hash.

    @param data octet containing the data to be hashed
    @function hash:process
    @return a new octet containing the hash of the data
    @usage 
	--create an octet and an hash object
	oct = OCTET.from_hex("0xa1b2c3d4")
	--create an hash object
	h1 = HASH.new()
	--apply the method to the octet
	print(h1:process(oct):hex())
	--print: 97ed8e55519b020c4d9aceb40e0d3bc7eaa22d080d49592bf21206cb697c8a58
*/
static int hash_process(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = NULL;
	octet *res = NULL;
	int len;
	const hash *h = hash_arg(L,1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	o = o_arg(L,2); SAFE_GOTO(o, ALLOCATE_OCT_ERR);
	len =  luaL_optinteger (L, 3, 0);

	if (len <= 0) {
		res = o_new(L, h->len);
	} else {
		res = o_new(L, len);
	}
	SAFE_GOTO(res, CREATE_OCT_ERR);
	_feed(h, o);
	if (len <= 0) {
		_yeld(h, res);
		res->len = h->len;
	} else {
		_yeld_len(h, res, len);
		res->len = len;
	}
end:
	o_free(L, o);
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/**
   Feed a new octet into a current hashing session. This is used to
   hash multiple chunks until @{yeld} is called.

   @param data octet containing the data to be hashed
   @function hash:feed
*/
static int hash_feed(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = NULL;
	const hash *h = hash_arg(L,1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	o = o_arg(L,2); SAFE_GOTO(o, ALLOCATE_OCT_ERR);
	_feed(h, o);
end:
	o_free(L, o);
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(0);
}

/**
   Yeld a new octet from the current hashing session. This is used to
   finalize the hashing of multiple chunks after @{feed} is called.

   @function hash:yeld
   @return a new octet containing the hash of the data

*/
static int hash_yeld(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const hash *h = hash_arg(L, 1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	octet *res = o_new(L, h->len); SAFE_GOTO(res, CREATE_OCT_ERR);
	_yeld(h, res);
	res->len = h->len;
end:
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/**
   Compute the HMAC of a message using a key. This method takes any
   data and any key material to compute an HMAC of the same length of
   the hash bytes of the keyring. This function works in accordance with
   RFC2104.

   @param key an octet containing the key to compute the HMAC
   @param data an octet containing the message to compute the HMAC
   @function hash:hmac
   @return a new octet containing the computed HMAC or false on failure
   @usage 
   --create the key
   key = OCTET.from_hex("0xa1b2c3d4")
   --create the hash
   h1 = HASH.new()
   --create the message
   message = OCTET.from_hex("0xc3d2")
   --compute the HMAC
   print(h1:hmac(key,message):hex())
   --print: 844548df11876f644413664403e648fa74ee4a3fb547c2dedb3db0a564c15abb
*/
static int hash_hmac(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *k = NULL, *in = NULL;
	const hash *h = hash_arg(L, 1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	k  = o_arg(L, 2);
	in = o_arg(L, 3);
	SAFE_GOTO(k && in, ALLOCATE_OCT_ERR);
	// length defaults to hash bytes (SHA256 = 32 = sha256)
	octet *out;
	if(h->algo == _SHA256) {
		out = o_new(L, SHA256+1); SAFE_GOTO(out, CREATE_OCT_ERR);
		//              hash    m   k  outlen  out
		if(!AMCL_(HMAC)(SHA256, (octet*)in, (octet*)k, SHA256, out)) {
			zerror(L, "%s: hmac (%u bytes) failed.", __func__,SHA256);
			lua_pop(L, 1);
			lua_pushboolean(L,0);
		}
	} else if(h->algo == _SHA512) {
		out = o_new(L, SHA512+1); SAFE_GOTO(out, CREATE_OCT_ERR);
		//              hash    m   k  outlen  out
		if(!AMCL_(HMAC)(SHA512, (octet*)in, (octet*)k, SHA512, out)) {
			zerror(L, "%s: hmac (%u bytes) failed.", __func__,SHA512);
			lua_pop(L, 1);
			lua_pushboolean(L,0);
		}
	} else {
		failed_msg = "HMAC is only supported for hash SHA256 or SHA512";
	}
end:
	o_free(L, k);
	o_free(L, in);
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/**
   Key Derivation Function (KDF2). Key derivation is used to
   strengthen keys against bruteforcing: they impose a number of
   costly computations to be iterated on the key. This function
   generates a new key from an existing key applying an octet of key
   derivation parameters.

   @param key octet of the key to be transformed
   @function hash:kdf2
   @return a new octet containing the derived key
*/

static int hash_kdf2(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *in = NULL;
	const hash *h = hash_arg(L, 1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	in = o_arg(L, 2); SAFE_GOTO(in, ALLOCATE_OCT_ERR);
	// output keylen is length of hash
	octet *out = o_new(L, h->len+0x0f); SAFE_GOTO(out, CREATE_OCT_ERR);
	KDF2(h->len, (octet*)in, NULL , h->len, out);
end:
	o_free(L, in);
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/**
   Password Based Key Derivation Function (PBKDF2). This function
   generates a new key from an existing key applying a salt and number
   of iterations.

   @param key octet of the key to be transformed
   @param salt octet containing a salt to be used in transformation
   @param iterations[opt=5000] number of iterations to be applied
   @param length[opt=key length] integer indicating the new length (default same as input key)
   @function hash:pbkdf2
   @return a new octet containing the derived key

   @see hash:kdf2
*/

static int hash_pbkdf2(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	int iter, keylen;
	octet *ss = NULL;
	const octet *k = NULL, *s = NULL;
	const hash *h = hash_arg(L,1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	k = o_arg(L, 2); SAFE_GOTO(k, ALLOCATE_OCT_ERR);
	// take a table as argument with salt, iterations and length parameters
	if(lua_type(L, 3) == LUA_TTABLE) {
		lua_getfield(L, 3, "salt");
		lua_getfield(L, 3, "iterations");
		lua_getfield(L, 3, "length"); // -3
		s = o_arg(L,-3); SAFE_GOTO(s, ALLOCATE_OCT_ERR);
		// default iterations 5000
		iter = luaL_optinteger(L,-2, 5000);
		keylen = luaL_optinteger(L,-1,k->len);
	} else {
		s = o_arg(L, 3); SAFE_GOTO(s, ALLOCATE_OCT_ERR);
		iter = luaL_optinteger(L, 4, 5000);
		// keylen is length of input key
		keylen = luaL_optinteger(L, 5, k->len);
	}
	// There must be the space to concat a 4 byte integer
	// (look at the source code of PBKDF2)
	ss = o_new(L, s->len+4); SAFE_GOTO(ss, CREATE_OCT_ERR);
	memcpy(ss->val, s->val, s->len);
	ss->len = s->len;
	octet *out = o_new(L, keylen); SAFE_GOTO(out, CREATE_OCT_ERR);
	// TODO: according to RFC2898, s should have a size of 8
	// c should be a positive integer
	PBKDF2(h->len, (octet*)k, ss, iter, keylen, out);
end:
	o_free(L, s);
	o_free(L, k);
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/**
	Seed a cryptographically secure pseudo-random number generator (CSPRNG) associated with a hash object. 
	*It uses an octet object as the seed and optionally "fast-forwards" the CSPRNG to improve randomness.
	
	@function hash:random_seed
	@param seed an octet object
 */
static int hash_srand(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *seed = NULL;
	const hash *h = hash_arg(L, 1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	seed = o_arg(L, 2); SAFE_GOTO(seed, ALLOCATE_OCT_ERR);
	if(!h->rng) { // TODO: reuse if same seed is already sown
		((hash*)h)->rng = (csprng*)malloc(sizeof(csprng)); SAFE_GOTO(h->rng, MALLOC_ERROR);
	}
	AMCL_(RAND_seed)(h->rng, seed->len, seed->val);
	// fast-forward to runtime_random (256 bytes) and 4 bytes lua
	for(register int i=0;i<PRNG_PREROLL+4;i++) RAND_byte(h->rng);
 end:
	o_free(L, seed);
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(0);
}
/** Generate a random 8-bit unsigned integer using a cryptographically secure pseudo-random number generator (CSPRNG) associated with a hash object. 
	*It ensures that the CSPRNG has been seeded before generating the random number.

	@function hash:random_int8
	@return a random 8-bit unsigned integer 
 */
static int rand_uint8(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const hash *h = hash_arg(L,1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	SAFE_GOTO(h->rng, "HASH random number generator lacks seed");
	uint8_t res = RAND_byte(h->rng);
	lua_pushinteger(L, (lua_Integer)res);
 end:
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/** Generate a random 16-bit unsigned integer using a cryptographically secure pseudo-random number generator (CSPRNG) associated with a hash object. 
	*It ensures that the CSPRNG has been seeded before generating the random number.

	@function hash:random_int16
	@return a random 16-bit unsigned integer 
 */
static int rand_uint16(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const hash *h = hash_arg(L,1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	SAFE_GOTO(h->rng, "HASH random number generator lacks seed");
	uint16_t res =
		RAND_byte(h->rng)
		| (uint32_t) RAND_byte(h->rng) << 8;
	lua_pushinteger(L, (lua_Integer)res);
 end:
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/** Generate a random 32-bit unsigned integer using a cryptographically secure pseudo-random number generator (CSPRNG) associated with a hash object. 
	*It ensures that the CSPRNG has been seeded before generating the random number.

	@function hash:random_int32
	@return a random 32-bit unsigned integer 
 */
static int rand_uint32(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const hash *h = hash_arg(L,1); SAFE_GOTO(h, ALLOCATE_HASH_ERR);
	SAFE_GOTO(h->rng, "HASH random number generator lacks seed");
	uint32_t res =
		RAND_byte(h->rng)
		| (uint32_t) RAND_byte(h->rng) << 8
		| (uint32_t) RAND_byte(h->rng) << 16
		| (uint32_t) RAND_byte(h->rng) << 24;
	lua_pushinteger(L, (lua_Integer)res);
 end:
	hash_free(L, h);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_hash(lua_State *L) {
	(void)L;
	const struct luaL_Reg hash_class[] = {
		{"new", lua_new_hash},
		{"octet", hash_to_octet},
		{"hmac", hash_hmac},
		{"kdf2", hash_kdf2},
		{"kdf", hash_kdf2},
		{"pbkdf2", hash_pbkdf2},
		{"pbkdf", hash_pbkdf2},
		{"mnemonic_seed", mnemonic_to_seed},
		{"random_seed", hash_srand},
		{"random_int8", rand_uint8},
		{"random_int16", rand_uint16},
		{"random_int32", rand_uint32},
		{NULL,NULL}};
	const struct luaL_Reg hash_methods[] = {
		{"octet", hash_to_octet},
		{"process", hash_process},
		{"feed", hash_feed},
		{"yeld", hash_yeld},
		{"do", hash_process},
		{"hmac", hash_hmac},
		{"kdf2", hash_kdf2},
		{"kdf", hash_kdf2},
		{"pbkdf2", hash_pbkdf2},
		{"pbkdf", hash_pbkdf2},
		{"random_seed", hash_srand},
		{"random_int8", rand_uint8},
		{"random_int16", rand_uint16},
		{"random_int32", rand_uint32},
		{"__gc", hash_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "hash", hash_class, hash_methods);
	return 1;
}
