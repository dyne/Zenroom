/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025 Dyne.org foundation
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

#include <zenroom.h>
#include <zen_error.h>
#include <lua_functions.h>
#include <zen_octet.h>
#include <longfellow-zk/circuits/mdoc/mdoc_zk.h>
#include <randombytes.h>

static int circuit_gen(lua_State *L) {
	BEGIN();
	CircuitGenerationErrorCode res;
	uint8_t *circuit;
	size_t circuit_len;
	const ZkSpecStruct *zk_spec = &kZkSpecs[0]; // v1
	const ZkSpecStruct* found_zk_spec =
		find_zk_spec(zk_spec->system, zk_spec->circuit_hash);
	res = generate_circuit(found_zk_spec, &circuit, &circuit_len);
	// TODO check res
	act(L,"Circuit spec v%lu with %lu attributes (%lu bytes)",
		zk_spec->version, zk_spec->num_attributes, circuit_len);
	// newuserdata already pushes the object in lua's stack
	octet *o = (octet *)lua_newuserdata(L, sizeof(octet));
	if(HEDLEY_UNLIKELY(o==NULL)) {
		zerror(L, "Cannot create octet, lua_newuserdata failure");
		END(0);
	}
	luaL_getmetatable(L, "zenroom.octet");
	lua_setmetatable(L, -2);
	o->val = (char*)circuit; // alloc'ed by generate_circuit
	if(HEDLEY_UNLIKELY(o->val==NULL)) {
		zerror(L, "Cannot create circuit, null ptr");
		END(0);
	}
	o->len = circuit_len;
	o->max = circuit_len;
	o->ref = 1;
	END(1);
}

int luaopen_longfellow(lua_State *L) {
	(void)L;
	const struct luaL_Reg longfellow_class[] = {
		{"gen_circuit", circuit_gen},
		// {"prove", prove},
		// {"verify", verify},
		{NULL,NULL}
	};
	const struct luaL_Reg longfellow_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "longfellow", longfellow_class, longfellow_methods);
	return 1;
}
