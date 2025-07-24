/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
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
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

#if (defined ARCH_LINUX) || (defined ARCH_OSX) || (defined ARCH_BSD)
#include <sys/types.h>
#include <sys/wait.h>
#endif

#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
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

// hex2oct used to import hex sequence into rng seed
#include <encoding.h>

// print functions
#include <mutt_sprintf.h>

// GLOBAL INSTANCE TO MEM POOL
#include <sfpool.h>
void *restrict ZMM = NULL;

// GLOBAL POINTER TO ZENROOM CONTEXT
void *ZEN = NULL;

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
extern void *sys_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);
extern void *sfpool_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);

// prototypes from lua_functions.c
extern int zen_setenv(lua_State *L, const char *key, const char *val);
extern void zen_add_function(lua_State *L, lua_CFunction func,
		const char *func_name);

// prototype from zen_random.c
extern void* rng_alloc(zenroom_t *ZZ);
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

	// zen_setenv(L, "MEMMANAGER", "libc");
	// act(L,"Memory manager: libc");

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

	Z(L);
	if(Z->logformat == LOG_JSON)
	  luaL_dostring(L, "CONF.debug.format='compact'");
	if(Z->scope == SCOPE_GIVEN) {
	  luaL_dostring(L, "CONF.exec.scope='given'");
	  luaL_dostring(L, "CONF.parser.strict_match=false");
	  luaL_dostring(L, "CONF.missing.fatal=false");
	  luaL_dostring(L, "CONF.debug.format='compact'");
	} else { // SCOPE_FULL is default
	  luaL_dostring(L, "CONF.exec.scope='full'");
	}
	return(LUA_OK);
}

#include <lstate.h>
// initializes globals: Z, L (in this order)
// zen_init_pmain is the Lua routine executed in protected mode
zenroom_t *zen_init(const char *conf, const char *keys, const char *data) {

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
	ZZ->scope = SCOPE_FULL;
	ZZ->debuglevel = 2;
	ZZ->random_generator = NULL;
	ZZ->random_external = 0;
	// set zero rngseed as config flag
	ZZ->zconf_rngseed[0] = '\0';
	ZZ->exitcode = 1; // success
#if defined(__EMSCRIPTEN__)
	ZZ->logformat = LOG_JSON;
#else
	ZZ->logformat = LOG_TEXT;
#endif
	// default maxiter 1000 steps
	ZZ->str_maxiter[0] = '1';
	ZZ->str_maxiter[1] = '0';
	ZZ->str_maxiter[2] = '0';
	ZZ->str_maxiter[3] = '0';
	ZZ->str_maxiter[4] = '\0';
	// default maxmem 1GB
	ZZ->str_maxmem[0] = '1';
	ZZ->str_maxmem[1] = '0';
	ZZ->str_maxmem[2] = '2';
	ZZ->str_maxmem[3] = '4';
	ZZ->str_maxmem[4] = '\0';
	// default memory pool blocks
	ZZ->sfpool_blocknum = 64;
	ZZ->sfpool_blocksize = 256;

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
		hex2buf(ZZ->random_seed, ZZ->zconf_rngseed);
	}

	// initialize the random generator
	ZZ->random_generator = rng_alloc(ZZ);

	// initialize Lua's context
	ZZ->lua = lua_newstate(sys_memory_manager, ZZ);
	if(!ZZ->lua) {
	  _err( "%s: Lua newstate creation failed\n", __func__);
	  free(ZZ->random_generator);
	  free(ZZ);
	  return NULL;
	}

	// use the generative garbage collector
	lua_gc(ZZ->lua, LUA_GCGEN);
	lua_gc(ZZ->lua, LUA_GCSTOP); // runs GC only manually

	// init log format if needed
	if(ZZ->logformat == LOG_JSON) json_start(ZZ->lua);

	// expose the debug level
	lua_pushinteger(ZZ->lua, ZZ->debuglevel);
	lua_setglobal (ZZ->lua, "DEBUG");

	lua_pushstring(ZZ->lua, ZZ->str_maxiter);
	lua_setglobal (ZZ->lua, "STR_MAXITER");

	lua_pushstring(ZZ->lua, ZZ->str_maxmem);
	lua_setglobal (ZZ->lua, "STR_MAXMEM");

	if(ZZ->scope == SCOPE_GIVEN) {
	  lua_pushstring(ZZ->lua, "GIVEN");
	  lua_setglobal (ZZ->lua, "ZENCODE_SCOPE");
	}

	lua_atpanic(ZZ->lua, &zen_lua_panic); // as done in lauxlib luaL_newstate
	lua_pushcfunction(ZZ->lua, &zen_init_pmain); // call protected mode init
	ZEN = ZZ;
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
	func(ZZ->lua,"Initialized memory: %u KB",
	    lua_gc(ZZ->lua,LUA_GCCOUNT,0));
	// uncomment to restrict further requires
	// zen_require_override(L,1);

	// switch to internal memory manager
	ZMM = malloc(sizeof(sfpool_t));
	if(sfpool_init((sfpool_t*)ZMM,
					ZZ->sfpool_blocknum,
					ZZ->sfpool_blocksize)==0) {
		_err( "%s: Sailfish pool memory initialization failed\n", __func__);
		free(ZZ->random_generator);
		free(ZZ);
		free(ZMM);
		return NULL;
	}
	lua_setallocf(ZZ->lua, sfpool_memory_manager, ZZ);

	// expose the random seed for optional determinism
	push_buffer_to_octet(ZZ->lua, ZZ->random_seed, RANDOM_SEED_LEN);
	lua_setglobal(ZZ->lua, "RNGSEED");
	if(ZZ->zconf_rngseed[0] != 0x0)
	  act(ZZ->lua, "RNG seed fed by external configuration");

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
		 ZZ->logformat == LOG_JSON ? "JSON" : "TEXT");
	  zen_setenv(ZZ->lua, "LOGFMT",
				 ZZ->logformat == LOG_JSON ? "JSON" : "TEXT");
	return(ZZ);
}

