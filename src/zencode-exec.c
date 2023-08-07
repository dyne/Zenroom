/*
 * This file is part of zenroom
 * 
 * Copyright (C) 2017-2023 Dyne.org foundation
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

#include <zenroom.h>

#if !defined(ARCH_WIN)
#include <sys/poll.h>
#endif

static void _getline(char *in) {
	register int ret;
	if( ! fgets(in, MAX_FILE, stdin) ) { in[0]=0x0; return; }
	ret = strlen(in);
	if(in[0]=='\n') { in[0]=0x0; return; } // remove newline on empty line
	if(in[0]=='\r') { in[0]=0x0; return; } // remove carriage return on empty line
	ret = strlen(in);
	if(ret<4) {// min base64 is 4 chars
		fprintf(stderr,"zencode-exec error: input line too short.\n");
		exit(EXIT_FAILURE);
	}
	if(in[ret-2]=='\r') { in[ret-2]=0x0; return; } // remove ending CRLF
	if(in[ret-1]=='\n') { in[ret-1]=0x0; return; } // remove ending LF
	fprintf(stderr, "zencode-exec invalid input\n");
	exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;
  register int ret;
  zenroom_t *Z;

#if !defined(ARCH_WIN)
  struct pollfd fds;
#endif

  char script_b64[MAX_ZENCODE];
  char keys_b64[MAX_FILE];
  char data_b64[MAX_FILE];
  char conf[MAX_CONFIG];
  char extra_b64[MAX_FILE];
  char context_b64[MAX_FILE];
  script_b64[0] = 0x0;
  keys_b64[0] = 0x0;
  data_b64[0] = 0x0;
  extra_b64[0] = 0x0;
  context_b64[0] = 0x0;
  conf[0] = 0x0;

// TODO(jaromil): find a way to check stdin on windows
#if !defined(ARCH_WIN)
  fds.fd = 0; // stdin
  fds.events = POLLIN;
  ret = poll(&fds, 1, -1); // by default wait until input
  if(ret == 0) {
	fprintf(stderr,"usage: stream | zencode-exec\n");
	exit(1);
  } else if(ret != 1) {
	fprintf(stderr,"stdin error: %s\n",strerror(errno));
	exit(1);
  }
#endif

  if( fgets(conf, MAX_CONFIG, stdin) ) {
	if(strlen(conf)>=MAX_CONFIG) {
	  fprintf(stderr,"zencode-exec error: conf string out of bounds.\n");
	  return EXIT_FAILURE;
	}
	if(conf[0] != '\n')	{
	  conf[strlen(conf)-1] = 0x0; // remove ending LF
	  strcat(conf,",logfmt=json");
	} else {
	  snprintf(conf,MAX_CONFIG,"logfmt=json");
	}
  } else {
	fprintf(stderr, "zencode-exec missing conf at line 1: %s\n",strerror(errno));
	return EXIT_FAILURE;
  }

  if( ! fgets(script_b64, MAX_ZENCODE, stdin) ) {
	fprintf(stderr, "zencode-exec missing script at line 2: %s\n",strerror(errno));
	return EXIT_FAILURE;
  }
  ret = strlen(script_b64);
  if( ret < 16) {
	fprintf(stderr, "zencode-exec error: script too short.\n");
	return EXIT_FAILURE;
  }
  if( script_b64[ret-2]=='\r' ) script_b64[ret-2] = 0x0; // remove ending CRLF
  if( script_b64[ret-1]=='\n' ) script_b64[ret-1] = 0x0; // remove ending LF

  _getline(keys_b64);
  _getline(data_b64);
  _getline(extra_b64);
  _getline(context_b64);

	{
		fprintf(stderr,"%s\n",conf);
		fprintf(stderr,"%s\n",script_b64);
		fprintf(stderr,"%s\n",keys_b64);
		fprintf(stderr,"%s\n",data_b64);
		fprintf(stderr,"%s\n",extra_b64);
		fprintf(stderr,"%s\n",context_b64);
	}
  Z = zen_init_extra(conf,
					 keys_b64[0]?keys_b64:NULL,
					 data_b64[0]?data_b64:NULL,
					 extra_b64[0]?extra_b64:NULL,
					 context_b64[0]?context_b64:NULL);
  if(!Z) {
	fprintf(stderr, "\"[!] Initialisation failed\",\n");
	fprintf(stderr,"\"ZENROOM JSON LOG END\" ]\n");
	return EXIT_FAILURE;
  }

  // TODO(jaromil): if used elsewhere promote to conf directives
  // heap and trace dumps in base64 encoded json
  zen_exec_script(Z, "CONF.debug.format='compact'");
  // import DATA and KEYS from base64
  zen_exec_script(Z, "CONF.input.format.fun = function(obj) return JSON.decode(OCTET.from_base64(obj):str()) end");
  zen_exec_script(Z, "CONF.code.encoding.fun = function(obj) return OCTET.from_base64(obj):str() end");

  zen_exec_zencode(Z, script_b64);

  register int exitcode = Z->exitcode;
  zen_teardown(Z);
  return exitcode;
}
