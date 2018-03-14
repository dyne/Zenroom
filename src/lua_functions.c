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

#include <jutils.h>
#include <luasandbox.h>
#include <luasandbox/lua.h>
#include <luasandbox/lualib.h>
#include <luasandbox/lauxlib.h>
#include <luazen.h>

extern int lualibs_detected_load(lsb_lua_sandbox *lsb);
extern int lua_cjson_safe_new(lua_State *l);
extern int lua_cjson_new(lua_State *l);

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

#include <bitop.h>
const struct luaL_Reg bit_funcs[] = {
  { "tobit",	bit_tobit },
  { "bnot",	bit_bnot },
  { "band",	bit_band },
  { "bor",	bit_bor },
  { "bxor",	bit_bxor },
  { "lshift",	bit_lshift },
  { "rshift",	bit_rshift },
  { "arshift",	bit_arshift },
  { "rol",	bit_rol },
  { "ror",	bit_ror },
  { "bswap",	bit_bswap },
  { "tohex",	bit_tohex },
  { NULL, NULL }
};

extern int get_debug();

void lsb_setglobal_string(lsb_lua_sandbox *lsb, char *key, char *val) {
	lua_State* L = lsb_get_lua(lsb);
	lua_pushstring(L, val);
	lua_setglobal(L, key);
}



void lsb_load_string(lsb_lua_sandbox *lsb, const char *code,
                     size_t size, char *name) {
	lua_State* L = lsb_get_lua(lsb);

	lua_getglobal(L, "loadstring");
	if(!lua_iscfunction(L, -1)) {
		error("lsb_load_string: function 'loadstring' not found");
		return; }
	func("memory addr: %p (%u bytes)", code, size);
	lua_pushlstring(L, code, size);

	if(lua_pcall(L, 1, 1, 0)) {
		error("lsb_load_string: cannot load %s extension", name);
		return; }

	if (lua_isstring(L, -1) || lua_isnil(L, -1)) {
		/* loader returned error message? */
		error("error loading lua string: %s", name);
		if(!lua_isnil(L,-1))
			error("%s", lua_tostring(L, -1));
		return; }

	act("loaded lua from string: %s", name);

	// run loaded module
	lua_setglobal(L, name);
}

void lsb_load_luamodule(lsb_lua_sandbox *lsb, lua_CFunction f, const char *name) {
	lua_State *L = lsb_get_lua(lsb);
	lua_pushcfunction(L, f);
	lua_pushstring(L, name);
	lua_call(L, 1, 1);
	lua_newtable(L);
	lua_setmetatable(L, -2);
	lua_pop(L, 1);
}

void lsb_load_cmodule(lsb_lua_sandbox *lsb, luaL_Reg *lib) {
	if(!lsb || !lib) {
		error("lsb_load_cmodule: NULL lib, loading aborted.");
		return; }
	for (; lib->func; lib++) {
		lsb_add_function(lsb, lib->func, lib->name);
	}
}

void lsb_load_extensions(lsb_lua_sandbox *lsb) {
	act("loading language extensions");

	lsb_load_luamodule(lsb, luaopen_base,   LUA_BASELIBNAME);
	lsb_load_luamodule(lsb, luaopen_table,  LUA_TABLIBNAME);
	lsb_load_luamodule(lsb, luaopen_string, LUA_STRLIBNAME);
	lsb_load_luamodule(lsb, luaopen_math,   LUA_MATHLIBNAME);
	lsb_load_luamodule(lsb, luaopen_io,     LUA_IOLIBNAME);
	lsb_load_luamodule(lsb, luaopen_os,     LUA_OSLIBNAME);
	lsb_load_luamodule(lsb, luaopen_coroutine, LUA_COLIBNAME);
	lsb_load_luamodule(lsb, luaopen_debug,     LUA_DBLIBNAME);


	// just the constructors are enough for cjson
	lsb_add_function(lsb, lua_cjson_safe_new, "cjson");
	lsb_add_function(lsb, lua_cjson_new, "cjson_full");

	lsb_load_cmodule(lsb, (luaL_Reg*) &luazen);
	lsb_load_cmodule(lsb, (luaL_Reg*) &bit_funcs);

	// load embedded lua extensions generated by build/embed-lualibs
	lualibs_detected_load(lsb);

	act("done loading all extensions");

}
