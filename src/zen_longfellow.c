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
#include <encoding.h>
#include <longfellow-zk/circuits/mdoc/mdoc_zk.h>
#include <randombytes.h>

static int circuit_gen(lua_State *L) {
	BEGIN();
	CircuitGenerationErrorCode res;
	uint8_t *circuit;
	size_t circuit_len;
	// char circuit_hash_hex[129];
	ZkSpecStruct *zk_spec = NULL;
	// number argument, import
	int tn;
	lua_Integer n = lua_tointegerx(L,1,&tn);
	if(tn) {
		act(L, "Requested circuit: %i",n);
		zk_spec = &kZkSpecs[n-1]; // v1 -> [0]...
	} else {
		zerror(L, "Missing argument: longfellow circuit version");
		END(0);
	}
	// const ZkSpecStruct* found_zk_spec =
	// 	find_zk_spec(zk_spec->system, zk_spec->circuit_hash);
	if(!zk_spec) {
		zerror(L,"Circuit spec not found: %i",tn);
		END(0);
	}
	act(L,"Generating circuit v%lu with %lu attributes (%lu bytes)",
		zk_spec->version, zk_spec->num_attributes, circuit_len);
	// buf2hex(circuit_hash_hex, zk_spec->circuit_hash, 64);
	// circuit_hash_hex[64] = 0x0;
	act(L,"%s %s",zk_spec->system, zk_spec->circuit_hash);
	res = generate_circuit(zk_spec, &circuit, &circuit_len);
	// TODO check res
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
