/*
 * This file is part of zenroom
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 *
 * Last modified by Denis Roio
 * on Thursday, 2nd September 2021
 */

#ifndef LIBRARY


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <ctype.h>
#include <time.h>

#if ! defined ARCH_WIN
#include <sys/types.h>
#include <sys/wait.h>
#endif

#include <errno.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <lua_functions.h>
#include <repl.h>

#include <zenroom.h>

#include <sys/types.h>
#include <unistd.h>

#if defined(ARCH_LINUX)
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

extern int zen_setenv(lua_State *L, char *key, char *val);

// This function exits the process on failure.
void load_file(char *dst, FILE *fd) {
	char *firstline = NULL;
	unsigned int file_size = 0L;
	unsigned int offset = 0;
	size_t bytes = 0;
	if(!fd) {
		fprintf(stderr, "Error opening %s\n", strerror(errno));
		exit(1); }
	if(fd!=stdin) {
		if(fseek(fd, 0L, SEEK_END)<0) {
			fprintf(stderr, "fseek(end) error in %s: %s\n", __func__,
			      strerror(errno));
			exit(1); }
		file_size = ftell(fd);
		if(fseek(fd, 0L, SEEK_SET)<0) {
			fprintf(stderr, "fseek(start) error in %s: %s\n", __func__,
			      strerror(errno));
			exit(1); }
#ifdef DEBUG
		fprintf(stderr, "size of file: %u\n", file_size);
#endif
	}

	firstline = malloc(MAX_STRING);
	// skip shebang on firstline
	if(!fgets(firstline, MAX_STRING, fd)) {
		if(errno==0) { // file is empty
			fprintf(stderr, "Error reading, file is empty\n");
			if(firstline) free(firstline);
			exit(1); }
		fprintf(stderr, "Error reading first line: %s\n", strerror(errno));
		exit(1); }
	if(firstline[0]=='#' && firstline[1]=='!')
		fprintf(stderr, "Skipping shebang\n");
	else {
		offset+=strlen(firstline);
		strncpy(dst, firstline, MAX_STRING);
	}

	size_t chunk;
	while(1) {
		chunk = MAX_STRING;
		if( offset+MAX_STRING>MAX_FILE )
			chunk = MAX_FILE-offset-1;
		if(!chunk) {
			fprintf(stderr, "File too big, truncated at maximum supported size\n");
			break; }
		bytes = fread(&dst[offset],1,chunk,fd);

		if(!bytes) {
			if(feof(fd)) {
				if((fd!=stdin) && (long)offset!=file_size) {
					fprintf(stderr, "Incomplete file read (%u of %u bytes)\n",
					      offset, file_size);
				} else {
					fprintf(stderr, "EOF after %u bytes\n",offset);
				}
 				dst[offset] = '\0';
				break;
			}
			if(ferror(fd)) {
				fprintf(stderr, "Error in %s: %s\n", __func__, strerror(errno));
				fclose(fd);
				if(firstline) free(firstline);
				exit(1); }
		}
		offset += bytes;
	}
	if(fd!=stdin) fclose(fd);
	fprintf(stderr, "loaded file (%u bytes)\n", offset);
	if(firstline) free(firstline);
}

static char *conffile = NULL;
static char *keysfile = NULL;
static char *scriptfile = NULL;
static char *datafile = NULL;
static char *extrafile = NULL;
static char *contextfile = NULL;
static char *sideload = NULL;
static char *sidescript = NULL;
static char *script = NULL;
static char *keys = NULL;
static char *data = NULL;
static char *extra = NULL;
static char *context = NULL;
static char *introspect = NULL;
static char *scriptarg = NULL;

// for benchmark, breaks c99 spec
struct timespec before = {0}, after = {0};

int cli_alloc_buffers() {
	conffile = malloc(MAX_STRING);
	scriptfile = malloc(MAX_STRING);
	sideload = malloc(MAX_STRING);
	keysfile = malloc(MAX_STRING);
	datafile = malloc(MAX_STRING);
	extrafile = malloc(MAX_STRING);
	contextfile = malloc(MAX_STRING);
	script = malloc(MAX_FILE);
	sidescript = malloc(MAX_FILE);
	keys = malloc(MAX_FILE);
	data = malloc(MAX_FILE);
	extra = malloc(MAX_FILE);
	context = malloc(MAX_FILE);
	introspect = malloc(MAX_STRING);
	scriptarg = malloc(MAX_STRING);
	return(1);
}

int cli_free_buffers() {
	free(conffile);
	free(scriptfile);
	free(sideload);
	free(keysfile);
	free(datafile);
	free(extrafile);
	free(contextfile);
	free(script);
	free(sidescript);
	free(keys);
	free(data);
	free(extra);
	free(context);
	free(introspect);
	free(scriptarg);
	return(1);
}

