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

#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <amcl.h> // OCT_frombase64

#include <zenroom.h>

#include <sys/poll.h>

char *alloc_from_b64(char *b64) {
  octet o;
  int encoded_size = strlen(b64);
  o.max = ((encoded_size+3)>>2)*3;
  o.val = malloc(o.max+1);
  OCT_frombase64(&o, b64);
  o.val[o.len-4] = '\0'; // -4 avoids some weird padding
  return(o.val);
}


int main(int argc, char **argv) {
  (void)argc;
  (void)argv;
  register int ret;
  zenroom_t *Z;
  struct pollfd fds;

  char script_b64[MAX_ZENCODE];
  char keys_b64[MAX_FILE];
  char data_b64[MAX_FILE];
  char conf[MAX_CONFIG];
  script_b64[0] = 0x0;
  keys_b64[0] = 0x0;
  data_b64[0] = 0x0;
  conf[0] = 0x0;

  char *script = NULL;
  char *keys = NULL;
  char *data = NULL;


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

  if( ! fgets(script_b64, MAX_ZENCODE, stdin) ) {
	fprintf(stderr, "fgets #1 (script): %s\n",strerror(errno));
	return EXIT_FAILURE;
  }
  script = alloc_from_b64(script_b64);
//  fprintf(stderr,"script in: %s\n",script);

  if( fgets(keys_b64, MAX_FILE, stdin) ) {
	keys = alloc_from_b64(keys_b64);
//	fprintf(stderr,"keys in: %s\n",keys);
  }

  if( fgets(data_b64, MAX_FILE, stdin) ) {
	data = alloc_from_b64(data_b64);
//	fprintf(stderr,"data in: %s\n",keys);
  }

  if( fgets(conf, MAX_CONFIG, stdin) ) {
	strcat(conf,",logfmt=json");
  } else {
	sprintf(conf,"logfmt=json");
  }

  Z = zen_init(conf, keys, data);
  if(!Z) {
	fprintf(stderr, "\"[!] Initialisation failed\",\n");
	if(script) free(script);
	if(keys) free(keys);
	if(data) free(data);
	fprintf(stderr,"\"ZENROOM JSON LOG END\" ]\n");
	return EXIT_FAILURE;
  }

  zen_exec_zencode(Z, script);

  register int exitcode = Z->exitcode;
  zen_teardown(Z);
  if(script) free(script);
  if(keys) free(keys);
  if(data) free(data);
  return exitcode;
}
