/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2023 Dyne.org foundation
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
#include <p256-m.h>
#include <randombytes.h>

#define PK_SIZE 64
#define SK_SIZE 32

#define ASSERT_OCT_LEN(OCT, TYPE, MSG)\
	if((OCT)->len != sizeof(TYPE)) { \
		failed_msg = (MSG);\
		lua_pushnil(L);\
		goto end;\
	}

#define PUSH_CHECK_OCT_LEN(OCT, TYPE)\
	lua_pushboolean(L, ((OCT)->len == sizeof(TYPE))):

int p256_generate_random(uint8_t *output, unsigned output_size)
{
	randombytes((unsigned char *) output, output_size);
	return 0;
}

static int p256_keygen(lua_State *L) {
	BEGIN();
	Z(L);
	uint8_t pub[PK_SIZE];
	octet *sk = o_new(L, SK_SIZE);
	sk->len = SK_SIZE;
	if(!sk) {
		THROW("Could not allocate secret key");
	} else {
		p256_gen_keypair((uint8_t*)sk->val, pub);
	}
	END(1);
}

static int p256_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL, *sk = NULL;
	sk = o_arg(L, 1);
	if(!sk) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}

	ASSERT_OCT_LEN(sk, SK_SIZE, "Invalid size for ECDSA secret key")

	pk = o_new(L, sizeof(PK_SIZE));
	if(!pk) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	pk->len = sizeof(PK_SIZE);

	ed25519_publickey((unsigned char*)sk->val, (unsigned char *)pk->val);
end:
	o_free(L, sk);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}

static int ed_sign(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = NULL, *m = NULL, *sig = NULL;
	sk = o_arg(L, 1);
	if(!sk) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	m = o_arg(L, 2);
	if(!m) {
		failed_msg = "Could not allocate message";
		goto end;
	}

	ASSERT_OCT_LEN(sk, ed25519_secret_key, "Invalid size for EdDSA secret key")

	ed25519_public_key pk;
	ed25519_publickey((unsigned char*)sk->val, pk);

	sig = o_new(L, sizeof(ed25519_signature));
	if(!sig) {
		failed_msg = "Could not allocate signature";
		goto end;
	}
	sig->len = sizeof(ed25519_signature);

	ed25519_sign((unsigned char*)m->val, m->len,
		     (unsigned char*)sk->val, pk,
		     (unsigned char*)sig->val);

end:
	o_free(L, m);
	o_free(L, sk);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}

static int ed_verify(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL, *sig = NULL, *m = NULL;
	pk = o_arg(L, 1);
	if(!pk) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	sig = o_arg(L, 2);
	if(!sig) {
		failed_msg = "Could not allocate signature";
		goto end;
	}
	m = o_arg(L, 3);
	if(!m) {
		failed_msg = "Could not allocate message";
		goto end;
	}

	ASSERT_OCT_LEN(pk, ed25519_public_key, "Invalid size for EdDSA public key")
	ASSERT_OCT_LEN(sig, ed25519_signature, "Invalid size for EdDSA signature")

	lua_pushboolean(L, ed25519_sign_open((unsigned char*)m->val, m->len,
				             (unsigned char*)pk->val,
					     (unsigned char*)sig->val) == 0);

end:
	o_free(L, m);
	o_free(L, pk);
	o_free(L, sig);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}
int luaopen_p256(lua_State *L) {
	(void)L;
	const struct luaL_Reg ed_class[] = {
		{"keygen", p256_keygen},
		{NULL,NULL}
	};
	const struct luaL_Reg ed_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "ed", ed_class, ed_methods);
	return 1;
}
