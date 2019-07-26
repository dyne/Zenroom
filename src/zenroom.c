/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2019 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#if (defined ARCH_LINUX) || (defined ARCH_OSX) || (defined ARCH_BSD)
#include <sys/types.h>
#include <sys/wait.h>
#endif


#include <errno.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>

#include <lua_functions.h>
#include <repl.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#include <zenroom.h>
#include <zen_memory.h>

// prototypes from lua_modules.c
extern int zen_require_override(lua_State *L, const int restricted);
extern int zen_lua_init(lua_State *L);

// prototypes from zen_io.c
extern void zen_add_io(lua_State *L);

// prototypes from zen_memory.c
extern zen_mem_t *libc_memory_init();
#ifdef USE_JEMALLOC
extern zen_mem_t *jemalloc_memory_init();
#endif
extern zen_mem_t *umm_memory_init(size_t size);
extern void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);
extern void *umm_info(void*);
extern int umm_integrity_check();

// prototypes from lua_functions.c
extern void load_file(char *dst, FILE *fd);
extern void zen_setenv(lua_State *L, char *key, char *val);
extern void zen_add_function(lua_State *L, lua_CFunction func,
		const char *func_name);

// single instance globals
zenroom_t *Z = NULL;   // zenroom STACK
zen_mem_t *MEM = NULL; // zenroom HEAP

static int zen_lua_panic (lua_State *L) {
	lua_writestringerror("PANIC: unprotected error in call to Lua API (%s)\n",
	                     lua_tostring(L, -1));
	return 0;  /* return to Lua to abort */
}

static int zen_init_pmain(lua_State *L) { // protected mode init
	// create the zenroom_t global context
	Z = (zenroom_t*)system_alloc(sizeof(zenroom_t));
	Z->lua = L;
	Z->mem = MEM;
	Z->stdout_buf = NULL;
	Z->stdout_pos = 0;
	Z->stdout_len = 0;
	Z->stderr_buf = NULL;
	Z->stderr_pos = 0;
	Z->stderr_len = 0;
	Z->userdata = NULL;
	Z->errorlevel = get_debug();
	Z->random_generator = NULL;
	Z->random_seed = NULL;
	Z->random_seed_len = 0;

	//Set zenroom context as a global in lua
	//this will be freed on lua_close
	lua_pushlightuserdata(L, Z);
	lua_setglobal(L, "_Z");

	// initialise global variables
#if defined(VERSION)
	zen_setenv(L, "VERSION", VERSION);
#endif
#if defined(ARCH)
	zen_setenv(L, "ARCH", ARCH);
#endif
#if defined(GITLOG)
	zen_setenv(L, "GITLOG", GITLOG);
#endif

	// open all standard lua libraries
	luaL_openlibs(L);
	// load our own openlibs and extensions
	zen_add_io(L);
	zen_require_override(L,0);
	if(!zen_lua_init(L)) {
		error(L,"%s: %s", __func__, "initialisation of lua scripts failed");
		return(LUA_ERRRUN);
	}
	return(LUA_OK);
}

zenroom_t *zen_init(const char *conf, char *keys, char *data) {
	(void) conf;
	lua_State *L = NULL;
	if(conf) {
		if(strcasecmp(conf,"umm")==0)
			MEM = umm_memory_init(UMM_HEAP); // (64KiB)
	} else {
#ifdef USE_JEMALLOC
		MEM = jemalloc_memory_init();
#else
		MEM = libc_memory_init();
#endif
	}
	L = lua_newstate(zen_memory_manager, MEM);
	if(!L) {
		error(L,"%s: %s", __func__, "Lua newstate creation failed");
		return NULL;
	}
	lua_atpanic(L, &zen_lua_panic); // as done in lauxlib luaL_newstate
	lua_pushcfunction(L, &zen_init_pmain);  /* to call in protected mode */
	lua_pushinteger(L, 0);  /* 1st argument */
	lua_pushlightuserdata(L, NULL); /* 2nd argument */
	int status = lua_pcall(L,2,1,0);
	if(status != LUA_OK) {
		error(L,"%s: %s (%u)", __func__, "Lua initialization failed",status);
		return NULL;
	}
	lua_gc(L, LUA_GCCOLLECT, 0);
	lua_gc(L, LUA_GCCOLLECT, 0);

	// uncomment to restrict further requires
	// zen_require_override(L,1);

	// load arguments if present
	if(data) {
		func(L, "declaring global: DATA");
		zen_setenv(L,"DATA",data);
	}
	if(keys) {
		func(L, "declaring global: KEYS");
		zen_setenv(L,"KEYS",keys);
	}
	return Z;
}


