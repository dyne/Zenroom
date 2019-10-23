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
//  @author Denis "Jaromil" Roio
//  @license AGPLv3
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

/**
   Create a new ECDH encryption keyring using a specified curve
   ('BLS383' by default).

   A keyring object will be returned implementing ECDH methods.

   Supported curves: 'BLS383', 'ED25519', 'GOLDILOCKS', 'SECP256K1'

   @param curve[opt=BLS383] name of elliptic curve to use
   @return a new keyring
   @function ECDH.new(curve)
   @usage
   keyring = ECDH.new()
   -- generate a keypair
   keypair = keyring:keygen()
   I.print(keypair)
   [[{ public = oct[] .... ,
       private = oct[] .... }]]
*/

ecdh* ecdh_new(lua_State *L, const char *curve) {
	HERE();
	ecdh *e = ecdh_new_curve(L, curve);
	if(!e) { SAFE(e); return NULL; }

	// key storage and key lengths are important
	e->seckey = NULL;
	e->seclen = e->secretkeysize;
	e->pubkey = NULL;
	e->publen = e->secretkeysize *2; // The public key size is half of this size; but this length is for the generation of the signature as well

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
   @{public} and @{private} methods.

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
	// return a table
	lua_createtable(L, 0, 2);
	octet *pk = o_new(L,e->publen +0x0f); SAFE(pk);
	lua_setfield(L, -2, "public");
	octet *sk = o_new(L,e->seclen +0x0f); SAFE(sk);
	lua_setfield(L, -2, "private");
	(*e->ECP__KEY_PAIR_GENERATE)(Z->random_generator,sk,pk);
	e->pubkey = pk;
	e->seckey = sk;
	return 1;
}

/*
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
	if(lua_isnoneornil(L, 2)) { // no 2nd arg, use keyring
		if(!e->pubkey) { lua_pushnil(L); return(1); }
		pk = e->pubkey;
	} else
		pk = o_arg(L, 2); SAFE(pk);
	if((*e->ECP__PUBLIC_KEY_VALIDATE)(pk)==0)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}

/*
   Generate a Diffie-Hellman shared session key. This function uses
   two keyrings to calculate a shared key, then process it internally
   through @{keyring:kdf2} to make it ready for use in
   @{keyring:aead_encrypt}. This is compliant with the IEEE-1363
   Diffie-Hellman shared secret specification for asymmetric key
   encryption.

   @param keyring containing the public key to be used
   @function keyring:session(keyring)
   @treturn[1] octet KDF2 hashed session key ready for @{keyring:aead_encrypt}
   @treturn[1] octet a @{BIG} number result of (private * public) % curve_order (before KDF2)
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
	octet *ses = o_new(L,e->secretkeysize); SAFE(ses);
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
   Imports a public key inside an ECDH keyring.

   This is a get/set method working both ways: without argument it
   returns the public key of a keyring, or if an @{OCTET} argument is
   provided and is a valid public key it is imported.

   If the keyring has a public key already, it will refuse to
   overwrite it and return an error.

   @param key[opt] octet of a public key to be imported
   @function keyring:public(key)
*/
static int ecdh_public(lua_State *L) {
	HERE();
	int res;
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(lua_isnoneornil(L, 2)) {
		if(!e->pubkey) {
			lua_pushnil(L);
			return 1; }
		o_dup(L,e->pubkey);
		return 1;
	}
	// has an argument: public key to set
	if(e->pubkey!=NULL) {
		ERROR();
		KEYPROT(e->curve, "public key"); }
	octet *o = o_arg(L, 2); SAFE(o);
	func(L, "%s: valid key",__func__);
	e->pubkey = o_new(L, o->len+2); // max is len+1
	OCT_copy(e->pubkey, o);
	res = (*e->ECP__PUBLIC_KEY_VALIDATE)(e->pubkey); // try as-is
	if(res<0) { // try adding prefix
		func(L,"ECDH public key import second try adding 0x04 prefix");
		for(int i=e->pubkey->len-1; i>0; i--) // shr 1 bytes in octet
			e->pubkey->val[i] = e->pubkey->val[i-1];
		e->pubkey->val[0] = 0x04;
		res = (*e->ECP__PUBLIC_KEY_VALIDATE)(e->pubkey); // try again
	}
	if(res<0) {
		ERROR();
		return lerror(L, "Public key argument is invalid."); }

	return 0;
}


