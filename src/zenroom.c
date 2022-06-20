/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2020 Dyne.org foundation
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

#include <zen_error.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <lua_functions.h>
#include <repl.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#include <zenroom.h>
#include <zen_memory.h>

// hex2oct used to import hex sequence into rng seed
#include <encoding.h>

// alternative print functions
#define STB_SPRINTF_IMPLEMENTATION 1
#define STB_SPRINTF_NOFLOAT 1
#define STB_SPRINTF_DECORATE(name) z_##name
#include <stb_sprintf.h>
#include <mutt_sprintf.h>

// zstd
#include <zstd.h>

// prototypes from zen_octet.c
extern void push_buffer_to_octet(lua_State *L, char *p, size_t len);

// prototypes from lua_modules.c
extern int zen_require_override(lua_State *L, const int restricted);
extern int zen_lua_init(lua_State *L);

// prototypes from zen_io.c
extern void zen_add_io(lua_State *L);
// prototypes from zen_parse.c
extern void zen_add_parse(lua_State *L);
// prototype from zen_config.c
extern int zen_conf_parse(zenroom_t *ZZ, const char *configuration);

// prototypes from zen_memory.c
// extern zen_mem_t *libc_memory_init();
#ifdef USE_JEMALLOC
extern zen_mem_t *jemalloc_memory_init();
#endif
extern void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);

// prototypes from lua_functions.c
extern int zen_setenv(lua_State *L, char *key, char *val);
extern void zen_add_function(lua_State *L, lua_CFunction func,
		const char *func_name);

// prototype from zen_random.c
extern void* rng_alloc();
extern void zen_add_random(lua_State *L);

//////////////////////////////////////////////////////////////

int zen_lua_panic (lua_State *L) {
	lua_writestringerror("PANIC: unprotected error in call to Lua API (%s)\n",
	                     lua_tostring(L, -1));
	return 0;  /* return to Lua to abort */
}

int zen_init_pmain(lua_State *L) { // protected mode init

	// Set zenroom context as a global in lua
	// this will be freed on lua_close
	// lua_pushlightuserdata(L, Z);
	// lua_setglobal(L, "_Z");

	// initialise global variables
#if defined(VERSION)
	zen_setenv(L, "VERSION", VERSION);
	act(NULL,"Release version: %s", VERSION);
#endif
#if defined(COMMIT)
	zen_setenv(L, "COMMIT", COMMIT);
	act(NULL,"Build commit hash: %s", COMMIT);
#endif
#if defined(BRANCH)
	zen_setenv(L, "BRANCH", BRANCH);
	func(NULL,"Build branch: %s", BRANCH);
#endif
#if defined(ARCH)
	zen_setenv(L, "ARCH", ARCH);
	func(NULL,"Build architecture: %s", ARCH);
#endif
#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)
#if defined(MAKETARGET)
	zen_setenv(L, "MAKETARGET", MAKETARGET);
	func(NULL,"Build target: %s", MAKETARGET);
#endif
#if defined(CFLAGS)
	zen_setenv(L, "CFLAGS", STRINGIZE_VALUE_OF(CFLAGS));
	func(NULL,"Build CFLAGS: %s", STRINGIZE_VALUE_OF(CFLAGS));
#endif
#if defined(GITLOG)
	zen_setenv(L, "GITLOG", GITLOG);
#endif

	// open all standard lua libraries
	luaL_openlibs(L);
	// load our own openlibs and extensions
	zen_add_io(L);
	zen_add_parse(L);

	zen_add_random(L);

	zen_require_override(L,0);
	if(!zen_lua_init(L)) {
		zerror(L, "Initialisation of lua scripts failed");
		return(LUA_ERRRUN);
	}
	return(LUA_OK);
}

