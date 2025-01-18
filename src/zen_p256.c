/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2023 Dyne.org foundation
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

#include <p256-m.h>

#include <zen_error.h>
#include <zen_octet.h>
#include <zenroom.h>
#include <lua_functions.h>

#define PK_SIZE 64
#define SK_SIZE 32
#define HASH_SIZE 32
#define SIG_SIZE 64

#define ASSERT_OCT_LEN(OCT, SIZE, MSG) \
	if ((OCT)->len != SIZE)        \
	{                              \
		failed_msg = (MSG);    \
		lua_pushnil(L);        \
		goto end;              \
	}

static int p256_keygen(lua_State *L)
{
	BEGIN();
	Z(L);
	uint8_t pub[PK_SIZE];
	octet *sk = o_new(L, SK_SIZE);
	sk->len = SK_SIZE;
	if(!sk) {
		THROW("Could not allocate secret key");
	} else {
		p256_gen_keypair(Z, NULL, (uint8_t*)sk->val, pub);
	}
	END(1);
}

static int p256_pubgen(lua_State *L)
{
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL, *sk = NULL;
	sk = o_arg(L, 1);
	if (!sk)
	{
		failed_msg = "Could not allocate secret key";
		goto end;
	}

	ASSERT_OCT_LEN(sk, SK_SIZE, "Invalid size for ECDSA secret key")

	pk = o_new(L, PK_SIZE);
	if (!pk)
	{
		failed_msg = "Could not allocate public key";
		goto end;
	}
	pk->len = PK_SIZE;

	int ret = p256_publickey((uint8_t *)sk->val, (uint8_t *)pk->val);
	if (ret != 0)
	{
		failed_msg = "Could not generate public key";
		goto end;
	}
end:
	o_free(L, sk);
	if (failed_msg != NULL)
	{
		THROW(failed_msg);
	}
	END(1);
}

static int p256_session(lua_State *L)
{
	BEGIN();
	END(1);
}

static int p256_pubcheck(lua_State *L)
{
	BEGIN();
	END(1);
}

static int p256_sign(lua_State *L)
{
	BEGIN();
	Z(L);

	int n_args = lua_gettop(L);
	hash256 sha256;
	char hash[HASH_SIZE];
	char *failed_msg = NULL;
	octet *sk = NULL, *m = NULL, *sig = NULL, *k = NULL;
	sk = o_arg(L, 1);
	if (!sk)
	{
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	m = o_arg(L, 2);
	if (!m)
	{
		failed_msg = "Could not allocate message";
		goto end;
	}

	ASSERT_OCT_LEN(sk, SK_SIZE, "Invalid size for ECDSA secret key")
	HASH256_init(&sha256);
	for (int i = 0; i < m->len; i++)
	{
		HASH256_process(&sha256, m->val[i]);
	}
	HASH256_hash(&sha256, hash);

	sig = o_new(L, SIG_SIZE);
	if (!sig)
	{
		failed_msg = "Could not allocate signature";
		goto end;
	}
	sig->len = SIG_SIZE;

	if(n_args > 2) {
		k = o_arg(L, 3);
		if(k == NULL) {
			failed_msg = "Could not allocate ephemeral key";
			goto end;
		}
	}

	int ret = p256_ecdsa_sign(Z, k, (uint8_t *)sig->val, (uint8_t *)sk->val,
				  (uint8_t *)hash, HASH_SIZE);
	if (ret != 0)
	{
		failed_msg = "Could not sign message";
		goto end;
	}

end:
	o_free(L, m);
	o_free(L, sk);
	o_free(L, k);
	if (failed_msg != NULL)
	{
		THROW(failed_msg);
	}
	END(1);
}

static int p256_verify(lua_State *L)
{
	BEGIN();
	hash256 sha256;
	char hash[HASH_SIZE];
	char *failed_msg = NULL;
	octet *pk = NULL, *sig = NULL, *m = NULL;
	pk = o_arg(L, 1);
	if (!pk)
	{
		failed_msg = "Could not allocate public key";
		goto end;
	}
	m = o_arg(L, 2);
	if (!m)
	{
		failed_msg = "Could not allocate message";
		goto end;
	}
	sig = o_arg(L, 3);
	if (!sig)
	{
		failed_msg = "Could not allocate signature";
		goto end;
	}

	ASSERT_OCT_LEN(pk, PK_SIZE, "Invalid size for EdDSA public key")
	ASSERT_OCT_LEN(sig, SIG_SIZE, "Invalid size for EdDSA signature")

	HASH256_init(&sha256);
	for (int i = 0; i < m->len; i++)
	{
		HASH256_process(&sha256, m->val[i]);
	}
	HASH256_hash(&sha256, hash);

	lua_pushboolean(L, p256_ecdsa_verify((uint8_t *)sig->val,
					     (uint8_t *)pk->val,
					     (uint8_t *)hash, HASH_SIZE) == 0);
end:
	o_free(L, m);
	o_free(L, pk);
	o_free(L, sig);
	if (failed_msg != NULL)
	{
		THROW(failed_msg);
	}
	END(1);
}

static int p256_pub_xy(lua_State *L)
{
	BEGIN();
	END(1);
}

static int p256_destroy(lua_State *L)
{
	BEGIN();
	END(0);
}

int luaopen_p256(lua_State *L)
{
	(void)L;
	const struct luaL_Reg p256_class[] = {
	    {"keygen", p256_keygen},
	    {"pubgen", p256_pubgen},
	    {"session", p256_session},
	    {"checkpub", p256_pubcheck},
	    {"pubcheck", p256_pubcheck},
	    {"validate", p256_pubcheck},
	    {"sign", p256_sign},
	    {"verify", p256_verify},
	    {"public_xy", p256_pub_xy},
	    {"pubxy", p256_pub_xy},
	    {NULL, NULL}};
	const struct luaL_Reg p256_methods[] = {
	    {"__gc", p256_destroy},
	    {NULL, NULL}};

	zen_add_class(L, "p256", p256_class, p256_methods);
	return 1;
}
