/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2026 Dyne.org foundation
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

///// IMPORTANT for JS APIs /////
// If you want to use a C api in JS you have to add
// the api name prefixed with an underscore in the
// WASM_EXPORT array in build/wasm.mk

/////////////////////////////////////////
// High-level API: execute Lua or Zencode scripts

// Execute a Lua script and return 0 on success.
// Output is printed to stdout; error diagnostics to stderr.
// In WASM, capture via Module.print / Module.printErr.
int zenroom_exec(const char *script, const char *conf, const char *keys, const char *data, const char *extra, const char *context);

int zencode_exec(const char *script, const char *conf, const char *keys, const char *data, const char *extra, const char *context);

// Buffer variants: write output to caller-provided buffers instead of
// stdout/stderr.  Buffers are NULL-terminated on success.  All length
// arguments are buffer sizes in bytes.  Preferred ABI for embedders
// and WASM (avoids global print handler races).
int zenroom_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data, const char *extra, const char *context,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);
int zencode_exec_tobuf(const char *script, const char *conf, const char *keys, const char *data, const char *extra, const char *context,
                       char *stdout_buf, size_t stdout_len,
                       char *stderr_buf, size_t stderr_len);

/////////////////////////////////////////
// Validation and introspection

// Validate input data by processing the Given scope only.
// Prints the CODEC as JSON on success.  Return 0 on success.
int zencode_valid_input(const char *script, const char *conf, const char *keys, const char *data, const char *extra);

// Parse a Zencode contract.  If strict=1, fail on any wrong syntax.
// If strict=0, return a JSON array of ignored and invalid statements.
// Return 0 when the contract is valid (strict=1) or the parse result
// could be produced (strict=0).
int zencode_valid_code(const char *script, const char *conf, const int strict);

// Return all registered Zencode statements as JSON (when scenario is
// NULL) or only those belonging to the named scenario.
int zencode_get_statements(const char *scenario);

/////////////////////////////////////////
// Direct hash primitives

// Legacy streaming hash API.  Returns serialised hash state as hex.
// hash_type: "sha256" or "sha512".  Return 0 on success.
int zenroom_hash_init(const char *hash_type);

// Update a streaming hash context with raw bytes.
// hash_ctx: hex state from hash_init / hash_update.
// buffer: raw bytes to hash.  buffer_size: length in bytes.
// Return 0 on success.
int zenroom_hash_update(const char *hash_ctx, const char *buffer, const int buffer_size);

// Finalise a streaming hash and print the base64 digest.
// hash_ctx: hex state from the last hash_update.
// Return 0 on success.
int zenroom_hash_final(const char *hash_ctx);

/////////////////////////////////////////
// One-shot hex hash and PBKDF2 (new ABI – prefer these for new code)

// Hash a hex-encoded message using the named algorithm.
// hash_type: lowercase string.  Supported: sha256, sha384, sha512,
//   sha3_256, sha3_512, shake256, keccak256, ripemd160.
// msg_hex: lowercase hex string (length must be even).
// Prints the lowercase hex digest to stdout.  Return 0 on success.
int zenroom_hash_hex(const char *hash_type, const char *msg_hex);

// Buffer variant: writes the hex digest into stdout_buf.
int zenroom_hash_hex_tobuf(const char *hash_type, const char *msg_hex,
                           char *stdout_buf, size_t stdout_len,
                           char *stderr_buf, size_t stderr_len);

// Derive a key using PBKDF2 with the named hash PRF.
// hash_type: lowercase string (supported: sha256, sha512).
// password_hex, salt_hex: lowercase hex strings.
// iterations: number of PBKDF2 rounds (>0).
// keylen: desired output length in bytes (>0).
// Prints the lowercase hex derived key to stdout.  Return 0 on success.
int zenroom_pbkdf2_hex(const char *hash_type, const char *password_hex,
                       const char *salt_hex, int iterations, int keylen);

// Buffer variant: writes the hex derived key into stdout_buf.
int zenroom_pbkdf2_hex_tobuf(const char *hash_type, const char *password_hex,
                             const char *salt_hex, int iterations, int keylen,
                             char *stdout_buf, size_t stdout_len,
                             char *stderr_buf, size_t stderr_len);

/////////////////////////////////////////
// Digital signature primitives (hex ABI)

