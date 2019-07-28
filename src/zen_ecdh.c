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

/// <h1>Elliptic Curve Diffie-Hellman encryption (ECDH)</h1>
//
//  Asymmetric public/private key encryption technologies.
//
//  ECDH encryption and ECDSA signing functionalities are provided by
//  this module. New keyring instances are instantiated by calling the
//  new() method, keys can be imported using the 
//
//  <code>
//  Alice = ECDH.new()
//  Bob = ECDH.new()
//  </code>
//
//  One can create more keyrings in the same script and call them with
//  meaningful variable names to help making code more
//  understandable. Each keyring instance offers methods prefixed with
//  a double-colon that operate on arguments as well keys contained by
//  the keyring: this way scripting can focus on the identities
//  represented by each keyring, giving them names as 'Alice' or
//  'Bob'.
//
//  @module ECDH
//  @author Denis "Jaromil" Roio, Enrico Zimuel
//  @license GPLv3
//  @copyright Dyne.org foundation 2017-2019


#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <ecdh_support.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <randombytes.h>
#include <lua_functions.h>

#include <zenroom.h>
#include <zen_memory.h>
#include <zen_hash.h>
#include <zen_ecdh.h>

#define KEYPROT(alg,key)	  \
	error(L, "%s engine has already a %s set:",alg,key); \
	lerror(L, "Zenroom won't overwrite. Use a .new() instance.");

// from zen_ecdh_factory.h to setup function pointers
extern ecdh *ecdh_new_curve(lua_State *L, const char *curve);


extern zenroom_t *Z; // accessed to check random_seed configuration


/// Global ECDH functions
// @section ECDH.globals

/***
    Create a new ECDH encryption keyring using a specified curve or
    BLS383 by default if omitted. The ECDH keyring created will
    offer methods to interact with other keyrings.

    Supported curves: BLS383, ED25519, GOLDILOCKS, SECP256K1

    Please note curve selection is only supported in ECDH. The curve
    BLS383 is the only one supported for @{ECP}/@{ECP2} arithmetics:
    it is the default to grant compatibility between ECDH.public() and
    @{ECP} points.

    @param curve[opt=BLS383] elliptic curve to be used
    @return a new ECDH keyring
    @function new(curve)
    @usage
    keyring = ECDH.new()
    -- generate a keypair
    keyring:keygen()
*/

ecdh* ecdh_new(lua_State *L, const char *curve) {
	HERE();
	ecdh *e = ecdh_new_curve(L, curve);
	if(!e) { SAFE(e); return NULL; }

	// key storage and key lengths are important
	e->seckey = NULL;
	e->seclen = e->keysize;   // TODO: check for each curve
	e->pubkey = NULL;
	e->publen = e->keysize*2; // TODO: check for each curve

	// initialise a new random number generator
	// TODO: make it a newuserdata object in LUA space so that
	// it can be cleanly collected by the GC as well it can be
	// saved transparently in the global state
	luaL_getmetatable(L, "zenroom.ecdh");
	lua_setmetatable(L, -2);
	return(e);
}
ecdh* ecdh_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.ecdh");
	luaL_argcheck(L, ud != NULL, n, "ecdh class expected");
	ecdh *e = (ecdh*)ud;
	return(e);
}
int ecdh_destroy(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L,1);
	SAFE(e);
	// FREE(r->pubkey);
	// FREE(r->privkey);
	return 0;
}


static int lua_new_ecdh(lua_State *L) {
	const char *curve = luaL_optstring(L, 1, "bls383");
	ecdh *e = ecdh_new(L, curve);
	SAFE(e);
	func(L,"new ecdh curve %s type %s", e->curve, e->type);
	// any action to be taken here?
	return 1;
}

static int ecdh_new_keygen(lua_State *L) {
	HERE();
	const char *curve = luaL_optstring(L, 1, "bls383");
	ecdh *e = ecdh_new(L, curve); SAFE(e);
	e->pubkey = o_new(L,e->publen +0x0f); SAFE(e->pubkey);
	e->seckey = o_new(L,e->seclen +0x0f); SAFE(e->seckey);
	(*e->ECP__KEY_PAIR_GENERATE)(Z->random_generator,e->seckey,e->pubkey);
	HEREecdh(e);
	lua_pop(L, 1);
	lua_pop(L, 1);
	//	HEREoct(pk); HEREoct(sk);
	return 1;
}

