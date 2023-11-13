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

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <p256-m.h>

#include <zen_error.h>
#include <zen_octet.h>
#include <zenroom.h>
#include <lua_functions.h>

static int p256_keygen(lua_State *L) {
  BEGIN();
  char *failed_msg = NULL;
  uint8_t priv[32];
  uint8_t pub[64];
  Z(L);
  p256_gen_keypair(Z, priv, pub);
  // return a table
  lua_createtable(L, 0, 2);
  octet *pk = o_new(L,64+4);
  if(pk == NULL) {
	failed_msg = "Could not create public key";
	goto end;
  }
  memcpy(pk->val, pub, 64);
  pk->len = 64;
  lua_setfield(L, -2, "public");
  octet *sk = o_new(L,32+4);
  if(sk == NULL) {
	failed_msg = "Could not create secret key";
	goto end;
  }
  memcpy(sk->val, priv, 32);
  sk->len = 32;
  lua_setfield(L, -2, "private");
 end:
  if(failed_msg) {
	THROW(failed_msg);
  }
  END(1);
}

static int p256_pubgen(lua_State *L) {
  BEGIN();
  END(1);
}

static int p256_session(lua_State *L) {
  BEGIN();
  END(1);
}

static int p256_pubcheck(lua_State *L) {
  BEGIN();
  END(1);
}

static int p256_sign(lua_State *L) {
  BEGIN();
  END(1);
}

static int p256_verify(lua_State *L) {
  BEGIN();
  END(1);
}

static int p256_pub_xy(lua_State *L) {
  BEGIN();
  END(1);
}

static int p256_destroy(lua_State *L) {
  BEGIN();
  END(0);
}



int luaopen_p256(lua_State *L) {
	(void)L;
	const struct luaL_Reg p256_class[] = {
		{"keygen",p256_keygen},
		{"pubgen",p256_pubgen},
		{"session", p256_session},
		{"checkpub", p256_pubcheck},
		{"pubcheck", p256_pubcheck},
		{"validate", p256_pubcheck},
		{"sign", p256_sign},
		{"verify", p256_verify},
		{"public_xy", p256_pub_xy},
		{"pubxy", p256_pub_xy},
		{NULL,NULL}};
	const struct luaL_Reg p256_methods[] = {
		{"__gc", p256_destroy},
		{NULL,NULL}
	 };

	zen_add_class(L, "p256", p256_class, p256_methods);
	return 1;
}
