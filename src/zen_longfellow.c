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
#include <randombytes.h>
#include <longfellow-zk/circuits/mdoc/mdoc_zk.h>

static ZkSpecStruct *_get_zkspec(lua_State *L, int idx) {
	ZkSpecStruct *zk_spec;
	// number argument, import
	int tn;
	lua_Integer n = lua_tointegerx(L,idx,&tn);
	if(n>kNumZkSpecs) {
		zerror(L, "Wrong circuit spec: %i",n);
		return NULL;
	}
	if(tn) {
		zk_spec = &kZkSpecs[n-1]; // v1 -> [0]...
	} else {
		zerror(L, "Missing argument: longfellow circuit version");
		return NULL;
	}
	// const ZkSpecStruct* found_zk_spec =
	// 	find_zk_spec(zk_spec->system, zk_spec->circuit_hash);
	if(!zk_spec) {
		zerror(L,"Circuit spec not found: %i",tn);
		return NULL;
	}
	return(zk_spec);
}
static int circuit_gen(lua_State *L) {
	BEGIN();
	CircuitGenerationErrorCode res;
	uint8_t *circuit;
	size_t circuit_len;
	ZkSpecStruct *zk_spec = _get_zkspec(L,1);
	if(!zk_spec) {
		zerror(L,"Cannot generate ZK circuit");
		END(0);
	}
	// char circuit_hash_hex[129];
	act(L,"Generating circuit v%lu with %lu attributes",
		zk_spec->version, zk_spec->num_attributes);
	// buf2hex(circuit_hash_hex, zk_spec->circuit_hash, 64);
	// circuit_hash_hex[64] = 0x0;
	act(L,"%s %s",zk_spec->system, zk_spec->circuit_hash);
	res = generate_circuit(zk_spec, &circuit, &circuit_len);
	if(res != CIRCUIT_GENERATION_SUCCESS) {
		zerror(L,"Internal error generating circuit: %i",res);
		END(0);
	}
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

// formatted as ZULU string time "2024-01-30T09:00:00Z"
#define NOW_DATA_SIZE 20
#define NUM_MDOC_TESTS 4 // instantiated in in mdoc_examples.h

// static int mdoc_example(lua_State *L) {
// 	BEGIN();
//     int index = luaL_checkinteger(L, 1); // Argument at stack index 1
//     if (index < 1 || index >= NUM_MDOC_TESTS) {
// 		zerror(L, "Example index out of bounds");
// 		END(0);
// 	}
// 	func(L,"Getting MDOC example %i",index);
// 	const struct MdocTests *tests = &mdoc_tests[index-1];
//     lua_newtable(L);
//     lua_pushstring(L, "pkx");
// 	octet *pkx = o_new(L,32+4);
// 	// test_data->pk* are hex sequences prefixed with 0x. here we
// 	// import them into octets from that format. later we'll cast them
// 	// back into such strings, so that inside zenroom they are binary
// 	hex2buf(pkx->val, tests->pkx->as_pointer[2]);
// 	pkx->len = 32;
//     lua_settable(L, -3);
//     lua_pushstring(L, "pky");
// 	octet *pky = o_new(L,32+4);
// 	hex2buf(pky->val, tests->pky->as_pointer[2]);
// 	pky->len = 32;
//     lua_settable(L, -3);
//     lua_pushstring(L, "transcript");
// 	octet *trans = o_new(L, tests->transcript_size);
// 	memcpy(trans->val, tests->transcript, tests->transcript_size);
// 	trans->len = tests->transcript_size;
//     lua_settable(L, -3);
//     if (tests->now) { // Check if pointer is valid
// 		lua_pushstring(L, "now");
// 		octet *now = o_new(L, NOW_DATA_SIZE);
// 		memcpy(now->val, tests->now, NOW_DATA_SIZE);
// 		now->len = NOW_DATA_SIZE;
// 		lua_settable(L, -3);
//     }
//     // // doc_type
//     lua_pushstring(L, "doc_type");
// 	octet *dtype = o_new(L,64);
// 	size_t dtype_len = strlen(tests->doc_type);
// 	memcpy(dtype->val, tests->doc_type, dtype_len);
// 	dtype->len = dtype_len;
//     lua_settable(L, -3);
//     // // mdoc
//     lua_pushstring(L, "mdoc");
// 	octet *mdoc = o_new(L,tests->mdoc_size);
// 	memcpy(mdoc->val, tests->mdoc, tests->mdoc_size);
// 	mdoc->len = tests->mdoc_size;
//     lua_settable(L, -3);
//     END(1);
// }

typedef struct {
    const char* id;
    size_t id_len;
    const char* value;
    size_t value_len;
} LuaTableEntry;

static size_t _get_kv(lua_State* L, uint8_t* dest, const char* field, size_t max_len) {
    lua_getfield(L, -1, field);
    size_t out_len = 0;
	size_t copy_len = 0;
    void *ud = luaL_testudata(L, -1, "zenroom.octet");
	if(ud) {
        const octet* oct = (const octet*)ud;
        copy_len = oct->len < max_len ? oct->len : max_len;
        memcpy(dest, oct->val, copy_len);
        out_len = copy_len;
    }
    else if (lua_isstring(L, -1)) {
        size_t str_len;
        const char* str = lua_tolstring(L, -1, &str_len);
		copy_len = str_len < max_len ? str_len : max_len;
        memcpy(dest, str, copy_len);
        out_len = copy_len;
    }
    lua_pop(L, 1);
	return(out_len);
}

static RequestedAttribute* _get_attributes(lua_State* L, int index, size_t* count) {
    if (!lua_istable(L, index)) {
        zerror(L, "Expected table at index %d", index);
        return NULL;
    }
    size_t array_size = lua_rawlen(L, index);
    if (array_size == 0) {
        *count = 0;
        return NULL;
    }
    RequestedAttribute* entries = (RequestedAttribute*)
		calloc(array_size, sizeof(RequestedAttribute));
    if (!entries) {
        zerror(L, "Memory allocation failed");
        return NULL;
    }
    for (size_t i = 1; i <= array_size; i++) {
        lua_rawgeti(L, index, i); /* table[i] onto stack */
        if (!lua_istable(L, -1)) {
            lua_pop(L, 1); /* skip non-table element */
            continue;
        }
		entries[i-1].id_len = _get_kv(L, entries[i-1].id, "id", 32);
		entries[i-1].value_len = _get_kv(L, entries[i-1].value, "value", 64);
        lua_pop(L, 1);
    }
    *count = array_size;
    return entries;
}

static const char *_prover_error_to_string(MdocProverErrorCode err) {
	const char* error_strings[] = {
        "Success",
        "Null input provided",
        "Invalid input format",
        "Circuit parsing failed",
        "Hash parsing failed",
        "Witness creation failed",
        "General failure",
        "Memory allocation failed",
        "Invalid ZK specification version"
    };
    if (err < MDOC_PROVER_SUCCESS || err > MDOC_PROVER_INVALID_ZK_SPEC_VERSION) {
        return "Unknown error code";
    }
    return error_strings[err];
}

static int mdoc_prove(lua_State *L) {
	BEGIN();
	int returned = 0;
	const octet *circuit = o_arg(L,1);
	const octet *mdoc = o_arg(L,2);
	const octet *opkx = o_arg(L,3);
	const octet *opky = o_arg(L,4);
	const octet *trans = o_arg(L,5);
	size_t attrs_len;
	RequestedAttribute* attrs = _get_attributes(L,6,&attrs_len);
	const octet *now = o_arg(L,7);
	const ZkSpecStruct *zkspec = _get_zkspec(L,8);
	if(zkspec->num_attributes != attrs_len) {
		zerror(L,"Wrong number of attributes: %li (expected %li)",
			   attrs_len, zkspec->num_attributes);
		goto endgame;
	}
	uint8_t *proof_bytes;
	size_t proof_bytelen;
	MdocProverErrorCode res;
	// pks need to be 0x prefixed and zero terminated hex strings
	char pkx[68]; pkx[0]='0'; pkx[1]='x';
	buf2hex(&pkx[2],opkx->val,32);
	pkx[64+2] = 0x0;
	char pky[68]; pky[0]='0'; pky[1]='x';
	buf2hex(&pky[2],opky->val,32);
	pky[64+2] = 0x0;
	o_free(L,opkx);
	o_free(L,opky);
	// MdocProverErrorCode run_mdoc_prover(
	//     const uint8_t *bcp, size_t bcsz, /* circuit data */
	//     const uint8_t *mdoc, size_t mdoc_len, const char *pkx,
	//     const char *pky,                          /* string rep of public key */
	//     const uint8_t *transcript, size_t tr_len, /* session transcript */
	//     const RequestedAttribute *attrs, size_t attrs_len,
	//     const char *now, /* time formatted as "2023-11-02T09:00:00Z" */
	//     uint8_t **prf, size_t *proof_len, const ZkSpecStruct *zk_spec) {
	res = run_mdoc_prover((const uint8_t *)circuit->val, circuit->len,
						  (const uint8_t *)mdoc->val, mdoc->len+1,
						  pkx, pky,
						  (const uint8_t *)trans->val, trans->len,
						  attrs, attrs_len,
						  now->val,
						  &proof_bytes, &proof_bytelen,
						  zkspec);
	if(res != MDOC_PROVER_SUCCESS) {
		zerror(L, "MDOC prover error: %s",
			   _prover_error_to_string(res));
		goto endgame;
	}
	octet *proof = o_new(L,proof_bytelen);
	returned = 1;
	memcpy(proof->val,proof_bytes,proof_bytelen);
	proof->len = proof_bytelen;
 endgame:
	o_free(L,circuit);
	o_free(L,mdoc);
	o_free(L,trans);
	if(attrs) free(attrs);
	o_free(L,now);

	END(returned);
}

static int get_circuit_id(lua_State *L) {
	BEGIN();
	const octet *circ = o_arg(L,1);
	const ZkSpecStruct *zkspec = _get_zkspec(L,2);
	uint8_t id[32];
	circuit_id(id,(const uint8_t*)circ->val,circ->len,zkspec);
	octet *res = o_new(L,32);
	memcpy(res->val,id,32);
	res->len = 32;
	END(1);
}

static int mdoc_verify(lua_State *L) {
	BEGIN();

	END(1);
}

int luaopen_longfellow(lua_State *L) {
	(void)L;
	const struct luaL_Reg longfellow_class[] = {
		{"gen_circuit", circuit_gen},
		// {"mdoc_example", mdoc_example},
		{"mdoc_prove", mdoc_prove},
		{"circuit_id", get_circuit_id},
		// {"verify", verify},
		{NULL,NULL}
	};
	const struct luaL_Reg longfellow_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "longfellow", longfellow_class, longfellow_methods);
	return 1;
}
