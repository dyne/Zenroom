// Zenroom ECDH module
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


/// <h1>Elliptic Curve Diffie-Hellman encryption (ECDH)</h1>
//
//  Asymmetric public/private key encryption technologies.
//
//  ECDH encryption functionalities are provided with all standard
//  functions by this extension. It is possible to create keyring
//  instances using the new() method:
//
//  <code>keyring = ECDH.new()</code>
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
//  @copyright Dyne.org foundation 2017-2018


#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <randombytes.h>
#include <lua_functions.h>


// TODO: wrap this for more curves (may solve GOLDILOCKS)
#include <ecdh_ED25519.h>


#include <zenroom.h>
#include <zen_memory.h>
#include <zen_ecdh.h>

#define KEYPROT(alg,key)	  \
	error(L, "%s engine has already a %s set:",alg,key); \
	lerror(L, "Zenroom won't overwrite. Use a .new() instance.");

// from zen_ecdh_factory.h to setup function pointers
extern ecdh *ecdh_new_curve(lua_State *L, const char *curve);

/// Global ECDH functions
// @section ECDH.globals

/***
    Create a new ECDH encryption keyring using a specified curve or
    ED25519 by default if omitted. The ECDH keyring created will
    offer methods to interact with other keyrings.

    Supported curves: ed25519, nist256, bn254cx, fp256bn

    @param curve[opt=ed25519] elliptic curve to be used
    @return a new ECDH keyring
    @function new(curve)
    @usage
    keyring = ECDH.new('ed25519')
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
	e->rng = zen_memory_alloc(sizeof(csprng));
	char *tmp = zen_memory_alloc(256);
	randombytes(tmp,252);
	// using time() from milagro
	unsign32 ttmp = GET_TIME();
	tmp[252] = (ttmp >> 24) & 0xff;
	tmp[253] = (ttmp >> 16) & 0xff;
	tmp[254] = (ttmp >>  8) & 0xff;
	tmp[255] =  ttmp & 0xff;
	RAND_seed(e->rng,256,tmp);
	zen_memory_free(tmp);

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
	if(e->rng) zen_memory_free(e->rng);
	// FREE(r->pubkey);
	// FREE(r->privkey);
	return 0;
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
	(*e->ECP__KEY_PAIR_GENERATE)(e->rng,sk,pk);
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
   KDF2 to make it ready for use in @{keyring:encrypt}. This is
   compliant with the IEEE-1363 Diffie-Hellman shared secret
   specification for asymmetric key encryption.

   @param keyring containing the public key to be used
   @function keyring:session(keyring)
   @treturn[1] octet KDF2 hashed session key ready for @{keyring:encrypt}
   @treturn[1] octet a big number result of mod(private,curve_order)*public
   @see keyring:encrypt
*/
static int ecdh_session(lua_State *L) {
	HERE();
	octet *pubkey;
	ecdh *e = ecdh_arg(L,1); SAFE(e);
	HEREecdh(e);
	SAFE(e->seckey);
	pubkey = o_arg(L,2); SAFE(pubkey);

	int res;
	res = (*e->ECP__PUBLIC_KEY_VALIDATE)(pubkey);
	if(res == ECDH_INVALID_PUBLIC_KEY) {
		lerror(L, "%s: argument found, but is an invalid key",__func__);
		return 0; }
	octet *kdf = o_new(L,e->hash); SAFE(kdf);
	octet *ses = o_new(L,e->keysize); SAFE(ses);
	(*e->ECP__SVDP_DH)(e->seckey,pubkey,ses);
	// here the NULL could be a salt (TODO: global?)
	// its used as 'p' in the hash function
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
		if(res == ECDH_INVALID_PUBLIC_KEY) {
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
	if(res == ECDH_INVALID_PUBLIC_KEY) {
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
	octet *pk = o_new(L,e->publen); SAFE(pk);
	(*e->ECP__KEY_PAIR_GENERATE)(NULL,e->seckey,pk);
	int res;
	res = (*e->ECP__PUBLIC_KEY_VALIDATE)(pk);
	if(res == ECDH_INVALID_PUBLIC_KEY) {
		ERROR();
		return lerror(L, "Invalid public key generation."); }
	e->pubkey = pk;
	return 1;
}


/**
   AES-GCM encrypt with Additional Data (AEAD) encrypts and
   authenticate a plaintext to a ciphtertext. Function compatible with
   IEEE P802.1 specification. Errors out if encryption fails or
   authentication fails, else returns the secret ciphertext and a
   SHA256 of the header to checksum the integrity of the accompanying
   plaintext.

   @param key AES key octet
   @param message input text in an octet
   @param iv initialization vector
   @param header clear text, authenticated for integrity (checksum)
   @function keyring:encrypt(key, message, iv, h)
   @treturn[1] octet containing the output ciphertext
   @treturn[1] octet containing the authentication tag (checksum)
*/

static int ecdh_aead_encrypt(lua_State *L) {
	HERE();
	// ecdh *e = ecdh_arg(L, 1); SAFE(e);
	// if(e->hash != 32) {
	// 	error(L,"curve %s hash is set to %i bytes length (SHA%i)",e->curve, e->hash, e->hash*8);
	// 	lerror(L,"AES-GCM/AEAD encryption only supports SHA256 hashing (32 bytes)");
	// 	HEREecdh(e);
	// 	return 0; }
	octet *k =  o_arg(L, 1); SAFE(k);
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
   @return a new octet containing the output ciphertext and the checksum
   @function keyring:decrypt(key, ciphertext, iv, h, tag)
*/

static int ecdh_aead_decrypt(lua_State *L) {
	HERE();
	octet *k = o_arg(L, 1); SAFE(k);
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
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *p = o_arg(L, 2);     SAFE(p);
	octet *in = o_arg(L, 3); SAFE(in);
	// keylen is length of input key
	const int keylen = luaL_optinteger(L, 4, in->len);
	octet *out = o_new(L, keylen); SAFE(out);
	KDF2(e->hash, p, in, keylen, out);
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
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *k = o_arg(L, 2);     SAFE(k);
	octet *s = o_arg(L, 3); SAFE(s);
	const int iter = luaL_optinteger(L, 4, 1000);
	// keylen is length of input key
	const int keylen = luaL_optinteger(L, 5, k->len);
	// keylen is length of input key
	octet *out = o_new(L, keylen); SAFE(out);
	// default iterations 1000
	PBKDF2(e->hash, k, s, iter, keylen, out);
	return 1;
}

static int lua_new_ecdh(lua_State *L) {
	const char *curve = luaL_optstring(L, 1, "ed25519");
	ecdh *e = ecdh_new(L, curve);
	SAFE(e);
	func(L,"new ecdh curve %s type %s", e->curve, e->type);
	// any action to be taken here?
	return 1;
}

static int ecdh_new_keygen(lua_State *L) {
	HERE();
	const char *curve = luaL_optstring(L, 1, "ed25519");
	ecdh *e = ecdh_new(L, curve); SAFE(e);
	e->pubkey = o_new(L,e->publen +0x0f); SAFE(e->pubkey);
	e->seckey = o_new(L,e->seclen +0x0f); SAFE(e->seckey);
	(*e->ECP__KEY_PAIR_GENERATE)(e->rng,e->seckey,e->pubkey);
	HEREecdh(e);
	lua_pop(L, 1);
	lua_pop(L, 1);
	//	HEREoct(pk); HEREoct(sk);
	return 1;
}


/**
   Cryptographically Secure Random Number Generator (RNG).

   Returns a new octet filled with random bytes.

   This method is initialised with a different seed for each keyring
   upon creation. It doesn't make any difference to use one keyring's
   RNG or another, but mixing them and making this behavior specific
   to different scripts helps randomness.

   Cryptographic security is achieved by hashing the random numbers
   using this sequence: unguessable seed -> SHA -> PRNG internal state
   -> SHA -> random numbers. See <a
   href="ftp://ftp.rsasecurity.com/pub/pdfs/bull-1.pdf">this paper</a>
   for a justification.

   @param int[opt=rsa->max] length of random material in bytes, defaults to maximum RSA size
   @function random(int)
   @usage
   ecdh = require'ecdh'
   ed25519 = ecdh.new('ed25519')
   -- generate a random octet (will be sized 2048/8 bytes)
   csrand = ed25519:random()
   -- print out the cryptographically secure random sequence in hex
   print(csrand:hex())

*/
static int ecdh_random(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L,1); SAFE(e);
	const int len = luaL_optinteger(L, 2, e->keysize);
	octet *out = o_new(L,len); SAFE(out);
	OCT_rand(out,e->rng,len);
	return 1;
}

#define COMMON_METHODS \
	{"session",ecdh_session}, \
	{"public", ecdh_public}, \
	{"private", ecdh_private}, \
	{"checkpub", ecdh_checkpub}


int luaopen_ecdh(lua_State *L) {
	const struct luaL_Reg ecdh_class[] = {
		{"new",lua_new_ecdh},
		{"keygen",ecdh_new_keygen},
		{"aead_encrypt", ecdh_aead_encrypt},
		{"aead_decrypt", ecdh_aead_decrypt},
		{"hash", ecdh_hash},
		{"hmac", ecdh_hmac},
		{"kdf2", ecdh_kdf2},
		{"pbkdf2", ecdh_pbkdf2},
		COMMON_METHODS,
		{NULL,NULL}};
	const struct luaL_Reg ecdh_methods[] = {
		{"random",ecdh_random},
		{"keygen",ecdh_keygen},
		COMMON_METHODS,
		{"__gc", ecdh_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "ecdh", ecdh_class, ecdh_methods);
	return 1;
}
