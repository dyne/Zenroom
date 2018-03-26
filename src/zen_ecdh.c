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
	int hash;
	char curve[16]; // just short names
	octet *pubkey;
	octet *seckey;
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
	e->seckey = NULL;
	e->pubkey = NULL;

	// initialise a new random number generator
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

int ecdh_keygen(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	if(e->seckey) {
		ERROR(); KEYPROT(e->curve,"private key"); return 0; }
	if(e->pubkey) {
		ERROR(); KEYPROT(e->curve,"public key"); return 0; }
	octet *pk = o_new(L,e->keysize*2); SAFE(pk);
	octet *sk = o_new(L,e->keysize); SAFE(sk);
	// TODO: generate a public key from any secret
	(*e->ECP__KEY_PAIR_GENERATE)(e->rng,sk,pk);
	e->pubkey = pk;
	e->seckey = sk;
	return 2;
}
	
int ecdh_session(lua_State *L) {
	ecdh *e = ecdh_arg(L, 1);	SAFE(e);
	octet *pk = o_arg(L,2);	SAFE(pk);
	octet *sk = o_arg(L,3); SAFE(sk);
	octet *ses = o_new(L,e->keysize); SAFE(ses);
	(*e->ECP__SVDP_DH)(sk,pk,ses);
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

int luaopen_ecdh(lua_State *L) {
	const struct luaL_Reg ecdh_class[] = {
		{"new",lua_new_ecdh},
		{"keygen",ecdh_keygen},
		{"session",ecdh_session},
		{NULL,NULL}};
	const struct luaL_Reg ecdh_methods[] = {
		{"random",ecdh_random},
		{"keygen",ecdh_keygen},
		{"session",ecdh_session},
		{"__gc", ecdh_destroy},
		{NULL,NULL}
	};

	zen_add_class(L, "ecdh", ecdh_class, ecdh_methods);
	return 1;
}
