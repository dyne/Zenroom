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
// #include <stdlib.h>
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

// print functions
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

// prototype from zen_memory.c
extern void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);

// prototypes from lua_functions.c
extern int zen_setenv(lua_State *L, const char *key, const char *val);
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
	act(L,"Release version: %s", VERSION);
#endif
#if defined(COMMIT)
	zen_setenv(L, "COMMIT", COMMIT);
	act(L,"Build commit hash: %s", COMMIT);
#endif
#if defined(BRANCH)
	zen_setenv(L, "BRANCH", BRANCH);
	func(L,"Build branch: %s", BRANCH);
#endif
#if defined(ARCH)
	zen_setenv(L, "ARCH", ARCH);
	func(L,"Build architecture: %s", ARCH);
#endif
#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)
#if defined(MAKETARGET)
	zen_setenv(L, "MAKETARGET", MAKETARGET);
	func(L,"Build target: %s", MAKETARGET);
#endif
#if defined(CFLAGS)
	zen_setenv(L, "CFLAGS", STRINGIZE_VALUE_OF(CFLAGS));
	func(L,"Build CFLAGS: %s", STRINGIZE_VALUE_OF(CFLAGS));
#endif
#if defined(GITLOG)
	zen_setenv(L, "GITLOG", GITLOG);
#endif

#ifdef MIMALLOC
	zen_setenv(L, "MEMMANAGER", "mimalloc");
	act(L,"Memory manager: mimalloc");