/// Instance Methods
// @type keyring

/**
   Generate an ECDH public/private key pair for a keyring

   Keys generated are both returned and stored inside the
   keyring. They can also be retrieved later using the
   <code>:public()</code> and <code>:private()</code> methods if
   necessary.

   @function keyring:keygen()
   @treturn[1] OCTET public key
   @treturn[1] OCTET private key
*/
static int ecdh_keygen(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(e->seckey) {
		ERROR(); KEYPROT(e->curve,"private key"); }
	if(e->pubkey) {
		ERROR(); KEYPROT(e->curve,"public key"); }
	octet *pk = o_new(L,e->publen +0x0f); SAFE(pk);
	octet *sk = o_new(L,e->seclen +0x0f); SAFE(sk);
	(*e->ECP__KEY_PAIR_GENERATE)(Z->random_generator,sk,pk);
	e->pubkey = pk;
	e->seckey = sk;
	HEREecdh(e);
//	HEREoct(pk); HEREoct(sk);
	return 2;
}

/**
   Validate an ECDH public key. Any octet can be a private key, but
   public keys aren't random and checking them is the only validation
   possible.

   @param key the input public key octet to be validated
   @function keyring:checkpub(key)
   @return true if public key is OK, or false if not.
*/

static int ecdh_checkpub(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L,1); SAFE(e);
	octet *pk = NULL;
	if(lua_isnoneornil(L, 2)) {
		if(!e->pubkey) {
			return lerror(L, "Public key not found."); }
		pk = e->pubkey;
	} else
		pk = o_arg(L, 2); SAFE(pk);
	if((*e->ECP__PUBLIC_KEY_VALIDATE)(pk)==0)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}

/**
   Generate a Diffie-Hellman shared session key. This function uses
   two keyrings to calculate a shared key, then process it through
   KDF2 to make it ready for use in @{keyring:aead_encrypt}. This is
   compliant with the IEEE-1363 Diffie-Hellman shared secret
   specification for asymmetric key encryption.

   @param keyring containing the public key to be used
   @function keyring:session(keyring)
   @treturn[1] octet KDF2 hashed session key ready for @{keyring:aead_encrypt}
   @treturn[1] octet a @{BIG} number result of (private * public) % curve_order
   @see keyring:aead_encrypt
*/
static int ecdh_session(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L,1); SAFE(e);
	if(!e->seckey) {
		lerror(L,"%s: secret key not found in 1st argument");
		return 0; }
	ecdh *p = ecdh_arg(L,2); SAFE(p);
	if(!p->pubkey) {
		lerror(L,"%s: public key not found in 2nd argument");
		return 0; }
	int res;
	res = (*e->ECP__PUBLIC_KEY_VALIDATE)(p->pubkey);
	if(res<0) {
		lerror(L, "%s: public key found invalid in 2nd argument",
		       __func__);
		return 0; }
	octet *kdf = o_new(L,e->hash); SAFE(kdf);
	octet *ses = o_new(L,e->keysize); SAFE(ses);
	(*e->ECP__SVDP_DH)(e->seckey,p->pubkey,ses);
	// process via KDF2
	// https://github.com/milagro-crypto/milagro-crypto-c/issues/285	
	// here the NULL could be a salt (TODO: global?)
	// its used internally by KDF2 as 'p' in the hash function
	//         ehashit(sha,z,counter,p,&H,0);
	KDF2(e->hash,ses,NULL,e->hash,kdf);
	return 2;
}

/**
   Imports or exports the public key from an ECDH keyring. This method
   functions in two ways: without argument it returns the public key
   of a keyring, or if an octet argument is provided it imports it as
   public key inside the keyring, but it refuses to overwrite and
   returns an error if a public key is already present.

   @param key[opt] octet of a public key to be imported
   @function keyring:public(key)
*/
static int ecdh_public(lua_State *L) {
	HERE();
	int res;
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(lua_isnoneornil(L, 2)) {
		if(!e->pubkey) {
			ERROR();
			return lerror(L, "Public key is not found in keyring.");
		}
		// export public key to octet
		res = (e->ECP__PUBLIC_KEY_VALIDATE)(e->pubkey);
		if(res<0) {
			ERROR();
			return lerror(L, "Public key found, but invalid."); }
		// succesfully return public key stored in keyring
		o_dup(L,e->pubkey);
		return 1;
	}
	// has an argument: public key to set
	if(e->pubkey!=NULL) {
		ERROR();
		KEYPROT(e->curve, "public key"); }
	octet *o = o_arg(L, 2); SAFE(o);
	res = (*e->ECP__PUBLIC_KEY_VALIDATE)(o);
	if(res<0) {
		ERROR();
		return lerror(L, "Public key argument is invalid."); }
	func(L, "%s: valid key",__func__);
	// succesfully set the new public key
	e->pubkey = o;
	return 0;
}


