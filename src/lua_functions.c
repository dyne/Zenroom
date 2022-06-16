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

#include <ctype.h>
#include <errno.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zenroom.h>
#include <zen_error.h>
#include <lua_functions.h>

int zen_unset(lua_State *L, char *key) {
	lua_pushnil(L);
	lua_setglobal(L, key);
	return 0;
}

int zen_setenv(lua_State *L, char *key, char *val) {
	if(!val) {
		func(L, "setenv: NULL string detected");
		return 1; }
	if(val[0]=='\0') {
		func(L, "setenv: empty value for key: %s", key);
		return 1; }
	lua_pushstring(L, val);
	lua_setglobal(L, key);
	return 0;
}

void zen_add_function(lua_State *L,
                      lua_CFunction func,
                      const char *func_name) {
	if (!L || !func || !func_name) return;
	lua_pushcfunction(L, func);
	lua_setglobal(L, func_name);
}


const char *zen_lua_findtable (lua_State *L, int idx,
                                   const char *fname, int szhint) {
	const char *e;
	if (idx) lua_pushvalue(L, idx);
	do {
		e = strchr(fname, '.');
		if (e == NULL) e = fname + strlen(fname);
		lua_pushlstring(L, fname, (size_t)(e - fname));
		if (lua_rawget(L, -2) == LUA_TNIL) {  /* no such field? */
			lua_pop(L, 1);  /* remove this nil */
			lua_createtable(L, 0, (*e == '.' ? 1 : szhint)); /* new table for field */
			lua_pushlstring(L, fname, (size_t)(e - fname));
			lua_pushvalue(L, -2);
			lua_settable(L, -4);  /* set new table into field */
		}
		else if (!lua_istable(L, -1)) {  /* field has a non-table value? */
			lua_pop(L, 2);  /* remove table and value */
			return fname;  /* return problematic part of the name */
		}
		lua_remove(L, -2);  /* remove previous table */
		fname = e + 1;
	} while (*e == '.');
	return NULL;
}

void zen_add_class(lua_State *L, char *name,
                  const luaL_Reg *_class, const luaL_Reg *methods) {
	char classmeta[512] = "zenroom.";
	strncat(classmeta, name, 511);
	luaL_newmetatable(L, classmeta);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);  /* pushes the metatable */
	lua_settable(L, -3);  /* metatable.__index = metatable */
	luaL_setfuncs(L,methods,0);

	zen_lua_findtable(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE, 1);
	if (lua_getfield(L, -1, name) != LUA_TTABLE) {
		// no LOADED[modname]?
		lua_pop(L, 1);  // remove previous result
		// try global variable (and create one if it does not exist)
		lua_pushglobaltable(L);
		// TODO: 'sizehint' 1 here is for new() constructor. if more
		// than one it should be counted on the class
		if (zen_lua_findtable(L, 0, name, 1) != NULL)
			luaL_error(L, "name conflict for module '%s'", name);
		lua_pushvalue(L, -1);
		lua_setfield(L, -3, name);  /* LOADED[modname] = new table */
	}
	lua_remove(L, -2);  /* remove LOADED table */

	// in lua 5.1 was: luaL_pushmodule(L,name,1);

	lua_insert(L, -1);
	luaL_setfuncs(L, _class,0);
}
