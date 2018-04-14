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
 * You should have received a copy of the GNU Public License along
 * with this source code; if not, write to: Free Software Foundation,
 * Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __ZENROOM_H__
#define __ZENROOM_H__

#define UMM_HEAP (64*1024) // 64KiB (masked with 0x7fff)
#define MAX_FILE (64*512) // load max 32KiB files
#define MAX_STRING 4097 // max 4KiB strings
#define MAX_OCTET 2049 // max 2KiB octets

#define LUA_BASELIBNAME "_G"

#define ZEN_BITS 8
#ifndef SIZE_MAX
 #if ZEN_BITS == 32
  #define SIZE_MAX 4294967296
 #elif ZEN_BITS == 8
  #define SIZE_MAX 65536
 #endif
#endif

// zenroom context, also available as "_Z" global in lua space
// contents are opaque in lua and available only as lightuserdata
typedef struct {
	void *lua; // (lua_State*)

	// TODO: void *mem; // (umm_block*)
	// short int mem_type;

	// if !NULL then print will use these buffers
	char *stdout_buf;
	size_t stdout_len;
	size_t stdout_pos;
	char *stderr_buf;
	size_t stderr_len;
	size_t stderr_pos;

	void *userdata; // anything passed at init (reserved for caller)
} zenroom_t;

zenroom_t *zen_init(const char *conf);
void zen_teardown(zenroom_t *zenroom);
int zenroom_exec(char *script, char *conf, char *keys,
                 char *data, int verbosity);
int zenroom_exec_tobuf(char *script, char *conf, char *keys,
                       char *data, int verbosity,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);

#endif
