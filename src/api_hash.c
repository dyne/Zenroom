/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2022 Dyne.org foundation
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

#include <stdlib.h>
#include <strings.h> // libc

#include <ecdh_support.h> // AMCL

#include <zen_error.h>
#include <encoding.h> // zenroom

 // first byte is type
#define SHA512 64

// returns a fills hash_ctx, which must be pre-allocated externally
int zenroom_hash_init(const char *hash_type,
		      char *hash_ctx, const int hash_ctx_size) {
  register char prefix = '0';
  // size tests
  register int len = sizeof(hash512); // amcl struct
  void *sh;
  if(hash_ctx_size<<1 <= len<<1) { // size*2 because hex encoded
    zerror(NULL, "%s :: invalid hash context size: %u <= %u",
	   __func__, hash_ctx_size<<1, len<<1);
    return 4;
  }
  if(strcasecmp(hash_type, "sha512") == 0) {    
    prefix = '4';
    sh = malloc(len);
    // TODO: check what malloc returns
    HASH512_init((hash512*)sh); // amcl init
  } else {
    zerror(NULL, "%s :: invalid hash type: %s", __func__, hash_type);
    return 4; // ERR_INIT
  }
  // serialize
  hash_ctx[0] = prefix;
  buf2hex(hash_ctx+1, (const char*)sh, (const size_t)len);
  free(sh);
  return 0;
}

// returns hash_ctx updated
uint8_t zenroom_hash_update(char *hash_ctx,
			  char *buffer, uint32_t buffer_size) {
  return 0;
}

// returns the hash string base64 encoded
uint8_t zenroom_hash_final(char *hash_ctx,
			 char *hash_result, uint32_t hash_result_size) {
  return 0;
}
