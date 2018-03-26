// Zenroom RSA module
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

/// <h1>RSA encryption</h1>
//
//  Asymmetric public/private key encryption technologies..
//
//  RSA encryption functionalities are provided with all standard
//  functions by this extension, which has to be required explicitly
//  as <code>rsa = require'rsa'</code>.
//
//  @module rsa
//  @author Denis "Jaromil" Roio
//  @license GPLv3
//  @copyright Dyne.org foundation 2017-2018

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zenroom.h>
#include <zen_rsa.h>
#include <zen_octet.h>
#include <lua_functions.h>
#include <randombytes.h>

#include <rsa_2048.h>
#include <rsa_4096.h>
#include <rsa_support.h>
#include <pbc_support.h>

// from zen_rsa_aux
extern int bitchoice(rsa *r, int bits);
extern int rsa_priv_to_oct(rsa *r, octet *dst, char *priv);
extern int rsa_pub_to_oct (rsa *r, octet *dst, char *pub);
extern int rsa_oct_to_priv(rsa*r, void *priv, octet *src);
extern int rsa_oct_to_pub(rsa *r, void *pub, octet *src);
extern void error_protect_keys(char *what);

rsa* rsa_new(lua_State *L, int bitsize) {
	if(bitsize!=2048 && bitsize!=4096) return NULL;
	int memsize = sizeof(rsa) + sizeof(csprng);
	if(bitsize==2048) {
		memsize+=sizeof(rsa_public_key_2048);
		memsize+=sizeof(rsa_private_key_2048);
	} else {
		memsize+=sizeof(rsa_public_key_4096);
		memsize+=sizeof(rsa_private_key_4096);
	}
	rsa *r = (rsa*)lua_newuserdata(L, memsize);
	SAFE(r);

	// checked to avoid overwriting
	r->rng = NULL;
	r->pubkey = NULL;
	r->privkey = NULL;

	func("%s %u",__func__,bitsize);
	// check that the bit choice is supported
	if(!bitchoice(r, bitsize)) {
		error("Cannot create RSA class instance");
		lua_pop(L, 1); // pops out the newuserdata instance
		return NULL;
	}
	func("hash: %u", r->hash);
	r->exponent = 65537; // may be: 3,5,17,257 or 65537
	func("publen: %u", r->publen);
	func("privlen: %u", r->privlen);
	func("fflen: %u", r->fflen);
	func("bigsize: %u", r->bigsize);
	func("modbytes: %u", r->modbytes);
	func("rfs: %u", r->rfs);

	// initialise a new random number generator
	r->rng = malloc(sizeof(csprng));
	char *tmp = malloc(256);
	randombytes(tmp,252);

	// using time() from milagro
	unsign32 ttmp = GET_TIME();
	tmp[252] = (ttmp >> 24) & 0xff;
	tmp[253] = (ttmp >> 16) & 0xff;
	tmp[254] = (ttmp >>  8) & 0xff;
	tmp[255] =  ttmp & 0xff;

	RAND_seed(r->rng,256,tmp);

	func("Created RSA engine %u bits",r->bits);

	luaL_getmetatable(L, "zenroom.rsa");
	lua_setmetatable(L, -2);
	return(r);
}
rsa* rsa_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.rsa");
	luaL_argcheck(L, ud != NULL, n, "rsa class expected");
	rsa *r = (rsa*)ud;
	return(r);
}

int rsa_destroy(lua_State *L) {
	func("%s",__func__);
	rsa *r = rsa_arg(L,1);
	SAFE(r);
	// FREE(r->rng);
	// FREE(r->pubkey);
	// FREE(r->privkey);
	return 0;
}

/// Global Functions
// @section rsa.globals

/***
    Create a new RSA encryption engine with a specified number of
    bits, or 2048 by default if omitted. The RSA engine will
    present methods to interact with octets.

    @param int[opt=2048] bits size of RSA encryption (2048 or 4096)
    @return a new RSA engine
    @function new(bits)
    @usage
rsa = require'rsa'
rsa2k = rsa.new(2048)
*/
static int newrsa(lua_State *L) {
	const int bits = luaL_optinteger(L, 1, 2048);
	rsa *r = rsa_new(L, bits);
	SAFE(r);
	warning("Beware RSA support is incomplete!");
	// any action to be taken here?
	return 1;
}

