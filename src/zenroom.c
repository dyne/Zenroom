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

// open/close
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
// read
#include <unistd.h>

#include <errno.h>

#include <jutils.h>

#include <bitop.h>
#include <luazen.h>

#include <luasandbox.h>
#include <luasandbox/util/util.h>
#include <luasandbox/lauxlib.h>

#define MAX_FILE 102400 // load max 100Kb files
#define MAX_STRING 4096

// prototypes from lua_functions
void lsb_setglobal_string(lsb_lua_sandbox *lsb, char *key, char *val);
void lsb_openlibs(lsb_lua_sandbox *lsb);
extern int lua_cjson_safe_new(lua_State *l);
extern int lua_cjson_new(lua_State *l);

// from timing.c
// extern int set_hook(lua_State *L);

// void log_debug(lua_State *l, lua_Debug *d) {
// 	error("%s\n%s\n%s",d->name, d->namewhat, d->short_src);
// }

static char *confdefault =
"memory_limit = 0\n"
"instruction_limit = 0\n"
"output_limit = 64*1024\n"
"log_level = 7\n"
"path = '/dev/null'\n"
"cpath = '/dev/null'\n"
"remove_entries = {\n"
"	[''] = {'dofile','load', 'loadfile','newproxy'},\n"
"	os = {'getenv','execute','exit','remove','rename',\n"
"		  'setlocale','tmpname'},\n"
"   math = {'random', 'randomseed'}\n"
" }\n"
"disable_modules = {io = 1}\n";

void logger(void *context, const char *component,
                   int level, const char *fmt, ...) {
	// suppress warnings about these unused paraments
	(void)context;
	(void)level;

	va_list args;
	// func("LUA: %s",(component) ? component : "unknown");
	va_start(args, fmt);
	vfprintf(stdout, fmt, args);
	va_end(args);
	fwrite("\n", 1, 1, stdout);
	fflush(stderr);
}

// simple function to load files with basic open/read that are not
// wrapped by emscripten to access its virtual filesystem. This
// function exists the process on failure.
void load_file(char *dst, char *path) {
	int fd = open(path, O_RDONLY);
	off_t len = 0;
	size_t readin = 0;
	func("load_file: %s", path);
	if(fd<0) {
		error("Error opening %s: %s", path, strerror(errno));
		close(fd);
		exit(1); }
	// calculate length
	len = lseek(fd,0,SEEK_END);
	if(len<0) {
		error("Error seeking end of %s: %s", path, strerror(errno));
		close(fd);
		exit(1); }
	if(lseek(fd,0,SEEK_SET)<0) {
		error("Error rewinding %s: %s", path, strerror(errno));
		close(fd);
		exit(1); }
	// TODO: skip shebang at first line
	readin = read(fd, dst, len);
	if(!readin) {
		error("Error reading %s: %s", path, strerror(errno));
		close(fd);
		exit(1); }
	act("loaded file: %s (%u bytes)", path, readin);
	func("file contents:\n%s\n", dst);
	close(fd);
}

char *safe_string(char *str) {
	int length = 0;
	while (length < MAX_STRING && str[length] != '\0') ++length;

	if (!length) {
		warning("NULL string detected");
		return NULL; }

	if (length >= MAX_STRING) {
		error("unterminated string detected:\n%s",str);
		return NULL; }

	for (int i = 0; i < length; ++i) {
		if (!isprint(str[i]) && !isspace(str[i])) {
			error("unprintable character (ASCII %d) at position %d",
			      (unsigned char)str[i], i);
			return NULL;
		}
	}
	return(str);
}

