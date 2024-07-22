/* This file is part of Zenroom (https://zenroom.org)
 *
 * Copyright (C) 2024 Dyne.org foundation
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

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_error.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_error.h>
#include <zen_octet.h>

int fuzz_byte_random(lua_State *L) {
	BEGIN();
	octet *o = o_arg(L,1); SAFE(o);
	if(o->len >= INT_MAX) {
		o_free(L,o);
		THROW("fuzz_byte: octet too big");
		END(0);
	}
	octet *res = o_dup(L,o);
	Z(L);
	if(res->len < 256) {
		uint8_t point8 = RAND_byte(Z->random_generator);
		res->val[point8%res->len] = RAND_byte(Z->random_generator);
	} else if(res->len < 65535) {
		uint16_t point16 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8;
		res->val[point16%res->len] = RAND_byte(Z->random_generator);
	} else if(res->len < (int)0xffffffff) {
		uint32_t point32 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8
			| (uint32_t) RAND_byte(Z->random_generator) << 16
			| (uint32_t) RAND_byte(Z->random_generator) << 24;
		res->val[point32%res->len] = RAND_byte(Z->random_generator);
	}
	o_free(L,o);
	END(1);
}


int fuzz_byte_xor(lua_State *L) {
	BEGIN();
	octet *o = o_arg(L,1); SAFE(o);
	if(o->len >= INT_MAX) {
		o_free(L,o);
		THROW("fuzz_byte: octet too big");
		END(0);
	}
	octet *res = o_dup(L,o);
	Z(L);
	if(res->len < 256) {
		uint8_t point8 = RAND_byte(Z->random_generator) % res->len;
		res->val[point8] ^= 0xff;
	} else if(res->len < 65535) {
		uint16_t point16 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8;
		point16 %= res->len;
		res->val[point16] ^= 0xff;
	} else if(res->len < INT_MAX) {
		uint32_t point32 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8
			| (uint32_t) RAND_byte(Z->random_generator) << 16
			| (uint32_t) RAND_byte(Z->random_generator) << 24;
		point32 %= res->len;
		res->val[point32] ^= 0xff;
	}
	o_free(L,o);
	END(1);
}