/**
   Returns X and Y coordinates of the public key inside an ECDH keyring.

   @function keyring:public(key)
   @treturn[1] OCTET coordinate X of public key
   @treturn[1] OCTET coordinate Y of public key

*/
static int ecdh_pub_xy(lua_State *L) {
	HERE();
	short res;
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(!e->pubkey) {
		ERROR();
		return lerror(L, "Public key is not found in keyring.");
	}
	res = (e->ECP__PUBLIC_KEY_VALIDATE)(e->pubkey);
	if(res<0) {
		ERROR();
		return lerror(L, "Public key found, but invalid."); }
	// Export public key to octet.  This is like o_dup but skips
	// first byte since that is used internally by Milagro as a
	// prefix for Montgomery (2) or non-Montgomery curves (4)
	register int i;
	octet *x = o_new(L, e->fieldsize+1);
	for(i=0; i < e->fieldsize; i++)
		x->val[i] = e->pubkey->val[i+1]; // +1 skips first byte
	x->val[e->fieldsize+1] = 0x0;
	x->len = e->fieldsize;
	res = 1;
	if(e->pubkey->len > e->fieldsize<<1) { // make sure y is there:
										   // could be omitted in
										   // montgomery notation
		octet *y = o_new(L, e->fieldsize+1);
		for(i=0; i < e->fieldsize; i++)
			y->val[i] = e->pubkey->val[e->fieldsize+i+1]; // +1 skips first byte
		y->val[e->fieldsize+1] = 0x0;
		y->len = e->fieldsize;
		res = 2;
	}
	return(res);
}

/**
   Imports a private key inside an ECDH keyring.

   This is a get/set method working both ways: without argument it
   returns the private key of a keyring, or if an @{OCTET} argument is
   provided it is imported as private key inside the keyring and used
   to derivate its corresponding public key.

   If the keyring contains already any key, it will refuse to
   overwrite them and return an error.

   @param key[opt] octet of a private key to be imported
   @function keyring:private(key)
*/
static int ecdh_private(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(lua_isnoneornil(L, 2)) {
		// no argument: return stored key
		if(!e->seckey) {
			lua_pushnil(L);
			return 1; }
		// export public key to octet
		o_dup(L, e->seckey);
		return 1;
	}
	if(e->seckey!=NULL) {
		ERROR(); KEYPROT(e->curve, "private key"); }
	e->seckey = o_arg(L, 2); SAFE(e->seckey);
	octet *pk = o_new(L,e->publen); SAFE(pk);
	(*e->ECP__KEY_PAIR_GENERATE)(NULL,e->seckey,pk);
	e->pubkey = pk;
	HEREecdh(e);
	return 1;
}

/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) signing
   function. This method uses the private key inside a keyring to sign
   a message, returning a signature to be used in @{keyring:verify}.

   @param message string or @{OCTET} message to sign
   @function keyring:sign(message)
   @return table containing signature parameters octets (r,s)
   @usage
   ecdh = ECDH.keygen() -- generate keys or import them
   m = "Message to be signed"
   signature = ecdh:sign(m)
   assert( ecdh:verify(m,signature) )
*/

static int ecdh_dsa_sign(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L,1); SAFE(e);
	octet *f = o_arg(L,2); SAFE(f);
	// IEEE ECDSA Signature, R and S are signature on F using private
	// key S. One can either pass an RNG or have K already
	// provide. For a correct K's generation see also RFC6979, however
	// this argument is provided here mostly for testing purposes with
	// pre-calculated vectors.
	if(lua_isnoneornil(L, 3)) {
		// return a table
		lua_createtable(L, 0, 2);
		octet *r = o_new(L,64); SAFE(r);
		lua_setfield(L, -2, "r");
		octet *s = o_new(L,64); SAFE(s);
		lua_setfield(L, -2, "s");
		// ECP_BLS383_SP_DSA(int sha,csprng *RNG,octet *K,octet *S,octet *F,octet *C,octet *D)
		(*e->ECP__SP_DSA)( 64, Z->random_generator,  NULL, e->seckey,    f,      r,      s );
	} else {
		octet *k = o_arg(L,3); SAFE(k);
		// return a table
		lua_createtable(L, 0, 2);
		octet *r = o_new(L,64); SAFE(r);
		lua_setfield(L, -2, "r");
		octet *s = o_new(L,64); SAFE(s);
		lua_setfield(L, -2, "s");
		(*e->ECP__SP_DSA)( 64, NULL,                 k,    e->seckey,    f,      r,      s );
	}
	return 1;
}


