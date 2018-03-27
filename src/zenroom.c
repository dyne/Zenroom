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

#include <lua.h>

#include <lua_functions.h>
#include <repl.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

// prototypes from lua_modules.c
extern void zen_load_extensions(lua_State *L);
extern void zen_add_function(lua_State *L, lua_CFunction func,
                                  const char *func_name);

// This function exits the process on failure.
void load_file(char *dst, FILE *fd) {
	char firstline[MAX_STRING];
	long file_size = 0L;
	size_t offset = 0;
	size_t bytes = 0;
	if(!fd) {
		error("Error opening %s", strerror(errno));
		exit(1); }
	if(fd!=stdin) {
		if(fseek(fd, 0L, SEEK_END)<0) {
			error("fseek(end) error in %s: %s",__func__,
			      strerror(errno));
			exit(1); }
		file_size = ftell(fd);
		if(fseek(fd, 0L, SEEK_SET)<0) {
			error("fseek(start) error in %s: %s",__func__,
			      strerror(errno));
			exit(1); }
		func("size of file: %u",file_size);
	}
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

	size_t chunk;
	while(1) {
		chunk = MAX_STRING;
		if( offset+MAX_STRING>MAX_FILE )
			chunk = MAX_FILE-offset-1;
		bytes = fread(&dst[offset],sizeof(char),chunk,fd);

		if(!bytes) {
			if(feof(fd)) {
				if((fd!=stdin) && (long)offset!=file_size)
					warning("Incomplete file read (%u of %u bytes)",
					      offset, file_size);
				else
					func("EOF after %u bytes",offset);
				break; }
			if(ferror(fd)) {
				error("Error in %s: %s",__func__,strerror(errno));
				fclose(fd);
				exit(1); }
		}
		offset += bytes;
	}
	if(fd!=stdin) fclose(fd);
	act("loaded file (%u bytes)", offset);
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

	zen_load_extensions(L);
	// load our own openlibs and extensions

	// load arguments from json if present
	if(data) // avoid errors on NULL args
		if(safe_string(data)) {
			func("declaring global: DATA");
			lsb_setglobal_string(L,"DATA",data);
		}
	if(keys)
		if(safe_string(keys)) {
			func("declaring global: KEYS");
			lsb_setglobal_string(L,"KEYS",keys);
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
		lua_State  *cli;
		cli = zen_init(NULL);
		// load our own extensions
		zen_load_extensions(cli);

		// print function
		zen_add_function(cli, repl_flush, "flush");
		zen_add_function(cli, repl_read, "read");
		zen_add_function(cli, repl_write, "write");

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
		load_file(script, fopen(scriptfile, "rb"));
	}

	// configuration from -c or default
	if(conffile[0]!='\0')
		load_file(conf, fopen(conffile, "r"));
	else
		act("using default configuration");


	ret = zenroom_exec(script,
	                   (conf[0]!='\0')?conf:NULL,
	                   (keys[0]!='\0')?keys:NULL,
	                   (data[0]!='\0')?data:NULL,
	                   verbosity);
	// exit(1) on failure
	exit(ret);
}
#endif