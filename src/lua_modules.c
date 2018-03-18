/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>
#include <errno.h>
#include <jutils.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <luazen.h>
#include <lua_functions.h>

#include <zenroom.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

extern int lualibs_load_all_detected(lua_State *L);
extern int lua_cjson_safe_new(lua_State *l);
extern int lua_cjson_new(lua_State *l);
extern void zen_add_io(lua_State *L);
extern zen_extension_t zen_extensions[];

const struct luaL_Reg luazen[] = {
	{"randombytes", lz_randombytes},

	// Symmetric encryption with Norx AEAD
	{"encrypt_norx", lz_aead_encrypt},
	{"decrypt_norx", lz_aead_decrypt},
	// Mostly obsolete symmetric stream-cipher
	// encrypt and decrypt with same function
	{"crypt_rc4", lz_rc4},
	{"crypt_rc4raw", lz_rc4raw},

	// Asymmetric shared secret session with x25519
	// all secrets are 32 bytes long
	{"keygen_session_x25519", lz_x25519_keypair},
	{"pubkey_session_x25519", lz_x25519_public_key},
	// session shared secret hashed by blake2b
	{"exchange_session_x25519", lz_key_exchange},

	// Blake2b hashing function
	{"hash_blake2b", lz_blake2b},
	{"hash_init_blake2b", lz_blake2b_init},
	{"hash_update_blake2b", lz_blake2b_update},
	{"hash_final_blake2b", lz_blake2b_final},
	// simple MD5 hashing function
	{"hash_md5", lz_md5},

	// Asymmetric signing with ed25519
	{"keygen_sign_ed25519", lz_sign_keypair},
	{"pubkey_sign_ed25519", lz_sign_public_key},
	{"sign_ed25519", lz_sign},
	{"check_ed25519", lz_check},

	// Key Derivation Function
	{"kdf_argon2i", lz_argon2i},

	{"xor", lz_xor},
	// brieflz compression
	{"compress_blz", lz_blz},
	{"decompress_blz", lz_unblz},
	// lzf compression
	{"compress_lzf", lz_lzf},
	{"decompress_lzf", lz_unlzf},

	// TODO: rename in all tests
	{"rc4", lz_rc4},
	{"rc4raw", lz_rc4raw},
	{"md5", lz_md5},

	{"encode_b64",	lz_b64encode},
	{"decode_b64",	lz_b64decode},
	{"encode_b58",	lz_b58encode},
	{"decode_b58",	lz_b58decode},
	//
	{NULL, NULL},
};



void zen_add_function(lsb_lua_sandbox *lsb, lua_CFunction func,
                      const char *func_name)
{
  if (!lsb || !func || !func_name) return;

  lua_pushcfunction(lsb->lua, func);
  lua_setglobal(lsb->lua, func_name);
}

void zen_load_luamodule(lsb_lua_sandbox *lsb, lua_CFunction f, const char *name) {
	lua_State *L = lsb->lua;
	lua_pushcfunction(L, f);
	lua_pushstring(L, name);
	lua_call(L, 1, 1);
	lua_newtable(L);
	lua_setmetatable(L, -2);
	lua_pop(L, 1);
}

void zen_load_cmodule(lsb_lua_sandbox *lsb, luaL_Reg *lib) {
	if(!lsb || !lib) {
		error("lsb_load_cmodule: NULL lib, loading aborted.");
		return; }
	for (; lib->func; lib++) {
		zen_add_function(lsb, lib->func, lib->name);
	}
}


int zen_load_string(lua_State *L, const char *code,
                     size_t size, const char *name) {
	int res;
	res = luaL_loadbufferx(L,code,size,name,"b");
	switch (res) {
	case LUA_OK: { func("loaded %s",name); break; }
	case LUA_ERRSYNTAX: { error("syntax error: %s",name); break; }
	case LUA_ERRMEM: { error("out of memory: %s", name); break;	}
	case LUA_ERRGCMM: {
		error("garbage collection error while loading %s", name);
		break; }
	}
	return(res);
}

int zen_require(lua_State *L) {
	size_t len;
	const char *s = lua_tolstring(L, 1, &len);
	if(!s) return 0;
	for (zen_extension_t *p = zen_extensions;
	     p->name != NULL; ++p) {
		if (strcmp(p->name, s) == 0) {
			if(zen_load_string(L, p->code, *p->size, p->name)
			   ==LUA_OK) {
				lua_call(L,0,1);
				break;
			} else return 0;
		}
	}
	return 1;
}

int zen_require_override(lua_State *L) {
	static const struct luaL_Reg custom_require [] =
		{ {"require", zen_require}, {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, custom_require, 0);
	lua_pop(L, 1);
	return 1;
}

void zen_load_extensions(lsb_lua_sandbox *lsb) {
	act("loading language extensions");

	// register our own print and io.write
	zen_add_io(lsb->lua);

	zen_require_override(lsb->lua);

	// just the constructors are enough for cjson
	zen_add_function(lsb, lua_cjson_safe_new, "cjson");
	zen_add_function(lsb, lua_cjson_new, "cjson_full");

	zen_load_cmodule(lsb, (luaL_Reg*) &luazen);

	// load embedded lua extensions generated by build/embed-lualibs

	act("done loading all extensions");

}