/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) verification
   function. This method uses the public key inside a keyring to verify
   a message, returning true or false. The signature parameters are
   returned as 'r' and 's' in this same order by @{keyring:sign}.

   @param message the message whose signature has to be verified
   @param signature the signature table returned by @{keyring:sign}
   @function keyring:verify(message,signature)
   @return true if the signature is OK, or false if not.
   @see keyring:sign
*/
static int ecdh_dsa_verify(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1); SAFE(e);
    // IEEE1363 ECDSA Signature Verification. Signature C and D on F
    // is verified using public key W
	octet *f = o_arg(L,2); SAFE(f);
	octet *r = NULL;
	octet *s = NULL;
	// take a table as argument, gather r and s from its keys
	// TODO: take an octet and split it
	// void *ud = luaL_checkudata(L, 3, "zenroom.octet");
	// if(ud) { // break octet in two r,s
	// 	octet *tmp = o_arg(L,3); SAFE(tmp);
	// 	r = o_dup(L,tmp); SAFE(r);
	// 	s = o_new(L,32); SAFE(s);
	// 	lua_pop(L,2); // pop r,s used internally
	// 	OCT_chop(r,s,32); // truncates r to 32 bytes and places the rest in s
	// } else
	if(lua_type(L, 3) == LUA_TTABLE) {
		lua_getfield(L, 3, "r");
		lua_getfield(L, 3, "s"); // -2 stack
		r = o_arg(L,-2); SAFE(r);
		s = o_arg(L,-1); SAFE(s);
	} else {
		ERROR(); lerror(L,"signature argument invalid: not a table");
	}
	int res = (*e->ECP__VP_DSA)(64, e->pubkey, f, r, s);
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

/*
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
        // AES key size nk can be 16, 24 or 32 bytes
	if(k->len > 32 || k->len < 16) {
		error(L,"ECDH.aead_encrypt accepts only keys of 16,24,32, this is %u", k->len);
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

/*
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
   Simple method for AES-GCM encryption with Additional Data (AEAD),
   compatible with IEEE P802.1 specification. Takes a keyring object
   for the public key and a table of parameters. Returns also a table
   with the cyphertext and a checksum that is accepted by @{decrypt}.

   @param keyring recipient keyring containing the public key
   @param message octet input text to be encrypted for secrecy
   @param header octet input header authenticated for integrity
   @function keyring:encrypt(keyring, message, header)
   @treturn ciphertext
*/

/** Results of @{keyring:encrypt}
    @table keyring:ciphertext
    @usage
    { text = "encrypted text",             -- @{OCTET}
      checksum = "control checksum",       -- @{OCTET} of 16 bytes
      iv = "random IV",                    -- @{OCTET} of 16 bytes
      header = "clear text header",        -- @{OCTET} often encoded JSON table
*/

static int ecdh_simple_encrypt(lua_State *L) {
	HERE();
	ecdh *s =  ecdh_arg(L, 1); SAFE(s);
	if(!s->seckey) {
		lerror(L,"%s: private key not found in sender keyring",__func__);
		return 0; }
	ecdh *r =  ecdh_arg(L, 2); SAFE(r);
	if(!r->pubkey) {
		lerror(L,"%s: public key not found in recipient keyring",__func__);
		return 0; }
	if( (*s->ECP__PUBLIC_KEY_VALIDATE)(r->pubkey) < 0) { // validate by sender
		lerror(L, "%s: invalid public key in recipient keyring", __func__);
		return 0; }
	octet *ses = o_new(L,s->secretkeysize); SAFE(ses);
	lua_pop(L,1); // pop the session (used internally)
	(*s->ECP__SVDP_DH)(s->seckey,r->pubkey,ses);
	octet *kdf = o_new(L,s->hash); SAFE(kdf);
	lua_pop(L,1); // pop the KDF result (used internally)
	KDF2(s->hash,ses,NULL,s->hash,kdf);
	// gather more arguments
	octet *in = o_arg(L, 3); SAFE(in); // secret to be encrypted
	octet *h =  o_arg(L, 4); SAFE(h); // header provided
	// prepare to return a table
	lua_createtable(L, 0, 5);
	octet *iv = o_new(L,16); SAFE(iv); // generate random IV
	OCT_rand(iv,Z->random_generator,16);
	lua_setfield(L,-2, "iv");
	octet *out = o_new(L, in->len+16); SAFE(out); // 16bytes padding
	lua_setfield(L, -2, "text");
	octet *checksum = o_new(L, 32); SAFE (checksum);
	lua_setfield(L, -2, "checksum");
	AES_GCM_ENCRYPT(kdf, iv, h, in, out, checksum);
	o_dup(L,h); lua_setfield(L, -2, "header");
	return 1;
}

