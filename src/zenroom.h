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

/////////////////////////////////////////
// high level api: one simple call

int zenroom_exec(char *script, char *conf, char *keys,
                 char *data, int verbosity);

// in case buffers should be used instead of stdout/err file
// descriptors, this call defines where to print out the output and
// the maximum sizes allowed for it. Output is NULL terminated.
int zenroom_exec_tobuf(char *script, char *conf, char *keys,
                       char *data, int verbosity,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);

// to obtain the Abstract Syntax Tree (AST) of a script
// (output is in metalua formatted as JSON)
int zenroom_parse_ast(char *script, int verbosity,
                      char *stdout_buf, size_t stdout_len,
                      char *stderr_buf, size_t stderr_len);

void set_debug(int lev);

////////////////////////////////////////


// lower level api: init (exec_line*) teardown

// heap initialised by the memory manager
typedef struct {
	void* (*malloc)(size_t size);
	void* (*realloc)(void *ptr, size_t size);
	void  (*free)(void *ptr);
	void* (*sys_malloc)(size_t size);
	void* (*sys_realloc)(void *ptr, size_t size);
	void  (*sys_free)(void *ptr);
	char  *heap;
	size_t heap_size;
} zen_mem_t;

// zenroom context, also available as "_Z" global in lua space
// contents are opaque in lua and available only as lightuserdata
typedef struct {
	void *lua; // (lua_State*)
	zen_mem_t *mem; // memory manager heap

	char *stdout_buf;
	size_t stdout_len;
	size_t stdout_pos;
	char *stderr_buf;
	size_t stderr_len;
	size_t stderr_pos;

	int errorlevel;
	void *userdata; // anything passed at init (reserved for caller)
} zenroom_t;


zenroom_t *zen_init(const char *conf, char *keys, char *data);
int  zen_exec_script(zenroom_t *Z, const char *script);
void zen_teardown(zenroom_t *zenroom);

#define UMM_HEAP (64*1024) // 64KiB (masked with 0x7fff)
#define MAX_FILE (64*1024) // load max 64KiB files
#ifndef MAX_STRING
#define MAX_STRING 4097 // max 4KiB strings
#endif
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

#endif
