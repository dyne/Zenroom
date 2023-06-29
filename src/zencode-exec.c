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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <zenroom.h>

#if !defined(ARCH_WIN)
#include <sys/poll.h>
#endif

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
  script_b64[0] = 0x0;
  keys_b64[0] = 0x0;
  data_b64[0] = 0x0;
  conf[0] = 0x0;

// TODO(jaromil): find a way to check stdin on windows
#if !defined(ARCH_WIN)
  fds.fd = 0; // stdin
  fds.events = POLLIN;
  ret = poll(&fds, 1, 0);
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
	  strcat(conf,",logfmt=json");
	} else {
	  snprintf(conf,MAX_CONFIG,"logfmt=json");
	}
  } else {
	  snprintf(conf,MAX_CONFIG,"logfmt=json");
  }

  if( ! fgets(script_b64, MAX_ZENCODE, stdin) ) {
	fprintf(stderr, "zencode-exec missing script at line 2: %s\n",strerror(errno));
	return EXIT_FAILURE;
  }

  if( fgets(keys_b64, MAX_FILE, stdin) ) {
	ret = strlen(keys_b64); keys_b64[ret-1] = 0x0; // remove newline
  }
  if( fgets(data_b64, MAX_FILE, stdin) ) {
	ret = strlen(data_b64); data_b64[ret-1] = 0x0; // remove newline
  }

  Z = zen_init(conf,
			   keys_b64[0]?keys_b64:NULL,
			   data_b64[0]?data_b64:NULL);
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


  ret = strlen(script_b64); script_b64[ret-1] = 0x0; // remove newline
  zen_exec_zencode(Z, script_b64);

  register int exitcode = Z->exitcode;
  zen_teardown(Z);
  return exitcode;
}
