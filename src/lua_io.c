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

#include<zenroom.h>
#include <luasandbox/lauxlib.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>

static int zen_print (lua_State *L) {
	char out[MAX_STRING];
	size_t pos = 0;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s;
		lua_pushvalue(L, -1);  /* function to be called */
		lua_pushvalue(L, i);   /* value to print */
		lua_call(L, 1, 1);
		s = lua_tolstring(L, -1, &len);  /* get result */
		if (s == NULL)
			return luaL_error(L, LUA_QL("tostring") " must return a string to "
			                  LUA_QL("print"));
		if (i>1) { out[pos]='\t'; pos++; }
		snprintf(out+pos,MAX_STRING-pos,"%s",s);
		pos+=len;
		lua_pop(L, 1);  /* pop result */
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
	return 0;
}

static int zen_iowrite (lua_State *L) {
	char out[MAX_STRING];
	size_t pos = 0;
	int nargs = lua_gettop(L) +1;
	int arg = 0;
	for (; nargs--; arg++) {
		size_t len;
		const char *s = lua_tolstring(L, arg, &len);
		if (arg>1) { out[pos]='\t'; pos++; }
		snprintf(out+pos,MAX_STRING-pos,"%s",s);
		pos+=len;
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
	lua_pushboolean(L, 1);
	return 1;
}


#else


static int zen_print (lua_State *L) {
	size_t l = 0;
	int status = 1;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s;
		lua_pushvalue(L, -1);  /* function to be called */
		lua_pushvalue(L, i);   /* value to print */
		lua_call(L, 1, 1);
		s = lua_tolstring(L, -1, &l);  /* get result */
		if (s == NULL)
			return luaL_error(L, LUA_QL("tostring") " must return a string to "
			                  LUA_QL("print"));
		if(i>1) fwrite("\t",sizeof(char),1,stdout);
		status = status && (fwrite(s, sizeof(char), l, stdout) == l);
		lua_pop(L, 1);  /* pop result */
	}
	fwrite("\n",sizeof(char),1,stdout);
	return 0;
}

static int zen_iowrite (lua_State *L) {
	int nargs = lua_gettop(L) +1;
	int status = 1;
	int arg = 0;
	FILE *out = stdout;
	for (; nargs--; arg++) {
		if (lua_type(L, arg) == LUA_TNUMBER) {
			/* optimization: could be done exactly as for strings */
			status = status &&
				fprintf(out, LUA_NUMBER_FMT, lua_tonumber(L, arg)) > 0;
		} else {
			size_t l;
			const char *s = lua_tolstring(L, arg, &l);
			status = status && (fwrite(s, sizeof(char), l, out) == l);
		}
	}
	if (!status) {
		lua_pushnil(L);
		lua_pushfstring(L, "%s", strerror(errno));
		lua_pushinteger(L, errno);
		return 3;
	}
	lua_pushboolean(L, 1);
	return 1;
}

#endif

void zen_add_io(lua_State *L) {
	// override print() and io.write()

	static const struct luaL_Reg custom_print [] =
		{ {"print", zen_print}, {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_register(L, NULL, custom_print); // for Lua versions < 5.2
	// luaL_setfuncs(L, printlib, 0);  // for Lua versions 5.2 or greater
	lua_pop(L, 1);

	static const struct luaL_Reg custom_iowrite [] =
		{ {"write", zen_iowrite}, {NULL, NULL} };
	lua_getglobal(L, "io");
	luaL_register(L, NULL, custom_iowrite);
	lua_pop(L, 1);

}
