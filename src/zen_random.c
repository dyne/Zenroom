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

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <lua_functions.h>

#include <time.h>

#include <amcl.h>

// easier name (csprng comes from amcl.h in milagro)
#define RNG csprng

#include <zenroom.h>
#include <zen_memory.h>
#include <randombytes.h>

extern zenroom_t *Z;

void* rng_alloc() {
	HERE();
	RNG *rng = (RNG*)zen_memory_alloc(sizeof(csprng));
	if(!rng) {
		lerror(NULL, "Error allocating new random number generator in %s",__func__);
		return NULL; }

	// random seed provided externally 
	if(Z->random_seed) {
		act(NULL,"Random seed is external, deterministic execution");
		if(!Z->random_generator) {
			// TODO: feed minimum 128 bytes
			RAND_seed(rng, Z->random_seed_len, Z->random_seed);
			// Z->random_generator is allocated only once and freed in
			// zen_teardown, lasts for the whole execution
			Z->random_generator = zen_memory_alloc(sizeof(csprng)+8);
			memcpy(Z->random_generator, rng, sizeof(csprng));
		} else {
			memcpy(rng, Z->random_generator, sizeof(csprng));
		}
#ifndef ARCH_CORTEX
	} else {
		// gather system random using randombytes()
		char *tmp = zen_memory_alloc(256);
		randombytes(tmp,252);
		// using time() from milagro
		unsign32 ttmp = (unsign32)time(NULL);
		tmp[252] = (ttmp >> 24) & 0xff;
		tmp[253] = (ttmp >> 16) & 0xff;
		tmp[254] = (ttmp >>  8) & 0xff;
		tmp[255] =  ttmp & 0xff;
		RAND_seed(rng,256,tmp);
		zen_memory_free(tmp);
#endif
	}
	return(rng);
}