zenroom_t *zen_init_extra(const char *conf, const char *keys, const char *data,
			const char *extra, const char *context) {
	zenroom_t *ZZ = zen_init(conf, keys, data);
	if(!ZZ) return NULL;
	if(extra) {
		func(ZZ->lua, "declaring global: EXTRA");
		zen_setenv(ZZ->lua,"EXTRA",extra);
	}
	if(context) {
		func(ZZ->lua, "declaring global: CONTEXT");
		zen_setenv(ZZ->lua,"CONTEXT",context);
	}
	return(ZZ);
}

void zen_teardown(zenroom_t *ZZ) {
	notice(ZZ->lua,"Zenroom teardown.");
	act(ZZ->lua,"Memory used: %u KB",
	    lua_gc(ZZ->lua,LUA_GCCOUNT,0));
#ifdef PROFILING
	if(ZMM) {
		sfpool_t *p = (sfpool_t*)ZMM;
		func(ZZ->lua,"🌊 sfpool init: %u blocks %u B each",
			p->total_blocks, p->block_size);
		func(ZZ->lua,"🌊 total alloc: %lu K",p->alloc_total/1024);
		func(ZZ->lua,"🌊 sfpool miss: %u - %lu K",p->miss_total,p->miss_bytes/1024);
		func(ZZ->lua,"🌊 sfpool hits: %u - %lu K",p->hits_total,p->hits_bytes/1024);
	}
#endif

	// stateful RNG instance for deterministic mode
	if(ZZ->random_generator) {
		free(ZZ->random_generator);
		ZZ->random_generator = NULL;
	}

	if(ZZ->logformat == LOG_JSON) json_end(ZZ->lua);

	lua_gc((lua_State*)ZZ->lua, LUA_GCCOLLECT, 0);
	// this call here frees also Z (lightuserdata)
	lua_close((lua_State*)ZZ->lua);
	ZZ->lua = NULL;
	if(ZMM) {
		sfpool_teardown((sfpool_t*)ZMM);
		free(ZMM);
	}
	ZMM = NULL;
	free(ZZ);
	ZZ = NULL;
	ZEN = NULL;
}

HEDLEY_NON_NULL(1,2)
int zen_exec_zencode(zenroom_t *ZZ, const char *script) {
	HEDLEY_ASSUME(ZZ!=NULL);
	HEDLEY_ASSUME(ZZ->lua!=NULL);
  lua_State* L = (lua_State*)ZZ->lua;
  // introspection on code being executed
  zen_setenv(L,"CODE",(char*)script);
  ZZ->exitcode = luaL_dostring
	(L,"local _res, _err <const> = pcall( function() ZEN:begin() end)\n"
	 "if not _res then exitcode(4) ZEN.OK = false error(_err,2) end\n");
  if(ZZ->exitcode != SUCCESS) {
	zerror(L, "Zencode init error");
	zerror(L, "%s", lua_tostring(L, -1));
	return ZZ->exitcode;
  }
  // fastalloc32_status(ZMM);
  ZZ->exitcode = luaL_dostring
	(L,"local _res, _err <const> = pcall( function() ZEN:parse(CONF.code.encoding.fun(CODE)) end)\n"
	 "if not _res then exitcode(3) ZEN.OK = false error(_err,2) end\n");
  if(ZZ->exitcode != SUCCESS) {
	zerror(L, "Zencode parser error");
	zerror(L, "%s", lua_tostring(L, -1));
	return ZZ->exitcode;
  }
  // fastalloc32_status(ZMM);
  ZZ->exitcode = luaL_dostring
	(L,"local _res, _err <const> = pcall( function() ZEN:run() end)\n"
	 "if not _res then exitcode(2) ZEN.OK = false error(_err,2) end\n");
  if(ZZ->exitcode != SUCCESS) {
	zerror(L, "Zencode runtime error");
	zerror(L, "%s", lua_tostring(L, -1));
	return ZZ->exitcode;
  }
  // fastalloc32_status(ZMM);
  if(ZZ->exitcode == SUCCESS) func(L, "Zencode successfully executed");
  return ZZ->exitcode;
}