#include <lstate.h>
// initializes globals: Z, L (in this order)
// zen_init_pmain is the Lua routine executed in protected mode
zenroom_t *zen_init(const char *conf, char *keys, char *data) {
	zenroom_t *ZZ = (zenroom_t*)malloc(sizeof(zenroom_t));

	// create the zenroom_t global context
	ZZ->stdout_buf = NULL;
	ZZ->stdout_pos = 0;
	ZZ->stdout_len = 0;
	ZZ->stdout_full = 0;
	ZZ->stderr_buf = NULL;
	ZZ->stderr_pos = 0;
	ZZ->stderr_len = 0;
	ZZ->stderr_full = 0;
	ZZ->userdata = NULL;
	ZZ->errorlevel = 0;
	ZZ->debuglevel = 2;
	ZZ->random_generator = NULL;
	ZZ->random_external = 0;
	ZZ->zstd_c = NULL;
	ZZ->zstd_d = NULL;
	// set zero rngseed as config flag
	ZZ->zconf_rngseed[0] = '\0';
	ZZ->zconf_printf = LIBC;
	ZZ->exitcode = 1; // success

	if(conf) {
		if( ! zen_conf_parse(ZZ, conf) ) { // stb parsing
			zerror(NULL, "Fatal error");
			return(NULL);
		}
	}

	switch(ZZ->zconf_printf) {
	case STB:
		ZZ->sprintf = &z_sprintf;
		ZZ->snprintf = &z_snprintf;
		ZZ->vsprintf = &z_vsprintf;
		ZZ->vsnprintf = &z_vsnprintf;
		act(NULL,"STB print functions in use");
		break;
	case MUTT:
		ZZ->sprintf = &sprintf; // TODO: mutt based
		ZZ->vsprintf = &vsprintf;
		ZZ->snprintf = &mutt_snprintf;
		ZZ->vsnprintf = &mutt_vsnprintf;
		act(NULL,"MUTT print functions in use");
		break;
	default: // LIBC_PRINTF
		ZZ->sprintf = &sprintf;
		ZZ->snprintf = &snprintf;
		ZZ->vsprintf = &vsprintf;
		ZZ->vsnprintf = &vsnprintf;
		func(NULL,"LIBC print functions in use");
		break;
	}

	// use RNGseed from configuration if present (deterministic mode)
	if(ZZ->zconf_rngseed[0] != 0x0) {
		ZZ->random_external = 1;
		memset(ZZ->random_seed, 0x0, RANDOM_SEED_LEN);
		int len = hex2buf(ZZ->random_seed, ZZ->zconf_rngseed);
		func(NULL, "RNG seed converted from hex to %u bytes", len);
	} else {
		func(NULL, "RNG seed not found in configuration");
	}
	// initialize the random generator
	ZZ->random_generator = rng_alloc(ZZ);

	// initialize Lua's context
	ZZ->lua = lua_newstate(zen_memory_manager, ZZ);
	if(!ZZ->lua) {
		zerror(NULL,"%s: %s", __func__, "Lua newstate creation failed");
		zen_teardown(ZZ);
		return NULL;
	}

	// expose the debug level
	lua_pushinteger(ZZ->lua, ZZ->debuglevel);
	lua_setglobal (ZZ->lua, "DEBUG");

	lua_atpanic(ZZ->lua, &zen_lua_panic); // as done in lauxlib luaL_newstate
	lua_pushcfunction(ZZ->lua, &zen_init_pmain);  /* to call in protected mode */
	int status = lua_pcall(ZZ->lua, 0,   1,  0);

	if(status != LUA_OK) {
		char *_err = (status == LUA_ERRRUN) ? "Runtime error at initialization" :
			(status == LUA_ERRMEM) ? "Memory allocation error at initalization" :
			(status == LUA_ERRERR) ? "Error handler fault at initalization" :
			"Unknown error at initalization";
		zerror(ZZ->lua, "%s: %s\n    %s", __func__, _err,
		      lua_tostring(ZZ->lua, 1)); // lua's traceback string
		zen_teardown(ZZ);
		return NULL;
	}

	lua_gc(ZZ->lua, LUA_GCCOLLECT, 0);
	lua_gc(ZZ->lua, LUA_GCCOLLECT, 0);
	act(ZZ->lua,"Memory in use: %u KB",
	    lua_gc(ZZ->lua,LUA_GCCOUNT,0));
	// uncomment to restrict further requires
	// zen_require_override(L,1);

	// expose the random seed for optional determinism
	push_buffer_to_octet(ZZ->lua, ZZ->random_seed, RANDOM_SEED_LEN);
	lua_setglobal(ZZ->lua, "RNGSEED");

	// load arguments if present
	if(data) {
		func(ZZ->lua, "declaring global: DATA");
		zen_setenv(ZZ->lua,"DATA",data);
	}
	if(keys) {
		func(ZZ->lua, "declaring global: KEYS");
		zen_setenv(ZZ->lua,"KEYS",keys);
	}
	return(ZZ);
}

void zen_teardown(zenroom_t *ZZ) {
	notice(NULL,"Zenroom teardown.");
	act(NULL,"Memory used: %u KB",
	    lua_gc(ZZ->lua,LUA_GCCOUNT,0));

	// stateful RNG instance for deterministic mode
	if(ZZ->random_generator) {
		zen_memory_free(ZZ->random_generator);
		ZZ->random_generator = NULL;
	}

	// save pointers inside Z to free after L and Z
	if(ZZ->lua) {
		func(NULL, "lua gc and close...");
		lua_gc((lua_State*)ZZ->lua, LUA_GCCOLLECT, 0);
		lua_gc((lua_State*)ZZ->lua, LUA_GCCOLLECT, 0);
		// this call here frees also Z (lightuserdata)
		lua_close((lua_State*)ZZ->lua);
		ZZ->lua = NULL;
	}

	// TODO: remove zstd header by segregating it to zen_io
	// teardown
	if(ZZ->zstd_c) {
	  ZSTD_freeCCtx(ZZ->zstd_c);
	  ZZ->zstd_c = NULL;
	}
	if(ZZ->zstd_d) {
	  ZSTD_freeDCtx(ZZ->zstd_d);
	  ZZ->zstd_d = NULL;
	}
	free(ZZ);
}