int zenroom_exec(char *script, char *conf, char *args, int debuglevel) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	lsb_lua_sandbox *lsb = NULL;
	int usage;
	int return_code = 1; // return error by default
	char *p;
	const luaL_Reg *lib;
	const char *r;

	if(!script) {
		error("NULL string as script for zenroom_exec()");
		exit(1); }
	set_debug(debuglevel);

	// TODO: how to pass config file and script to javascript?

	lsb_logger lsb_vm_logger = { .context = "zenroom_exec",
	                             .cb = logger };

	lsb = lsb_create(NULL, script, (conf)?safe_string(conf):confdefault, &lsb_vm_logger);
	if(!lsb) {
		error("Error creating sandbox: %s", lsb_get_error(lsb));
		exit(1); }

	// load our own extensions
	lib = (luaL_Reg*) &luazen;
	func("loading luazen extensions");
	for (; lib->func; lib++) {
		func("%s",lib->name);
		lsb_add_function(lsb, lib->func, lib->name);
	}

	lib = (luaL_Reg*) &bit_funcs;
	func("loading bitop extensions");
	for (; lib->func; lib++) {
		func("%s",lib->name);
		lsb_add_function(lsb, lib->func, lib->name);
	}

	func("loading cjson extensions");
	lsb_add_function(lsb, lua_cjson_new, "cjson");
	lsb_add_function(lsb, lua_cjson_safe_new, "cjson_safe");

	// load arguments from json if present
	if(args) // avoid errors on NULL args
		if(safe_string(args))
			lsb_setglobal_string(lsb,"arguments",args);

	// TODO: MILAGRO

	// initialise global variables
	lsb_setglobal_string(lsb, "VERSION", VERSION);
	lsb_openlibs(lsb);

	r = lsb_init(lsb, NULL);
	if(r) {
		error(r);
		error(lsb_get_error(lsb));
		error("Error detected. Execution aborted.");
		lsb_pcall_teardown(lsb);
		lsb_stop_sandbox_clean(lsb);
		p = lsb_destroy(lsb);
		if(p) free(p);
		exit(1);
	}
	return_code = 0; // return success
	// debugging stats here
	// while(lsb_get_state(lsb) == LSB_RUNNING)
	//  act("running...");

	usage = lsb_usage(lsb, LSB_UT_MEMORY, LSB_US_CURRENT);
	act("used memory: %u bytes", usage);
	usage = lsb_usage(lsb, LSB_UT_INSTRUCTION, LSB_US_CURRENT);
	act("executed operations: %u", usage);

	notice("Zenroom operations completed.");

	lsb_pcall_teardown(lsb);
	lsb_stop_sandbox_clean(lsb);
	p = lsb_destroy(lsb);
	if(p) free(p);
	return(return_code);
}

int main(int argc, char **argv) {
	static char conffile[512] = "zenroom.conf";
	static char scriptfile[512] = "zenroom.lua";
	static char argfile[512];
	static char script[MAX_FILE];
	static char conf[MAX_FILE];
	static char args[MAX_FILE];

	int opt, index;
	int debuglevel = 1;
	int ret;
	const char *short_options = "hdc:a:i";
    const char *help =
		"Usage: zenroom [ -c config ] [ -a arguments ] [ script.lua | - ]\n";
    conffile[0] = '\0';
    scriptfile[0] = '\0';
    argfile[0] = '\0';
    args[0] = '\0';

	notice( "Zenroom - crypto language restricted execution environment %s",VERSION);
	act("Copyright (C) 2017-2018 Dyne.org foundation");
	while((opt = getopt(argc, argv, short_options)) != -1) {
		switch(opt) {
		case 'd':
			debuglevel = 3;
			break;
		case 'h':
			fprintf(stdout,"%s",help);
			exit(0);
			break;
		case 'a':
			snprintf(argfile,511,"%s",optarg);
			break;
		case 'c':
			snprintf(conffile,511,"%s",optarg);
			break;
		case '?': error(help); exit(1);
		default:  error(help); exit(1);
		}
	}
	for (index = optind; index < argc; index++) {
		char *path = argv[index];
		if(path[0]=='-') { scriptfile[0]='\0'; break; }
		else snprintf(scriptfile,511,"%s",argv[index]);
	}
	if(scriptfile[0]=='\0') {
		// get script from stdin
		char ch;
		int c;
		for(c=0; c<MAX_FILE-1; c++) {
			if(!read(STDIN_FILENO, &ch, 1)) break;
			script[c]=ch;
		}
		script[c]='\0';
	} else
		load_file(script, scriptfile);
	// configuration from -c or default
	if(conffile[0]!='\0')
		load_file(conf, conffile);
	else
		act("using default configuration");

	if(argfile[0]!='\0') load_file(args, argfile);
	ret = zenroom_exec(script,
	                   (conffile[0]=='\0')?confdefault:conf, 
	                   (args[0]=='\0')?NULL:args, debuglevel);
	// exit(1) on failure
	exit(ret);
}
