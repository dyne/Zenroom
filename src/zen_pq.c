/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2020 Dyne.org foundation
 * designed, written and maintained by Alberto Lerda <albertolerda97@gmail.com>
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

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <zenroom.h>
#include <zen_error.h>
#include <zen_memory.h>
#include <lua_functions.h>
#include <zen_octet.h>


#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES 1312
#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES 2528
#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_BYTES 2420
#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_ALGNAME "Dilithium2"

// Post quantum digital signature
extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_keypair(uint8_t *pk, uint8_t *sk);

extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_signature(
    uint8_t *sig, size_t *siglen,
    const uint8_t *m, size_t mlen, const uint8_t *sk);

extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_verify(
    const uint8_t *sig, size_t siglen,
    const uint8_t *m, size_t mlen, const uint8_t *pk);

extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign(
    uint8_t *sm, size_t *smlen,
    const uint8_t *m, size_t mlen, const uint8_t *sk);

extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_open(
    uint8_t *m, size_t *mlen,
    const uint8_t *sm, size_t smlen, const uint8_t *pk);


static int pq_signature_keygen(lua_State *L) {
	lua_createtable(L, 0, 2);
        octet *private = o_new(L,PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES); SAFE(private);
	lua_setfield(L, -2, "private");
        octet *public = o_new(L,PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES); SAFE(public);
	lua_setfield(L, -2, "public");

	PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_keypair((uint8_t*)public->val, (uint8_t*)private->val);
	public->len = PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES;
	private->len = PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES;

	return 1;
}

static int pq_sign(lua_State *L) {
	octet *sk = o_arg(L,1); SAFE(sk);
	octet *m = o_arg(L,2); SAFE(m);

	if(sk->len != PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES) {
		lerror(L,"invalid size for secret key");
		lua_pushboolean(L, 0);
		return 1;
	}
	octet *sig = o_new(L,PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_BYTES); SAFE(sig);

	if(PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_signature((uint8_t*)sig->val, (size_t*)&sig->len,
							  (uint8_t*)m->val, m->len, (uint8_t*)sk->val)
	   && sig->len > 0) {
		lerror(L,"error in the signature");
		lua_pushboolean(L, 0);
		return 1;

	}
	return 1;
}

static int pq_verify(lua_State *L) {
        octet *pk = o_arg(L,1); SAFE(pk);
	octet *sig = o_arg(L,2); SAFE(sig);
	octet *m = o_arg(L,3); SAFE(m);

	if(pk->len != PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES) {
		lerror(L,"invalid size for public key");
		lua_pushboolean(L, 0);
		return 1;
	}

	int result = PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_verify((uint8_t*)sig->val, (size_t)sig->len,
								 (uint8_t*)m->val, m->len, (uint8_t*)pk->val);
	lua_pushboolean(L, result == 0);
	return 1;
}


int luaopen_pq(lua_State *L) {
	(void)L;
	const struct luaL_Reg ecdh_class[] = {
	        {"sigkeygen", pq_signature_keygen},
	        {"sign", pq_sign},
	        {"verify", pq_verify},
		{NULL,NULL}
	};
	const struct luaL_Reg ecdh_methods[] = {
		{NULL,NULL}
	};

	zen_add_class("pq", ecdh_class, ecdh_methods);
	return 1;
}