int protect_exec_lua(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "missing lua script string argument");
	luaL_dostring(L, s);
	return 0;
}

int zen_exec_lua(zenroom_t *ZZ, const char *script) {
	HEDLEY_ASSUME(ZZ!=NULL);
	HEDLEY_ASSUME(ZZ->lua!=NULL);
	lua_State *L = (lua_State*)ZZ->lua;
	// introspection on code being executed
	zen_setenv(L,"CODE",(char*)script);
	int ret = luaL_dostring(L, script);
	if(ret == SUCCESS) {
		func(L, "Lua script successfully executed");
		ZZ->exitcode = SUCCESS;
        } else {
		zerror(L, "Lua script error:");
		zerror(L, "%s", lua_tostring(L, -1));
		zerror(L, "Execution aborted");
		ZZ->exitcode = ZZ->exitcode==SUCCESS ? ERR_GENERIC : ZZ->exitcode;
	}
	return ZZ->exitcode;
}

int _check_script_arg(zenroom_t *ZZ, const char *s) {
  if(!s) {
    zerror(ZZ->lua, "NULL string as script argument");
    zerror(ZZ->lua, "Execution aborted");
    zen_teardown(ZZ);
#ifdef __EMSCRIPTEN__
    EM_ASM({Module.exec_error();});
    EM_ASM(Module.onAbort(););
#endif
    return ERR_INIT;
  }
  if(s[0] == '\0') {
    zerror(ZZ->lua, "Empty string as script argument");
    zerror(ZZ->lua, "Execution aborted");
    zen_teardown(ZZ);
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

int _check_zenroom_result(zenroom_t *zz) {
  int exitcode = zz->exitcode;
  if(exitcode != SUCCESS) {
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

int zencode_exec(const char *script, const char *conf, const char *keys, const char *data,
	const char *extra, const char *context) {

	const char *c, *k, *d, *e, *x;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	e = extra ? (extra[0] == '\0') ? NULL : extra : NULL;
	x = context ? (context[0] == '\0') ? NULL : context : NULL;

	zenroom_t *Z = zen_init_extra(c, k, d, e, x);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;
	if (_check_script_arg(Z, script) != SUCCESS) return ERR_INIT;

	zen_exec_zencode(Z, script);
	return( _check_zenroom_result(Z) );
}

int zenroom_exec(const char *script, const char *conf, const char *keys, const char *data,
	const char *extra, const char *context) {

	const char *c, *k, *d, *e, *x;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	e = extra ? (extra[0] == '\0') ? NULL : extra : NULL;
	x = context ? (context[0] == '\0') ? NULL : context : NULL;

	zenroom_t *Z = zen_init_extra(c, k, d, e, x);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;
	if (_check_script_arg(Z, script) != SUCCESS) return ERR_INIT;

	zen_exec_lua(Z, script);
	return( _check_zenroom_result(Z));
}

int zencode_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data,
	const char *extra, const char *context,
	char *stdout_buf, size_t stdout_len,
	char *stderr_buf, size_t stderr_len) {

	const char *c, *k, *d, *e, *x;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	e = extra ? (extra[0] == '\0') ? NULL : extra : NULL;
	x = context ? (context[0] == '\0') ? NULL : context : NULL;

	zenroom_t *Z = zen_init_extra(c, k, d, e, x);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;
	if (_check_script_arg(Z, script) != SUCCESS) return ERR_INIT;

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;
	zen_exec_zencode(Z, script);
	return( _check_zenroom_result(Z));
}


int zenroom_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data,
	const char *extra, const char *context,
	char *stdout_buf, size_t stdout_len,
	char *stderr_buf, size_t stderr_len) {

	const char *c, *k, *d, *e, *x;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	d = data ? (data[0] == '\0') ? NULL : data : NULL;
	e = extra ? (extra[0] == '\0') ? NULL : extra : NULL;
	x = context ? (context[0] == '\0') ? NULL : context : NULL;

	zenroom_t *Z = zen_init_extra(c, k, d, e, x);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;
	if (_check_script_arg(Z, script) != SUCCESS) return ERR_INIT;

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;
	zen_exec_lua(Z, script);
	return( _check_zenroom_result(Z));
}

int zencode_valid_input(const char *script, const char *conf, const char *keys, const char *data, const char *extra) {
	(void)conf;
	(void)extra;
	const char *c = "scope=given";
	const char *k = keys ? (keys[0] == '\0') ? NULL : keys : NULL;
	const char *d = data ? (data[0] == '\0') ? NULL : data : NULL;

	zenroom_t *Z = zen_init(c, k, d);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;
	if (_check_script_arg(Z, script) != SUCCESS) return ERR_INIT;

	zen_exec_zencode(Z, script);
	return( _check_zenroom_result(Z));
}

int zencode_valid_code(const char *script, const char *conf, const int strict) {
	const char *c;
	c = conf ? (conf[0] == '\0') ? NULL : conf : NULL;
	zenroom_t *Z = zen_init(c, NULL, NULL);
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;
	if (_check_script_arg(Z, script) != SUCCESS) return ERR_INIT;
	// disable strict parsing
	if (!strict) {
		luaL_dostring(Z->lua, "CONF.parser.strict_parse=false");
	}
	// ZEN:begin()
	lua_getglobal(Z->lua, "ZEN");
	lua_getfield(Z->lua, -1, "begin");
	lua_getglobal(Z->lua, "ZEN");
	if (lua_pcall(Z->lua, 1, 0, 0) != LUA_OK) {
		zerror(Z->lua, "Zencode init error");
		zerror(Z->lua, "%s", lua_tostring(Z->lua, -1));
		Z->exitcode = ERR_GENERIC;
	} else {
		// ZEN:parse(script)
		lua_getglobal(Z->lua, "ZEN");
		lua_getfield(Z->lua, -1, "parse");
		lua_getglobal(Z->lua, "ZEN");
		lua_pushstring(Z->lua, (char*)script);
		if (lua_pcall(Z->lua, 2, 1, 0) != LUA_OK) {
			zerror(Z->lua, "Zencode parse error");
			zerror(Z->lua, "%s", lua_tostring(Z->lua, -1));
			Z->exitcode = ERR_GENERIC;
		} else {
			const char * res = lua_tostring(Z->lua, -1);
			_out("%s", res);
			Z->exitcode = SUCCESS;
		}
	}
	return( _check_zenroom_result(Z));
}

int zencode_get_statements(const char *scenario) {
	zenroom_t *Z = zen_init(NULL, NULL, NULL);
	const char *s;
	s = scenario ? (scenario[0] == '\0') ? NULL : scenario : NULL;
	if(s) {
		func(Z->lua, "declaring global: SCENARIO");
		zen_setenv(Z->lua, "SCENARIO", scenario);
	}
	if (_check_zenroom_init(Z) != SUCCESS) return ERR_INIT;
	static char zscript[MAX_ZENCODE] =
		"function Given(text, fn) table.insert(ZEN.given_steps, text) end\n"
		"function When(text, fn) table.insert(ZEN.when_steps, text) end\n"
		"function Then(text, fn) table.insert(ZEN.then_steps, text) end\n"
		"function IfWhen(text, fn) table.insert(ZEN.if_steps, text) end\n"
		"function Foreach(text, fn) table.insert(ZEN.foreach_steps, text) end\n"
		"ZEN.add_schema = function(arr) return nil end\n"
		"ZEN.given_steps = {}\n"
		"ZEN.when_steps = {}\n"
		"ZEN.then_steps = {}\n"
		"ZEN.if_steps = {}\n"
		"ZEN.foreach_steps = {}\n"
		"for _, v in ipairs(zencode_scenarios()) do\n"
		"  if not SCENARIO then\n"
		"    require_once('zencode_'..v)\n"
		"  elseif SCENARIO == v then\n"
		"    require_once('zencode_'..v)\n"
		"  end\n"
		"end\n"
		"STATEMENTS = JSON.encode(\n"
		"{ Given = ZEN.given_steps,\n"
		"  When = ZEN.when_steps,\n"
		"  Then = ZEN.then_steps,\n"
		"  If = ZEN.if_steps,\n"
		"  Foreach = ZEN.foreach_steps })";
	int ret = luaL_dostring(Z->lua, zscript);
	if(ret) {
		zerror(Z->lua, "Zencode execution error\n");
		zerror(Z->lua, "%s", lua_tostring(Z->lua, -1));
		Z->exitcode = ERR_GENERIC;
	} else {
		lua_getglobal(Z->lua, "STATEMENTS");
		const char * res = lua_tostring(Z->lua, -1);
		_out("%s", res);
		Z->exitcode = SUCCESS;
	}
	return( _check_zenroom_result(Z));
}