/**
   Simple method for AES-GCM decrypt with Additional Data
   (AEAD). Takes a table as returned by @{keyring:encrypt} containing
   text, checksum, header, IV and the sender's pubkey.  Returns an
   octet containing the decrypted message or error if any problem
   arises (invalid checksum etc.). Compatible with IEEE P802.1
   specification.

   @param ciphertext table with text, checksum, iv, header and pubkey
   @return octet containing the decrypted message
   @function keyring:decrypt(ciphertext)
*/

static int ecdh_simple_decrypt(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1); SAFE(e);
	if(!e->seckey) {
		lerror(L,"%s: private key not found in keyring",__func__);
		return 0; }
	// take a table as argument, gather r and s from its keys
	if(lua_type(L, 2) != LUA_TTABLE) {
		ERROR(); lerror(L,"%s argument invalid: not a table",__func__);
		return 0;}
	lua_getfield(L,2, "text");   // -5
	lua_getfield(L,2, "checksum"); // -4
	lua_getfield(L,2, "iv");      // -3
	lua_getfield(L,2, "header"); // -2
	lua_getfield(L,2, "pubkey");// -1
	octet *msg = o_arg(L,-5); SAFE(msg);
	octet *chk = o_arg(L,-4); SAFE(chk);
	if(chk->len != 16) {
		lerror(L,"%s invalid checksum argument length",__func__);
		return 0; }
	octet *iv = o_arg(L,-3);  SAFE(iv);
	if(iv->len != 16) {
		lerror(L,"%s invalid IV argument length",__func__);
		return 0; }
	octet *head = o_arg(L,-2); SAFE(head);
	octet *pubkey = o_arg(L,-1); SAFE(pubkey);
	if( (*e->ECP__PUBLIC_KEY_VALIDATE)(pubkey) < 0) { // validate public key
		lerror(L, "%s: invalid public key in ciphertext", __func__);
		return 0; }
	// calculate session
	octet *ses = o_new(L,e->secretkeysize); SAFE(ses);
	lua_pop(L,1); // pop the session (used internally)
	(*e->ECP__SVDP_DH)(e->seckey,pubkey,ses);
	octet *kdf = o_new(L,e->hash); SAFE(kdf);
	lua_pop(L,1); // pop the KDF result (used internally)
	KDF2(e->hash,ses,NULL,e->hash,kdf);
	// output is padded to next word
	octet *out = o_new(L, msg->len+16); SAFE(out);
	octet *outchk = o_new(L,32); SAFE(outchk); // measured empirically is 16
	lua_pop(L,1); // pop the checksum (checked internally)
	AES_GCM_DECRYPT(kdf, iv, head, msg, out, outchk);
	// check equality of checksums
	int i, eq = 1;
	for (i=0; i<chk->len; i++)
		if (chk->val[i]!=outchk->val[i]) eq = 0;
	if(!eq) {
		lerror(L,"%s error in decryption, checksum mismatch",__func__);
		lua_pop(L,1); // the out octet is still in stack
		return 0; }
	return 1;
}

/*
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
   @function keyring:hmac(key, data)
   @return a new octet containing the computed HMAC or false on failure
*/
static int ecdh_hmac(lua_State *L) {
	HERE();
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *k = o_arg(L, 2);     SAFE(k);
	octet *in = o_arg(L, 3);    SAFE(in);
	// length defaults to hash bytes (e->hash = 32 = sha256)
	octet *out = o_new(L, e->hash+1); SAFE(out);
	if(!HMAC(e->hash, in, k, e->hash, out)) {
		error(L, "%s: hmac (%u bytes) failed.", e->hash);
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

   @param hash initialized @{HASH} or @{ECDH} object
   @param key octet of the key to be transformed
   @function keyring:kdf2(key)
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
	{"verify", ecdh_dsa_verify}, \
	{"hmac", ecdh_hmac}, \
	{"hash", ecdh_hash}, \
	{"public_xy", ecdh_pub_xy}



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
		{"session", ecdh_session},
		COMMON_METHODS,
		{NULL,NULL}};
	const struct luaL_Reg ecdh_methods[] = {
		{"keygen",ecdh_keygen},
		{"session",ecdh_session},
		{"encrypt",ecdh_simple_encrypt},
		{"decrypt",ecdh_simple_decrypt},
		COMMON_METHODS,
		{"__gc", ecdh_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "ecdh", ecdh_class, ecdh_methods);
	return 1;
}