int zen_exec_zencode(zenroom_t *ZZ, const char *script) {
	if(!ZZ) {
		zerror(NULL,"%s: Zenroom context is NULL.");
		return ERR_INIT; }

	if(!ZZ->lua) {
		zerror(NULL, "%s: Zenroom context not initialised.");
		ZZ->exitcode = ERR_INIT;
		return ZZ->exitcode; }
	int ret;
	char *zscript = malloc(MAX_ZENCODE);
	lua_State* L = (lua_State*)ZZ->lua;
	// introspection on code being executed
	(*ZZ->snprintf)(zscript,MAX_ZENCODE-1,
	        "local _res, _err\n"
		"_res, _err = pcall( function() ZEN:begin() end)\n"
		"if not _res then exitcode(4) ZEN.OK = false error('INIT: '.._err,2) end\n"
		"_res, _err = pcall( function() ZEN:parse([[\n%s\n]]) end)\n"
		"if not _res then exitcode(3) ZEN.OK = false error('PARSE: '.._err,2) end\n"
		"_res, _err = pcall( function() ZEN:run() end)\n"
		"if not _res then exitcode(2) ZEN.OK = false error('EXEC: '.._err,2) end\n"
		, script);
	zen_setenv(L,"CODE",(char*)zscript);
	ret = luaL_dostring(L, zscript);
	free(zscript);
	if(ret == SUCCESS) {
	  notice(L, "Script successfully executed");
	} else {
	  zerror(L, "ERROR:");
	  zerror(L, "%s", lua_tostring(L, -1));
	  zerror(L, "Execution aborted");
  	  ZZ->exitcode = ZZ->exitcode==SUCCESS ? ERR_GENERIC : ZZ->exitcode;
	}
	return ZZ->exitcode;
}

int zen_exec_script(zenroom_t *ZZ, const char *script) {
	if(!ZZ) {
		zerror(NULL,"%s: Zenroom context is NULL.");
		return ERR_INIT; }
	if(!ZZ->lua) {
		zerror(NULL, "%s: Zenroom context not initialised.");
		return ERR_INIT; }
	int ret;
	lua_State* L = (lua_State*)ZZ->lua;
	// introspection on code being executed
	zen_setenv(L,"CODE",(char*)script);
	ret = luaL_dostring(L, script);
	if(ret == SUCCESS) {
	  notice(L, "Script successfully executed");
	  ZZ->exitcode = SUCCESS;
	} else {
	  zerror(L, "ERROR:");
	  zerror(L, "%s", lua_tostring(L, -1));
	  zerror(L, "Execution aborted");
	  ZZ->exitcode = ZZ->exitcode==SUCCESS ? ERR_GENERIC : ZZ->exitcode;
	}
	return ZZ->exitcode;
}

int _check_script_arg(char *s) {
  if(!s) {
    zerror(NULL, "NULL string as script argument");
    zerror(NULL, "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort(););
#endif
    return ERR_INIT;
  }
  if(s[0] == '\0') {
    zerror(NULL, "Empty string as script argument");
    zerror(NULL, "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort(););
#endif
    return ERR_INIT;
  }
  return SUCCESS;
}

int _check_zenroom_init(zenroom_t *zz) {
  if(!zz) {
    zerror(NULL, "Zenroom initialisation failed.");
    zerror(NULL, "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort());
#endif
    return ERR_INIT;
  }
  if(!zz->lua) {
    zerror(NULL, "Lua initialisation failed.");
    zen_teardown(zz);
    zerror(NULL, "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort());
#endif
    return ERR_INIT;
  }
  return SUCCESS;
}

int _check_zenroom_result(zenroom_t *zz, int res) {
  register int exitcode;
  if(res != SUCCESS) {
    zerror(zz->lua, "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort());
#endif
  } else {
    act(zz->lua, "Zenroom execution completed.");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_ok();});
#endif
  }
  exitcode = zz->exitcode;
  zen_teardown(zz);
  return(exitcode);
}

int zencode_exec(char *script, char *conf, char *keys, char *data) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	zenroom_t *Z = zen_init(c, k, d);

	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;

	return( _check_zenroom_result(Z, zen_exec_zencode(Z, script) ));
}

int zenroom_exec(char *script, char *conf, char *keys, char *data) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;

	zenroom_t *Z = zen_init(c, k, d);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;

	return( _check_zenroom_result(Z, zen_exec_script(Z, script) ));
}

int zencode_exec_tobuf(char *script, char *conf, char *keys, char *data,
		char *stdout_buf, size_t stdout_len,
		char *stderr_buf, size_t stderr_len) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;

	zenroom_t *Z = zen_init(c, k, d);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;

	return( _check_zenroom_result(Z, zen_exec_zencode(Z, script) ));
}


int zenroom_exec_tobuf(char *script, char *conf, char *keys, char *data,
		char *stdout_buf, size_t stdout_len,
		char *stderr_buf, size_t stderr_len) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;

	zenroom_t *Z = zen_init(c, k, d);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;

	return( _check_zenroom_result(Z, zen_exec_script(Z, script) ));
}