/// RSA Methods
// @type rsa

/**
   RSA key pair generation, returns new public and private keys. Two
   new octets are instantiated by this function and returned
   separately.

   @function rsa:keygen()
   @treturn[1] octet public key
   @treturn[1] octet private key
   @usage
   rsa = require'rsa'
   r2k = rsa.new(2048)
   pub,priv = r2k:keygen()
*/
static int rsa_keygen(lua_State *L) {
	rsa *r = rsa_arg(L, 1);
	SAFE(r);
	if(r->pubkey!=NULL) {
		ERROR(); error_protect_keys("public key"); return 0; }
	if(r->privkey!=NULL) {
		ERROR(); error_protect_keys("private key"); return 0; }

	if(r->bits == 2048) {
		r->privkey = malloc(sizeof(rsa_private_key_2048));
		r->pubkey  = malloc(sizeof(rsa_public_key_2048));
		RSA_2048_KEY_PAIR(r->rng, r->exponent,
		                  (rsa_private_key_2048*)r->privkey,
		                  (rsa_public_key_2048*)r->pubkey,
		                  NULL, NULL);
	} else {
		r->privkey = malloc(sizeof(rsa_private_key_4096));
		r->pubkey  = malloc(sizeof(rsa_public_key_4096));
		RSA_4096_KEY_PAIR(r->rng, r->exponent,
		                  (rsa_private_key_4096*)r->privkey,
		                  (rsa_public_key_4096*)r->pubkey,
		                  NULL, NULL);
	}
	return 0; // nothing returned
}

static int rsa_encrypt(lua_State *L) {
	rsa *r = rsa_arg(L, 1);	SAFE(r);
	octet *o_msg = o_arg(L,2); SAFE(o_msg);
	if(!r->pubkey) {
		ERROR();
		error("Public key not found in RSA engine. Use :public()");
		return 0; }

	octet *o_dst = o_new(L, o_msg->len+r->rfs); // TODO: check size
	SAFE(o_dst);

	if(r->bits == 2048) {
		RSA_2048_ENCRYPT((rsa_public_key_2048*)r->pubkey,
		                 o_msg, o_dst);
	} else if(r->bits == 4096) {
		RSA_4096_ENCRYPT((rsa_public_key_4096*)r->pubkey,
		                 o_msg, o_dst);
	}

	return 1;
}

static int rsa_decrypt(lua_State *L) {
	rsa *r = rsa_arg(L, 1); SAFE(r);
	octet *o_enc = o_arg(L,2); SAFE(o_enc);

	if(!r->privkey) {
		ERROR();
		error("Private key not found in RSA engine. Use :private()");
		return 0; }

	octet *o_dst = o_new(L, o_enc->len + r->rfs); // TODO: check size
	SAFE(o_dst);

	if(r->bits == 2048) {
		RSA_2048_DECRYPT((rsa_private_key_2048*)r->privkey,
		                 o_enc, o_dst);
	} else if(r->bits == 4096) {
		RSA_4096_DECRYPT((rsa_private_key_4096*)r->privkey,
		                 o_enc, o_dst);
	}
	return 1;
}

static int rsa_public(lua_State *L) {
	rsa *r = rsa_arg(L,1);
	SAFE(r);

	if(lua_isnoneornil(L, 2)) {
		if(!r->pubkey) {
			ERROR(); error("Public key is not found."); return 0; }

		// export public key to octet
		octet *exp = o_new(L,r->publen);
		rsa_pub_to_oct(r,exp,r->pubkey);
		return 1;
	}
	if(r->pubkey!=NULL) {
		ERROR(); error_protect_keys("public key"); return 0; }
	// import public key from octet
	octet *imp = o_arg(L,2);
	SAFE(imp);
	r->pubkey = malloc(r->publen);
	rsa_oct_to_pub(r,r->pubkey,imp);
	return 0;
}


static int rsa_private(lua_State *L) {
	rsa *r = rsa_arg(L,1);
	SAFE(r);

	if(lua_isnoneornil(L, 2)) {
		if(!r->privkey) {
			ERROR(); error("Private key is not found."); return 0; }

		// export public key to octet
		octet *exp = o_new(L,r->privlen);
		rsa_priv_to_oct(r,exp,r->privkey);
		return 1;
	}
	if(r->privkey!=NULL) {
		ERROR(); error_protect_keys("private key"); return 0; }
	// import private key from octet
	octet *imp = o_arg(L,2);
	SAFE(imp);
	r->privkey = malloc(r->privlen);
	rsa_oct_to_priv(r,r->privkey,imp);
	return 0;
}



