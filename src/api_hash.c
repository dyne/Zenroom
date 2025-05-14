/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2022-2025 Dyne.org foundation
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

// external API function for streaming hash
#include <stdio.h>
#include <strings.h>

#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
#endif

#include <amcl.h>
#include <ecdh_support.h> // AMCL

#include <zen_error.h>
#include <encoding.h> // zenroom

 // first byte is type
#define ZEN_SHA512 '4'
#define ZEN_SHA256 '2'

int print_ctx_hex(char prefix, void *sh, int len) {
  char *hash_ctx = malloc((len<<1)+2);
  if(!hash_ctx) {_err( "%s :: cannot allocate hash_ctx",__func__);return FAIL();}
  hash_ctx[0] = prefix;
  buf2hex(hash_ctx+1, (const char*)sh, (const size_t)len);
  hash_ctx[(len<<1)+1] = 0x0; // null terminated string
  _out("%s",hash_ctx);
  free(hash_ctx);
  return OK();
}

// returns a fills hash_ctx, which must be pre-allocated externally
int zenroom_hash_init(const char *hash_type) {
  register char prefix = '0';
  // size tests
  register int len = 0;
  void *sh = NULL;
  if(strcasecmp(hash_type, "sha512") == 0) {    
    prefix = ZEN_SHA512;
    len = sizeof(hash512); // amcl struct
    sh = calloc(len, 1);
	if(!sh) {_err( "%s :: cannot allocate sh",__func__);return FAIL();}
    HASH512_init((hash512*)sh); // amcl init
  } else if(strcasecmp(hash_type, "sha256") == 0) {    
    prefix = ZEN_SHA256;
    len = sizeof(hash256);
	sh = calloc(len, 1);
	if(!sh) {_err( "%s :: cannot allocate hash",__func__);return FAIL();}
    HASH256_init((hash256*)sh); // amcl init
  }
  else {
	_err("%s :: invalid hash type: %s", __func__, hash_type);
	return FAIL();
  }
  if(print_ctx_hex(prefix, sh, len) == 1) {free(sh);return FAIL();};
  free(sh);
  return OK();
}

// returns hash_ctx updated
int zenroom_hash_update(const char *hash_ctx,
			const char *buffer, const int buffer_size) {
  register char prefix = hash_ctx[0];
  register int len, c;
  char *sh = NULL;
  char *hex_buf = calloc(buffer_size<<1, 1);
  if(!hex_buf) {_err( "%s :: cannot allocate hex_buf",__func__);return FAIL();}
  if(hex2buf(hex_buf, buffer)<0) {free(hex_buf);_err("%s :: cannot do hex2buf %s",__func__, buffer);return FAIL();}
  if(prefix==ZEN_SHA512) {
    len = sizeof(hash512);
	sh = calloc(len, 1);
	if(!sh) {free(hex_buf);_err( "%s :: cannot allocate hash",__func__);return FAIL();}
	if(hex2buf(sh, hash_ctx+1)<0) {free(sh);free(hex_buf);_err("%s :: cannot do hex2buf %s",__func__, hash_ctx+1);return FAIL();}
    for(c=0; c<buffer_size<<1; c++) {
      HASH512_process((hash512*)sh, hex_buf[c]);
    }
  } else if(prefix==ZEN_SHA256) {
    len = sizeof(hash256);
	sh = calloc(len, 1);
	if(!sh) {free(hex_buf);_err( "%s :: cannot allocate hash",__func__);return FAIL();}
	if(hex2buf(sh, hash_ctx+1)<0) {free(sh);free(hex_buf);_err("%s :: cannot do hex2buf %s",__func__, hash_ctx+1);return FAIL();}
    for(c=0; c<buffer_size<<1; c++) {
      HASH256_process((hash256*)sh, hex_buf[c]);
    }
  } else {
	free(hex_buf);
    _err("%s :: invalid hash context prefix: %c", __func__, prefix);
	return FAIL();
  }
  if(print_ctx_hex(prefix, sh, len) == 1) {free(sh);return FAIL();};
  free(hex_buf);
  free(sh);
  return OK();
}

// returns the hash string base64 encoded
int zenroom_hash_final(const char *hash_ctx) {
  register char prefix = hash_ctx[0];
  register int len;
  char *hash_result = malloc(90);
  if(!hash_result) {_err( "%s :: cannot allocate hash_result",__func__);return FAIL();}
  octet tmp;
  char *sh;
  if(prefix==ZEN_SHA512) {
    tmp.len = 64;
    tmp.val = (char*)malloc(64);
	if(!tmp.val) {free(hash_result);_err( "%s :: cannot allocate tmp.val",__func__);return FAIL();}
    len = sizeof(hash512);
    sh = (char*)calloc(len, 1);
	if(!sh) {free(tmp.val);free(hash_result);_err( "%s :: cannot allocate sh",__func__);return FAIL();}
    if(hex2buf(sh, hash_ctx+1)<0) {free(sh);free(tmp.val);free(hash_result);_err("%s :: cannot do hex2buf %s",__func__, hash_ctx+1);return FAIL();};
    HASH512_hash((hash512*)sh, tmp.val);
  } else if(prefix==ZEN_SHA256) {
    tmp.len = 32;
    tmp.val = (char*)malloc(32);
	if(!tmp.val) {free(hash_result);_err( "%s :: cannot allocate tmp.val",__func__);return FAIL();}
    len = sizeof(hash256);
    sh = (char*)calloc(len, 1);
    if(!sh) {free(tmp.val);free(hash_result);_err( "%s :: cannot allocate sh",__func__);return FAIL();}
    if(hex2buf(sh, hash_ctx+1)<0) {free(sh);free(tmp.val);free(hash_result);_err("%s :: cannot do hex2buf %s",__func__, hash_ctx+1);return FAIL();};
    HASH256_hash((hash256*)sh, tmp.val);
  } else {
	free(hash_result);
    _err("%s :: invalid hash context prefix: %c", __func__, prefix);
	return FAIL();
  }
  OCT_tobase64(hash_result,&tmp);
  free(tmp.val);
  _out("%s",hash_result);
  free(hash_result);
  free(sh);
  return OK();
}
