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
 */

// for usage information see: bindings/README.md

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <getopt.h>

#include <zenroom.h>
#include <encoding.h>

#if !defined(ARCH_WIN)
#include <sys/poll.h>
#endif


#if defined(LUA_EXEC)
#define CMDNAME "lua-exec"
#else
#define CMDNAME "zencode-exec"
#endif

static char conf        [MAX_CONFIG];
static char script_b64  [MAX_ZENCODE];
static char keys_b64    [MAX_FILE];
static char data_b64    [MAX_FILE];
static char extra_b64   [MAX_FILE];
static char context_b64 [MAX_FILE];

static char *line_alloc(char *in, int max) {
	if( ! fgets(in, max, stdin) ) return NULL;
	if(in[0]=='\n') return NULL; // newline is empty line
	if(in[0]=='\r') return NULL; // carriage return is empty line
	int len = is_base64(in);
	if(!len) {
		fprintf(stderr,"Invalid input base64 encoding\n");
		exit(EXIT_FAILURE);
	}
	in[len]=0x0;
	if(in[len-2]=='\r') in[len-2]=0x0; // remove ending CRLF
	if(in[len-1]=='\n') in[len-1]=0x0; // remove ending LF
	char *line = malloc(B64decoded_len(len));
	int reallen = B64decode(line, in);
	line[reallen] = 0x0;
	return(line);
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;
  int ret;
  zenroom_t *Z;

#if !defined(ARCH_WIN)
  struct pollfd fds;
#endif

  conf[0] = 0x0;
  script_b64[0] = 0x0;
  keys_b64[0] = 0x0;
  data_b64[0] = 0x0;
  extra_b64[0] = 0x0;
  context_b64[0] = 0x0;

  int opt;
  const char *short_options = "v";
  while((opt = getopt(argc, argv, short_options)) != -1) {
	  switch(opt) {
	  case 'v':
#if defined(LUA_EXEC)
		  fprintf(stderr,"Lua auxiliary executor for Zenroom bindings\n");
#else
		  fprintf(stderr,"Zencode auxiliary executor for Zenroom bindings\n");
#endif
		  exit(0);
		  break;
	  }
  }

// TODO(jaromil): find a way to check stdin on windows
#if !defined(ARCH_WIN)
  fds.fd = 0; // stdin
  fds.events = POLLIN;
  ret = poll(&fds, 1, -1); // by default wait until input
  if(ret == 0) {
	fprintf(stderr,"usage: stream | %s\n",CMDNAME);
	exit(1);
  } else if(ret != 1) {
	fprintf(stderr,"stdin error: %s\n",strerror(errno));
	exit(1);
  }
#endif

  if( fgets(conf, MAX_CONFIG, stdin) ) {
	  if(strlen(conf)>=MAX_CONFIG) {
		  fprintf(stderr,"%s error: conf string out of bounds.\n",CMDNAME);
		  return EXIT_FAILURE;
	  }
	  if(conf[0] != '\n')	{
		  int cl = strlen(conf);
		  if( conf[cl-2]=='\r' ) conf[cl-2] = 0x0; // remove ending CRLF
		  if( conf[cl-1]=='\n' ) conf[cl-1] = 0x0; // remove ending LF
		  conf[cl] = 0x0;
		  strcat(conf,",logfmt=json");
	  } else {
		  snprintf(conf,MAX_CONFIG,"logfmt=json");
	  }
  } else {
	  fprintf(stderr, "%s missing conf at line 1: %s\n",CMDNAME,strerror(errno));
	  return EXIT_FAILURE;
  }

  char *script =  line_alloc(script_b64,  MAX_ZENCODE);
  char *keys =    line_alloc(keys_b64,    MAX_FILE);
  char *data =    line_alloc(data_b64,    MAX_FILE);
  char *extra =   line_alloc(extra_b64,   MAX_FILE);
  char *context = line_alloc(context_b64, MAX_FILE);
  // call zenroom init with all arguments
  Z = zen_init_extra(conf,keys,data,extra,context);
  free(keys);
  free(data);
  free(extra);
  free(context);

  if(!Z) {
	fprintf(stderr, "\"[!] Initialisation failed\",\n");
	fprintf(stderr,"\"ZENROOM JSON LOG END\" ]\n");
	return EXIT_FAILURE;
  }

  // call zenroom exec
#if defined(LUA_EXEC)
  zen_exec_lua(Z, script);
#else
  // heap and trace dumps in base64 encoded json (J64)
  zen_exec_lua(Z, "CONF.debug.format='compact'");
  zen_exec_zencode(Z, script);
#endif
  free(script);
  int exitcode = Z->exitcode;
  zen_teardown(Z);
  return exitcode;
}
