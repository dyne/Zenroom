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


#ifndef LIBRARY

extern void zen_setenv(lua_State *L, char *key, char *val);
extern void load_file(char *dst, FILE *fd);

int main(int argc, char **argv) {
	char conffile[MAX_STRING];
	char scriptfile[MAX_STRING];
	char keysfile[MAX_STRING];
	char datafile[MAX_STRING];
	char rngseed[MAX_STRING];
	char script[MAX_FILE];
	// char conf[MAX_FILE];
	char keys[MAX_FILE];
	char data[MAX_FILE];
	int opt, index;
	int   interactive         = 0;
#if DEBUG == 1
	int   unprotected         = 1;
#else
	int   unprotected         = 0;
#endif
	(void)unprotected; // remove warning

	int   zencode             = 0;

	const char *short_options = "hd:ic:k:a:S:p:uz";
	const char *help          =
		"Usage: zenroom [-h] [ -d lvl ] [ -i ] [ -c config ] [ -k keys ] [ -a data ] [ -S seed ] [ -z ] [ [ -p ] script.lua ]\n";
	int pid, status, retval;
	conffile   [0] = '\0';
	scriptfile [0] = '\0';
	keysfile   [0] = '\0';
	datafile   [0] = '\0';
	rngseed    [0] = '\0';
	data       [0] = '\0';
	keys       [0] = '\0';
	// conf[0] = '\0';
	script[0] = '\0';
	int verbosity = 1;

	while((opt = getopt(argc, argv, short_options)) != -1) {
		switch(opt) {
		case 'd':
			verbosity = atoi(optarg);
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
			snprintf(keysfile,MAX_STRING-1,"%s",optarg);
			break;
		case 'a':
			snprintf(datafile,MAX_STRING-1,"%s",optarg);
			break;
		case 'c':
			snprintf(conffile,MAX_STRING-1,"%s",optarg);
			break;
		case 'S':
			snprintf(rngseed,MAX_STRING-1,"%s",optarg);
			break;
		case 'u':
			unprotected = 1;
			break;
		case 'z':
			zencode = 1;
			interactive = 0;
			break;
		case '?': error(0,help); return EXIT_FAILURE;
		default:  error(0,help); return EXIT_FAILURE;
		}
	}
	if(verbosity) {
		notice(NULL, "Zenroom v%s - crypto language restricted VM",VERSION);
		act(NULL, "Copyright (C) 2017-2019 Dyne.org foundation");
	}

	for (index = optind; index < argc; index++) {
		snprintf(scriptfile,MAX_STRING-1,"%s",argv[index]);
	}

	if(keysfile[0]!='\0') {
		if(verbosity) act(NULL, "reading KEYS from file: %s", keysfile);
		load_file(keys, fopen(keysfile, "r"));
	}

	if(datafile[0]!='\0' && verbosity) {
		if(verbosity) act(NULL, "reading DATA from file: %s", datafile);
		load_file(data, fopen(datafile, "r"));
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
		if(verbosity) notice(NULL, "Interactive console, press ctrl-d to quit.");
		res = repl_loop(cli);
		if(res)
			// quits on ctrl-D
			zen_teardown(cli);
		return(res);
	}

	if(scriptfile[0]!='\0') {
		////////////////////////////////////
		// load a file as script and execute
		if(verbosity) notice(NULL, "reading Zencode from file: %s", scriptfile);
		load_file(script, fopen(scriptfile, "rb"));
	} else {
		////////////////////////
		// get another argument from stdin
		if(verbosity) act(NULL, "reading Zencode from stdin");
		load_file(script, stdin);
		func(NULL, "%s\n--",script);
	}

	// configuration from -c or default
	if(conffile[0]!='\0') {
		if(verbosity) act(NULL, "selected configuration: %s",conffile);
	// load_file(conf, fopen(conffile, "r"));
	} else
		if(verbosity) act(NULL, "using default configuration");

	zenroom_t *Z;
	set_debug(verbosity);
	Z = zen_init(
			(conffile[0])?conffile:NULL,
			(keys[0])?keys:NULL,
			(data[0])?data:NULL);
	if(!Z) {
		error(NULL, "Initialisation failed.");
		return EXIT_FAILURE; }

	// configure to parse Lua or Zencode
	if(zencode) {
		if(verbosity) notice(NULL, "Direct Zencode execution");
		func(NULL, script);
	}


	if(rngseed[0] != '\0') {
		if(verbosity) act(NULL, "deterministic mode (random seed provided)");
		Z->random_seed = rngseed; // TODO: parse to import (hex?)
		Z->random_seed_len = strlen(rngseed);
		// export the random_seed buffer to Lua
		zen_setenv((lua_State*)Z->lua, "RANDOM_SEED", Z->random_seed);
	}

#if DEBUG == 1
	if(unprotected) { // avoid seccomp in all cases
		int res;
		if(verbosity) act(NULL, "unprotected mode (debug build)");
		if(zencode)
			res = zen_exec_zencode(Z, script);
		else
			res = zen_exec_script(Z, script);			
		zen_teardown(Z);
		if(res) return EXIT_FAILURE;
		else return EXIT_SUCCESS;
	}
#endif

#if (defined(ARCH_WIN) || defined(DISABLE_FORK)) || defined(ARCH_CORTEX)
	if(zencode)
		if( zen_exec_zencode(Z, script) ) return EXIT_FAILURE;
	else
		if( zen_exec_script(Z, script) ) return EXIT_FAILURE;

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
		if(verbosity) act(NULL, "starting execution.");
		if(zencode) {
			if( zen_exec_zencode(Z, script) ) return EXIT_FAILURE;
		} else {
			if( zen_exec_script(Z, script) ) return EXIT_FAILURE;
		}
		return EXIT_SUCCESS;
	}
	do {
		pid = wait(&status);
	} while(pid == -1);

	if (WIFEXITED(status)) {
		retval = WEXITSTATUS(status);
		if (retval == 0)
			if(verbosity) notice(NULL, "Execution completed.");
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
