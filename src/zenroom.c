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

#include <luasandbox.h>

#include <lua_functions.h>
#include <repl.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

// prototypes from lua_modules.c
extern void zen_load_extensions(lsb_lua_sandbox *lsb);


static char *confdefault =
"memory_limit = 0\n"
"instruction_limit = 0\n"
"output_limit = 64*1024\n"
"log_level = 7\n"
"path = '/dev/null'\n"
"cpath = '/dev/null'\n"
"remove_entries = {\n"
"	[''] = {'dofile', 'load', 'loadfile','newproxy'},\n"
"	os = {'execute','remove','rename','setlocale','tmpname'},\n"
"   math = {'random', 'randomseed'},\n"
"   io = {'close', 'open', 'popen', 'tmpfile'}\n"
" }\n";
// "disable_modules = {io = 1}\n";

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
void load_file(char *dst, FILE *fd) {
	char firstline[MAX_STRING];
	size_t offset = 0;
	size_t bytes = 0;

	if(!fd) {
		error("Error opening %s", strerror(errno));
		exit(1); }
	// skip shebang on firstline
	if(!fgets(firstline, MAX_STRING, fd)) {
		error("Error reading first line: %s", strerror(errno));
		exit(1); }
	if(firstline[0]=='#' && firstline[1]=='!')
		func("Skipping shebang");
	else {
		offset+=strlen(firstline);
		strncpy(dst,firstline,MAX_STRING);
	}
	for(;;) {
		if( offset+1024>MAX_FILE ) break;
		bytes = fread(&dst[offset],sizeof(char),MAX_STRING,fd);
		offset += bytes;
		if( bytes<MAX_STRING && feof(fd) ) break;
	}
	fclose(fd);
	act("loaded file (%u bytes)", offset);
	func("file contents:\n%s", dst);
}

char *safe_string(char *str) {
	int i, length = 0;
	if(!str) {
		warning("NULL string detected");
		return NULL; }
	if(str[0]=='\0') {
		warning("empty string detected");
		return NULL; }

	while (length < MAX_STRING && str[length] != '\0') ++length;

	if (length == MAX_STRING)
		warning("maximum size string detected (may be truncated) at address %p",str);

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

	lsb = zen_init(conf);
	if(!lsb) {
		error("Initialisation failed.");
		return 1;
	}

	zen_load_extensions(lsb);
	// load our own openlibs and extensions

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

	r = zen_exec_script(lsb, script);
	if(r) {
#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_error();});
#endif
		error(r);
		error(lsb_get_error(lsb));
		error("Error detected. Execution aborted.");

		usage = lsb_usage(lsb, LSB_UT_MEMORY, LSB_US_CURRENT);
		error("used memory: %u bytes", usage);
		usage = lsb_usage(lsb, LSB_UT_INSTRUCTION, LSB_US_CURRENT);
		error("executed operations: %u", usage);

		zen_teardown(lsb);
		return(1);
	}
	return_code = 0; // return success
	// debugging stats here
	// while(lsb_get_state(lsb) == LSB_RUNNING)
	//  act("running...");

#ifdef __EMSCRIPTEN__
		EM_ASM({Module.exec_ok();});
#endif

	usage = lsb_usage(lsb, LSB_UT_MEMORY, LSB_US_CURRENT);
	act("used memory: %u bytes", usage);
	usage = lsb_usage(lsb, LSB_UT_INSTRUCTION, LSB_US_CURRENT);
	act("executed operations: %u", usage);

	notice("Zenroom operations completed.");
	zen_teardown(lsb);
	return(return_code);
}

int main(int argc, char **argv) {
	char conffile[MAX_STRING] = "zenroom.conf";
	char scriptfile[MAX_STRING] = "zenroom.lua";
	char keysfile[MAX_STRING];
	char datafile[MAX_STRING];
	char script[MAX_FILE];
	char conf[MAX_FILE];
	char keys[MAX_FILE];
	char data[MAX_FILE];
	int readstdin = 0;
	int opt, index;
    int verbosity = 1;
	int ret;
	const char *short_options = "hdc:k:a:";
    const char *help =
	    "Usage: zenroom [-dh] [ -c config ] [ -k keys ] [ -a data ] [ script.lua | - ]\n";
    conffile[0] = '\0';
    scriptfile[0] = '\0';
    keysfile[0] = '\0';
    datafile[0] = '\0';
    data[0] = '\0';
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
		char *path = argv[index];
		if(path[0]=='-') { readstdin = 1; }
		else snprintf(scriptfile,511,"%s",argv[index]);
	}

	if(keysfile[0]!='\0') {
		act("reading KEYS from file: %s", keysfile);
		load_file(keys, fopen(keysfile, "r"));
	}

	if(datafile[0]!='\0') {
		act("reading DATA from file: %s", datafile);
		load_file(data, fopen(datafile, "r"));
	}

	if(readstdin) {
		////////////////////////
		// get another argument from stdin
		act("reading CODE from stdin");
		load_file(script, stdin);
		func("%s\n--",script);

		////////////////////////////////////
		// start an interactive repl console
	} else if(scriptfile[0]=='\0') {
		lsb_lua_sandbox *cli;
		cli = zen_init(confdefault);
		// load our own extensions
		zen_load_extensions(cli);

		// print function
		lsb_add_function(cli, output_print, "print");
		lsb_add_function(cli, repl_flush, "flush");
		lsb_add_function(cli, repl_read, "read");
		lsb_add_function(cli, repl_write, "write");

		if(data[0]!='\0') lsb_setglobal_string(cli,"DATA",data);
		if(keys[0]!='\0') lsb_setglobal_string(cli,"KEYS",keys);
		notice("Interactive console, press ctrl-d to quit.");
		repl_loop(cli);
		// quits on ctrl-D
		zen_teardown(cli);
	} else {
		////////////////////////////////////
		// load a file as script and execute
		act("reading CODE from file: %s", scriptfile);
		load_file(script, fopen(scriptfile, "r"));
	}

	// configuration from -c or default
	if(conffile[0]!='\0')
		load_file(conf, fopen(conffile, "r"));
	else
		act("using default configuration");


	ret = zenroom_exec(script,
	                   (conf[0]!='\0')?conf:confdefault,
	                   (keys[0]!='\0')?keys:NULL,
	                   (data[0]!='\0')?data:NULL,
	                   verbosity);
	// exit(1) on failure
	exit(ret);
}
