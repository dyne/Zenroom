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
#include <luasandbox.h>
#include <luasandbox/lua.h>
#include <luasandbox/lualib.h>
#include <luasandbox/lauxlib.h>
#include <luazen.h>
#include <lua_functions.h>

#include <zenroom.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

extern int lualibs_detected_load(lsb_lua_sandbox *lsb);
extern int lua_cjson_safe_new(lua_State *l);
extern int lua_cjson_new(lua_State *l);

static const luaL_Reg preload_module_list[] = {
  { LUA_BASELIBNAME, luaopen_base },
  { LUA_TABLIBNAME, luaopen_table },
  { LUA_STRLIBNAME, luaopen_string },
  { LUA_MATHLIBNAME, luaopen_math },
  { LUA_OSLIBNAME, luaopen_os },
  { LUA_DBLIBNAME, luaopen_debug},
  { NULL, NULL }
};


static int pushresult (lua_State *L, int i, const char *filename) {
  int en = errno;  /* calls to Lua API may change this value */
  if (i) {
    lua_pushboolean(L, 1);
    return 1;
  }
  else {
    lua_pushnil(L);
    if (filename)
      lua_pushfstring(L, "%s: %s", filename, strerror(en));
    else
      lua_pushfstring(L, "%s", strerror(en));
    lua_pushinteger(L, en);
    return 3;
  }
}
static int zen_print (lua_State *L) {
	char out[MAX_STRING];
	int pos = 0;
	int len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s;
		lua_pushvalue(L, -1);  /* function to be called */
		lua_pushvalue(L, i);   /* value to print */
		lua_call(L, 1, 1);
		s = lua_tostring(L, -1);  /* get result */
		if (s == NULL)
			return luaL_error(L, LUA_QL("tostring") " must return a string to "
			                  LUA_QL("print"));
		len = strlen(s);
		if (i>1) { out[pos]='\t'; pos++; }
		snprintf(out+pos,MAX_STRING,"%s",s);
		pos+=len;
		lua_pop(L, 1);  /* pop result */
	}
#ifdef __EMSCRIPTEN__
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
#endif
	fprintf(stdout,"%s\n",out);
	return 0;
}
// TODO: fix this, right now doesn't writes anything out
static int zen_iowrite (lua_State *L) {
	int nargs = lua_gettop(L) - 1;
	int status = 1;
	int arg = 1;
	FILE *out = stdout;
	for (; nargs--; arg++) {
		if (lua_type(L, arg) == LUA_TNUMBER) {
			/* optimization: could be done exactly as for strings */
			status = status &&
				fprintf(out, LUA_NUMBER_FMT, lua_tonumber(L, arg)) > 0;
		} else {
			size_t l;
			const char *s = luaL_checklstring(L, arg, &l);
			status = status && (fwrite(s, sizeof(char), l, out) == l);
		}
	}
	return pushresult(L, status, NULL);
}

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


static int libsize(const luaL_Reg *l)
{
  int size = 0;
  for (; l->name; l++) size++;
  return size;
}

void preload_modules(lua_State *lua)
{
  const luaL_Reg *lib = preload_module_list;
  luaL_findtable(lua, LUA_REGISTRYINDEX, "_PRELOADED",
                 libsize(preload_module_list));
  for (; lib->func; lib++) {
    lua_pushstring(lua, lib->name);
    lua_pushcfunction(lua, lib->func);
    lua_rawset(lua, -3);
  }
  lua_pop(lua, 1); // remove the preloaded table
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

void zen_load_extensions(lsb_lua_sandbox *lsb) {
	act("loading language extensions");

	lsb_load_luamodule(lsb, luaopen_base,   LUA_BASELIBNAME);
	lsb_load_luamodule(lsb, luaopen_table,  LUA_TABLIBNAME);
	lsb_load_luamodule(lsb, luaopen_string, LUA_STRLIBNAME);
	lsb_load_luamodule(lsb, luaopen_math,   LUA_MATHLIBNAME);
	lsb_load_luamodule(lsb, luaopen_io,     LUA_IOLIBNAME);
	lsb_load_luamodule(lsb, luaopen_os,     LUA_OSLIBNAME);
	lsb_load_luamodule(lsb, luaopen_coroutine, LUA_COLIBNAME);
	lsb_load_luamodule(lsb, luaopen_debug,     LUA_DBLIBNAME);

	// override print() and io.write()
	static const struct luaL_Reg custom_print [] =
		{ {"print", zen_print}, {NULL, NULL} };
	lua_getglobal(lsb->lua, "_G");
	luaL_register(lsb->lua, NULL, custom_print); // for Lua versions < 5.2
	// luaL_setfuncs(L, printlib, 0);  // for Lua versions 5.2 or greater
	lua_pop(lsb->lua, 1);
	// static const struct luaL_Reg custom_iowrite [] =
	// 	{ {"write", zen_iowrite}, {NULL, NULL} };
	// lua_getglobal(lsb->lua, "io");
	// luaL_register(lsb->lua, NULL, custom_iowrite);
	// lua_pop(lsb->lua, 1);


	// just the constructors are enough for cjson
	lsb_add_function(lsb, lua_cjson_safe_new, "cjson");
	lsb_add_function(lsb, lua_cjson_new, "cjson_full");

	lsb_load_cmodule(lsb, (luaL_Reg*) &luazen);
	lsb_load_cmodule(lsb, (luaL_Reg*) &bit_funcs);

	// load embedded lua extensions generated by build/embed-lualibs
	lualibs_detected_load(lsb);

	act("done loading all extensions");

}
