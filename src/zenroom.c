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
#ifdef ARCH_LINUX
#include <sys/prctl.h>
#include <linux/seccomp.h>
#include <linux/filter.h>
#include <sys/syscall.h>
static const struct sock_filter  strict_filter[] = {
	BPF_STMT(BPF_LD | BPF_W | BPF_ABS, (offsetof (struct seccomp_data, nr))),

	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_getrandom,    6, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_rt_sigreturn, 5, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_read,         4, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_write,        3, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_exit,         2, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_exit_group,   1, 0),

	BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_KILL),
	BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW)
};

static const struct sock_fprog  strict = {
	.len = (unsigned short)( sizeof strict_filter / sizeof strict_filter[0] ),
	.filter = (struct sock_filter *)strict_filter
};
#endif

// prototypes from lua_modules.c
extern int zen_require_override(lua_State *L, const int restricted);
extern int zen_lua_init(lua_State *L);

// prototypes from zen_io.c
extern void zen_add_io(lua_State *L);

// prototypes from zen_memory.c
extern zen_mem_t *libc_memory_init();
extern zen_mem_t *umm_memory_init(size_t size);
extern void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);
extern void *umm_info(void*);
extern int umm_integrity_check();

// prototypes from lua_functions.c
extern void load_file(char *dst, FILE *fd);
extern void zen_setenv(lua_State *L, char *key, char *val);
extern void zen_add_function(lua_State *L, lua_CFunction func,
		const char *func_name);

// prototypes from zen_ast.c
zenroom_t *ast_init(char *script);
int  ast_parse(zenroom_t *Z);
void ast_teardown(zenroom_t *Z);

zenroom_t *zen_init(const char *conf,
		char *keys, char *data) {
	(void) conf;
	lua_State *L = NULL;
	zen_mem_t *mem = NULL;
	if(conf) {
		if(strcasecmp(conf,"umm")==0)
			mem = umm_memory_init(UMM_HEAP); // (64KiB)
	} else
		mem = libc_memory_init();

	L = lua_newstate(zen_memory_manager, mem);
	if(!L) {
		error(L,"%s: %s", __func__, "lua state creation failed");
		return NULL;
	}

	// create the zenroom_t global context
	zenroom_t *Z = system_alloc(sizeof(zenroom_t));
	Z->lua = L;
	Z->mem = mem;
	Z->stdout_buf = NULL;
	Z->stdout_pos = 0;
	Z->stdout_len = 0;
	Z->stderr_buf = NULL;
	Z->stderr_pos = 0;
	Z->stderr_len = 0;
	Z->userdata = NULL;
	Z->errorlevel = 0;

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
		return NULL;
	}
	//////////////////// end of create

	lua_gc(L, LUA_GCCOLLECT, 0);
	lua_gc(L, LUA_GCCOLLECT, 0);
	// allow further requires
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

	return(Z);
}