// algo: lowercase string.  Supported: "eddsa", "p256", "mldsa44".
// eddsa = Ed25519 (via ed25519-donna).
// p256 = P-256 / secp256r1 ECDSA (via zen_p256.c Lua module).
// mldsa44 = ML-DSA-44 FIPS 204 post-quantum (via zen_qp.c QP module).
// All binary inputs/outputs are lowercase hex strings.
// verify functions print "1" on success, "0" on failure.
// All functions return OK (0) on success, FAIL (1) on error.

// Generate a new secret key.  rngseed: optional 64-byte hex seed,
// NULL to use the internal PRNG.  Prints hex secret key.
int zenroom_sign_keygen(const char *algo, const char *rngseed);

// Derive the public key from a hex-encoded secret key.
int zenroom_sign_pubgen(const char *algo, const char *key);

// Sign a hex-encoded message with a hex-encoded secret key.
// Prints the hex signature.
int zenroom_sign_create(const char *algo, const char *key, const char *msg);

// Verify a hex signature against a message and public key.
// pk: hex-encoded public key.  msg: hex-encoded message.
// sig: hex-encoded signature.  Prints "1" or "0".
int zenroom_sign_verify(const char *algo, const char *pk, const char *msg, const char *sig);

// Buffer variants of the above.
int zenroom_sign_keygen_tobuf(const char *algo, const char *rngseed,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
int zenroom_sign_pubgen_tobuf(const char *algo, const char *key,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
int zenroom_sign_create_tobuf(const char *algo, const char *key, const char *msg,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);
int zenroom_sign_verify_tobuf(const char *algo, const char *pk, const char *msg, const char *sig,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);

/////////////////////////////////////////
// Recipe execution (Lua-backed higher-level workflows)

// Execute a named recipe backed by embedded Lua/Zencode scripts.
// name: recipe identifier (e.g. "merkle.root", "merkle.verify_proof").
// conf, keys, data, extra, context: strings as in zenroom_exec_tobuf.
// data is a JSON string; every binary value inside MUST be lowercase hex.
// Output is always a JSON string printed to stdout.
// Return OK (0) on success, FAIL (1) on error.
int zenroom_recipe_exec(const char *name, const char *conf, const char *keys,
                        const char *data, const char *extra, const char *context);

// Buffer variant: writes the JSON result into stdout_buf.
int zenroom_recipe_exec_tobuf(const char *name, const char *conf, const char *keys,
                              const char *data, const char *extra, const char *context,
                              char *stdout_buf, size_t stdout_len,
                              char *stderr_buf, size_t stderr_len);

////////////////////////////////////////


// lower level api: init (exec_line*) teardown
extern void *ZEN;

#define RANDOM_SEED_LEN 64
#define STR_MAXITER_LEN 10
#define STR_MAXMEM_LEN 10

// conf switches
typedef enum { STB, MUTT, LIBC } printftype;
typedef enum { NIL, VERBOSE, SCOPE, RNGSEED, LOGFMT, MAXITER, MAXMEM,
			   MEMBLOCKNUM, MEMBLOCKSIZE } zconf;

// zenroom context, also available as "_Z" global in lua space
// contents are opaque in lua and available only as lightuserdata
typedef struct {
	void *lua; // (lua_State*)

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

    int scope;
	int debuglevel;
	int errorlevel;
    int logformat;
	void *userdata; // anything passed at init (reserved for caller)

  	char zconf_rngseed[(RANDOM_SEED_LEN*2)+4]; // 0x and terminating \0

	char str_maxiter[STR_MAXITER_LEN + 1];
	char str_maxmem[STR_MAXMEM_LEN + 1];

	int sfpool_blocknum;
	int sfpool_blocksize;

	int exitcode;
} zenroom_t;

// ZENCODE EXEC SCOPE
#define SCOPE_FULL 0
#define SCOPE_GIVEN 1

// LOG FORMATS
#define LOG_TEXT 0
#define LOG_JSON  1

// EXIT CODES
#define ERR_INIT 4
#define ERR_PARSE 3
#define ERR_EXEC 2
#define ERR_GENERIC 1 // EXIT_FAILURE
#define SUCCESS 0 // EXIT_SUCCESS

zenroom_t *zen_init(const char *conf, const char *keys, const char *data);
zenroom_t *zen_init_extra(const char *conf, const char *keys, const char *data,	const char *extra, const char *context);
int  zen_exec_lua(zenroom_t *Z, const char *script);
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
#define MAX_STRING 21504 // max 21KiB strings
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