/**
   Imports or exports the private key from an ECDH keyring. This method
   functions in two ways: without argument it returns the private key
   of a keyring, or if an octet argument is provided it imports it as
   private  key inside the keyring and generates a public key for it. If
   a private key is already present in the keyring it refuses to
   overwrite and returns an error.

   @param key[opt] octet of a private key to be imported
   @function keyring:private(key)
*/
static int ecdh_private(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(lua_isnoneornil(L, 2)) {
		// no argument: return stored key
		if(!e->seckey) {
			ERROR();
			return lerror(L, "Private key is not found in keyring."); }
		// export public key to octet
		o_dup(L, e->seckey);
		return 1;
	}
	if(e->seckey!=NULL) {
		ERROR(); KEYPROT(e->curve, "private key"); }
	e->seckey = o_arg(L, 2); SAFE(e->seckey);
	octet *pk = o_new(L,e->publen+0x0f); SAFE(pk);
	(*e->ECP__KEY_PAIR_GENERATE)(NULL,e->seckey,pk);
	int res;
	res = (*e->ECP__PUBLIC_KEY_VALIDATE)(pk);
	if(res<0) {
		ERROR();
		return lerror(L, "Invalid public key generation."); }
	e->pubkey = pk;
	HEREecdh(e);
	return 1;
}

/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) signing
   function. This method uses the private key inside a keyring to
   sign a message, returning two parameters 'r' and 's' representing
   the signature. The parameters can be used in @{keyring:verify}.

   @param message string or @{OCTET} message to sign
   @function keyring:sign(message)
   @treturn[1] octet containing the first signature parameter (r)
   @treturn[1] octet containing the second signature parameter (s)
   @usage
   ecdh = ECDH.keygen() -- generate keys or import them
   m = "Message to be signed"
   r,s = ecdh:sign(m)
   assert( ecdh:verify(m,r,s) )
*/

static int ecdh_dsa_sign(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L,1); SAFE(e);
	octet *f = o_arg(L,2); SAFE(f);
	octet *c = o_new(L,64); SAFE(c);
	octet *d = o_new(L,64); SAFE(d);
	// IEEE ECDSA Signature, C and D are signature on F using private key S
	// either pass an RNG or K already randomised
	// for K's generation see also RFC6979
	// ECP_BLS383_SP_DSA(int sha,csprng *RNG,octet *K,octet *S,octet *F,octet *C,octet *D)
	(*e->ECP__SP_DSA)(     64,     Z->random_generator,     NULL, e->seckey,    f,      c,      d );
	return 2;
}


/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) verification
   function. This method uses the public key iside a keyring to verify
   a message, returning true or false. The signature parameters are
   returned as 'r' and 's' in this same order by @{keyring:sign}.

   @param message the message whose signature has to be verified
   @param r the first signature parameter
   @param s the second signature paramter
   @function keyring:verify(message,r,s)
   @return true if the signature is OK, or false if not.
   @see keyring:sign
*/
static int ecdh_dsa_verify(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1); SAFE(e);
    // IEEE1363 ECDSA Signature Verification. Signature C and D on F
    // is verified using public key W
	octet *f = o_arg(L,2); SAFE(f);
	octet *c = o_arg(L,3); SAFE(c);
	octet *d = o_arg(L,4); SAFE(d);
	int res = (*e->ECP__VP_DSA)(64, e->pubkey, f, c, d);
	if(res <0) // ECDH_INVALID in milagro/include/ecdh.h.in (!?!)
		// TODO: maybe suggest fixing since there seems to be
		// no criteria between ERROR (used in the first check
		// in VP_SDA) and INVALID (in the following two
		// checks...)
		lua_pushboolean(L, 0);
	else
		lua_pushboolean(L, 1);
	return 1;
}
/**
   AES-GCM encrypt with Additional Data (AEAD) encrypts and
   authenticate a plaintext to a ciphtertext. Function compatible with
   IEEE P802.1 specification. Errors out if encryption fails, else
   returns the secret ciphertext and a SHA256 of the header to
   checksum the integrity of the accompanying plaintext, to be
   compared with the one obtained by @{aead_decrypt}.

   @param key AES key octet (must be 8, 16, 32 or 64 bytes long)
   @param message input text in an octet
   @param iv initialization vector (can be random each time)
   @param header clear text, authenticated for integrity (checksum)
   @function aead_encrypt(key, message, iv, h)
   @treturn[1] octet containing the output ciphertext
   @treturn[1] octet containing the authentication tag (checksum)
*/

