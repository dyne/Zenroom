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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

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
extern int zen_require_override(lua_State *L);

// prototypes from zen_io.c
extern void zen_add_io(lua_State *L);

// prototypes from zen_memory.c
extern void libc_memory_init();
extern void umm_memory_init(size_t size);
extern void *umm_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);
extern void *umm_info(void*, int);
extern int umm_integrity_check();

// prototypes from lua_functions.c
extern void load_file(char *dst, FILE *fd);
extern char *safe_string(char *str);
extern void zen_setenv(lua_State *L, char *key, char *val);
extern void zen_add_function(lua_State *L, lua_CFunction func,
                             const char *func_name);

zenroom_t *zen_init(const char *conf) {
	(void) conf;
	lua_State *L = NULL;

	if(conf) {
		if(strcmp(conf,"umm")==0) {
			umm_memory_init(UMM_HEAP); // defined in zenroom.h (64KiB)
			L = lua_newstate(umm_memory_manager, NULL);
		} else {
			error(L,"%s: unknown memory manager: %s",
			      __func__,conf);
		}
	} else {
		libc_memory_init();
		L = luaL_newstate();
	}
	if(!L) {
		error(L,"%s: %s", __func__, "lua state creation failed");
		return NULL;
	}

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
	zen_require_override(L);
	//////////////////// end of create

	lua_gc(L, LUA_GCCOLLECT, 0);
//	lua_setfield(L, LUA_REGISTRYINDEX, LSB_THIS_PTR);

	// create the zenroom_t global context
	zenroom_t *Z = system_alloc(sizeof(zenroom_t));
	Z->lua = L;
	Z->stdout_buf = NULL;
	Z->stdout_pos = 0;
	Z->stdout_len = 0;
	Z->stderr_buf = NULL;
	Z->stderr_pos = 0;
	Z->stderr_len = 0;
	Z->userdata = NULL;
	//Set zenroom context as a global in lua
	lua_pushlightuserdata(L, Z);
	lua_setglobal(L, "_Z");
	return(Z);
}

extern char *zen_heap;
void zen_teardown(zenroom_t *Z) {
	
	notice(Z->lua,"Zenroom teardown.");
    if(zen_heap) {
	    if(umm_integrity_check())
		    act(Z->lua,"HEAP integrity checks passed.");
	    umm_info(zen_heap,0); }
    if(Z->lua) {
	    lua_gc((lua_State*)Z->lua, LUA_GCCOLLECT, 0);
	    lua_gc((lua_State*)Z->lua, LUA_GCCOLLECT, 0);
	    lua_close((lua_State*)Z->lua);
    }
    if(zen_heap) free(zen_heap);
    system_free(Z);
}


int zen_exec_script(lua_State *L, const char *script) {
	int ret;
	lua_State* lua = L;
	// introspection on code being executed
	zen_setenv(L,"CODE",(char*)script);
	ret = luaL_dostring(lua, script);
	if(ret) {
		error(L, "%s", lua_tostring(lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}

int zenroom_exec(char *script, char *conf, char *keys,
                 char *data, int verbosity) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	zenroom_t *Z = NULL;
	lua_State *L = NULL;
	int return_code = 1; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		exit(1); }
	set_debug(verbosity);


	Z = zen_init(conf);
	if(!Z) {
		error(L, "Initialisation failed.");
		return 1; }
	L = Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return 1; }

	// load arguments from json if present
	if(data) // avoid errors on NULL args
		if(safe_string(data)) {
			func(L, "declaring global: DATA");
			zen_setenv(L,"DATA",data);
		}
	if(keys)
		if(safe_string(keys)) {
			func(L, "declaring global: KEYS");
			zen_setenv(L,"KEYS",keys);
		}

	r = zen_exec_script(L, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return(1);
	}
	return_code = 0; // return success

#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_ok();});
#endif

	notice(L, "Zenroom operations completed.");
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

	int return_code = 1; // return error by default
	int r;

	if(!script) {
		error(L, "NULL string as script for zenroom_exec()");
		exit(1); }
	set_debug(verbosity);

	Z = zen_init(conf);
	if(!Z) {
		error(L, "Initialisation failed.");
		return 1; }
	L = Z->lua;
	if(!L) {
		error(L, "Initialisation failed.");
		return 1; }

	// setup stdout and stderr buffers
	Z->stdout_buf = stdout_buf;
	Z->stdout_len = stdout_len;
	Z->stderr_buf = stderr_buf;
	Z->stderr_len = stderr_len;

	// load arguments from json if present
	if(data) // avoid errors on NULL args
		if(safe_string(data)) {
			func(L, "declaring global: DATA");
			zen_setenv(L,"DATA",data);
		}
	if(keys)
		if(safe_string(keys)) {
			func(L, "declaring global: KEYS");
			zen_setenv(L,"KEYS",keys);
		}

	r = zen_exec_script(L, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
//		error(r);
		error(L, "Error detected. Execution aborted.");

		zen_teardown(Z);
		return(1);
	}
	return_code = 0; // return success

#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_ok();});
#endif

	notice(L, "Zenroom operations completed.");
	zen_teardown(Z);
	return(return_code);
}

