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

#include "lfzk_bindings.h"

namespace proofs {
namespace lua {

void register_zk_bindings(sol::state_view& lua) {
    // ========================================================================
    // Field Element Types
    // ========================================================================
    
    auto fp256_elt = lua.new_usertype<LuaFp256Elt>("Fp256Elt",
        sol::constructors<>(),
        
        // Arithmetic operators (metamethods for Lua operators)
        sol::meta_function::addition, &LuaFp256Elt::add,
        sol::meta_function::subtraction, &LuaFp256Elt::sub,
        sol::meta_function::multiplication, &LuaFp256Elt::mul,
        sol::meta_function::unary_minus, &LuaFp256Elt::neg,
        sol::meta_function::equal_to, &LuaFp256Elt::eq,
        
        // Methods
        "inv", &LuaFp256Elt::inv
    );
    
    auto gf2128_elt = lua.new_usertype<LuaGF2128Elt>("GF2128Elt",
        sol::constructors<>(),
        
        sol::meta_function::addition, &LuaGF2128Elt::add,
        sol::meta_function::multiplication, &LuaGF2128Elt::mul,
        sol::meta_function::equal_to, &LuaGF2128Elt::eq
    );
    
    // ========================================================================
    // Field Instance Types
    // ========================================================================
    
    auto fp256_field = lua.new_usertype<LuaFp256Field>("Fp256Field",
        sol::constructors<LuaFp256Field()>(),
        
        // Constants
        "zero", &LuaFp256Field::zero,
        "one", &LuaFp256Field::one,
        "two", &LuaFp256Field::two,
        "half", &LuaFp256Field::half,
        
        // Scalar conversion
        "of_scalar", &LuaFp256Field::of_scalar,
        
        // Functional arithmetic operations
        "addf", &LuaFp256Field::addf,
        "subf", &LuaFp256Field::subf,
        "mulf", &LuaFp256Field::mulf,
        "negf", &LuaFp256Field::negf,
        "invertf", &LuaFp256Field::invertf
    );
    
    auto gf2128_field = lua.new_usertype<LuaGF2128Field>("GF2128Field",
        sol::constructors<LuaGF2128Field()>(),
        
        // Constants
        "zero", &LuaGF2128Field::zero,
        "one", &LuaGF2128Field::one,
        
        // Functional arithmetic operations
        "addf", &LuaGF2128Field::addf,
        "mulf", &LuaGF2128Field::mulf
    );
    
    // ========================================================================
    // Low-Level Arithmetic Circuit (QuadCircuit)
    // ========================================================================
    
    auto quad_circuit = lua.new_usertype<LuaQuadCircuit>("QuadCircuit",
        sol::constructors<LuaQuadCircuit()>(),
        
        // Wire creation
        "input_wire", &LuaQuadCircuit::input_wire,
        "private_input", &LuaQuadCircuit::private_input,
        "begin_full_field", &LuaQuadCircuit::begin_full_field,
        
        // Arithmetic operations
        "add", &LuaQuadCircuit::add,
        "sub", &LuaQuadCircuit::sub,
        "mul", sol::overload(
            &LuaQuadCircuit::mul,
            &LuaQuadCircuit::mul_scalar,
            &LuaQuadCircuit::mul_scaled
        ),
        
        "linear", sol::overload(
            &LuaQuadCircuit::linear,
            &LuaQuadCircuit::linear_scaled
        ),
        
        "konst", &LuaQuadCircuit::konst,
        "axpy", &LuaQuadCircuit::axpy,
        "apy", &LuaQuadCircuit::apy,
        
        // Constraints
        "assert0", &LuaQuadCircuit::assert0,
        
        // Output
        "output_wire", &LuaQuadCircuit::output_wire,
        
        // Compilation
        "mkcircuit", &LuaQuadCircuit::mkcircuit,
        
        // Metrics (read-only properties)
        "ninput", sol::property(&LuaQuadCircuit::ninput),
        "npub_input", sol::property(&LuaQuadCircuit::npub_input),
        "noutput", sol::property(&LuaQuadCircuit::noutput),
        "depth", sol::property(&LuaQuadCircuit::depth),
        "nwires", sol::property(&LuaQuadCircuit::nwires),
        "nquad_terms", sol::property(&LuaQuadCircuit::nquad_terms)
    );
    
    // ========================================================================
    // High-Level Boolean Logic
    // ========================================================================
    
    // BitW (boolean wire)
    auto bitw = lua.new_usertype<LuaBitW>("BitW",
        sol::constructors<>(),
        "wire_id", &LuaBitW::wire_id
    );
    
    // EltW (field element wire)
    auto eltw = lua.new_usertype<LuaEltW>("EltW",
        sol::constructors<>(),
        "wire_id", &LuaEltW::wire_id
    );
    
    // BitVec8
    auto bitvec8 = lua.new_usertype<LuaBitVec<8>>("BitVec8",
        sol::constructors<>(),
        
        // Array access (1-indexed)
        "get", &LuaBitVec<8>::get,
        "set", &LuaBitVec<8>::set,
        "size", &LuaBitVec<8>::size,
        
        // Lua array indexing
        sol::meta_function::index, &LuaBitVec<8>::get,
        sol::meta_function::new_index, &LuaBitVec<8>::set,
        sol::meta_function::length, &LuaBitVec<8>::size
    );
    
    // BitVec32
    auto bitvec32 = lua.new_usertype<LuaBitVec<32>>("BitVec32",
        sol::constructors<>(),
        
        "get", &LuaBitVec<32>::get,
        "set", &LuaBitVec<32>::set,
        "size", &LuaBitVec<32>::size,
        
        sol::meta_function::index, &LuaBitVec<32>::get,
        sol::meta_function::new_index, &LuaBitVec<32>::set,
        sol::meta_function::length, &LuaBitVec<32>::size
    );
    
    // BitVec64
    auto bitvec64 = lua.new_usertype<LuaBitVec<64>>("BitVec64",
        sol::constructors<>(),
        
        "get", &LuaBitVec<64>::get,
        "set", &LuaBitVec<64>::set,
        "size", &LuaBitVec<64>::size,
        
        sol::meta_function::index, &LuaBitVec<64>::get,
        sol::meta_function::new_index, &LuaBitVec<64>::set,
        sol::meta_function::length, &LuaBitVec<64>::size
    );
    
    // BitVec16
    auto bitvec16 = lua.new_usertype<LuaBitVec<16>>("BitVec16",
        sol::constructors<>(),
        
        "get", &LuaBitVec<16>::get,
        "set", &LuaBitVec<16>::set,
        "size", &LuaBitVec<16>::size,
        
        sol::meta_function::index, &LuaBitVec<16>::get,
        sol::meta_function::new_index, &LuaBitVec<16>::set,
        sol::meta_function::length, &LuaBitVec<16>::size
    );
    
    // BitVec128
    auto bitvec128 = lua.new_usertype<LuaBitVec<128>>("BitVec128",
        sol::constructors<>(),
        
        "get", &LuaBitVec<128>::get,
        "set", &LuaBitVec<128>::set,
        "size", &LuaBitVec<128>::size,
        
        sol::meta_function::index, &LuaBitVec<128>::get,
        sol::meta_function::new_index, &LuaBitVec<128>::set,
        sol::meta_function::length, &LuaBitVec<128>::size
    );
    
    // BitVec256
    auto bitvec256 = lua.new_usertype<LuaBitVec<256>>("BitVec256",
        sol::constructors<>(),
        
        "get", &LuaBitVec<256>::get,
        "set", &LuaBitVec<256>::set,
        "size", &LuaBitVec<256>::size,
        
        sol::meta_function::index, &LuaBitVec<256>::get,
        sol::meta_function::new_index, &LuaBitVec<256>::set,
        sol::meta_function::length, &LuaBitVec<256>::size
    );
    
    // Logic (main high-level API)
    auto logic = lua.new_usertype<LuaLogic>("Logic",
        sol::constructors<LuaLogic()>(),
        
        // Field operations
        "zero", &LuaLogic::zero,
        "one", &LuaLogic::one,
        "mone", &LuaLogic::mone,
        "elt", &LuaLogic::elt,
        
        // Wire arithmetic
        "add", &LuaLogic::add,
        "sub", &LuaLogic::sub,
        "mul", sol::overload(
            &LuaLogic::mul,
            &LuaLogic::mul_scalar
        ),
        "mul_scalar", &LuaLogic::mul_scalar,
        "mul_3arg", &LuaLogic::mul_3arg,
        "mux_elt", &LuaLogic::mux_elt,
        
        "konst", sol::overload(
            &LuaLogic::konst,
            &LuaLogic::konst_int
        ),
        
        // Linear algebra operations
        "ax", &LuaLogic::ax,
        "axy", &LuaLogic::axy,
        "axpy", &LuaLogic::axpy,
        "apy", &LuaLogic::apy,
        
        // Boolean operations
        "bit", &LuaLogic::bit,
        "lnot", &LuaLogic::lnot,
        "land", &LuaLogic::land,
        "lor", &LuaLogic::lor,
        "lxor", &LuaLogic::lxor,
        "limplies", &LuaLogic::limplies,
        "mux", &LuaLogic::mux,
        
        // SHA-256 specific operations
        "lCh", &LuaLogic::lCh,
        "lMaj", &LuaLogic::lMaj,
        "lxor3", &LuaLogic::lxor3,
        "rebase", &LuaLogic::rebase,
        "lmul", &LuaLogic::lmul,
        "lor_exclusive", &LuaLogic::lor_exclusive,
        
        // Conversion operations
        "eval", &LuaLogic::eval,
        "as_scalar8", &LuaLogic::as_scalar8,
        "as_scalar32", &LuaLogic::as_scalar32,
        "as_scalar64", &LuaLogic::as_scalar64,
        
        // Assertions
        "assert0", sol::overload(
            &LuaLogic::assert0_elt,
            &LuaLogic::assert0_bit
        ),
        "assert1", &LuaLogic::assert1,
        "assert_eq", sol::overload(
            &LuaLogic::assert_eq_elt,
            &LuaLogic::assert_eq_bit
        ),
        "assert_is_bit", &LuaLogic::assert_is_bit,
        
        // I/O
        "eltw_input", &LuaLogic::eltw_input,
        "input", &LuaLogic::input,
        "output", &LuaLogic::output,
        
        // 8-bit vector operations
        "vinput8", &LuaLogic::vinput8,
        "vbit8", &LuaLogic::vbit8,
        "vnot8", &LuaLogic::vnot8,
        "vand8", &LuaLogic::vand8,
        "vor8", &LuaLogic::vor8,
        "vxor8", &LuaLogic::vxor8,
        "vadd8", &LuaLogic::vadd8,
        "veq8", &LuaLogic::veq8,
        "vlt8", &LuaLogic::vlt8,
        "vleq8", &LuaLogic::vleq8,
        "vCh8", &LuaLogic::vCh8,
        "vMaj8", &LuaLogic::vMaj8,
        "vxor3_8", &LuaLogic::vxor3_8,
        "vshr8", &LuaLogic::vshr8,
        "vshl8", &LuaLogic::vshl8,
        "vrotr8", &LuaLogic::vrotr8,
        "vrotl8", &LuaLogic::vrotl8,
        "vadd8_const", &LuaLogic::vadd8_const,
        "veq8_const", &LuaLogic::veq8_const,
        "vlt8_const", &LuaLogic::vlt8_const,
        "vor_exclusive8", &LuaLogic::vor_exclusive8,
        "voutput8", &LuaLogic::voutput8,
        "vassert0_8", &LuaLogic::vassert0_8,
        "vassert_eq8", &LuaLogic::vassert_eq8,
        
        // 32-bit vector operations
        "vinput32", &LuaLogic::vinput32,
        "vbit32", &LuaLogic::vbit32,
        "vadd32", &LuaLogic::vadd32,
        "veq32", &LuaLogic::veq32,
        "vnot32", &LuaLogic::vnot32,
        "vand32", &LuaLogic::vand32,
        "vor32", &LuaLogic::vor32,
        "vxor32", &LuaLogic::vxor32,
        "vlt32", &LuaLogic::vlt32,
        "vleq32", &LuaLogic::vleq32,
        "vCh32", &LuaLogic::vCh32,
        "vMaj32", &LuaLogic::vMaj32,
        "vxor3_32", &LuaLogic::vxor3_32,
        "vshr32", &LuaLogic::vshr32,
        "vshl32", &LuaLogic::vshl32,
        "vrotr32", &LuaLogic::vrotr32,
        "vrotl32", &LuaLogic::vrotl32,
        
        // 64-bit vector operations
        "vinput64", &LuaLogic::vinput64,
        "vbit64", &LuaLogic::vbit64,
        "vadd64", &LuaLogic::vadd64,
        "veq64", &LuaLogic::veq64,
        
        // 16-bit vector operations
        "vinput16", &LuaLogic::vinput16,
        "vbit16", &LuaLogic::vbit16,
        
        // 128-bit vector operations
        "vinput128", &LuaLogic::vinput128,
        "vbit128", &LuaLogic::vbit128,
        
        // 256-bit vector operations
        "vinput256", &LuaLogic::vinput256,
        "vbit256", &LuaLogic::vbit256,
        
        // Access underlying circuit
        "get_circuit", &LuaLogic::get_circuit,
        
        // Aggregate operations
        "add_range", &LuaLogic::add_range,
        "mul_range", &LuaLogic::mul_range,
        "land_range", &LuaLogic::land_range,
        "lor_range", &LuaLogic::lor_range,
        
        // Array operations
        "eq0", &LuaLogic::eq0,
        "eq_array", &LuaLogic::eq_array,
        "lt_array", &LuaLogic::lt_array,
        "leq_array", &LuaLogic::leq_array,
        "scan_and", &LuaLogic::scan_and,
        "scan_or", &LuaLogic::scan_or,
        "scan_xor", &LuaLogic::scan_xor,
        
        // Router primitives
        "vinput_var", &LuaLogic::vinput_var,
        "vbit_var", &LuaLogic::vbit_var,
        "create_routing", &LuaLogic::create_routing,
        "create_bit_plucker", &LuaLogic::create_bit_plucker,
        "create_memcmp", &LuaLogic::create_memcmp,
        "vlt_var", &LuaLogic::vlt_var,
        "vleq_var", &LuaLogic::vleq_var,
        "veq_var", &LuaLogic::veq_var
    );
    
    // ========================================================================
    // Router Primitives
    // ========================================================================
    
    // Variable-bit bit vector
    auto bitvec_var = lua.new_usertype<LuaBitVecVar>("BitVecVar",
        sol::constructors<>(),
        
        "get", &LuaBitVecVar::get,
        "set", &LuaBitVecVar::set,
        "size", &LuaBitVecVar::size,
        
        sol::meta_function::index, &LuaBitVecVar::get,
        sol::meta_function::new_index, &LuaBitVecVar::set,
        sol::meta_function::length, &LuaBitVecVar::size
    );
    
    // Routing class
    auto routing = lua.new_usertype<LuaRouting>("Routing",
        sol::constructors<>(),
        
        "shift8", &LuaRouting::shift8,
        "unshift8", &LuaRouting::unshift8
    );
    
    // BitPlucker class
    auto bit_plucker = lua.new_usertype<LuaBitPlucker>("BitPlucker",
        sol::constructors<>(),
        
        "pluck", &LuaBitPlucker::pluck,
        "unpack_v32", &LuaBitPlucker::unpack_v32,
        "packed_input_v32", &LuaBitPlucker::packed_input_v32
    );
    
    // Memcmp class
    auto memcmp = lua.new_usertype<LuaMemcmp>("Memcmp",
        sol::constructors<>(),
        
        "lt", &LuaMemcmp::lt,
        "leq", &LuaMemcmp::leq
    );
    
    // GF2_128 Wire Wrappers
    auto gf2128_bitw = lua.new_usertype<LuaGF2128BitW>("GF2128BitW",
        sol::constructors<>(),
        "wire_id", &LuaGF2128BitW::wire_id
    );
    
    auto gf2128_eltw = lua.new_usertype<LuaGF2128EltW>("GF2128EltW",
        sol::constructors<>(),
        "wire_id", &LuaGF2128EltW::wire_id
    );
    
    // GF2_128 Logic (high-level API for GF2_128)
    auto gf2128_logic = lua.new_usertype<LuaGF2128Logic>("GF2128Logic",
        sol::constructors<LuaGF2128Logic()>(),
        
        // Field operations
        "zero", &LuaGF2128Logic::zero,
        "one", &LuaGF2128Logic::one,
        
        // Wire arithmetic
        "add", &LuaGF2128Logic::add,
        "mul", &LuaGF2128Logic::mul,
        "mul_scalar", &LuaGF2128Logic::mul_scalar,
        "konst", sol::overload(
            &LuaGF2128Logic::konst,
            &LuaGF2128Logic::konst_int
        ),
        
        // I/O
        "eltw_input", &LuaGF2128Logic::eltw_input,
        "output", &LuaGF2128Logic::output,
        
        // Assertions
        "assert_eq_elt", &LuaGF2128Logic::assert_eq_elt,
        
        // Access underlying circuit
        "get_circuit", &LuaGF2128Logic::get_circuit
    );
    
    // ========================================================================
    // Utility Functions (global namespace)
    // ========================================================================
    
    lua.set_function("create_fp256_field", []() -> LuaFp256Field* {
        return new LuaFp256Field();
    });
    
    lua.set_function("create_gf2128_field", []() -> LuaGF2128Field* {
        return new LuaGF2128Field();
    });
    
    lua.set_function("create_quad_circuit", []() -> LuaQuadCircuit* {
        return new LuaQuadCircuit();
    });
    
    lua.set_function("create_logic", []() -> LuaLogic* {
        return new LuaLogic();
    });
    
    lua.set_function("create_gf2128_logic", []() -> LuaGF2128Logic* {
        return new LuaGF2128Logic();
    });
    
    // ========================================================================
    // Version Information
    // ========================================================================
    
    lua["LONGFELLOW_ZK_VERSION"] = "0.1.0";
    lua["SOL_VERSION"] = SOL_VERSION_STRING;
}

}  // namespace lua
}  // namespace proofs

// ============================================================================
// Lua Module Entry Point
// ============================================================================

extern "C" {

int luaopen_zk_bindings(lua_State* L) {
    sol::state_view lua(L);
    proofs::lua::register_zk_bindings(lua);
    return 0;  // No return values
}

}
