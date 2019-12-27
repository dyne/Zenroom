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
extern int ecdh_init(ecdh *e);

extern zenroom_t *Z; // accessed to check random_seed configuration

ecdh *ECDH = NULL;

/// Global ECDH functions
// @section ECDH.globals

// // internal to instance inside init.lua
// int ecdh_new(lua_State *L) {
// 	ecdh *e = (ecdh*)lua_newuserdata(L, sizeof(ecdh));
// 	ecdh_init(e);
// 	luaL_getmetatable(L, "zenroom.ecdh");
// 	lua_setmetatable(L, -2);
// 	ECDH = e; // global pointer to a single ECDH instance
// 	return(1);
// }

ecdh* ecdh_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.ecdh");
	luaL_argcheck(L, ud != NULL, n, "ecdh class expected");
	ecdh *e = (ecdh*)ud;
	return(e);
}

int ecdh_destroy(lua_State *L) { 
	(void)L;
	// no allocation done
	return 0; }

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
	SAFE(ECDH);
	// return a table
	lua_createtable(L, 0, 2);
	octet *pk = o_new(L,ECDH->fieldsize*2 +1); SAFE(pk);
	lua_setfield(L, -2, "public");
	octet *sk = o_new(L,ECDH->fieldsize); SAFE(sk);
	lua_setfield(L, -2, "private");
	(*ECDH->ECP__KEY_PAIR_GENERATE)(Z->random_generator,sk,pk);
	return 1;
}

/*
   Validate an ECDH public key.
   This is done by:
   1. Checking that it is not the point at infinity
   2. Validating that it is on the correct group.

   @param key the input public key octet to be validated
   @function keyring:checkpub(key)
   @return true if public key is OK, or false if not.
*/

