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

#include <luazen.h>

#include <zenroom.h>
#include <lua_functions.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

lsb_err_id ZEN_ERR_UTIL_NULL    = "pointer is NULL";
lsb_err_id ZEN_ERR_UTIL_OOM     = "memory allocation failed";
lsb_err_id ZEN_ERR_UTIL_FULL    = "buffer full";
lsb_err_id ZEN_ERR_UTIL_PRANGE  = "parameter out of range";

extern void zen_load_extensions(lsb_lua_sandbox *lsb);
extern void preload_modules(lua_State *lua);

/**
* Implementation of the memory allocator for the Lua state.
*
* See: http://www.lua.org/manual/5.1/manual.html#lua_Alloc
*
* @param ud Pointer to the lsb_lua_sandbox
* @param ptr Pointer to the memory block being allocated/reallocated/freed.
* @param osize The original size of the memory block.
* @param nsize The new size of the memory block.
*
* @return void* A pointer to the memory block.
*/
// TODO: fix to work with lua 5.3 and implement simple memory fence
void* memory_manager(void *ud, void *ptr, size_t osize, size_t nsize)
{
  lsb_lua_sandbox *lsb = (lsb_lua_sandbox *)ud;

  void *nptr = NULL;
  if (nsize == 0) {
    free(ptr);
    lsb->mem_usage -= osize;
  } else {
    size_t new_state_memory =
        lsb->mem_usage + nsize - osize;
    if (0 == lsb->mem_max
        || new_state_memory
        <= lsb->mem_max) {
      nptr = realloc(ptr, nsize);
      if (nptr != NULL) {
        lsb->mem_usage = new_state_memory;
        if (lsb->mem_usage > lsb->mem_max) {
          lsb->mem_max = lsb->mem_usage;
        }
      }
    }
  }
  return nptr;
}

void lsb_add_function(lsb_lua_sandbox *lsb, lua_CFunction func,
                      const char *func_name)
{
	if (!lsb || !func || !func_name) return;

	lua_pushcfunction(lsb->lua, func);
	lua_setglobal(lsb->lua, func_name);
}

void lsb_setglobal_string(lsb_lua_sandbox *lsb, char *key, char *val) {
	lua_State* L = lsb->lua;
	lua_pushstring(L, val);
	lua_setglobal(L, key);
}

int zen_add_package(lua_State *L, char *name, lua_CFunction func) {
	lua_register(L,name,func);
	char cmd[MAX_STRING];
	snprintf(cmd,MAX_STRING,
	         "table.insert(package.searchers, 2, %s",name);
	return luaL_dostring(L,cmd);
}

void zen_add_function(lsb_lua_sandbox *lsb,
                      lua_CFunction func,
                      const char *func_name) {
	if (!lsb || !func || !func_name) return;	
	lua_pushcfunction(lsb->lua, func);
	lua_setglobal(lsb->lua, func_name);
}


lsb_lua_sandbox *zen_init() {
	lsb_lua_sandbox *lsb = NULL;


	lsb = calloc(1, sizeof(*lsb));
	if (!lsb) {
		error("%s: %s", __func__, "memory allocation failed");
		return NULL; }
	lsb->mem_usage=0;
	lsb->mem_max=0;
	lsb->op_usage=0;
	lsb->op_max=0;

	// lsb->lua = lua_newstate(memory_manager, lsb);
	lsb->lua = luaL_newstate();
	if(!lsb->lua) {
		error("%s: %s", __func__, "lua state creation failed");
		free(lsb);
		return NULL;
	}

	lsb->error_message[0] = 0;
	lsb->state_file = NULL;

	// initialise global variables
	lsb_setglobal_string(lsb, "VERSION", VERSION);
	lsb_setglobal_string(lsb, "ARCH", ARCH);
	// open all standard lua libraries
	luaL_openlibs(lsb->lua);
	//////////////////// end of create

	lua_pushlightuserdata(lsb->lua, lsb);
	lua_setfield(lsb->lua, LUA_REGISTRYINDEX, LSB_THIS_PTR);

	return(lsb);

}

int zen_teardown(lsb_lua_sandbox *lsb) {
	lua_State *lua = lsb->lua;

	notice("Zenroom console quit.");
    if(lua) lua_gc(lua, LUA_GCCOLLECT, 0);
    if(lsb->mem_usage > lsb->mem_max)
	    lsb->mem_usage = lsb->mem_max;
    lua_close(lsb->lua);
    lsb->lua = NULL;
    free(lsb);
	return(0);
}

int zen_exec_line(lsb_lua_sandbox *lsb, const char *line) {
	int ret;
	lua_State* lua = lsb->lua;

	ret = luaL_dostring(lua, line);
	if(ret) {
		error("%s", lua_tostring(lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}


int zen_exec_script(lsb_lua_sandbox *lsb, const char *script) {
	int ret;
	lua_State* lua = lsb->lua;

	ret = luaL_dostring(lua, script);
    lua_gc(lua, LUA_GCCOLLECT, 0);
	if(ret) {
		error("%s", lua_tostring(lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}

void zen_add_class(lua_State *L, char *name,
                  luaL_Reg *class, luaL_Reg *methods) {
	char classmeta[512];
	snprintf(classmeta,511,"zenroom.%s", name);
	luaL_newmetatable(L, classmeta);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);  /* pushes the metatable */
	lua_settable(L, -3);  /* metatable.__index = metatable */
	luaL_setfuncs(L,methods,0);

	luaL_findtable(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE, 1);
	if (lua_getfield(L, -1, name) != LUA_TTABLE) {
		// no LOADED[modname]?
		lua_pop(L, 1);  // remove previous result
		// try global variable (and create one if it does not exist)
		lua_pushglobaltable(L);
		// TODO: 'sizehint' 1 here is for new() constructor. if more
		// than one it should be counted on the class
		if (luaL_findtable(L, 0, name, 1) != NULL)
			luaL_error(L, "name conflict for module '%s'", name);
		lua_pushvalue(L, -1);
		lua_setfield(L, -3, name);  /* LOADED[modname] = new table */
	}
	lua_remove(L, -2);  /* remove LOADED table */

	// in lua 5.1 was: luaL_pushmodule(L,name,1);

	lua_insert(L,-1);
	luaL_setfuncs(L,class,0);
}
