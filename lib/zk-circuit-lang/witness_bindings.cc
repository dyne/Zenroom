// Copyright (C) 2025 Dyne.org foundation
// designed, written and maintained by Denis Roio <jaromil@dyne.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#include "witness_bindings.h"
#include "octet_conversions.h"

#include <vector>
#include <memory>
#include <cstring>

#include "circuits/sha/flatsha256_witness.h"
#include "circuits/ecdsa/verify_witness.h"
#include "ec/p256.h"
#include "algebra/fp_p256.h"

namespace proofs {
namespace lua {

// ============================================================================
// SHA-256 Witness Generation
// ============================================================================

int sha256_compute_message(lua_State* L) {
    // Arg 1: message (OCTET)
    const octet* msg = o_arg(L, 1);
    if (!msg) {
        return luaL_error(L, "SHA256: first argument must be an OCTET");
    }
    
    // Arg 2: max_blocks (integer)
    if (!lua_isnumber(L, 2)) {
        o_free(L, msg);
        return luaL_error(L, "SHA256: second argument must be a number");
    }
    int max_blocks = lua_tointeger(L, 2);
    
    if (max_blocks < 1 || max_blocks > 16) {
        o_free(L, msg);
        return luaL_error(L, "SHA256: max_blocks must be between 1 and 16");
    }
    
    // Prepare output buffers
    uint8_t numb;
    std::vector<uint8_t> padded(64 * max_blocks);
    std::vector<FlatSHA256Witness::BlockWitness> bw(max_blocks);
    size_t msg_len = o_len(msg);
    const char *msg_val = o_val(msg);
    // Call witness generation (zero-copy from OCTET)
    FlatSHA256Witness::transform_and_witness_message(
        msg_len,
        (uint8_t*)msg_val,
        max_blocks,
        numb,
        padded.data(),
        bw.data()
    );
    
    // Create result table
    lua_newtable(L);
    
    // result.num_blocks = numb
    lua_pushinteger(L, numb);
    lua_setfield(L, -2, "num_blocks");
    
    // result.padded_input = OCTET
    octet* padded_oct = ::o_push(L, (char*)padded.data(), numb * 64);
    lua_setfield(L, -2, "padded_input");
    
    // result.witnesses = table of block witnesses
    lua_newtable(L);
    for (size_t i = 0; i < numb; i++) {
        lua_newtable(L);
        
        // outw array (48 elements)
        lua_newtable(L);
        for (int j = 0; j < 48; j++) {
            lua_pushinteger(L, bw[i].outw[j]);
            lua_rawseti(L, -2, j + 1);
        }
        lua_setfield(L, -2, "outw");
        
        // oute array (64 elements)
        lua_newtable(L);
        for (int j = 0; j < 64; j++) {
            lua_pushinteger(L, bw[i].oute[j]);
            lua_rawseti(L, -2, j + 1);
        }
        lua_setfield(L, -2, "oute");
        
        // outa array (64 elements)
        lua_newtable(L);
        for (int j = 0; j < 64; j++) {
            lua_pushinteger(L, bw[i].outa[j]);
            lua_rawseti(L, -2, j + 1);
        }
        lua_setfield(L, -2, "outa");
        
        // h1 array (8 elements - final hash)
        lua_newtable(L);
        for (int j = 0; j < 8; j++) {
            lua_pushinteger(L, bw[i].h1[j]);
            lua_rawseti(L, -2, j + 1);
        }
        lua_setfield(L, -2, "h1");
        
        // Add block witness to witnesses table
        lua_rawseti(L, -2, i + 1);  // Lua 1-indexed
    }
    lua_setfield(L, -2, "witnesses");
    
    // Clean up
    o_free(L, msg);
    
    return 1;  // Return result table
}

// ============================================================================
// ECDSA Witness Generation
// ============================================================================

// Structure to hold ECDSA witness data
struct ECDSAWitnessData {
    using EC = P256;
    using ScalarField = Fp256Scalar;
    using WitnessType = VerifyWitness3<EC, ScalarField>;
    
    std::unique_ptr<WitnessType> witness;
    const EC* ec;
    const ScalarField* fn;
    
