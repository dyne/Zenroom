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

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <lua_functions.h>

#include <zenroom.h>
#include <zen_memory.h>

// prototypes from lua_modules.c
extern int zen_require_override(lua_State *L);
extern int lua_cjson_safe_new(lua_State *l);

void zen_add_io(lua_State *L);

// prototypes from zen_memory.c
extern zen_mem_t *libc_memory_init();
extern void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);

// prototype from lpeglabel/lptree.c
int luaopen_lpeglabel (lua_State *L);

zenroom_t *ast_init() {
	lua_State *L = NULL;
	zen_mem_t *mem = NULL;
	mem = libc_memory_init();
	L = lua_newstate(zen_memory_manager, mem);
	if(!L) {
		error(L,"%s: %s", __func__, "lua state creation failed");
		return NULL;
	}
	// create the zenroom_t global context
	zenroom_t *Z = system_alloc(sizeof(zenroom_t));
	Z->lua = L;
	Z->mem = mem;
	Z->stdout_buf = NULL;
	Z->stdout_pos = 0;
	Z->stdout_len = 0;
	Z->stderr_buf = NULL;
	Z->stderr_pos = 0;
	Z->stderr_len = 0;
	Z->userdata = NULL;
	//Set zenroom context as a global in lua
	//this will be freed on lua_close
	lua_pushlightuserdata(L, Z);
	lua_setglobal(L, "_Z");
	// open all standard lua libraries
	luaL_openlibs(L);
	// open lpeglabel

	luaL_requiref(L, "lpeg", luaopen_lpeglabel, 1);
	luaL_requiref(L, "json", lua_cjson_safe_new, 1);

	// load our own openlibs and extensions
	zen_add_io(L);
	zen_require_override(L);

	return(Z);
}

int ast_parse(zenroom_t *Z) {
	int ret = luaL_dostring(Z->lua, "require'ast'");
	if(ret) {
		error(Z->lua, "%s", lua_tostring(Z->lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}

void ast_teardown(zenroom_t *Z) {
	void *mem = Z->mem;
	if(Z->lua) lua_close((lua_State*)Z->lua);
	if(mem) system_free(mem);
}
