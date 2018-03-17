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

#include <zenroom.h>
#include <lua_functions.h>
#include <lua_config.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

lsb_err_id ZEN_ERR_UTIL_NULL    = "pointer is NULL";
lsb_err_id ZEN_ERR_UTIL_OOM     = "memory allocation failed";
lsb_err_id ZEN_ERR_UTIL_FULL    = "buffer full";
lsb_err_id ZEN_ERR_UTIL_PRANGE  = "parameter out of range";

extern void zen_load_extensions(lsb_lua_sandbox *lsb);
extern void preload_modules(lua_State *lua);
extern void lsb_output_coroutine(lsb_lua_sandbox *lsb, lua_State *lua,
                                 int start, int end, int append);

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
void* memory_manager(void *ud, void *ptr, size_t osize, size_t nsize)
{
  lsb_lua_sandbox *lsb = (lsb_lua_sandbox *)ud;

  void *nptr = NULL;
  if (nsize == 0) {
    free(ptr);
    lsb->usage[LSB_UT_MEMORY][LSB_US_CURRENT] -= osize;
  } else {
    size_t new_state_memory =
        lsb->usage[LSB_UT_MEMORY][LSB_US_CURRENT] + nsize - osize;
    if (0 == lsb->usage[LSB_UT_MEMORY][LSB_US_LIMIT]
        || new_state_memory
        <= lsb->usage[LSB_UT_MEMORY][LSB_US_LIMIT]) {
      nptr = realloc(ptr, nsize);
      if (nptr != NULL) {
        lsb->usage[LSB_UT_MEMORY][LSB_US_CURRENT] =
            new_state_memory;
        if (lsb->usage[LSB_UT_MEMORY][LSB_US_CURRENT]
            > lsb->usage[LSB_UT_MEMORY][LSB_US_MAXIMUM]) {
          lsb->usage[LSB_UT_MEMORY][LSB_US_MAXIMUM] =
              lsb->usage[LSB_UT_MEMORY][LSB_US_CURRENT];
        }
      }
    }
  }
  return nptr;
}

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

// TODO: remove all logger (...and remove lsb)
void zen_logger(void *context, const char *component,
                   int level, const char *fmt, ...) {
	// suppress warnings about these unused paraments
	(void)component;
	(void)context;
	(void)level;

	char out[MAX_STRING];
	size_t len;
	va_list args;
	va_start(args, fmt);
	vsnprintf(out,MAX_STRING,fmt,args);
	va_end(args);
	len = strlen(out);

#ifdef __EMSCRIPTEN__
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
#endif
	fwrite(out, 1, len, stdout);
	fflush(stdout);
}


lsb_lua_sandbox *zen_init(const char *conf) {
	lsb_lua_sandbox *lsb = NULL;

	lsb_logger lsb_zen_logger = { .context = "zenroom",
	                              .cb = zen_logger };

	lsb = calloc(1, sizeof(*lsb));
	if (!lsb) {
		zen_logger("zen_init", __func__, 3,
		            "memory allocation failed");
		return NULL;
	}
	lsb->logger = lsb_zen_logger;
	lsb->lua = lua_newstate(memory_manager, lsb);
	if(!lsb->lua) {
		zen_logger("zen_init", __func__, 3,
		            "lua state creation failed");
		free(lsb);
		return NULL;
	}

	// add the config to the lsb_config registry table
	lua_State *lua_cfg = load_zen_config(conf, &lsb->logger);
	if (!lua_cfg) {
		lua_close(lsb->lua);
		free(lsb);
		return NULL;
	}
	lua_pushnil(lua_cfg);
	lua_pushvalue(lua_cfg, LUA_GLOBALSINDEX);
	copy_table(lsb->lua, lua_cfg, &lsb->logger);
	lua_pop(lua_cfg, 2);
	lua_close(lua_cfg);
	size_t ml = get_size(lsb->lua, -1, LSB_MEMORY_LIMIT);
	size_t il = get_size(lsb->lua, -1, LSB_INSTRUCTION_LIMIT);
	size_t ol = get_size(lsb->lua, -1, LSB_OUTPUT_LIMIT);
	// TODO: reactivate limits
	// size_t log_level = get_size(lsb->lua, -1, LSB_LOG_LEVEL);
	lua_setfield(lsb->lua, LUA_REGISTRYINDEX, LSB_CONFIG_TABLE);
	lua_pushlightuserdata(lsb->lua, lsb);
	lua_setfield(lsb->lua, LUA_REGISTRYINDEX, LSB_THIS_PTR);
	lua_pushcfunction(lsb->lua, &read_config);
	lua_setglobal(lsb->lua, "read_config");
	lsb->usage[LSB_UT_MEMORY][LSB_US_LIMIT] = ml;
	lsb->usage[LSB_UT_INSTRUCTION][LSB_US_LIMIT] = il;
	lsb->usage[LSB_UT_OUTPUT][LSB_US_LIMIT] = ol;
	lsb->state = LSB_UNKNOWN;
	lsb->error_message[0] = 0;
	lsb->state_file = NULL;

	lsb->output.maxsize = MAX_MEMORY;
	lsb->output.size    = MAX_STRING;
	lsb->output.pos     = 0;
	lsb->output.buf     = malloc(MAX_MEMORY);

	// initialise global variables
	lsb_setglobal_string(lsb, "VERSION", VERSION);

	preload_modules(lsb->lua);
	//////////////////// end of create

	// load package module
	lua_pushcfunction(lsb->lua, luaopen_package);
	lua_pushstring(lsb->lua, LUA_LOADLIBNAME);
	lua_call(lsb->lua, 1, 1);
	lua_newtable(lsb->lua);
	lua_setmetatable(lsb->lua, -2);
	lua_pop(lsb->lua, 1);

	lua_pushlightuserdata(lsb->lua, lsb);
	lua_setfield(lsb->lua, LUA_REGISTRYINDEX, LSB_THIS_PTR);

	lua_getglobal(lsb->lua, "require");
	if(!lua_iscfunction(lsb->lua, -1)) {
		error("LUA init: function 'require' not found");
		return NULL; }
	lua_pushstring(lsb->lua, LUA_BASELIBNAME);
	if(lua_pcall(lsb->lua, 1, 0, 0)) {
		error("LUA init: cannot load base library");
		return NULL; }

	return(lsb);

}

int zen_teardown(lsb_lua_sandbox *lsb) {
	char *p;
	lua_State *lua = lsb_get_lua(lsb);

	notice("Zenroom console quit.");
    if(lua) lua_gc(lua, LUA_GCCOLLECT, 0);

	lsb_pcall_teardown(lsb);
	lsb_stop_sandbox_clean(lsb);
	p = lsb_destroy(lsb);
	if(p) {
		error(p);
		free(p);
	}
	return(0);
}

int zen_exec_line(lsb_lua_sandbox *lsb, const char *line) {
	int ret;
	lua_State* lua = lsb_get_lua(lsb);

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
	lua_State* lua = lsb_get_lua(lsb);

	ret = luaL_dostring(lua, script);
    lua_gc(lua, LUA_GCCOLLECT, 0);
	if(ret) {
		error("%s", lua_tostring(lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}
