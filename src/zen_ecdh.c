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


#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zenroom.h>
#include <zen_octet.h>
#include <randombytes.h>
#include <lua_functions.h>

#include <ecdh_ED25519.h>
#include <pbc_support.h>

#define fail return 0

typedef struct {
	// function pointers
	int (*ECP__KEY_PAIR_GENERATE)(csprng *R,octet *s,octet *W);
	int (*ECP__PUBLIC_KEY_VALIDATE)(octet *W);
	int (*ECP__SVDP_DH)(octet *s,octet *W,octet *K);
	void (*ECP__ECIES_ENCRYPT)(int h,octet *P1,octet *P2,
	                           csprng *R,octet *W,octet *M,int len,
	                           octet *V,octet *C,octet *T);
	int (*ECP__ECIES_DECRYPT)(int h,octet *P1,octet *P2,
	                          octet *V,octet *C,octet *T,
	                          octet *U,octet *M);
	int (*ECP__SP_DSA)(int h,csprng *R,octet *k,octet *s,
	                   octet *M,octet *c,octet *d);
	int (*ECP__VP_DSA)(int h,octet *W,octet *M,octet *c,octet *d);
	csprng *rng;
	int keysize;
	int hash; // hash type is also bytes length of hash
	char curve[16]; // just short names
	octet *pubkey;
	int publen;
	octet *seckey;
	int seclen;
} ecdh;

ecdh* ecdh_new(lua_State *L, const char *curve) {
	ecdh *e = (ecdh*)lua_newuserdata(L, sizeof(ecdh));

	// hardcoded on ed25519 for now
	(void)curve;
	e->keysize = EGS_ED25519;
	e->rng = NULL;
	e->hash = HASH_TYPE_ECC_ED25519;

	e->ECP__KEY_PAIR_GENERATE = ECP_ED25519_KEY_PAIR_GENERATE;
	e->ECP__PUBLIC_KEY_VALIDATE	= ECP_ED25519_PUBLIC_KEY_VALIDATE;
	e->ECP__SVDP_DH = ECP_ED25519_SVDP_DH;
	e->ECP__ECIES_ENCRYPT = ECP_ED25519_ECIES_ENCRYPT;
	e->ECP__ECIES_DECRYPT = ECP_ED25519_ECIES_DECRYPT;
	e->ECP__SP_DSA = ECP_ED25519_SP_DSA;
	e->ECP__VP_DSA = ECP_ED25519_VP_DSA;

	// key storage and key lengths are important 
	e->seckey = NULL;
	e->seclen = e->keysize;   // TODO: check for each curve
	e->pubkey = NULL;
	e->publen = e->keysize*2; // TODO: check for each curve

	// initialise a new random number generator
	// TODO: make it a newuserdata object in LUA space so that
	// it can be cleanly collected by the GC as well it can be
	// saved transparently in the global state
	e->rng = malloc(sizeof(csprng));
	char *tmp = malloc(256);
	randombytes(tmp,252);
	// using time() from milagro
	unsign32 ttmp = GET_TIME();
	tmp[252] = (ttmp >> 24) & 0xff;
	tmp[253] = (ttmp >> 16) & 0xff;
	tmp[254] = (ttmp >>  8) & 0xff;
	tmp[255] =  ttmp & 0xff;	
	RAND_seed(e->rng,256,tmp);
	free(tmp);

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
	FREE(e->rng);	
	// FREE(r->pubkey);
	// FREE(r->privkey);
	return 0;
}

static int ecdh_keygen(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(e->seckey) {
		ERROR(); KEYPROT(e->curve,"private key"); fail; }
	if(e->pubkey) {
		ERROR(); KEYPROT(e->curve,"public key"); fail; }
	octet *pk = o_new(L,e->publen); SAFE(pk);
	octet *sk = o_new(L,e->seclen); SAFE(sk);
	// TODO: generate a public key from any secret
	(*e->ECP__KEY_PAIR_GENERATE)(e->rng,sk,pk);
	e->pubkey = pk;
	e->seckey = sk;
	return 2;
}

static int ecdh_checkpub(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *pk = NULL;
	if(lua_isnoneornil(L, 2)) {
		if(!e->pubkey) {
			ERROR(); error("Public key not found."); fail; }
		pk = e->pubkey;
	} else
		pk = o_arg(L, 2); SAFE(pk);
	if((*e->ECP__PUBLIC_KEY_VALIDATE)(pk)==0)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	return 1;
}

static int ecdh_session(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *pk = o_arg(L,2);	SAFE(pk);
	octet *sk = o_arg(L,3); SAFE(sk);
	octet *ses = o_new(L,e->keysize); SAFE(ses);
	(*e->ECP__SVDP_DH)(sk,pk,ses);
	return 1;
}

