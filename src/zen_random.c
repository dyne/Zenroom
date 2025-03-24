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

#include <time.h>

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


void* rng_alloc(zenroom_t *ZZ) {
	RNG *rng = (RNG*)malloc(sizeof(csprng));
	if(!rng) {
		_err( "Error allocating new random number generator");
		return NULL;
	}

	// random seed provided externally 
	if(ZZ->random_external) {
#ifndef ARCH_CORTEX
	} else {
		// gather system random using randombytes()
		randombytes(ZZ->random_seed,RANDOM_SEED_LEN-4);
		// using time() from milagro
		unsign32 ttmp = (unsign32)time(NULL);
		ZZ->random_seed[60] = (ttmp >> 24) & 0xff;
		ZZ->random_seed[61] = (ttmp >> 16) & 0xff;
		ZZ->random_seed[62] = (ttmp >>  8) & 0xff;
		ZZ->random_seed[63] =  ttmp & 0xff;
#endif
	}
	// RAND_seed is destructive, preserve seed here
	char tseed[RANDOM_SEED_LEN];
	memcpy(tseed,ZZ->random_seed,RANDOM_SEED_LEN);
	AMCL_(RAND_seed)(rng, RANDOM_SEED_LEN, tseed);
	// return into ZZ->random_generator
	return(rng);
}


static int rng_uint8(lua_State *L) {
	BEGIN();
	Z(L);
	uint8_t res = RAND_byte(Z->random_generator);
	lua_pushinteger(L, (lua_Integer)res);
	END(1);
}

static int rng_uint16(lua_State *L) {
	BEGIN();
	Z(L);
	uint16_t res =
		RAND_byte(Z->random_generator)
		| (uint32_t) RAND_byte(Z->random_generator) << 8;
	lua_pushinteger(L, (lua_Integer)res);
	END(1);
}

static int rng_int32(lua_State *L) {
	BEGIN();
	Z(L);
	uint32_t res =
		RAND_byte(Z->random_generator)
		| (uint32_t) RAND_byte(Z->random_generator) << 8
		| (uint32_t) RAND_byte(Z->random_generator) << 16
		| (uint32_t) RAND_byte(Z->random_generator) << 24;
	lua_pushinteger(L, (lua_Integer)res);
	END(1);
}

static int rng_seed(lua_State *L) {
	BEGIN();
	Z(L);
	const octet *in = o_arg(L, 1);
	if(in->len < 4) {
		zerror(L, "Random seed error: too small (%u bytes)", in->len);
		lua_pushnil(L);
		goto end;
	}
	AMCL_(RAND_seed)(Z->random_generator, in->len, in->val);
	o_dup(L,in); // push seed to Lua stack for setglobal
	lua_setglobal(L, "RNGSEED");
	octet *rr = o_new(L, PRNG_PREROLL);
	for(register int i=0;i<PRNG_PREROLL;i++)
		rr->val[i] = RAND_byte(Z->random_generator);
	rr->len = PRNG_PREROLL;
	// HEREoct(rr);
	// plus 4 bytes used by Lua init
	RAND_byte(Z->random_generator);
	RAND_byte(Z->random_generator);
	RAND_byte(Z->random_generator);
	RAND_byte(Z->random_generator);
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
		  *p = RAND_byte(Z->random_generator);
	}

}
