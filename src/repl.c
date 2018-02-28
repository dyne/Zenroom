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
#include <jutils.h>
#include <zenroom.h>
#include <linenoise.h>

#include <luasandbox.h>
#include <luasandbox/lua.h>
#include <luasandbox/lualib.h>
#include <luasandbox/lauxlib.h>
#include <luasandbox/util/util.h>
#include <luasandbox/util/output_buffer.h>

extern void completion(const char *buf, linenoiseCompletions *lc);

extern void lsb_load_extensions(lsb_lua_sandbox *lsb);

extern int lua_cjson_safe_new(lua_State *l);
extern int lua_cjson_new(lua_State *l);

// extern unsigned int  cheatsheet_len;
// extern unsigned char cheatsheet[];

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

static const luaL_Reg preload_module_list[] = {
  { LUA_BASELIBNAME, luaopen_base },
  { LUA_TABLIBNAME, luaopen_table },
  { LUA_STRLIBNAME, luaopen_string },
  { LUA_MATHLIBNAME, luaopen_math },
  { NULL, NULL }
};

// int print_help(lua_State *lua) {
// 	(void)lua;
// 	fwrite(cheatsheet,sizeof(unsigned char),cheatsheet_len,stdout);
// 	fflush(stdout);
// 	return 1;
// }

static int libsize(const luaL_Reg *l)
{
  int size = 0;
  for (; l->name; l++) size++;
  return size;
}

static void preload_modules(lua_State *lua)
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

extern void lsb_output_coroutine(lsb_lua_sandbox *lsb, lua_State *lua,
                                 int start, int end, int append);

static int output(lua_State *lua)
{
  lua_getfield(lua, LUA_REGISTRYINDEX, LSB_THIS_PTR);
  lsb_lua_sandbox *lsb = lua_touserdata(lua, -1);
  lua_pop(lua, 1); // remove this ptr
  if (!lsb)
	  return(luaL_error(lua, "%s() invalid " LSB_THIS_PTR, __func__));

  int n = lua_gettop(lua);
  if (n == 0) {
    return luaL_argerror(lsb->lua, 0, "must have at least one argument");
  }
  lsb_output_coroutine(lsb, lua, 1, n, 1);
  return 0;
}


int output_print(lua_State *lua)
{
  lua_getfield(lua, LUA_REGISTRYINDEX, LSB_THIS_PTR);
  lsb_lua_sandbox *lsb = lua_touserdata(lua, -1);
  lua_pop(lua, 1); // remove this ptr
  if (!lsb) return luaL_error(lua, "print() invalid " LSB_THIS_PTR);

  lsb->output.buf[0] = 0;
  lsb->output.pos = 0; // clear the buffer

  int n = lua_gettop(lua);
  if (!lsb->logger.cb || n == 0) {
    return 0;
  }

  lua_getglobal(lua, "tostring");
  int i;
  for (i = 1; i <= n; ++i) {
    lua_pushvalue(lua, -1);  // tostring
    lua_pushvalue(lua, i);   // value
    lua_call(lua, 1, 1);
    const char *s = lua_tostring(lua, -1);
    if (s == NULL) {
      return luaL_error(lua, LUA_QL("tostring") " must return a string to "
                        LUA_QL("print"));
    }
    if (i > 1) {
      lsb_outputc(&lsb->output, '\t');
    }

    while (*s) {
      // if (isprint(*s)) {
        lsb_outputc(&lsb->output, *s);
      // } else {
      //   lsb_outputc(&lsb->output, ' ');
      // }
      ++s;
    }
    lua_pop(lua, 1);
  }

  const char *component = NULL;
  lua_getfield(lua, LUA_REGISTRYINDEX, LSB_CONFIG_TABLE);
  if (lua_type(lua, -1) == LUA_TTABLE) {
    // this makes an assumptions by looking for a Heka sandbox specific cfg
    // variable but will fall back to the lua filename in the generic case
    lua_getfield(lua, -1, "Logger");
    component = lua_tostring(lua, -1);
    if (!component) {
      component = lsb->lua_file;
    }
  }

  lsb->logger.cb(lsb->logger.context, component, 7, "%s", lsb->output.buf);
  lsb->output.pos = 0;
  return 0;
}


void* memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);

void repl_logger(void *context, const char *component,
                   int level, const char *fmt, ...) {
	// suppress warnings about these unused paraments
	(void)component;
	(void)context;
	(void)level;

	va_list args;
	va_start(args, fmt);
	vfprintf(stdout, fmt, args);
	va_end(args);
	fwrite("\n", 1, 1, stdout);
	fflush(stdout);
}

lsb_lua_sandbox *repl_init() {
	lsb_lua_sandbox *lsb = NULL;

	lsb_logger lsb_repl_logger = { .context = "repl",
	                               .cb = repl_logger };

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

	lsb->output.maxsize = MAX_FILE;
	lsb->output.size    = MAX_STRING;
	lsb->output.pos     = 0;
	lsb->output.buf     = malloc(MAX_STRING);
	lua_pushcfunction(lsb->lua, &output);
	lua_setglobal(lsb->lua, "output");

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

	// load our own extensions
	lsb_load_extensions(lsb);

	// print function
	lsb_add_function(lsb, output_print, "print");
	// help function
	// lsb_add_function(lsb, print_help "help");

	func("loading cjson extensions");
	lsb_add_function(lsb, lua_cjson_new, "cjson");
	lsb_add_function(lsb, lua_cjson_safe_new, "cjson_safe");

	linenoiseHistorySetMaxLen(1024);
    linenoiseSetMultiLine(1);
    linenoiseSetCompletionCallback(completion);

    notice("Interactive REPL console.");
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

int repl_exec(lua_State* lua, const char *line) {
	int ret;
	ret = luaL_dostring(lua, line);
	linenoiseHistoryAdd(line);
	if(ret != 0) {
		error("%s", lua_tostring(lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}

void repl_loop(lsb_lua_sandbox *lsb) {
	static const char *line;
	if(!lsb) return;
	lua_State* L = lsb_get_lua(lsb);
	if(!L) return;
	char prompt[6] = "zen> \0";
	int ret;
	while((line = linenoise(prompt)) != NULL) {
		ret = repl_exec(L, line);
		if(ret != 0) prompt[3]='!';
		else prompt[3]='>';
		linenoiseFree((void *)line);
	}
	lua_gc(L, LUA_GCCOLLECT, 0);
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