/***
    PKCS V1.5 padding of a message prior to RSA signature.

    Returns a new octet, ready for RSA signature.

    @param const octet to be padded, contents not modified.
    @return a new octet padded according to PKCS1.5 scheme
    @function rsa:pkcs15(const)
*/

static int pkcs15(lua_State *L) {
	rsa *r = rsa_arg(L,1);
	if(!r) return 0;
	octet *in = o_arg(L,2);
	if(!in) return 0;
	octet *out = o_new(L, r->bits/8);
	if(!out) return 0;
	if(!PKCS15(r->hash, in, out)) {
		ERROR();
		lua_pop(L,1); // remove the o_new from stack
		return 0;
	}
	return 1;
}

/**
   Creates a new octet fit to work with this RSA instance.

   The new octet is of a size compatible with the number of bits used
   by this RSA instance.

   @return a new octet with maximum lenfgh to RSA bit size divided by 8
   @function rsa:octet()
*/
static int rsa_octet(lua_State *L) {
	rsa *r = rsa_arg(L,1); SAFE(r);
	octet *out = o_new(L, r->rfs);
	SAFE(out);
	return 1;
}

/**
   Cryptographically Secure Random Number Generator.

   Returns a new octet filled with random bytes.

   Unguessable seed -> SHA -> PRNG internal state -> SHA -> random
   numbers.

   See <a href="ftp://ftp.rsasecurity.com/pub/pdfs/bull-1.pdf">this
   paper</a> for a justification.

   @param int[opt=rsa->max] length of random material in bytes, defaults to maximum RSA size
   @function random(int)
   @usage
rsa = require'rsa'
rsa2k = rsa.new()
-- generate a random octet (will be sized 2048/8 bytes)
csrand = rsa2k:random()
-- print out the cryptographically secure random sequence in hex
print(csrand:hex())

*/
static int rsa_random(lua_State *L) {
	rsa *r = rsa_arg(L,1); SAFE(r);
	const int len = luaL_optinteger(L, 2, r->max);
	octet *out = o_new(L,r->max); SAFE(out);
	OCT_rand(out,r->rng,len);
	return 1;
}

/*
   OAEP padding of a message prior to RSA encryption. A new octet is
   returned with the padded message, while the input octet is left
   untouched.

   @param const octet with the input message to be padded
   @return a new octet with the padded message ready for RSA encryption
   @function rsa:oaep_encode(const)
*/
static int oaep_encode(lua_State *L) {
	rsa *r = rsa_arg(L, 1); SAFE(r);
	octet *in = o_arg(L, 2); SAFE(in);
	octet *out = o_new(L, in->len + (r->hash*3));
	SAFE(out);
	// TODO: check destination size calculation here
	if(OAEP_ENCODE(r->hash, in, r->rng, NULL, out) >0) {
		ERROR(); return 0; }
	return 1;
}

/*
	OAEP unpadding of a message after RSA decryption. Unpadding is
	done in-place, directly modifying the given octet.

	@param octet the input padded message, unpadded on output
	@function rsa:oaep_decode(octet)
*/
static int oaep_decode(lua_State *L) {
	rsa *r = rsa_arg(L, 1); SAFE(r);
	octet *o = o_arg(L, 2);	SAFE(o);
	if(OAEP_DECODE(r->hash, NULL, o) >0) {
		ERROR(); return 0; }
	return 1;
}

int luaopen_rsa(lua_State *L) {
	const struct luaL_Reg rsa_class[] = {{"new",newrsa},{NULL,NULL}};
	const struct luaL_Reg rsa_methods[] = {
		{"octet", rsa_octet},
		{"pkcs15",pkcs15},
		{"random",rsa_random},
		{"keygen",rsa_keygen},
		{"encrypt",rsa_encrypt},
		{"decrypt",rsa_decrypt},
		{"public",rsa_public},
		{"private", rsa_private},
		{"oaep_encode",oaep_encode},
		{"oaep_decode",oaep_decode},
		{"__gc", rsa_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "rsa", rsa_class, rsa_methods);
	return 1;
}