int main(int argc, char **argv) {
	int opt, index;
	int   interactive         = 0;
	int   zencode             = 0;
	int valid_input = 0;
	int use_seccomp = 0;

	zenroom_t *Z;
	const char *short_options = ":hsD:ic:k:a:x:y:e:zvl:";
	const char *help          =
		"Zenroom\n"
		"Secure language interpreter of the domain-specific Zencode, making it easy to execute fast cryptographic operations on any data structure\n\n"
		"Usage:\n"
		"  zenroom [options] [script]\n\n"
		"Options:\n"
		"  -h              Print this help message\n"
		"  -i              Start interactive Lua mode (default scripting language)\n"
		"  -z              Start ZenCode mode (rather than Lua)\n"
		"  -c config       Load configuration from file\n"
		"  -a data.json    Load data JSON file\n"
		"  -k keys.json    Load keys JSON file\n"
		"  -x extra.json   Load extra JSON file\n"
		"  -y context      Load context from file\n"
		"  -D scenario     Print all the statements under the scenario\n"
		"  -v              Validate input data\n"
		"  -e              Execute a Lua one-liner at startup\n"
		"  -s              Activate seccomp execution (Linux only)\n"
		"  -l lib.lua      Load an external Lua library from file\n"
		"\n"
		"Examples:\n"
		"  zenroom script.lua\n"
		"    Runs the lua script in script.lua\n"
		"  zenroom -i\n"
		"    Starts an interactive Lua console\n"
		"  zenroom -z\n"
		"    Starts an interactive zenCode console\n"
		"  zenroom -z script.zen\n"
		"    Runs the zenCode script in script.zen\n"
		"  zenroom -z -a data.json -k keys.json -e extra.json script.zen\n"
		"    Runs the zenCode script in script.zen with data, keys and extra loaded from files\n";
	const char *please_help = "Please use -h for help.\n";
	for (int i = 1; i < argc; i++) {
		if (strncmp(argv[i], "--", 2) == 0) {
			fprintf(stderr, "Invalid option: long option like '%s' are not supported.\n\n", argv[i]);
			fprintf(stderr, "%s", please_help);
			return EXIT_FAILURE;
		}
	}
	int pid, status, retval;
	cli_alloc_buffers();
	conffile    [0] = '\0';
	scriptfile  [0] = '\0';
	sideload    [0] = '\0';
	keysfile    [0] = '\0';
	datafile    [0] = '\0';
	extrafile   [0] = '\0';
	contextfile [0] = '\0';
	data        [0] = '\0';
	keys        [0] = '\0';
	extra       [0] = '\0';
	context     [0] = '\0';
	introspect  [0] = '\0';
	scriptarg   [0] = '\0';
	// conf[0] = '\0';
	script[0] = '\0';
	int verbosity = 1;
	while((opt = getopt(argc, argv, short_options)) != -1) {
		switch(opt) {
		case 'D':
			snprintf(introspect,MAX_STRING-1,"%s",optarg);
			break;
		case 'h':
			fprintf(stdout,"%s",help);
			cli_free_buffers();
			return EXIT_SUCCESS;
			break;
		case 's':
		        use_seccomp = 1;
			break;
		case 'i':
			interactive = 1;
			break;
		case 'l':
			snprintf(sideload,MAX_STRING-1,"%s",optarg);
			break;
		case 'k':
			snprintf(keysfile,MAX_STRING-1,"%s",optarg);
			break;
		case 'a':
			snprintf(datafile,MAX_STRING-1,"%s",optarg);
			break;
		case 'x':
			snprintf(extrafile,MAX_STRING-1,"%s",optarg);
			break;
		case 'y':
			snprintf(contextfile,MAX_STRING-1,"%s",optarg);
			break;
		case 'e':
			snprintf(scriptarg,MAX_STRING-1,"%s",optarg);
			break;
		case 'c':
			snprintf(conffile,MAX_STRING-1,"%s",optarg);
			break;
		case 'z':
			zencode = 1;
			interactive = 0;
			break;
		case 'v':
		  valid_input = 1;
		  interactive = 0;
		  break;
		case ':': fprintf(stderr, "Option '-%c' requires an argument\n\n%s", optopt, please_help); cli_free_buffers(); return EXIT_FAILURE;
		case '?': fprintf(stderr, "Invalid option: '-%c'\n\n%s", optopt, please_help); cli_free_buffers(); return EXIT_FAILURE;
		default:  fprintf(stderr, "Error: unknown option '-%c'\n\n%s", optopt, please_help); cli_free_buffers(); return EXIT_FAILURE;
		}
	}

	if(verbosity) {
		fprintf(stderr, "Zenroom %s - secure crypto language VM\n",VERSION);
		fprintf(stderr, "Zenroom is Copyright (C) 2017-%s by the Dyne.org foundation\n", CURRENT_YEAR);
	}

	for (index = optind; index < argc; index++) {
		snprintf(scriptfile,MAX_STRING-1,"%s",argv[index]);
	}

	if(keysfile[0]!='\0') {
		if(verbosity) fprintf(stderr, "reading KEYS from file: %s\n", keysfile);
		load_file(keys, fopen(keysfile, "r"));
	}

	if(datafile[0]!='\0' && verbosity) {
		if(verbosity) fprintf(stderr, "reading DATA from file: %s\n", datafile);
		load_file(data, fopen(datafile, "r"));
	}

	if(extrafile[0]!='\0' && verbosity) {
		if(verbosity) fprintf(stderr, "reading EXTRA from file: %s\n", extrafile);
		load_file(extra, fopen(extrafile, "r"));
	}

	if(contextfile[0]!='\0' && verbosity) {
		if(verbosity) fprintf(stderr, "reading CONTEXT from file: %s\n", contextfile);
		load_file(context, fopen(contextfile, "r"));
	}

	if(interactive) {
		////////////////////////////////////
		// start an interactive repl console
		Z = zen_init_extra(
			conffile[0]?conffile:NULL,
			keys[0]?keys:NULL,
			data[0]?data:NULL,
			extra[0]?extra:NULL,
			context[0]?context:NULL);
		if(!Z) {
		  fprintf(stderr, "Internal error in Zenroom initialization\n");
		  return(EXIT_FAILURE);
		}

		lua_State *L = (lua_State*)Z->lua;
		lua_gc(L, LUA_GCRESTART); // runs GC only manually

		// print function
		zen_add_function(L, repl_flush, "flush");
		zen_add_function(L, repl_read, "read");
		zen_add_function(L, repl_write, "write");

		if(sideload[0]!='\0') {
			fprintf(stderr,"Side loading library: %s\n",sideload);
			load_file(sidescript, fopen(sideload,"rb"));
			zen_exec_lua(Z, sidescript);
			if(Z->exitcode!=0)
				fprintf(stderr,"Side load exit code error: %u\n",Z->exitcode);
		}

		int res;
		if(verbosity) fprintf(stderr, "Interactive console, press ctrl-d to quit.\n");
		res = repl_loop(Z);
		if(res) zen_teardown(Z); // quits on ctrl-D
		cli_free_buffers();
		return(res);
	}

	///////////////////
	// Input validation
	if (valid_input) {
		int exitcode;
		if(scriptfile[0]!='\0') load_file(script, fopen(scriptfile, "rb"));
		else load_file(script, stdin);
		exitcode = zencode_valid_input(script, "scope=given",
										(keys[0])?keys:NULL,
										(data[0])?data:NULL,
										(extra[0])?extra:NULL);
		if(exitcode) fprintf(stderr, "Execution failed.\n");
		cli_free_buffers();
		return(exitcode);
	} /////////////////

	///////
	// configuration from -c or default
	if(conffile[0]!='\0') {
		if(verbosity) fprintf(stderr, "configuration: %s\n",conffile);
	// load_file(conf, fopen(conffile, "r"));
	} else
		if(verbosity) fprintf(stderr, "using default configuration\n");

	// time from here
    clock_gettime(CLOCK_MONOTONIC, &before);

	Z = zen_init_extra(
			(conffile[0])?conffile:NULL,
			(keys[0])?keys:NULL,
			(data[0])?data:NULL,
			(extra[0])?extra:NULL,
			(context[0])?context:NULL);
	if(!Z) {
		fprintf(stderr, "Initialisation failed.\n");
		cli_free_buffers();
		return EXIT_FAILURE; }

	// print scenario documentation
	if(introspect[0]!='\0') {
		static char zscript[MAX_ZENCODE];
		fprintf(stderr, "Documentation for scenario: %s\n",introspect);
		snprintf(zscript,MAX_ZENCODE-1,
				"function Given(text, fn) ZEN.given_steps[text] = true end\n"
				"function When(text, fn) ZEN.when_steps[text] = true end\n"
				"function Then(text, fn) ZEN.then_steps[text] = true end\n"
				"function IfWhen(text, fn) ZEN.if_steps[text] = true end\n"
				"function Foreach(text, fn) ZEN.foreach_steps[text] = true end\n"
				"function ZEN.add_schema(arr)\n"
				"  for k,v in pairs(arr) do ZEN.schemas[k] = true end end\n"
				"ZEN.given_steps = {}\n"
				"ZEN.when_steps = {}\n"
				"ZEN.then_steps = {}\n"
				"ZEN.if_steps = {}\n"
				"ZEN.foreach_steps = {}\n"
				"ZEN.schemas = {}\n"
				"require_once('zencode_%s')\n"
				"print(JSON.encode(\n"
				"{ Scenario = \"%s\",\n"
				"  Given = ZEN.given_steps,\n"
				"  When = ZEN.when_steps,\n"
				"  Then = ZEN.then_steps,\n"
				"  If = ZEN.if_steps,\n"
				"  Foreach = ZEN.foreach_steps,\n"
				"  Schemas = ZEN.schemas }))", introspect, introspect);
		int ret = luaL_dostring(Z->lua, zscript);
		if(ret) {
			fprintf(stderr, "Zencode execution error\n");
			fprintf(stderr, "Script:\n%s\n", zscript);
			fprintf(stderr, "%s\n", lua_tostring(Z->lua, -1));
			fflush(stderr);
		}
		zen_teardown(Z);
		cli_free_buffers();
		return EXIT_SUCCESS;
	}

	if(sideload[0]!='\0') {
		fprintf(stderr,"Side loading library: %s\n",sideload);
		load_file(sidescript, fopen(sideload,"rb"));
		zen_exec_lua(Z, sidescript);
		// TODO: detect error
	}

	if(scriptfile[0]!='\0') {
		////////////////////////////////////
		// load a file as script and execute
		if(verbosity) fprintf(stderr, "reading code from file: %s\n", scriptfile);
		load_file(script, fopen(scriptfile, "rb"));
	} else if(scriptarg[0]!='\0') {
		if(verbosity) fprintf(stderr, "executing argument: %s\n",scriptarg);
		snprintf(script,"%s",scriptarg);
	} else {
		////////////////////////
		// get another argument from stdin
		if(verbosity) fprintf(stderr, "reading code from stdin\n");
		load_file(script, stdin);
		// func(NULL, "%s\n--",script);
	}

	// configure to parse Lua or Zencode
	if(zencode) {
		fprintf(stderr, "Zencode execution\n");
	} else {
		fprintf(stderr, "Lua execution\n");
	}

#if (defined(ARCH_WIN) || defined(DISABLE_FORK)) || defined(ARCH_CORTEX) || defined(ARCH_BSD)
	if(zencode)
		zen_exec_zencode(Z, script);
	else
		zen_exec_lua(Z, script);

#else /* POSIX */
	if (!use_seccomp) {
		if(zencode) {
			zen_exec_zencode(Z, script);
		} else {
			zen_exec_lua(Z, script);
		}
	} else {
		fprintf(stderr, "protected mode (seccomp isolation) activated\n");
		if (fork() == 0) {
#   ifdef ARCH_LINUX /* LINUX engages SECCOMP. */
			if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0)) {

				fprintf(stderr, "Seccomp fail to set no_new_privs: %s\n", strerror(errno));
				zen_teardown(Z);

				cli_free_buffers();
				return EXIT_FAILURE;
			}
			if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &strict)) {

				fprintf(stderr, "Seccomp fail to install filter: %s\n", strerror(errno));
				zen_teardown(Z);

				cli_free_buffers();
				return EXIT_FAILURE;
			}
#   endif /* ARCH_LINUX */
			if(verbosity) fprintf(stderr, "starting execution.\n");
			int exitcode;
			if(zencode) {
				exitcode = zen_exec_zencode(Z, script);
			} else {
				exitcode = zen_exec_lua(Z, script);
			}
			zen_teardown(Z);
			cli_free_buffers();
			return exitcode;
		}
		do {
			pid = wait(&status);
		} while(pid == -1);

		if (WIFEXITED(status)) {
			retval = WEXITSTATUS(status);
			if (retval == 0)
				if(verbosity) fprintf(stderr, "Execution completed.\n");
		} else if (WIFSIGNALED(status)) {
			fprintf(stderr, "Execution interrupted by signal %d.\n", WTERMSIG(status));
		}
	}
#endif /* POSIX */
	int exitcode = Z->exitcode;
	zen_teardown(Z);

	{
		// measure and report time of execution
		clock_gettime(CLOCK_MONOTONIC, &after);
		long musecs = (after.tv_sec - before.tv_sec) * 1000000L;
		fprintf(stderr,"Time used: %lu\n", ( ((after.tv_nsec - before.tv_nsec) / 1000L) + musecs) );
	}

	cli_free_buffers();
	return exitcode;
}

#endif // LIBRARY