void zen_teardown(zenroom_t *Z) {

	func(Z->lua,"Zenroom teardown.");
	if(Z->mem->heap) {
		if(umm_integrity_check())
			func(Z->lua,"HEAP integrity checks passed.");
		umm_info(Z->mem->heap); }
	// stateful RNG instance for deterministic mode
	if(Z->random_generator) {
		zen_memory_free(Z->random_generator);
		Z->random_generator = NULL;
	}
	// save pointers inside Z to free after L and Z
	if(Z->lua) {
		func(Z->lua, "lua gc and close...");
		lua_gc((lua_State*)Z->lua, LUA_GCCOLLECT, 0);
		lua_gc((lua_State*)Z->lua, LUA_GCCOLLECT, 0);
		// this call here frees also Z (lightuserdata)
		lua_close((lua_State*)Z->lua);
	}
	func(NULL,"zen free");

	if(MEM) {
		if(Z) (*MEM->free)(Z);
		(*MEM->free)(MEM);
		func(NULL,"teardown completed");
		return; }
	warning(NULL,"MEM not found");
	if(Z) free(Z);
}

int zen_exec_zencode(zenroom_t *Z, const char *script) {
	if(!Z) {
		error(NULL,"%s: Zenroom context is NULL.",__func__);
		return 1; }
	if(!Z->lua) {
		error(NULL,"%s: Zenroom context not initialised.",
		      __func__);
		return 1; }
	int ret;
	lua_State* L = (lua_State*)Z->lua;
	// introspection on code being executed
	char zscript[MAX_STRING];
	snprintf(zscript,MAX_STRING-1,
	         "ZEN:begin(%u)\nZEN:parse([[\n%s\n]])\nZEN:run()\n",
	         Z->errorlevel, script);
	zen_setenv(L,"CODE",(char*)zscript);
	ret = luaL_dostring(L, zscript);
	if(ret) {
		error(L, "%s", lua_tostring(L, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}

int zen_exec_script(zenroom_t *Z, const char *script) {
	if(!Z) {
		error(NULL,"%s: Zenroom context is NULL.",__func__);
		return 1; }
	if(!Z->lua) {
		error(NULL,"%s: Zenroom context not initialised.",
				__func__);
		return 1; }
	int ret;
	lua_State* L = (lua_State*)Z->lua;
	// introspection on code being executed
	zen_setenv(L,"CODE",(char*)script);
	ret = luaL_dostring(L, script);
	if(ret) {
		error(L, "%s", lua_tostring(L, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}


int zencode_exec(char *script, char *conf, char *keys,
		char *data, int verbosity) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	zenroom_t *Z = NULL;
	lua_State *L = NULL;
	int return_code = EXIT_FAILURE; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		return EXIT_FAILURE; }
	if(script[0] == '\0') {
		error(L, "Empty string as script for zenroom_exec()");
		return EXIT_FAILURE; }

	set_debug(verbosity);

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	Z = zen_init(c, k, d);
	if(!Z) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }
	L = (lua_State*)Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }

	r = zen_exec_zencode(Z, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
		//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return EXIT_FAILURE;
	}
	return_code = EXIT_SUCCESS; // return success

#ifdef __EMSCRIPTEN__
	EM_ASM({Module.exec_ok();});
#endif

	func(L, "Zenroom operations completed.");
	zen_teardown(Z);
	return(return_code);
}

int zenroom_exec(char *script, char *conf, char *keys,
		char *data, int verbosity) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	zenroom_t *Z = NULL;
	lua_State *L = NULL;
	int return_code = EXIT_FAILURE; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		return EXIT_FAILURE; }
	if(script[0] == '\0') {
		error(L, "Empty string as script for zenroom_exec()");
		return EXIT_FAILURE; }

	set_debug(verbosity);

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	Z = zen_init(c, k, d);
	if(!Z) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }
	L = (lua_State*)Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }

	r = zen_exec_script(Z, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
		//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return EXIT_FAILURE;
	}
	return_code = EXIT_SUCCESS; // return success

#ifdef __EMSCRIPTEN__
	EM_ASM({Module.exec_ok();});
#endif

	func(L, "Zenroom operations completed.");
	zen_teardown(Z);
	return(return_code);
}



