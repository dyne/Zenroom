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
	octet *o = o_arg(L, 1);
	SAFE(o);
	if(o->len >= INT_MAX) {
		o_free(L,o);
		THROW("fuzz_byte: octet too big");
		END(0);
	}
	octet *res = o_dup(L,o);
	Z(L);
	uint8_t rnd = RAND_byte(Z->random_generator);
	if(res->len < 256) {
		uint8_t point8 = RAND_byte(Z->random_generator);
		while((uint8_t)res->val[point8%res->len] == rnd) {
			rnd = RAND_byte(Z->random_generator);
		}
		res->val[point8 % res->len] = rnd;	
	} else if(res->len < 65535) {
		uint16_t point16 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8;
		while ((uint8_t)res->val[point16 % res->len] == rnd) {
			rnd = RAND_byte(Z->random_generator);
		}
		res->val[point16%res->len] = rnd;
	} else if(res->len < INT_MAX) {
		uint32_t point32 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8
			| (uint32_t) RAND_byte(Z->random_generator) << 16
			| (uint32_t) RAND_byte(Z->random_generator) << 24;
		while ((uint8_t)res->val[point32 % res->len] == rnd) {
			rnd = RAND_byte(Z->random_generator);
		}
		res->val[point32%res->len] = rnd;
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


int fuzz_bit_random(lua_State *L) {
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
		uint8_t bit_position = RAND_byte(Z->random_generator) % 8;
		res->val[point8%res->len] ^= (1 << bit_position);
	}
	else if(res->len <  65535) {
		uint16_t point16 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8;
		uint8_t bit_position = RAND_byte(Z->random_generator) % 8;
		res->val[point16%res->len] ^= (1 << bit_position);
	} else if(res->len < INT_MAX) {
		uint32_t point32 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8
			| (uint32_t) RAND_byte(Z->random_generator) << 16
			| (uint32_t) RAND_byte(Z->random_generator) << 24;
		uint8_t bit_position = RAND_byte(Z->random_generator) % 8;
		res->val[point32%res->len] ^= (1 << bit_position);
	}
	o_free(L,o);
	END(1);
}

void OCT_circular_shl_bytes(octet *x, int n) {
	if (n >= x->len) {
		n = n % (x->len);
	}

	if (n > 0) {
		unsigned char temp[x->len];
		for (int i = 0; i < x->len; i++) {
			temp[i] = x->val[i];
		}
		for (int i = 0; i < x->len; i++) {
			x->val[i] = temp[(i + n) % x->len];
		}
	}
}

void OCT_circular_shl_bits(octet *x, int n) {
	if (n >= 8 * x->len) {
		n = n % (8 * x->len);
	}
	int byte_shift = n / 8;
	int bit_shift = n % 8;
	int carry_bits = 8 - bit_shift;

	if (byte_shift > 0) {
		unsigned char temp[x->len];
		for (int i = 0; i < x->len; i++) {
			temp[i] = x->val[i];
		}

		for (int i = 0; i < x->len; i++) {
			x->val[i] = temp[(i + byte_shift) % x->len];
		}
	}
	if (bit_shift > 0) {
		unsigned char carry = 0;
		unsigned char first_byte_carry = (x->val[0] >> carry_bits) & ((1 << bit_shift) - 1);

		for (int i = x->len - 1; i >= 0; i--) {
			unsigned char current = x->val[i];
			x->val[i] = (current << bit_shift) | carry;
			carry = (current >> carry_bits) & ((1 << bit_shift) - 1);
		}
		x->val[x->len - 1] |= first_byte_carry;
	}
}

int fuzz_byte_circular_shift_random(lua_State *L) {
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
		while (point8 % res->len ==  (uint8_t)0) {
			point8 = RAND_byte(Z->random_generator);
		}
		OCT_circular_shl_bytes(res, (point8 % res->len));
	} else if(res->len < 65535) {
		uint16_t point16 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8;
		while (point16 % res->len == (uint16_t) 0) {
			point16 = 
				RAND_byte(Z->random_generator) 
				| (uint32_t)RAND_byte(Z->random_generator) << 8;
		}
		OCT_circular_shl_bytes(res, (point16%res->len));
	} else if(res->len < INT_MAX) {
		uint32_t point32 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8
			| (uint32_t) RAND_byte(Z->random_generator) << 16
			| (uint32_t) RAND_byte(Z->random_generator) << 24;
		while (point32 % res->len == (uint32_t) 0) {
			point32 =
				RAND_byte(Z->random_generator)
				| (uint32_t) RAND_byte(Z->random_generator) << 8
				| (uint32_t) RAND_byte(Z->random_generator) << 16
				| (uint32_t) RAND_byte(Z->random_generator) << 24;
		}
		OCT_circular_shl_bytes(res, (point32%res->len));
	}
	o_free(L,o);
	END(1);
}

int fuzz_bit_circular_shift_random(lua_State *L) {
	BEGIN();
	octet *o = o_arg(L, 1);
	SAFE(o);

	if (o->len >= INT_MAX) {
		o_free(L, o);
		THROW("fuzz_byte: octet too big");
		END(0);
	}

	octet *res = o_dup(L, o);
	Z(L);

	uint32_t total_bits = res->len * 8;
	uint32_t shift_bits = 0;

	if (res->len < 256) {
		shift_bits = (RAND_byte(Z->random_generator) % res->len) * 8 + (RAND_byte(Z->random_generator) % 8);
		while (shift_bits % total_bits ==  (uint32_t) 0) {
			shift_bits = (RAND_byte(Z->random_generator) % res->len) * 8 + (RAND_byte(Z->random_generator) % 8);
		}
	}
	else if (res->len < 65535) {
		uint16_t point16 = 
			RAND_byte(Z->random_generator)
			| (uint32_t)RAND_byte(Z->random_generator) << 8;
		shift_bits = (point16 % res->len) * 8 + (RAND_byte(Z->random_generator) % 8);
		while (shift_bits % total_bits == (uint32_t) 0) {
			shift_bits = (point16 % res->len) * 8 + (RAND_byte(Z->random_generator) % 8);
		}
	}
	else if (res->len < INT_MAX) {
		uint32_t point32 =
			RAND_byte(Z->random_generator)
			| (uint32_t) RAND_byte(Z->random_generator) << 8
			| (uint32_t) RAND_byte(Z->random_generator) << 16
			| (uint32_t) RAND_byte(Z->random_generator) << 24;
		shift_bits = (point32 % res->len) * 8 + (RAND_byte(Z->random_generator) % 8);
		while (shift_bits % total_bits == (uint32_t) 0) {
			shift_bits = (point32 % res->len) * 8 + (RAND_byte(Z->random_generator) % 8);
		}
	}

	OCT_circular_shl_bits(res, shift_bits);

	o_free(L, o);
	END(1);
}

