/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2020 Dyne.org foundation
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

#ifndef __ZENROOM_H__
#define __ZENROOM_H__

#include <stddef.h>

/////////////////////////////////////////
// high level api: one simple call

int zenroom_exec(const char *script, const char *conf, const char *keys, const char *data);

int zencode_exec(const char *script, const char *conf, const char *keys, const char *data);

// in case buffers should be used instead of stdout/err file
// descriptors, this call defines where to print out the output and
// the maximum sizes allowed for it. Output is NULL terminated.
int zenroom_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);
int zencode_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);

// direct access hash calls
// hash_type may be a string of: 'sha256' or 'sha512'
// all functions return 0 on success, anything else signals an error
// the output is always a string printed to stdout, i.e:
// zenroom_hash_init('sha256') will print the hex encoded hash_ctx string
int zenroom_hash_init(const char *hash_type);
// zenroom_hash_update(hash_ctx, bytes, size) will print the updated hash_ctx in hex
int zenroom_hash_update(const char *hash_ctx, const char *buffer, const int buffer_size);
// zenroom_hash_final(hash_ctx) will print the base64 encoded hash of the data so far
int zenroom_hash_final(const char *hash_ctx);
////////////////////////////////////////


// lower level api: init (exec_line*) teardown

#define RANDOM_SEED_LEN 64
#define STR_MAXITER_LEN 10

// conf switches
typedef enum { STB, MUTT, LIBC } printftype;
typedef enum { NIL, VERBOSE, COLOR, RNGSEED, LOGFMT, MAXITER } zconf;

// zenroom context, also available as "_Z" global in lua space
// contents are opaque in lua and available only as lightuserdata
typedef struct {
	void *lua; // (lua_State*)
    void *zstd_c; // ZSTD context
    void *zstd_d;

	char *stdout_buf;
	size_t stdout_len;
	size_t stdout_pos;
	size_t stdout_full;

	char *stderr_buf;
	size_t stderr_len;
	size_t stderr_pos;
	size_t stderr_full;

	void *random_generator; // cast to RNG
	char random_seed[RANDOM_SEED_LEN+4];
    char runtime_random256[256+4];
	int random_external; // signal when rngseed is external

	int debuglevel;
	int errorlevel;
    int logformat;
	void *userdata; // anything passed at init (reserved for caller)

  	char zconf_rngseed[(RANDOM_SEED_LEN*2)+4]; // 0x and terminating \0

        char str_maxiter[STR_MAXITER_LEN + 1];

        int memcount_octets;
        int memcount_bigs;
        int memcount_hashes;
        int memcount_ecp;
        int memcount_ecp2;
        int memcount_ecdhs;
        int memcount_floats;
	int exitcode;
} zenroom_t;

// LOG FORMATS
#define TEXT 0
#define JSON  1

// EXIT CODES
#define ERR_INIT 4
#define ERR_PARSE 3
#define ERR_EXEC 2
#define ERR_GENERIC 1 // EXIT_FAILURE
#define SUCCESS 0 // EXIT_SUCCESS

zenroom_t *zen_init(const char *conf, const char *keys, const char *data);
int  zen_exec_script(zenroom_t *Z, const char *script);
int  zen_exec_zencode(zenroom_t *Z, const char *script);
void zen_teardown(zenroom_t *zenroom);

#define MAX_LINE 1024 // 1KiB maximum length for a newline terminated line (Zencode)

#ifndef MAX_ZENCODE_LINE
#define MAX_ZENCODE_LINE 512
#endif

#ifndef MAX_CONFIG // for the configuration parser
#define MAX_CONFIG 512
#endif

#ifndef MAX_ZENCODE // maximum size of a zencode script
#define MAX_ZENCODE 16384
#endif

#ifndef MAX_FILE // for cli.c
#define MAX_FILE 2048000 // load max 2MiB files
#endif

#ifndef MAX_STRING // mostly for cli.c
#define MAX_STRING 20480 // max 20KiB strings
#endif

#ifndef MAX_OCTET
#define MAX_OCTET 4096000 // max 4MiB for octets
#endif

#define LUA_BASELIBNAME "_G"

#define ZEN_BITS 32
#ifndef SIZE_MAX
#if ZEN_BITS == 32
#define SIZE_MAX 4294967296
#elif ZEN_BITS == 8
#define SIZE_MAX 65536
#endif
#endif

// number of bytes pre-fetched from the PRNG on seed initialization
// should never exceed 256
#define PRNG_PREROLL 256
// runtime random_seed addes 4 bytes to this (260 total) used by Lua init

#endif
