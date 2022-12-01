/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2019 Dyne.org foundation
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

#ifndef __ZEN_HASH_H__
#define __ZEN_HASH_H__

#include <lua.h>
#include <amcl.h>
#include <rmd160.h>
#include <blake2.h>

#define SHA256 32
#define SHA512 64

#define _SHA256 2
#define _SHA384 3
#define _SHA512 5
#define _SHA3_224 3224
#define _SHA3_256 3256
#define _SHA3_384 3384
#define _SHA3_512 3512
#define _SHA3_256 3256
#define _KECCAK256 7
#define _RMD160 160
#define _BLAKE2B 464
#define _BLAKE2S 465

typedef struct {
	char name[16];
	int algo;
	int len;
	hash256 *sha256;
	hash384 *sha384;
	hash512 *sha512;
	sha3 *sha3_256; // SHA3 aka keccak with 32 bytes
	sha3 *sha3_512; // SHA3 aka keccak with 64 bytes
        sha3 *keccak256;
        dword *rmd160;
  blake2b_state *blake2b;
  blake2s_state *blake2s;

        csprng *rng; // zencode runtime random
        // ...
} hash;


hash* hash_new(lua_State *L, const char *hashtype);
hash* hash_arg(lua_State *L, int n);

#endif
