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

#include <jutils.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <lua_functions.h>
#include <repl.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#include <zenroom.h>

// prototypes from lua_modules.c
extern void zen_load_extensions(lua_State *L);
extern void zen_add_function(lua_State *L, lua_CFunction func,
                                  const char *func_name);
void zen_setenv(lua_State *L, char *key, char *val);

// prototypes from zen_memory.c
extern void libc_memory_init();
extern void umm_memory_init(size_t size);
extern void* umm_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);
extern void *umm_info(void*, int);
extern int umm_integrity_check();

// prototypes from lua_functions.c
extern void load_file(char *dst, FILE *fd);
extern char *safe_string(char *str);

lua_State *zen_init(const char *conf) {
	(void) conf;
	lua_State *L = NULL;

	if(conf) {
		if(strcmp(conf,"umm")==0) {
			umm_memory_init(MAX_HEAP); // defined in zenroom.h
			L = lua_newstate(umm_memory_manager, NULL);
		} else {
			error("%s: unknown memory manager: %s",
			      __func__,conf);
		}
	} else {
		libc_memory_init();
		L = luaL_newstate();
	}
	if(!L) {
		error("%s: %s", __func__, "lua state creation failed");
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
	zen_load_extensions(L);
	//////////////////// end of create

	lua_gc(L, LUA_GCCOLLECT, 0);
//	lua_setfield(L, LUA_REGISTRYINDEX, LSB_THIS_PTR);

	return(L);

}

extern char *zen_heap;
void zen_teardown(lua_State *L) {
	notice("Zenroom teardown.");
    if(L) lua_gc(L, LUA_GCCOLLECT, 0);
    lua_close(L);
    if(zen_heap) {
	    if(umm_integrity_check(zen_heap))
		    act("HEAP integrity checks passed.");
	    // umm_info(zen_heap,0);
	    free(zen_heap);
    }
}

int zen_exec_line(lua_State *L, const char *line) {
	int ret;
	lua_State* lua = L;

	ret = luaL_dostring(lua, line);
	if(ret) {
		error("%s", lua_tostring(lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}


int zen_exec_script(lua_State *L, const char *script) {
	int ret;
	lua_State* lua = L;

	ret = luaL_dostring(lua, script);
	if(ret) {
		error("%s", lua_tostring(lua, -1));
		fflush(stderr);
		return ret;
	}
	return 0;
}

int zenroom_exec(char *script, char *conf, char *keys,
                 char *data, int verbosity) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	lua_State *L = NULL;
	int return_code = 1; // return error by default
	int r;

	if(!script) {
		error("NULL string as script for zenroom_exec()");
		exit(1); }
	set_debug(verbosity);

	L = zen_init(conf);
	if(!L) {
		error("Initialisation failed.");
		return 1;
	}

	// load arguments from json if present
	if(data) // avoid errors on NULL args
		if(safe_string(data)) {
			func("declaring global: DATA");
			zen_setenv(L,"DATA",data);
		}
	if(keys)
		if(safe_string(keys)) {
			func("declaring global: KEYS");
			zen_setenv(L,"KEYS",keys);
		}

	r = zen_exec_script(L, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
//		error(r);
		error("Error detected. Execution aborted.");

		zen_teardown(L);
		return(1);
	}
	return_code = 0; // return success

#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_ok();});
#endif

	notice("Zenroom operations completed.");
	zen_teardown(L);
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

	notice( "Zenroom v%s - crypto language restricted VM",VERSION);
	act("Copyright (C) 2017-2018 Dyne.org foundation");
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
		case '?': error(help); exit(1);
		default:  error(help); exit(1);
		}
	}
	for (index = optind; index < argc; index++) {
		snprintf(scriptfile,511,"%s",argv[index]);
	}

	if(keysfile[0]!='\0') {
		act("reading KEYS from file: %s", keysfile);
		load_file(keys, fopen(keysfile, "r"));
	}

	if(datafile[0]!='\0') {
		act("reading DATA from file: %s", datafile);
		load_file(data, fopen(datafile, "r"));
	}

	if(interactive) {
		////////////////////////////////////
		// start an interactive repl console
		lua_State  *cli;
		cli = zen_init(NULL);

		// print function
		zen_add_function(cli, repl_flush, "flush");
		zen_add_function(cli, repl_read, "read");
		zen_add_function(cli, repl_write, "write");

		if(data[0]!='\0') zen_setenv(cli,"DATA",data);
		if(keys[0]!='\0') zen_setenv(cli,"KEYS",keys);
		notice("Interactive console, press ctrl-d to quit.");
		repl_loop(cli);
		// quits on ctrl-D
		zen_teardown(cli);
		return 0;
	}

	if(scriptfile[0]!='\0') {
		////////////////////////////////////
		// load a file as script and execute
		act("reading CODE from file: %s", scriptfile);
		load_file(script, fopen(scriptfile, "rb"));
	} else {
		////////////////////////
		// get another argument from stdin
		act("reading CODE from stdin");
		load_file(script, stdin);
		func("%s\n--",script);
	}

	static lua_State *L;
	// configuration from -c or default
	if(conffile[0]!='\0')
		act("selected configuration: %s",conffile);
		// load_file(conf, fopen(conffile, "r"));
	else
		act("using default configuration");

	set_debug(verbosity);
	L = zen_init((conffile[0])?conffile:NULL);
	if(!L) {
		error("Initialisation failed.");
		return 1; }
	if(data[0]) zen_setenv(L,"DATA",data);
	if(keys[0]) zen_setenv(L,"KEYS",keys);
	if( zen_exec_script(L, script) ) error("Blocked execution.");
	else notice("Execution completed.");
	// report experimental memory manager
	if((strcmp(conffile,"umm")==0) && zen_heap) {
		lua_gc(L, LUA_GCCOLLECT, 0);
		if(umm_integrity_check(zen_heap)) act("HEAP integrity checks passed.");
		umm_info(zen_heap,0);
	}
	zen_teardown(L);
	return 0;
}
#endif