#ifndef LIBRARY
int main(int argc, char **argv) {
	char conffile[MAX_STRING];
	char scriptfile[MAX_STRING];
	char keysfile[MAX_STRING];
	char datafile[MAX_STRING];
	char script[MAX_FILE];
	// char conf[MAX_FILE];
	char keys[MAX_FILE];
	char data[MAX_FILE];
	int opt, index;
    int verbosity = 1;
    int interactive = 0;
	const char *short_options = "hdic:k:a:";
    const char *help =
	    "Usage: zenroom [-dh] [ -i ] [ -c config ] [ -k keys ] [ -a data ] [ script.lua ]\n";
    conffile[0] = '\0';
    scriptfile[0] = '\0';
    keysfile[0] = '\0';
    datafile[0] = '\0';
    data[0] = '\0';
    keys[0] = '\0';
    // conf[0] = '\0';
    script[0] = '\0';

	notice(NULL, "Zenroom v%s - crypto language restricted VM",VERSION);
	act(NULL, "Copyright (C) 2017-2018 Dyne.org foundation");
	while((opt = getopt(argc, argv, short_options)) != -1) {
		switch(opt) {
		case 'd':
			verbosity = 3;
			set_debug(verbosity);
			break;
		case 'h':
			fprintf(stdout,"%s",help);
			exit(0);
			break;
		case 'i':
			interactive = 1;
			break;
		case 'k':
			snprintf(keysfile,511,"%s",optarg);
			break;
		case 'a':
			snprintf(datafile,511,"%s",optarg);
			break;
		case 'c':
			snprintf(conffile,511,"%s",optarg);
			break;
		case '?': error(0,help); exit(1);
		default:  error(0,help); exit(1);
		}
	}
	for (index = optind; index < argc; index++) {
		snprintf(scriptfile,511,"%s",argv[index]);
	}

	if(keysfile[0]!='\0') {
		act(NULL, "reading KEYS from file: %s", keysfile);
		load_file(keys, fopen(keysfile, "r"));
	}

	if(datafile[0]!='\0') {
		act(NULL, "reading DATA from file: %s", datafile);
		load_file(data, fopen(datafile, "r"));
	}

	if(interactive) {
		////////////////////////////////////
		// start an interactive repl console
		zenroom_t *cli;
		cli = zen_init(NULL);
		lua_State *L = (lua_State*)cli->lua;

		// print function
		zen_add_function(L, repl_flush, "flush");
		zen_add_function(L, repl_read, "read");
		zen_add_function(L, repl_write, "write");

		if(data[0]!='\0') zen_setenv(L,"DATA",data);
		if(keys[0]!='\0') zen_setenv(L,"KEYS",keys);
		notice(NULL, "Interactive console, press ctrl-d to quit.");
		repl_loop(L);
		// quits on ctrl-D
		zen_teardown(cli);
		return 0;
	}

	if(scriptfile[0]!='\0') {
		////////////////////////////////////
		// load a file as script and execute
		act(NULL, "reading CODE from file: %s", scriptfile);
		load_file(script, fopen(scriptfile, "rb"));
	} else {
		////////////////////////
		// get another argument from stdin
		act(NULL, "reading CODE from stdin");
		load_file(script, stdin);
		func(NULL, "%s\n--",script);
	}

	// configuration from -c or default
	if(conffile[0]!='\0')
		act(NULL, "selected configuration: %s",conffile);
		// load_file(conf, fopen(conffile, "r"));
	else
		act(NULL, "using default configuration");

	zenroom_t *Z;
	lua_State *L;
	set_debug(verbosity);
	Z = zen_init((conffile[0])?conffile:NULL);
	if(!Z) {
		error(NULL, "Initialisation failed.");
		return 1; }
	L = (lua_State*)Z->lua;
	if(data[0]) zen_setenv(L,"DATA",data);
	if(keys[0]) zen_setenv(L,"KEYS",keys);
	if( zen_exec_script(L, script) ) error(NULL, "Blocked execution.");
	else notice(NULL, "Execution completed.");
	// report experimental memory manager
	// if((strcmp(conffile,"umm")==0) && zen_heap) {
	// 	lua_gc(L, LUA_GCCOLLECT, 0);
	// }
	zen_teardown(Z);
	return 0;
}
#endif
