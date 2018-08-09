// Zenroom Shamir Secret Sharing module
//
// (c) Copyright 2017-2018 Dyne.org foundation
// written and maintained by Denis Roio <jaromil@dyne.org>
// design based on SSS by Daan Sprenkels
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

// For now, the only supported message size is 1024 bytes (hardcoded)
// TODO: marshal longer messages into a 64B padded octets (in LUA)


#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <zen_memory.h>
#include <lua_functions.h>

#include <sss.h>
#include <hazmat.h>
#include <tweetnacl.h>
#include <randombytes.h>

#define MAX_SHARES 64


/* Return a mutable pointer to the ciphertext part of this Share */
static uint8_t* get_ciphertext(sss_Share *share) {
//	return &((uint8_t*)share->val)[sss_KEYSHARE_LEN];
	return &((uint8_t*) share)[sss_KEYSHARE_LEN];
}
/* Return a mutable pointer to the Keyshare part of this Share */
static sss_Keyshare* get_keyshare(sss_Share *share) {
	return (sss_Keyshare*) &share[0]; }

static int lua_sss_share(lua_State *L) {
	int res;
	octet *msg = o_arg(L,1); SAFE(msg);
	lua_Number n = lua_tonumberx(L, 2, &res);
	if(!res) {
		lerror(L, "missing integer as second argument of SSS.share()");
		return 0; }
	lua_Number k = lua_tonumberx(L, 3, &res);
	if(!res) {
		lerror(L, "missing integer as third argument of SSS.share()");
		return 0; }
	// loosely adapted from sss_create_shares to use underlying hazmat
	unsigned char key[32];
	unsigned char m[crypto_secretbox_ZEROBYTES + sss_MLEN] = { 0 };
	unsigned long long mlen = sizeof(m); /* length includes zero-bytes */
	unsigned char c[mlen];
	int tmp;
	sss_Keyshare *keyshares = zen_memory_alloc(n*sizeof(sss_Keyshare));
	size_t idx;
/* Nonce for the `crypto_secretbox` authenticated encryption.  The
 * nonce is constant (zero), because we are using an ephemeral key. */
	static const unsigned char nonce[crypto_secretbox_NONCEBYTES] = { 0 };
	/* Generate a random encryption key */
	randombytes(key, sizeof(key));
	/* AEAD encrypt the data with the key */
	memcpy(&m[crypto_secretbox_ZEROBYTES], msg->val, sss_MLEN);
	tmp = crypto_secretbox(c, m, mlen, nonce, key);
	if(tmp!=0) {
		lerror(L,"SSS.share() fatal error in AEAD encryption");
		return 0; }
	/* Generate KeyShares */
	sss_create_keyshares(keyshares,key,(int)n,(int)k);
	/* Build regular shares */
	int sharelen = sizeof(sss_Share)*n;
	octet *o = o_new(L,sharelen);
	o->len = sharelen;
	sss_Share *out = (sss_Share*)o->val;
	for (idx = 0; idx < n; idx++) {
		memcpy(get_keyshare((sss_Share*) &out[idx]), &keyshares[idx][0],
		       sss_KEYSHARE_LEN);
		memcpy(get_ciphertext((sss_Share*) &out[idx]),
		       &c[crypto_secretbox_BOXZEROBYTES], sss_CLEN);
	}
	zen_memory_free(keyshares);
	return 1;
}

int luaopen_sss(lua_State *L) {
	const struct luaL_Reg sss_class[] = {
		{"share",lua_sss_share},
		{NULL,NULL}
	};
	const struct luaL_Reg sss_methods[] = {
		{NULL,NULL}
	};
	zen_add_class(L, "sss", sss_class, sss_methods);
	return 1;
}