static int ecdh_aead_encrypt(lua_State *L) {
	HERE();
	octet *k =  o_arg(L, 1); SAFE(k);
	// check if key is a power of two byte length, as well not bigger
	// than 64 bytes and not smaller than 16 bytes
	if(!(k->len && !(k->len & (k->len - 1))) ||
	   (k->len > 64 && k->len < 16) ) {
		error(L,"ECDH.aead_encrypt accepts only keys of ^2 length (16,32,64), this is %u", k->len);
		lerror(L,"ECDH encryption aborted");
		return 0; }
	octet *in = o_arg(L, 2); SAFE(in);
	octet *iv = o_arg(L, 3); SAFE(iv);
	octet *h =  o_arg(L, 4); SAFE(h);
	// output is padded to next word
	octet *out = o_new(L, in->len+16); SAFE(out);
	octet *t = o_new(L, 32); SAFE (t);
	AES_GCM_ENCRYPT(k, iv, h, in, out, t);
	return 2;
}

/**
   AES-GCM decrypt with Additional Data (AEAD) decrypts and
   authenticate a plaintext to a ciphtertext . Compatible with IEEE
   P802.1 specification.

   @param key AES key octet
   @param message input text in an octet
   @param iv initialization vector
   @param header the additional data
   @treturn[1] octet containing the output ciphertext
   @treturn[1] octet containing the authentication tag (checksum)
   @function aead_decrypt(key, ciphertext, iv, h)
*/

static int ecdh_aead_decrypt(lua_State *L) {
	HERE();
	octet *k = o_arg(L, 1); SAFE(k);
	if(!(k->len && !(k->len & (k->len - 1))) ||
	   (k->len > 64 && k->len < 16) ) {
		error(L,"ECDH.aead_decrypt accepts only keys of ^2 length (16,32,64), this is %u", k->len);
		lerror(L,"ECDH decryption aborted");
		return 0; }
	octet *in = o_arg(L, 2); SAFE(in);
	octet *iv = o_arg(L, 3); SAFE(iv);
	octet *h = o_arg(L, 4); SAFE(h);

	// output is padded to next word
	octet *out = o_new(L, in->len+16); SAFE(out);
	octet *t2 = o_new(L,32); SAFE(t2); // measured empirically is 16
	AES_GCM_DECRYPT(k, iv, h, in, out, t2);
	return 2;
}

/**
   Hash an octet into a new octet. Use the keyring's hash function to
   hash an octet string and return a new one containing the hash of
   the string.

   @param string octet containing the data to be hashed
   @function keyring:hash(string)
   @return a new octet containing the hash of the data
*/
static int ecdh_hash(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	HEREecdh(e);
	octet *in = o_arg(L, 2); SAFE(in);
	HEREoct(in);
	// hash type indicates also the length in bytes
	octet *out = o_new(L, e->hash); SAFE(out);
	HASH(e->hash, in, out);
	HEREoct(out);
	return 1;
}

/**
   Compute the HMAC of a message using a key. This method takes any
   data and any key material to comput an HMAC of the same length of
   the hash bytes of the keyring.

   @param key an octet containing the key to compute the HMAC
   @param data an octet containing the message to compute the HMAC
   @param len[opt=keyring->hash bytes] length of HMAC or default
   @function keyring:hmac(key, data, len)
   @return a new octet containing the computer HMAC or false on failure
*/
static int ecdh_hmac(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *k = o_arg(L, 2);     SAFE(k);
	octet *in = o_arg(L, 3);    SAFE(in);
	// length defaults to hash bytes
	const int len = luaL_optinteger(L, 4, e->hash);
	octet *out = o_new(L, len); SAFE(out);
	if(!HMAC(e->hash, in, k, len, out)) {
		error(L, "%s: hmac (%u bytes) failed.", len);
		lua_pop(L, 1);
		lua_pushboolean(L,0);
	}
	return 1;
}