static int ecdh_public(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(lua_isnoneornil(L, 2)) {
		if(!e->pubkey) {
			ERROR(); error("Public key is not found."); fail; }
		// export public key to octet
		octet *exp = o_new(L,e->publen);
		OCT_copy(exp,e->pubkey);
		return 1;
	}
	if(e->pubkey!=NULL) {
		ERROR(); KEYPROT(e->curve, "private key"); fail; }
	e->pubkey = o_arg(L, 2); SAFE(e->pubkey);
	return 0;
}

static int ecdh_private(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(lua_isnoneornil(L, 2)) {
		if(!e->seckey) {
			ERROR(); error("Private key is not found."); fail; }
		// export public key to octet
		octet *exp = o_new(L,e->seclen);
		OCT_copy(exp,e->seckey);
		return 1;
	}
	if(e->seckey!=NULL) {
		ERROR(); KEYPROT(e->curve, "private key"); fail; }
	e->seckey = o_arg(L, 2); SAFE(e->seckey);
	return 0;
}

static int ecdh_encrypt(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *k = o_arg(L, 2); SAFE(k);
	octet *in = o_arg(L, 3); SAFE(in);
	// output is padded to next word
	octet *out = o_new(L, in->len+16); SAFE(out);
	AES_CBC_IV0_ENCRYPT(k,in,out);
	return 1;
}

static int ecdh_decrypt(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *k = o_arg(L, 2); SAFE(k);
	octet *in = o_arg(L, 3); SAFE(in);
	// output is padded to next word
	octet *out = o_new(L, in->len+16); SAFE(out);
	if(!AES_CBC_IV0_DECRYPT(k,in,out)) {
		error("%s: decryption failed.",__func__);
		lua_pop(L, 1);
		lua_pushboolean(L, 0);
	}
	return 1;
}

static int ecdh_hash(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *in = o_arg(L, 2); SAFE(in);
	// hash type indicates also the length in bytes
	octet *out = o_new(L, e->hash); SAFE(out);
	HASH(e->hash, in, out);
	return 1;
}


static int ecdh_hmac(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *k = o_arg(L, 2);     SAFE(k);
	octet *in = o_arg(L, 3);    SAFE(in);	
	// length defaults to hash bytes
	const int len = luaL_optinteger(L, 4, e->hash);
	octet *out = o_new(L, len); SAFE(out);
	if(!HMAC(e->hash, in, k, len, out)) {
		error("%s: hmac (%u bytes) failed.", len);
		lua_pop(L, 1);
		lua_pushboolean(L,0);
	}
	return 1;
}


static int ecdh_kdf2(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *p = o_arg(L, 2);     SAFE(p);
	octet *in = o_arg(L, 3); SAFE(in);
	// keylen is length of input key
	const int keylen = luaL_optinteger(L, 4, in->len);
	octet *out = o_new(L, keylen); SAFE(out);
	KDF2(e->hash, p, in, keylen, out);
	return 1;
}

static int ecdh_pbkdf2(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *k = o_arg(L, 2);     SAFE(k);
	octet *s = o_arg(L, 3); SAFE(s);
	// keylen is length of input key
	const int keylen = luaL_optinteger(L, 4, k->len);
	// keylen is length of input key
	octet *out = o_new(L, keylen); SAFE(out);
	// default iterations 1000
	const int iter = luaL_optinteger(L, 5, 1000);
	PBKDF2(e->hash, k, s, iter, keylen, out);
	return 1;
}

static int lua_new_ecdh(lua_State *L) {
	const char *curve = luaL_optstring(L, 1, "ec25519");
	ecdh *e = ecdh_new(L, curve);
	SAFE(e);
	// any action to be taken here?
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
   ecdh = require'ecdh'
   ed25519 = ecdh.new('ed25519')
   -- generate a random octet (will be sized 2048/8 bytes)
   csrand = ed25519:random()
   -- print out the cryptographically secure random sequence in hex
   print(csrand:hex())

*/
static int ecdh_random(lua_State *L) {
	ecdh *e = ecdh_arg(L,1); SAFE(e);
	const int len = luaL_optinteger(L, 2, e->keysize);
	octet *out = o_new(L,len); SAFE(out);
	OCT_rand(out,e->rng,len);
	return 1;
}

#define COMMON_METHODS \
	{"keygen",ecdh_keygen}, \
	{"session",ecdh_session}, \
	{"public", ecdh_public}, \
	{"private", ecdh_private}, \
	{"encrypt", ecdh_encrypt}, \
	{"decrypt", ecdh_decrypt}, \
	{"hash", ecdh_hash}, \
	{"hmac", ecdh_hmac}, \
	{"kdf2", ecdh_kdf2}, \
	{"pbkdf2", ecdh_pbkdf2}, \
	{"checkpub", ecdh_checkpub}

int luaopen_ecdh(lua_State *L) {
	const struct luaL_Reg ecdh_class[] = {
		{"new",lua_new_ecdh},
		COMMON_METHODS,
		{NULL,NULL}};
	const struct luaL_Reg ecdh_methods[] = {
		{"random",ecdh_random},
		COMMON_METHODS,
		{"__gc", ecdh_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "ecdh", ecdh_class, ecdh_methods);
	return 1;
}
