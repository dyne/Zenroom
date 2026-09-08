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


/// <h1>Cryptographically Secure Random Number Generator (RNG)</h1>
//
// Each new RNG instance is initialised with a different random seed
//
// Cryptographic security is achieved by hashing the random numbers
// using this sequence: unguessable seed -> SHA -> PRNG internal state
// -> SHA -> random numbers. See <a
// href="ftp://ftp.rsasecurity.com/pub/pdfs/bull-1.pdf">this paper</a>
// for an exstensive description of the process. More recent methods
// (fortuna etc) are in the works.
//
// @module RNG
// @author Denis "Jaromil" Roio
// @license GPLv3
// @copyright Dyne.org foundation 2017-2019

#include <zenroom.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

// easier name (csprng comes from amcl.h in milagro)
#define RNG csprng

// compat
#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
#endif

#include <zen_octet.h>
#include <randombytes.h>

static void zen_rng_zeroize(void *buffer, size_t len) {
	volatile uint8_t *out = buffer;
	while(len--) *out++ = 0;
}

int zen_entropy_fill(void *buffer, size_t len) {
	if(len == 0) return 0;
	if(!buffer) return -1;
	return randombytes(buffer, len) == 0 ? 0 : -1;
}

int zen_rng_init(zenroom_t *Z, const void *seed, size_t seed_len) {
	if(!Z || Z->random_generator || !seed || seed_len == 0 || seed_len > INT_MAX) return -1;
	/* The RNG outlives any temporary allocator policy, so own it directly. */
	RNG *rng = (RNG*)malloc(sizeof(csprng));
	if(!rng) {
		_err( "Error allocating new random number generator");
		return -1;
	}
	Z->random_generator = rng;
	if(zen_rng_reseed(Z, seed, seed_len) != 0) {
		zen_rng_clear(Z);
		return -1;
	}
	return 0;
}

int zen_rng_reseed(zenroom_t *Z, const void *seed, size_t seed_len) {
	if(!Z || !Z->random_generator || !seed || seed_len == 0 || seed_len > INT_MAX) return -1;
	/* RAND_seed mutates its raw input: always preserve caller-owned seed data. */
	char *raw = malloc(seed_len);
	if(!raw) return -1;
	memcpy(raw, seed, seed_len);
	AMCL_(RAND_seed)((RNG *)Z->random_generator, (int)seed_len, raw);
	zen_rng_zeroize(raw, seed_len);
	free(raw);
	return 0;
}

int zen_rng_fill(zenroom_t *Z, void *buffer, size_t len) {
	if(len == 0) return 0;
	if(!Z || !Z->random_generator || !buffer) return -1;
	uint8_t *out = buffer;
	for(size_t i = 0; i < len; i++) out[i] = RAND_byte((RNG *)Z->random_generator);
	return 0;
}

int zen_rng_callback_fill(void *context, void *buffer, size_t len) {
	return zen_rng_fill((zenroom_t *)context, buffer, len);
}

void zen_rng_clear(zenroom_t *Z) {
	if(!Z || !Z->random_generator) return;
	RAND_clean((RNG *)Z->random_generator);
	zen_rng_zeroize(Z->random_generator, sizeof(RNG));
	free(Z->random_generator);
	Z->random_generator = NULL;
}

void* rng_alloc(zenroom_t *Z) {
	if(!Z) return NULL;
	/* Cortex-M retains its established deterministic zero-seed startup path.
	 * Its board-specific entropy adapter is not validated by this runtime. */
#ifndef ARCH_CORTEX
	if(!Z->random_external && zen_entropy_fill(Z->random_seed, RANDOM_SEED_LEN) != 0) {
		_err("Error gathering operating-system entropy");
		return NULL;
	}
#endif
	return zen_rng_init(Z, Z->random_seed, RANDOM_SEED_LEN) == 0
		? Z->random_generator : NULL;
}


static int rng_uint8(lua_State *L) {
	BEGIN();
	zenroom_t *Z = zen_get_context(L);
	uint8_t res;
	if(zen_rng_fill(Z, &res, sizeof(res)) != 0) return luaL_error(L, "Random generator unavailable");
	lua_pushinteger(L, (lua_Integer)res);
	END(1);
}

static int rng_uint16(lua_State *L) {
	BEGIN();
	zenroom_t *Z = zen_get_context(L);
	uint8_t bytes[2];
	if(zen_rng_fill(Z, bytes, sizeof(bytes)) != 0) return luaL_error(L, "Random generator unavailable");
	uint16_t res = bytes[0] | (uint16_t)bytes[1] << 8;
	lua_pushinteger(L, (lua_Integer)res);
	END(1);
}

static int rng_int32(lua_State *L) {
	BEGIN();
	zenroom_t *Z = zen_get_context(L);
	uint8_t bytes[4];
	if(zen_rng_fill(Z, bytes, sizeof(bytes)) != 0) return luaL_error(L, "Random generator unavailable");
	uint32_t res = bytes[0] | (uint32_t)bytes[1] << 8 |
		(uint32_t)bytes[2] << 16 | (uint32_t)bytes[3] << 24;
	lua_pushinteger(L, (lua_Integer)res);
	END(1);
}

static int rng_seed(lua_State *L) {
	BEGIN();
	zenroom_t *Z = zen_get_context(L);
	const octet *in = o_arg(L, 1);
	if(in->len < 4) {
		zerror(L, "Random seed error: too small (%u bytes)", in->len);
		lua_pushnil(L);
		goto end;
	}
	if(zen_rng_reseed(Z, in->val, in->len) != 0) {
		zerror(L, "Random seed error: unsupported seed length (%u bytes)", in->len);
		lua_pushnil(L);
		goto end;
	}
	o_dup(L,in); // push seed to Lua stack for setglobal
	lua_setglobal(L, "RNGSEED");
	octet *rr = o_new(L, PRNG_PREROLL);
	for(register int i=0;i<PRNG_PREROLL;i++)
		if(zen_rng_fill(Z, &rr->val[i], 1) != 0) return luaL_error(L, "Random generator unavailable");
	rr->len = PRNG_PREROLL;
	// HEREoct(rr);
	// plus 4 bytes used by Lua init
	uint8_t discarded[4];
	if(zen_rng_fill(Z, discarded, sizeof(discarded)) != 0) return luaL_error(L, "Random generator unavailable");
	// return "runtime random" fingerprint
	end:
	o_free(L,in);
	END(1);
}

void zen_add_random(lua_State *L) {
	static const struct luaL_Reg rng_base [] =
		{ {"random_int8",  rng_uint8  },
		  {"random_byte",  rng_uint8  },
		  {"random_int16", rng_uint16 },
		  {"random_word", rng_uint16 },
		  {"random_int32", rng_int32 },
		  {"random8",  rng_uint8  },
		  {"random16", rng_uint16 },
		  {"random32", rng_int32 },
		  {"random",  rng_uint16  },
		  {"random_seed", rng_seed },
		  {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, rng_base, 0);
	lua_pop(L, 1);
	zenroom_t *Z = NULL;
	void *_zv; lua_getallocf(L, &_zv); Z = _zv;
	{ // pre-fill runtime_random
		// used in
		register int i;
		register char *p = Z->runtime_random256;
		for(i=0;i<PRNG_PREROLL;i++,p++)
		  if(zen_rng_fill(Z, p, 1) != 0) luaL_error(L, "Random generator unavailable");
	}

}