#else
	zen_setenv(L, "MEMMANAGER", "libc");
	act(L,"Memory manager: libc");
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
zenroom_t *zen_init(const char *conf, const char *keys, const char *data) {

#ifdef MIMALLOC
  mi_stats_reset();
#endif

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
	ZZ->exitcode = 1; // success
	ZZ->logformat = TEXT;
	ZZ->str_maxiter[0] = '1';
	ZZ->str_maxiter[1] = '0';
	ZZ->str_maxiter[2] = '0';
	ZZ->str_maxiter[3] = '0';
	ZZ->str_maxiter[4] = '\0';
	ZZ->memcount_octets = 0;
	ZZ->memcount_bigs = 0;
	ZZ->memcount_hashes = 0;
	ZZ->memcount_ecp = 0;
	ZZ->memcount_ecp2 = 0;
	ZZ->memcount_floats = 0;
	ZZ->memcount_ecdhs = 0;

	if(conf) {
		if( ! zen_conf_parse(ZZ, conf) ) { // stb parsing
			_err( "Error parsing configuration: %s\n", conf);
			return(NULL);
		}
	}

	// use RNGseed from configuration if present (deterministic mode)
	if(ZZ->zconf_rngseed[0] != 0x0) {
		ZZ->random_external = 1;
		memset(ZZ->random_seed, 0x0, RANDOM_SEED_LEN);
		int len = hex2buf(ZZ->random_seed, ZZ->zconf_rngseed);
		if(ZZ->debuglevel > 2)
		  _err("RNG seed converted from hex to %u bytes\n", len);
	} else {
	  if(ZZ->debuglevel > 2)
		_err("RNG seed not found in configuration\n");
	}

	// initialize the random generator
	ZZ->random_generator = rng_alloc(ZZ);

	// initialize Lua's context
	ZZ->lua = lua_newstate(zen_memory_manager, ZZ);
	if(!ZZ->lua) {
	  _err( "%s: Lua newstate creation failed\n", __func__);
	  zen_teardown(ZZ);
	  return NULL;
	}

	// init log format if needed
	if(ZZ->logformat == JSON) json_start(ZZ->lua);

	// expose the debug level
	lua_pushinteger(ZZ->lua, ZZ->debuglevel);
	lua_setglobal (ZZ->lua, "DEBUG");

	lua_pushstring(ZZ->lua, ZZ->str_maxiter);
	lua_setglobal (ZZ->lua, "STR_MAXITER");

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
	func(ZZ->lua,"Initialized memory: %u KB",
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
	func(ZZ->lua, "declaring log format: %s",
		 ZZ->logformat == JSON ? "JSON" : "TEXT");
	  zen_setenv(ZZ->lua, "LOGFMT",
				 ZZ->logformat == JSON ? "JSON" : "TEXT");
	return(ZZ);
}

void zen_teardown(zenroom_t *ZZ) {
	notice(ZZ->lua,"Zenroom teardown.");
	act(ZZ->lua,"Memory used: %u KB",
	    lua_gc(ZZ->lua,LUA_GCCOUNT,0));
	func(ZZ->lua,"Octet memory left allocated: %u B",
		ZZ->memcount_octets);
	func(ZZ->lua,"Number of ECPs points left unallocated: %d",
		ZZ->memcount_ecp);
	func(ZZ->lua,"Number of ECP2s left unallocated: %d",
		ZZ->memcount_ecp2);
	func(ZZ->lua,"Number of HASHes left unallocated: %d",
		ZZ->memcount_hashes);
	func(ZZ->lua,"Number of BIGs left unallocated: %d",
		ZZ->memcount_bigs);
	func(ZZ->lua,"Number of FLOATs left unallocated: %d",
		ZZ->memcount_floats);
	func(ZZ->lua,"Number of ECDHs left unallocated: %d",
		ZZ->memcount_ecdhs);
	int memcount = ZZ->memcount_octets + ZZ->memcount_ecp
	  + ZZ->memcount_ecp2 + ZZ->memcount_hashes + ZZ->memcount_bigs
	  + ZZ->memcount_floats + ZZ->memcount_ecdhs;
	if(memcount>0)
	  act(ZZ->lua, "Zenroom memory left allocated: %u B", memcount);

	// stateful RNG instance for deterministic mode
	if(ZZ->random_generator) {
		free(ZZ->random_generator);
		ZZ->random_generator = NULL;
	}

	if(ZZ->logformat == JSON) json_end(ZZ->lua);

	lua_gc((lua_State*)ZZ->lua, LUA_GCCOLLECT, 0);
	lua_gc((lua_State*)ZZ->lua, LUA_GCCOLLECT, 0);
	// this call here frees also Z (lightuserdata)
	lua_close((lua_State*)ZZ->lua);
	ZZ->lua = NULL;

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

#ifdef MIMALLOC
	if(ZZ->debuglevel > 3) mi_stats_print(NULL);
#endif

	free(ZZ);

}

#define SAFE_EXEC \
  if(!ZZ) {														\
	_err("Execution error: Zenroom is not initialized\n");		\
	return ERR_INIT;											\
  }																\
  if(!ZZ->lua) {												\
  _err( "Execution error: Lua is not initialised\n");			\
  ZZ->exitcode = ERR_INIT;										\
  return ZZ->exitcode;											\
  }

int zen_exec_zencode(zenroom_t *ZZ, const char *script) {
  SAFE_EXEC;
	int ret;
	char *zscript = malloc(MAX_ZENCODE);
	lua_State* L = (lua_State*)ZZ->lua;
	// introspection on code being executed
	mutt_snprintf(zscript,MAX_ZENCODE-1,
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
  SAFE_EXEC;
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

int _check_script_arg(const char *s) {
  if(!s) {
    _err( "NULL string as script argument");
    _err( "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort(););
#endif
    return ERR_INIT;
  }
  if(s[0] == '\0') {
    _err( "Empty string as script argument");
    _err( "Execution aborted");
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
    _err( "Zenroom initialisation failed.");
    _err( "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort());
#endif
    return ERR_INIT;
  }
  if(!zz->lua) {
    _err( "Lua initialisation failed.");
    zen_teardown(zz);
    _err( "Execution aborted");
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort());
#endif
    return ERR_INIT;
  }
  return SUCCESS;
}

int _check_zenroom_result(zenroom_t *zz, int res) {
  int exitcode = res;
  zz->exitcode = res;
  if(res != SUCCESS) {
    zerror(zz->lua, "Execution aborted with errors.");
  } else {
    act(zz->lua, "Zenroom execution completed.");
  }
  zen_teardown(zz);
#ifdef __EMSCRIPTEN__
  if(exitcode==SUCCESS) {
    EM_ASM({Module.exec_ok();});
  } else {
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort());
  }
#endif
  return(exitcode);
}

int zencode_exec(const char *script, const char *conf, const char *keys, const char *data) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	const char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	zenroom_t *Z = zen_init(c, k, d);

	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;

	return( _check_zenroom_result(Z, zen_exec_zencode(Z, script) ));
}

int zenroom_exec(const char *script, const char *conf, const char *keys, const char *data) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	const char *c, *k, *d;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;

	zenroom_t *Z = zen_init(c, k, d);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;

	return( _check_zenroom_result(Z, zen_exec_script(Z, script) ));
}

int zencode_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data,
		char *stdout_buf, size_t stdout_len,
		char *stderr_buf, size_t stderr_len) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	const char *c, *k, *d;
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


int zenroom_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data,
		char *stdout_buf, size_t stdout_len,
		char *stderr_buf, size_t stderr_len) {

	if (_check_script_arg(script) != SUCCESS) return ERR_INIT;

	const char *c, *k, *d;
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