int zencode_exec_tobuf(char *script, char *conf, char *keys,
		char *data, int verbosity,
		char *stdout_buf, size_t stdout_len,
		char *stderr_buf, size_t stderr_len) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	zenroom_t *Z = NULL;
	lua_State *L = NULL;

	int return_code = EXIT_FAILURE; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		return EXIT_FAILURE; }
	if(script[0] == '\0') {
		error(L, "Empty string as script for zenroom_exec()");
		return EXIT_FAILURE; }

	set_debug(verbosity);

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	Z = zen_init(c, k, d);
	if(!Z) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }
	L = (lua_State*)Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;

	r = zen_exec_zencode(Z, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
		//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return EXIT_FAILURE;
	}
	return_code = EXIT_SUCCESS; // return success

#ifdef __EMSCRIPTEN__
	EM_ASM({Module.exec_ok();});
#endif

	func(L, "Zenroom operations completed.");
	zen_teardown(Z);
	return(return_code);
}


int zenroom_exec_tobuf(char *script, char *conf, char *keys,
		char *data, int verbosity,
		char *stdout_buf, size_t stdout_len,
		char *stderr_buf, size_t stderr_len) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	zenroom_t *Z = NULL;
	lua_State *L = NULL;

	int return_code = EXIT_FAILURE; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		return EXIT_FAILURE; }
	if(script[0] == '\0') {
		error(L, "Empty string as script for zenroom_exec()");
		return EXIT_FAILURE; }

	set_debug(verbosity);

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	Z = zen_init(c, k, d);
	if(!Z) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }
	L = (lua_State*)Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;

	r = zen_exec_script(Z, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
		//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return EXIT_FAILURE;
	}
	return_code = EXIT_SUCCESS; // return success

#ifdef __EMSCRIPTEN__
	EM_ASM({Module.exec_ok();});
#endif

	func(L, "Zenroom operations completed.");
	zen_teardown(Z);
	return(return_code);
}


int zenroom_exec_rng_tobuf(char *script, char *conf, char *keys,
                       char *data, int verbosity,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len,
                       char *random_seed, size_t random_seed_len) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	zenroom_t *Z = NULL;
	lua_State *L = NULL;
	char *_random_seed = NULL;
	int return_code = EXIT_FAILURE; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		return EXIT_FAILURE; }
	if(script[0] == '\0') {
		error(L, "Empty string as script for zenroom_exec()");
		return EXIT_FAILURE; }

	set_debug(verbosity);

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	_random_seed = random_seed ? (random_seed[0] == '\0') ? NULL : random_seed : NULL;
	if(!_random_seed) {
		error(NULL, "%s called with empty random seed",__func__);
		return EXIT_FAILURE; }

	Z = zen_init(c, k, d);
	if(!Z) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }
	L = (lua_State*)Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;
	Z->random_seed = _random_seed;
	Z->random_seed_len = random_seed_len;
	// export the random_seed buffer to Lua
	zen_setenv(L, "RANDOM_SEED", Z->random_seed);

	r = zen_exec_script(Z, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
		//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return EXIT_FAILURE;
	}
	return_code = EXIT_SUCCESS; // return success

#ifdef __EMSCRIPTEN__
	EM_ASM({Module.exec_ok();});
#endif

	func(L, "Zenroom operations completed.");
	zen_teardown(Z);
	return(return_code);
}


int zencode_exec_rng_tobuf(char *script, char *conf, char *keys,
                           char *data, int verbosity,
                           char *stdout_buf, size_t stdout_len,
                           char *stderr_buf, size_t stderr_len,
                           char *random_seed, size_t random_seed_len) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	zenroom_t *Z = NULL;
	lua_State *L = NULL;
	char *_random_seed = NULL;
	int return_code = EXIT_FAILURE; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		return EXIT_FAILURE; }
	if(script[0] == '\0') {
		error(L, "Empty string as script for zenroom_exec()");
		return EXIT_FAILURE; }

	set_debug(verbosity);

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	_random_seed = random_seed ? (random_seed[0] == '\0') ? NULL : random_seed : NULL;
	if(!_random_seed) {
		error(NULL, "%s called with empty random seed",__func__);
		return EXIT_FAILURE; }

	Z = zen_init(c, k, d);
	if(!Z) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }
	L = (lua_State*)Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return EXIT_FAILURE; }

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;
	Z->random_seed = _random_seed;
	Z->random_seed_len = random_seed_len;
	// export the random_seed buffer to Lua
	zen_setenv(L, "RANDOM_SEED", Z->random_seed);

	r = zen_exec_zencode(Z, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
		//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return EXIT_FAILURE;
	}
	return_code = EXIT_SUCCESS; // return success

#ifdef __EMSCRIPTEN__
	EM_ASM({Module.exec_ok();});
#endif

	func(L, "Zenroom operations completed.");
	zen_teardown(Z);
	return(return_code);
}