static int ecdh_pubcheck(lua_State *L) {
	SAFE(ECDH);
	octet *pk = o_arg(L, 1); SAFE(pk);
	if((*ECDH->ECP__PUBLIC_KEY_VALIDATE)(pk)==0)
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
   encryption. It can be found here:
   https://perso.telecom-paristech.fr/guilley/recherche/cryptoprocesseurs/ieee/00891000.pdf, section 6.2

   @param keyring containing the public key to be used
   @function keyring:session(keyring)
   @treturn[1] octet KDF2 hashed session key ready for @{keyring:aead_encrypt}
   @treturn[1] octet a @{BIG} number result of (private * public) % curve_order (before KDF2)
   @see keyring:aead_encrypt
*/
static int ecdh_session(lua_State *L) {
	SAFE(ECDH);
	octet *f = o_arg(L,1); SAFE(f);
	octet *s = o_arg(L,2); SAFE(s);
	octet *sk, *pk;
	pk = (*ECDH->ECP__PUBLIC_KEY_VALIDATE)(s)==0 ? s :
		(*ECDH->ECP__PUBLIC_KEY_VALIDATE)(f)==0 ? f : NULL;
	if(!pk) {
		lerror(L, "%s: public key not found in any argument", __func__);
		return 0; }
	sk = (pk==s) ? f : s;
	octet *kdf = o_new(L,SHA256); SAFE(kdf);
	octet *ses = o_new(L,SHA256); SAFE(ses);
	(*ECDH->ECP__SVDP_DH)(sk,pk,ses);
	// NULL would be used internally by KDF2 as 'p' in the hash
	// function ehashit(sha,z,counter,p,&H,0);
	KDF2(SHA256,ses,NULL,SHA256,kdf);
	return 2;
}


/**
   Returns X and Y coordinates of a public key

   @function ECDH.xy(public_key)
   @treturn[1] OCTET coordinate X of public key
   @treturn[1] OCTET coordinate Y of public key

*/
static int ecdh_pub_xy(lua_State *L) {
	SAFE(ECDH);
	octet *pk = o_arg(L, 1); SAFE(pk);
	if((*ECDH->ECP__PUBLIC_KEY_VALIDATE)(pk)!=0) {
		return lerror(L, "Invalid public key passed as argument");
	}
	// Export public key to octet.  This is like o_dup but skips
	// first byte since that is used internally by Milagro as a
	// prefix for Montgomery (2) or non-Montgomery curves (4)
	int res;
	register int i;
	octet *x = o_new(L, ECDH->fieldsize+1);
	for(i=0; i < ECDH->fieldsize; i++)
		x->val[i] = pk->val[i+1]; // +1 skips first byte
	x->val[ECDH->fieldsize+1] = 0x0;
	x->len = ECDH->fieldsize;
	res = 1;
	if(pk->len > ECDH->fieldsize<<1) { // make sure y is there:
		                               // could be omitted in
		                               // montgomery notation
		octet *y = o_new(L, ECDH->fieldsize+1);
		for(i=0; i < ECDH->fieldsize; i++)
			y->val[i] = pk->val[ECDH->fieldsize+i+1]; // +1 skips first byte
		y->val[ECDH->fieldsize+1] = 0x0;
		y->len = ECDH->fieldsize;
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
   @function ECDH.pubgen(key)
*/
static int ecdh_pubgen(lua_State *L) {
	SAFE(ECDH);
	octet *sk = o_arg(L, 1); SAFE(sk);
	octet *pk = o_new(L,ECDH->fieldsize*2 +1); SAFE(pk);
	// If RNG is NULL then the private key is provided externally in S
	// otherwise it is generated randomly internally
	(*ECDH->ECP__KEY_PAIR_GENERATE)(NULL,sk,pk);
	return 1;
}

/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) signing
   function. This method uses the private key inside a keyring to sign
   a message, returning a signature to be used in @{keyring:verify}.

   @param kp.public @{OCTET} of a public key
   @param message string or @{OCTET} message to sign
   @function ECDH.sign(kp.private, message)
   @return table containing signature parameters octets (r,s)
   @usage
   kp = ECDH.keygen() -- generate keys or import them
   m = "Message to be signed"
   signature = ECDH.sign(kp.private, m)
   assert( ECDH.verify(kp.public, m, signature) )
*/

static int ecdh_dsa_sign(lua_State *L) {
	SAFE(ECDH);
	octet *sk = o_arg(L,1); SAFE(sk);
	octet *m = o_arg(L,2); SAFE(m);
	// IEEE ECDSA Signature, R and S are signature on F using private
	// key S. One can either pass an RNG or have K already
	// provide. For a correct K's generation see also RFC6979, however
	// this argument is provided here mostly for testing purposes with
	// pre-calculated vectors.
	int max_size = 64;
	if(lua_isnoneornil(L, 3)) {
		// return a table
		lua_createtable(L, 0, 2);
		octet *r = o_new(L,max_size); SAFE(r);
		lua_setfield(L, -2, "r");
		octet *s = o_new(L,max_size); SAFE(s);
		lua_setfield(L, -2, "s");
		(*ECDH->ECP__SP_DSA)( max_size, Z->random_generator, NULL, sk, m, r, s);
	} else {
		octet *k = o_arg(L,3); SAFE(k);
		// return a table
		lua_createtable(L, 0, 2);
		octet *r = o_new(L,max_size); SAFE(r);
		lua_setfield(L, -2, "r");
		octet *s = o_new(L,max_size); SAFE(s);
		lua_setfield(L, -2, "s");
		(*ECDH->ECP__SP_DSA)( max_size, NULL, k, sk, m, r, s );
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
   @function ECDH.verify(kp.public, message,signature)
   @return true if the signature is OK, or false if not.
   @see ECDH.sign
*/
static int ecdh_dsa_verify(lua_State *L) {
	SAFE(ECDH);
    // IEEE1363 ECDSA Signature Verification. Signature C and D on F
    // is verified using public key W
	octet *pk = o_arg(L,1); SAFE(pk);
	octet *m = o_arg(L,2); SAFE(m);
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
	int max_size = 64;
	int res = (*ECDH->ECP__VP_DSA)(max_size, pk, m, r, s);
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

   @param key AES key octet (must be 16, 24 or 32 bytes long)
   @param message input text in an octet
   @param iv initialization vector. If the key is reused several times,
          this param should be random, so the iv/key is different every time.
          Follow RFC5116, section 3.1 for recommendations
   @param header clear text, authenticated for integrity (checksum)
   @param tag the authenticated tag. As per RFC5116, this should be 16 bytes
          long
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
        if (iv->len < 12) {
		error(L,"ECDH.aead_encrypt accepts an iv of 12 bytes minimum, this is %u", iv->len);
		lerror(L,"ECDH encryption aborted");
		return 0; }

	octet *h =  o_arg(L, 4); SAFE(h);
	// output is padded to next word
	octet *out = o_new(L, in->len+16); SAFE(out);

	octet *t = o_new(L, 16); SAFE (t);
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
	if(k->len > 32 || k->len < 16) {
		error(L,"ECDH.aead_decrypt accepts only keys of 16,24,32, this is %u", k->len);
		lerror(L,"ECDH decryption aborted");
		return 0; }

	octet *in = o_arg(L, 2); SAFE(in);

	octet *iv = o_arg(L, 3); SAFE(iv);
        if (iv->len < 12) {
		error(L,"ECDH.aead_decrypt accepts an iv of 12 bytes minimum, this is %u", iv->len);
		lerror(L,"ECDH decryption aborted");
		return 0; }

	octet *h = o_arg(L, 4); SAFE(h);
	// output is padded to next word
	octet *out = o_new(L, in->len+16); SAFE(out);
	octet *t2 = o_new(L,16); SAFE(t2);

	AES_GCM_DECRYPT(k, iv, h, in, out, t2);
	return 2;
}




int luaopen_ecdh(lua_State *L) {
	const struct luaL_Reg ecdh_class[] = {
		{"keygen",ecdh_keygen},
		{"pubgen",ecdh_pubgen},
		{"aead_encrypt",   ecdh_aead_encrypt},
		{"aead_decrypt",   ecdh_aead_decrypt},
		{"aesgcm_encrypt", ecdh_aead_encrypt},
		{"aesgcm_decrypt", ecdh_aead_decrypt},
		{"aes_encrypt",    ecdh_aead_encrypt},
		{"aes_decrypt",    ecdh_aead_decrypt},
		{"session", ecdh_session},
		{"checkpub", ecdh_pubcheck},
		{"pubcheck", ecdh_pubcheck},		
		{"validate", ecdh_pubcheck},
		{"sign", ecdh_dsa_sign},
		{"verify", ecdh_dsa_verify},
		{"public_xy", ecdh_pub_xy},
		{"pubxy", ecdh_pub_xy},
		{NULL,NULL}};
	const struct luaL_Reg ecdh_methods[] = {
		{"__gc", ecdh_destroy},
		{NULL,NULL}
	 };


	ECDH = system_alloc(sizeof(ecdh));
	ecdh_init(ECDH);

	zen_add_class(L, "ecdh", ecdh_class, ecdh_methods);
	return 1;
}
