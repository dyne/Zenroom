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
#include <linenoise.h>

// #include <bitop.h>
// #include <luazen.h>

#include <luasandbox.h>
#include <luasandbox/lua.h>
#include <luasandbox/lualib.h>
#include <luasandbox/util/util.h>
#include <luasandbox/util/output_buffer.h>

#include <luasandbox/lauxlib.h>

extern int lua_cjson_safe_new(lua_State *l);
extern int lua_cjson_new(lua_State *l);


struct lsb_lua_sandbox {
	lua_State         *lua;
	void              *parent;
	char              *lua_file;
	char              *state_file;
	lsb_logger        logger;
	lsb_state         state;
	lsb_output_buffer output;
	size_t            usage[LSB_UT_MAX][LSB_US_MAX];
	char              error_message[LSB_ERROR_SIZE];
};

void* memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);
extern void preload_modules(lua_State *lua);


int repl_print(lua_State *L) {
	const char *str = luaL_checkstring(L, 1);
	fprintf(stdout,"--\n%s\n--",str);
	fflush(stdout);
	return 1;
}
	


void repl_logger(void *context, const char *component,
                   int level, const char *fmt, ...) {
	// suppress warnings about these unused paraments
	(void)context;
	(void)level;

	va_list args;
	va_start(args, fmt);
	vfprintf(stderr, fmt, args);
	va_end(args);
	fwrite("\n", 1, 1, stderr);
	fflush(stderr);
}

lsb_logger lsb_repl_logger = { .context = "repl",
                               .cb = repl_logger };

lsb_lua_sandbox *repl_init(char *conf) {
	lsb_lua_sandbox *lsb = NULL;
	const luaL_Reg *lib;

	lsb = calloc(1, sizeof(*lsb));
	if (!lsb) {
		repl_logger("init_repl", __func__, 3,
		            "memory allocation failed");
		return NULL;
	}
	lsb->logger = lsb_repl_logger;
	lsb->lua = lua_newstate(memory_manager, lsb);
	if(!lsb->lua) {
		repl_logger("init_repl", __func__, 3,
		            "lua state creation failed");
		free(lsb);
		return NULL;
	}

	// // load our own extensions
	// lib = (luaL_Reg*) &luazen;
	// func("loading luazen extensions");
	// for (; lib->func; lib++) {
	// 	func("%s",lib->name);
	// 	lsb_add_function(lsb, lib->func, lib->name);
	// }
	// lib = (luaL_Reg*) &bit_funcs;
	// func("loading bitop extensions");
	// for (; lib->func; lib++) {
	// 	func("%s",lib->name);
	// 	lsb_add_function(lsb, lib->func, lib->name);
	// }
	func("loading cjson extensions");
	lsb_add_function(lsb, lua_cjson_new, "cjson");
	lsb_add_function(lsb, lua_cjson_safe_new, "cjson_safe");

	// load package module
	lua_pushcfunction(lsb->lua, luaopen_package);
	lua_pushstring(lsb->lua, LUA_LOADLIBNAME);
	lua_call(lsb->lua, 1, 1);
	lua_newtable(lsb->lua);
	lua_setmetatable(lsb->lua, -2);
	lua_pop(lsb->lua, 1);

	preload_modules(lsb->lua);

	linenoiseHistorySetMaxLen(1024);
    linenoiseSetMultiLine(1);

    lsb_add_function(lsb, repl_print, "print");

	return(lsb);

}

int repl_teardown(lsb_lua_sandbox *lsb) {
	char *p;

	notice("Zenroom console quit.");

	lsb_pcall_teardown(lsb);
	lsb_stop_sandbox_clean(lsb);
	p = lsb_destroy(lsb);
	if(p) {
		error(p);
		free(p);
	}
	return(1);
}

int repl_exec(lsb_lua_sandbox *lsb, const char *line) {
	int ret;

	if (!lsb) return -1;

	ret = luaL_loadstring(lsb->lua, line);
	linenoiseHistoryAdd(line);
	// lua_gc(lsb->lua, LUA_GCCOLLECT, 0);
	if(ret != 0) {
		error("%s", lua_tostring(lsb->lua, -1));
		fflush(stderr);
		return ret;
	} // else
	  //   lsb->state = LSB_RUNNING;

	return 0;
}


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

