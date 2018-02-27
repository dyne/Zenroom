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
#include <zenroom.h>

#include <linenoise.h>

#include <luasandbox.h>
#include <luasandbox/util/util.h>
#include <luasandbox/lauxlib.h>

// prototypes from lua_functions
extern void lsb_setglobal_string(lsb_lua_sandbox *lsb, char *key, char *val);
extern void lsb_openlibs(lsb_lua_sandbox *lsb);
extern void lsb_load_extensions(lsb_lua_sandbox *lsb);

extern int lua_cjson_safe_new(lua_State *l);
extern int lua_cjson_new(lua_State *l);

// from repl.c
extern lsb_lua_sandbox *repl_init(char *conf);
extern int repl_exec(lsb_lua_sandbox *lsb, const char *line);
extern int repl_teardown(lsb_lua_sandbox *lsb);

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
"	[''] = {'dofile', 'load', 'loadfile','newproxy'},\n"
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
	(void)component;

	va_list args;
	// func("LUA: %s",(component) ? component : "unknown");
	va_start(args, fmt);
	vfprintf(stdout, fmt, args);
	va_end(args);
	fwrite("\n", 1, 1, stdout);
	fflush(stdout);
}


// This function exits the process on failure.
void load_file(char *dst, char *path) {
	char firstline[512];
	size_t offset = 0;
	size_t bytes = 0;

	FILE *fd = fopen(path, "r");
	if(!fd) {
		error("Error opening %s: %s", path, strerror(errno));
		exit(1); }
	if(!fgets(firstline, 512, fd)) {
		error("Error reading first line of %s: %s", path, strerror(errno));
		exit(1); }
	if(firstline[0]=='#' && firstline[1]=='!')
		func("Skipping shebang in %s", path);
	else {
		offset+=strlen(firstline);
		strncpy(dst,firstline,512);
	}
	for(;;) {
		if( offset+1024>MAX_FILE ) break;
		bytes = fread(&dst[offset],sizeof(char),1024,fd);
		offset += bytes;
		if( bytes<1024 && feof(fd) ) break;
	}
	fclose(fd);
	act("loaded file: %s (%u bytes)", path, offset);
	func("file contents:\n%s", dst);
}

char *safe_string(char *str) {
	int i, length = 0;
	while (length < MAX_STRING && str[length] != '\0') ++length;

	if (!length) {
		warning("NULL string detected");
		return NULL; }

	if (length >= MAX_STRING) {
		error("unterminated string detected:\n%s",str);
		return NULL; }

	for (i = 0; i < length; ++i) {
		if (!isprint(str[i]) && !isspace(str[i])) {
			error("unprintable character (ASCII %d) at position %d",
			      (unsigned char)str[i], i);
			return NULL;
		}
	}
	return(str);
}

int zenroom_exec(char *script, char *conf, char *keys,
                 char *data, int verbosity) {
	// the sandbox context (can be initialised only once)
	// stores the script file and configuration
	lsb_lua_sandbox *lsb = NULL;
	int usage;
	int return_code = 1; // return error by default
	char *p;
	const char *r;

	if(!script) {
		error("NULL string as script for zenroom_exec()");
		exit(1); }
	set_debug(verbosity);

	// TODO: how to pass config file and script to javascript?


	lsb_logger lsb_vm_logger = { .context = "zenroom_exec",
	                             .cb = logger };

	lsb = lsb_create(NULL, script, (conf)?safe_string(conf):confdefault, &lsb_vm_logger);
	if(!lsb) {
		error("Error creating sandbox: %s", lsb_get_error(lsb));
		exit(1); }


	// initialise global variables
	lsb_setglobal_string(lsb, "VERSION", VERSION);
	lsb_openlibs(lsb);

	lsb_load_extensions(lsb);
	// load our own extensions

	func("loading cjson extensions");
	lsb_add_function(lsb, lua_cjson_safe_new, "cjson");
	lsb_add_function(lsb, lua_cjson_new, "cjson_full");

	// load arguments from json if present
	if(data) // avoid errors on NULL args
		if(safe_string(data)) {
			func("declaring global: DATA");
			lsb_setglobal_string(lsb,"DATA",data);
		}
	if(keys)
		if(safe_string(keys)) {
			func("declaring global: KEYS");
			lsb_setglobal_string(lsb,"KEYS",keys);
		}
	// TODO: MILAGRO

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
	char conffile[512] = "zenroom.conf";
	char scriptfile[512] = "zenroom.lua";
	char keysfile[512];
	char script[MAX_FILE];
	char conf[MAX_FILE];
	char keys[MAX_FILE];
	char pipedin[MAX_FILE];
	int readstdin = 0;
	int opt, index;
    int verbosity = 1;
	int ret;
	const char *short_options = "hdc:k:i";
    const char *help =
		"Usage: zenroom [-dh] [ -c config ] [ -k keys ] [ script.lua ] [ - ]\n";
    conffile[0] = '\0';
    scriptfile[0] = '\0';
    keysfile[0] = '\0';
    keys[0] = '\0';
    conf[0] = '\0';
    script[0] = '\0';

	notice( "Zenroom - crypto language restricted execution environment %s",VERSION);
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
		case 'k':
			snprintf(keysfile,511,"%s",optarg);
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
		if(path[0]=='-') { readstdin = 1; }
		else snprintf(scriptfile,511,"%s",argv[index]);
	}

	if(keysfile[0]!='\0') {
		act("reading KEYS from file");
		load_file(keys, keysfile);
	}

	if(readstdin) {
		////////////////////////
		// get another argument from stdin
		act("reading DATA from stdin");
		size_t bytes = 0;
		size_t offset = 0;
		for(;;) {
			bytes = fread(&pipedin[offset],sizeof(char),1024,stdin);
			offset += bytes;
			if( bytes<1024 && feof(stdin) ) break;
		}
		func("%u bytes read",offset);
		func("%s",pipedin);

		////////////////////////////////////
		// start an interactive repl console
	}

	if(scriptfile[0]=='\0') {
		lsb_lua_sandbox *cli;
		char *line;
		cli = repl_init(confdefault);
		if(readstdin)     lsb_setglobal_string(cli,"DATA",pipedin);
		if(keys[0]!='\0') lsb_setglobal_string(cli,"KEYS",keys);
		while((line = linenoise("zen> ")) != NULL) {
			repl_exec(cli, line);
			// if(ret != 0) break;
			linenoiseFree(line);
		}
		repl_teardown(cli);
	} else {
		////////////////////////////////////
		// load a file as script and execute
		load_file(script, scriptfile);
	}

	// configuration from -c or default
	if(conffile[0]!='\0')
		load_file(conf, conffile);
	else
		act("using default configuration");


	ret = zenroom_exec(script,
	                   (conf[0]!='\0')?conf:confdefault,
	                   (keys[0]!='\0')?keys:NULL,
	                   (readstdin)?pipedin:NULL,
	                   verbosity);
	// exit(1) on failure
	exit(ret);
}