    ECDSAWitnessData() : ec(&p256), fn(&p256_scalar) {
        witness = std::make_unique<WitnessType>(*fn, *ec);
    }
};

// Metatable name for ECDSA witness userdata
static const char* ECDSA_WITNESS_MT = "ZK.ECDSAWitness";

int ecdsa_create_witness(lua_State* L) {
    // Get OCTET arguments
    const octet* pkX_oct = o_arg(L, 1);
    const octet* pkY_oct = o_arg(L, 2);
    const octet* e_oct = o_arg(L, 3);
    const octet* r_oct = o_arg(L, 4);
    const octet* s_oct = o_arg(L, 5);
    size_t pkX_oct_len = o_len(pkX_oct);
    size_t pkY_oct_len = o_len(pkY_oct);
    size_t e_oct_len = o_len(e_oct);
    size_t r_oct_len = o_len(r_oct);
    size_t s_oct_len = o_len(s_oct);
    
    bool success = false;
    const char* error_msg = nullptr;
    
    // Validate arguments
    if (!pkX_oct) { error_msg = "pkX must be an OCTET"; goto cleanup; }
    if (!pkY_oct) { error_msg = "pkY must be an OCTET"; goto cleanup; }
    if (!e_oct) { error_msg = "e must be an OCTET"; goto cleanup; }
    if (!r_oct) { error_msg = "r must be an OCTET"; goto cleanup; }
    if (!s_oct) { error_msg = "s must be an OCTET"; goto cleanup; }
    if (pkX_oct_len != 32) { error_msg = "pkX must be 32 bytes"; goto cleanup; }
    if (pkY_oct_len != 32) { error_msg = "pkY must be 32 bytes"; goto cleanup; }
    if (e_oct_len != 32) { error_msg = "e must be 32 bytes"; goto cleanup; }
    if (r_oct_len != 32) { error_msg = "r must be 32 bytes"; goto cleanup; }
    if (s_oct_len != 32) { error_msg = "s must be 32 bytes"; goto cleanup; }
    
    {
        // Create witness data structure
        ECDSAWitnessData* data = (ECDSAWitnessData*)lua_newuserdata(L, sizeof(ECDSAWitnessData));
        new(data) ECDSAWitnessData();  // Placement new
        
        // Set metatable
        luaL_getmetatable(L, ECDSA_WITNESS_MT);
        lua_setmetatable(L, -2);
        
        // Convert OCTETs to field elements/nats
        auto pkX = data->ec->f_.to_montgomery(nat_from_octet<Fp256Nat>(pkX_oct));
        auto pkY = data->ec->f_.to_montgomery(nat_from_octet<Fp256Nat>(pkY_oct));
        auto e = nat_from_octet<Fp256Nat>(e_oct);
        auto r = nat_from_octet<Fp256Nat>(r_oct);
        auto s = nat_from_octet<Fp256Nat>(s_oct);
        
        // Compute witness
        success = data->witness->compute_witness(pkX, pkY, e, r, s);
        
        if (!success) {
            error_msg = "ECDSA witness computation failed (invalid signature)";
        }
    }
    
cleanup:
    // Free allocated octets
    if (pkX_oct) o_free(L, pkX_oct);
    if (pkY_oct) o_free(L, pkY_oct);
    if (e_oct) o_free(L, e_oct);
    if (r_oct) o_free(L, r_oct);
    if (s_oct) o_free(L, s_oct);
    
    if (error_msg) {
        return luaL_error(L, "ECDSA: %s", error_msg);
    }
    
    if (!success) {
        return luaL_error(L, "ECDSA: witness computation failed");
    }
    
    return 1;  // Return witness userdata
}

// Accessor: get rx as OCTET
int ecdsa_get_rx(lua_State* L) {
    ECDSAWitnessData* data = (ECDSAWitnessData*)luaL_checkudata(L, 1, ECDSA_WITNESS_MT);
    field_elt_to_octet(L, data->witness->rx_, data->ec->f_);
    return 1;
}

// Accessor: get ry as OCTET
int ecdsa_get_ry(lua_State* L) {
    ECDSAWitnessData* data = (ECDSAWitnessData*)luaL_checkudata(L, 1, ECDSA_WITNESS_MT);
    field_elt_to_octet(L, data->witness->ry_, data->ec->f_);
    return 1;
}

// Accessor: get rx_inv as OCTET
int ecdsa_get_rx_inv(lua_State* L) {
    ECDSAWitnessData* data = (ECDSAWitnessData*)luaL_checkudata(L, 1, ECDSA_WITNESS_MT);
    field_elt_to_octet(L, data->witness->rx_inv_, data->ec->f_);
    return 1;
}

// Accessor: get s_inv as OCTET
int ecdsa_get_s_inv(lua_State* L) {
    ECDSAWitnessData* data = (ECDSAWitnessData*)luaL_checkudata(L, 1, ECDSA_WITNESS_MT);
    field_elt_to_octet(L, data->witness->s_inv_, data->ec->f_);
    return 1;
}

// Destructor for ECDSA witness userdata
static int ecdsa_gc(lua_State* L) {
    ECDSAWitnessData* data = (ECDSAWitnessData*)luaL_checkudata(L, 1, ECDSA_WITNESS_MT);
    data->~ECDSAWitnessData();  // Explicit destructor call
    return 0;
}

// ============================================================================
// Type Conversion Utilities
// ============================================================================

int nat_from_octet_be(lua_State* L) {
    const octet* oct = o_arg(L, 1);
    if (!oct) {
        return luaL_error(L, "nat_from_octet: argument must be an OCTET");
    }
    if (o_len(oct) != 32) {
        o_free(L, oct);
        return luaL_error(L, "nat_from_octet: OCTET must be 32 bytes");
    }
    
    auto nat = nat_from_octet<Fp256Nat>(oct);
    o_free(L, oct);
    
    // Return as table of limbs for inspection (debugging purposes)
    lua_newtable(L);
    for (size_t i = 0; i < Fp256Nat::kLimbs; i++) {
        lua_pushinteger(L, nat.limb_[i]);
        lua_rawseti(L, -2, i + 1);
    }
    
    return 1;
}

// ============================================================================
// Module Registration
// ============================================================================

static const luaL_Reg ecdsa_witness_methods[] = {
    {"get_rx", ecdsa_get_rx},
    {"get_ry", ecdsa_get_ry},
    {"get_rx_inv", ecdsa_get_rx_inv},
    {"get_s_inv", ecdsa_get_s_inv},
    {"__gc", ecdsa_gc},
    {NULL, NULL}
};

static const luaL_Reg zk_witness_functions[] = {
    {"sha256_compute_message", sha256_compute_message},
    {"ecdsa_create_witness", ecdsa_create_witness},
    {"nat_from_octet", nat_from_octet_be},
    {NULL, NULL}
};

int luaopen_zk_witness(lua_State* L) {
    // Create ECDSA witness metatable
    luaL_newmetatable(L, ECDSA_WITNESS_MT);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, ecdsa_witness_methods, 0);
    lua_pop(L, 1);
    
    // Create ZK module table
    luaL_newlib(L, zk_witness_functions);
    
    return 1;
}

}  // namespace lua
}  // namespace proofs