/**
   Key Derivation Function (KDF2). Key derivation is used to
   strengthen keys against bruteforcing: they impose a number of
   costly computations to be iterated on the key. This function
   generates a new key from an existing key applying an octet of key
   derivation parameters.

   @param parameters[opt=nil] octet of key derivation parameters (can be <code>nil</code>)
   @param key octet of the key to be transformed
   @param length[opt=key length] integer indicating the new length (default same as input key)
   @function keyring:kdf2(parameters, key, length)
   @return a new octet containing the derived key
*/

static int ecdh_kdf2(lua_State *L) {
	HERE();
	int hashlen = 0;
	if(luaL_testudata(L, 1, "zenroom.ecdh")) {
		ecdh *e = ecdh_arg(L,1); SAFE(e);
		hashlen = e->hash;
	} else if(luaL_testudata(L, 1, "zenroom.hash")) {
		hash *h = hash_arg(L,1); SAFE(h);
		hashlen = h->len;
	} else {
		lerror(L,"Invalid first argument for ECDH.kdf2: should be an ECDH or HASH object");
		return 0;
	}
	octet *in = o_arg(L, 2); SAFE(in);
	// output keylen is length of hash
	octet *out = o_new(L, hashlen+0x0f); SAFE(out);
	KDF2(hashlen, in, NULL , hashlen, out);
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

static int ecdh_pbkdf2(lua_State *L) {
	HERE();
	int hashlen = 0;
	if(luaL_testudata(L, 1, "zenroom.ecdh")) {
		ecdh *e = ecdh_arg(L,1); SAFE(e);
		hashlen = e->hash;
	} else if(luaL_testudata(L, 1, "zenroom.hash")) {
		hash *h = hash_arg(L,1); SAFE(h);
		hashlen = h->len;
	} else {
		lerror(L,"Invalid first argument for ECDH.pbkdf2: should be an ECDH or HASH object");
		return 0;
	}
	octet *k = o_arg(L, 2); SAFE(k);
	octet *s = o_arg(L, 3); SAFE(s);
	// default iterations 1000
	const int iter = luaL_optinteger(L, 4, 1000);
	// keylen is length of input key
	const int keylen = luaL_optinteger(L, 5, k->len);

	octet *out = o_new(L, keylen); SAFE(out);

	// TODO: OPTIMIZATION: reuse the initialized hash* structure in
	// hmac->ehashit instead of milagro's
	PBKDF2(hashlen, k, s, iter, keylen, out);
	return 1;
}


#define COMMON_METHODS \
	{"public", ecdh_public}, \
	{"private", ecdh_private}, \
	{"checkpub", ecdh_checkpub}, \
	{"kdf2", ecdh_kdf2}, \
	{"kdf", ecdh_kdf2}, \
	{"pbkdf2", ecdh_pbkdf2}, \
	{"pbkdf", ecdh_pbkdf2}, \
	{"sign", ecdh_dsa_sign}, \
	{"verify", ecdh_dsa_verify}



int luaopen_ecdh(lua_State *L) {
	const struct luaL_Reg ecdh_class[] = {
		{"new",lua_new_ecdh},
		{"keygen",ecdh_new_keygen},
		{"aead_encrypt",   ecdh_aead_encrypt},
		{"aead_decrypt",   ecdh_aead_decrypt},
		{"aesgcm_encrypt", ecdh_aead_encrypt},
		{"aesgcm_decrypt", ecdh_aead_decrypt},
		{"aes_encrypt",    ecdh_aead_encrypt},
		{"aes_decrypt",    ecdh_aead_decrypt},
		{"hash", ecdh_hash},
		{"hmac", ecdh_hmac},
		{"session", ecdh_session},
		COMMON_METHODS,
		{NULL,NULL}};
	const struct luaL_Reg ecdh_methods[] = {
		{"keygen",ecdh_keygen},
		{"session",ecdh_session},
		COMMON_METHODS,
		{"__gc", ecdh_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "ecdh", ecdh_class, ecdh_methods);
	return 1;
}