void zen_teardown(zenroom_t *Z) {

	act(Z->lua,"Zenroom teardown.");
	if(Z->mem->heap) {
		if(umm_integrity_check())
			func(Z->lua,"HEAP integrity checks passed.");
		umm_info(Z->mem->heap); }
	// save pointers inside Z to free after L and Z
	void *mem = Z->mem;
	void *heap = Z->mem->heap;
	if(Z->lua) {
		func(Z->lua, "lua gc and close...");
		lua_gc((lua_State*)Z->lua, LUA_GCCOLLECT, 0);
		lua_gc((lua_State*)Z->lua, LUA_GCCOLLECT, 0);
		// this call here frees also Z (lightuserdata)
		lua_close((lua_State*)Z->lua);
	}
	func(NULL,"zen free");
	if(heap)
		system_free(heap);
	free(Z);
	if(mem) system_free(mem);
	func(NULL,"teardown completed");
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
	lua_State* L = Z->lua;
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
	L = Z->lua;
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
	L = Z->lua;
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
	int   verbosity           = 1;
	int   interactive         = 0;
	int   parseast            = 0;
#if DEBUG == 1
	int   unprotected         = 1;
#else
	int   unprotected         = 0;
#endif
	(void)unprotected; // remove warning
	const char *short_options = "hdic:k:a:p:u";
	const char *help          =
		"Usage: zenroom [-dh] [ -i ] [ -c config ] [ -k keys ] [ -a data ] [ [ -p ] script.lua ]\n";
	int pid, status, retval;
	conffile   [0] = '\0';
	scriptfile [0] = '\0';
	keysfile   [0] = '\0';
	datafile   [0] = '\0';
	data       [0] = '\0';
	keys       [0] = '\0';
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
			return EXIT_SUCCESS;
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
		case 'p':
			parseast = 1;
			snprintf(scriptfile,511,"%s",optarg);
			break;
		case 'u':
			unprotected = 1;
			break;
		case '?': error(0,help); return EXIT_FAILURE;
		default:  error(0,help); return EXIT_FAILURE;
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

	if(parseast) {
		load_file(script, fopen(scriptfile, "rb"));
		zenroom_t *ast = ast_init(script);
		ast_parse(ast);
		ast_teardown(ast);
		return EXIT_SUCCESS;
	}

	if(interactive) {
		////////////////////////////////////
		// start an interactive repl console
		zenroom_t *cli;
		cli = zen_init(
				conffile[0]?conffile:NULL,
				keys[0]?keys:NULL,
				data[0]?data:NULL);
		lua_State *L = (lua_State*)cli->lua;

		// print function
		zen_add_function(L, repl_flush, "flush");
		zen_add_function(L, repl_read, "read");
		zen_add_function(L, repl_write, "write");
		int res;
		notice(NULL, "Interactive console, press ctrl-d to quit.");
		res = repl_loop(cli);
		if(res)
			// quits on ctrl-D
			zen_teardown(cli);
		return(res);
	}

	if(scriptfile[0]!='\0') {
		////////////////////////////////////
		// load a file as script and execute
		notice(NULL, "reading Zencode from file: %s", scriptfile);
		load_file(script, fopen(scriptfile, "rb"));
	} else {
		////////////////////////
		// get another argument from stdin
		act(NULL, "reading Zencode from stdin");
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
	set_debug(verbosity);
	Z = zen_init(
			(conffile[0])?conffile:NULL,
			(keys[0])?keys:NULL,
			(data[0])?data:NULL);
	if(!Z) {
		error(NULL, "Initialisation failed.");
		return EXIT_FAILURE; }

#if DEBUG == 1
	if(unprotected) { // avoid seccomp in all cases
		int res;
		notice(NULL, "Starting execution (unprotected mode)");
		res = zen_exec_script(Z, script);
		zen_teardown(Z);
		if(res) return EXIT_FAILURE;
		else return EXIT_SUCCESS;
	}
#endif

#if (defined(ARCH_WIN) || defined(DISABLE_FORK))
	if( zen_exec_script(Z, script) ) {
		return EXIT_FAILURE; }
#else /* POSIX */
	if (fork() == 0) {
#   ifdef ARCH_LINUX /* LINUX engages SECCOMP. */
		if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0)) {
			fprintf(stderr, "Cannot set no_new_privs: %m.\n");
			return EXIT_FAILURE;
		}
		if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &strict)) {
			fprintf(stderr, "Cannot install seccomp filter: %m.\n");
			return EXIT_FAILURE;
		}
#   endif /* ARCH_LINUX */
		notice(NULL, "Starting execution.");
		if( zen_exec_script(Z, script) ) {
			return EXIT_FAILURE; }
		return EXIT_SUCCESS;
	}
	do {
		pid = wait(&status);
	} while(pid == -1);

	if (WIFEXITED(status)) {
		retval = WEXITSTATUS(status);
		if (retval == 0)
			notice(NULL, "Execution completed.");
	} else if (WIFSIGNALED(status)) {
		notice(NULL, "Execution interrupted by signal %d.", WTERMSIG(status));
	}
#endif /* POSIX */

	// report experimental memory manager
	// if((strcmp(conffile,"umm")==0) && zen_heap) {
	// 	lua_gc(L, LUA_GCCOLLECT, 0);
	// }
	zen_teardown(Z);
	return EXIT_SUCCESS;
}
#endif
