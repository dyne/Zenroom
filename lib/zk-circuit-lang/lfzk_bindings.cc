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
#include "witness_bindings.h"

namespace proofs {
namespace lua {

// Route C++ exceptions into Zenroom's error machinery so Lua sees native
// diagnostics with stack traces and logging.
int zk_exception_handler(lua_State* L,
                         sol::optional<const std::exception&> maybe_ex,
                         sol::string_view description) {
    std::string message;
    if (maybe_ex) {
        message = maybe_ex->what();
    }
    if (message.empty()) {
        message.assign(description.data(), description.size());
    }
    if (message.empty()) {
        message = "unknown C++ exception";
    }
    lerror(L,"%s", message.c_str());  // never returns
    return 1;
}

// Deterministic PRF-backed RNG for testable proofs
class SeededRandomEngine : public RandomEngine {
public:
    explicit SeededRandomEngine(const uint8_t* seed, size_t len) {
        SHA256 sha;
        sha.Update(seed, len);
        sha.DigestData(key_);
        prf_ = std::make_unique<FSPRF>(key_);
    }

    void bytes(uint8_t* buf, size_t n) override {
        prf_->bytes(buf, n);
    }

private:
    uint8_t key_[kPRFKeySize];
    std::unique_ptr<FSPRF> prf_;
};

// Hardcoded root for FFT-based Reed-Solomon (same as mdoc_zk.cc)
static constexpr char kRootX[] =
    "112649224146410281873500457609690258373018840430489408729223714171582664"
    "680802";
static constexpr char kRootY[] =
    "317040948518153410669569855215889129699039744181079354462206130544166376"
    "41043";

// Build Dense witness arrays from Lua table of OCTETs
int lua_build_witness_inputs(lua_State* L) {
    sol::state_view lua(L);
    sol::table opts = sol::stack::get<sol::table>(L, 1);

    LuaCircuitArtifact* art = opts["circuit"];
    if (!art || !art->circuit) {
        lerror(L, "build_witness_inputs: missing circuit");
        return 0;
    }
    sol::optional<sol::table> inputs_opt = opts["inputs"];
    if (!inputs_opt) {
        lerror(L, "build_witness_inputs: missing inputs table");
        return 0;
    }
    sol::table inputs = inputs_opt.value();

    size_t ninputs = art->circuit->ninputs;
    size_t npub = art->npub_input();

    LuaWitnessInputs witness(ninputs, npub);
    witness.field = &art->field;
    const auto& F = art->field;

    // Default all zeros, then set wire 0 = 1
    for (auto& v : witness.all->v_) v = F.zero();
    for (auto& v : witness.pub->v_) v = F.zero();
    if (ninputs > 0) {
        witness.all->v_[0] = F.one();
        if (npub > 0) {
            witness.pub->v_[0] = F.one();
        }
    }

    // Populate provided inputs
    for (const auto& kv : inputs) {
        if (!kv.first.is<size_t>()) {
            lerror(L, "build_witness_inputs: input keys must be numbers");
            return 0;
        }
        size_t idx = kv.first.as<size_t>();
        if (idx >= ninputs) {
            lerror(L, "build_witness_inputs: index %zu out of range", idx);
            return 0;
        }

        kv.second.push();
        int val_idx = lua_gettop(L);
        const octet* o = o_arg(L, val_idx);
        if (!o) {
            lua_pop(L, 1);
            lerror(L, "build_witness_inputs: input %zu must be an OCTET", idx);
            return 0;
        }
        if (o_len(o) != 32) {
            o_free(L, o);
            lua_pop(L, 1);
            lerror(L, "build_witness_inputs: input %zu must be 32 bytes", idx);
            return 0;
        }

        auto nat = nat_from_octet<Fp256Nat>(o);
        witness.all->v_[idx] = F.to_montgomery(nat);
        if (idx < npub) {
            witness.pub->v_[idx] = witness.all->v_[idx];
        }

        o_free(L, o);
        lua_pop(L, 1);  // pop value
    }

    return sol::stack::push(L, std::move(witness));
}

// Prove circuit with provided witness
int lua_prove_circuit(lua_State* L) {
    sol::state_view lua(L);
    sol::table opts = sol::stack::get<sol::table>(L, 1);

    LuaCircuitArtifact* art = opts["circuit"];
    LuaWitnessInputs* witness = opts["inputs"];

    if (!art || !art->circuit) {
        lerror(L, "prove_circuit: missing circuit");
        return 0;
    }
    if (!witness || !witness->all) {
        lerror(L, "prove_circuit: missing inputs");
        return 0;
    }

    uint8_t seed_buf[kSHA256DigestSize] = {0};
    size_t seed_len = sizeof(seed_buf);
    if (opts["seed"].valid()) {
        opts["seed"].push();
        const octet* seed = o_arg(L, -1);
        if (seed) {
            size_t copy_len = o_len(seed) < seed_len ? o_len(seed) : seed_len;
            memcpy(seed_buf, o_val(seed), copy_len);
            o_free(L, seed);
        }
        lua_pop(L, 1);
    }

    using Field = Fp256Base;
    const Field& F = witness->field ? *witness->field : art->field;
    Fp2<Field> F2(F);
    auto omega = F2.of_string(kRootX, kRootY);
    FFTExtConvolutionFactory<Field, Fp2<Field>> fft(F, F2, omega, 1ull << 31);
    ReedSolomonFactory<Field, FFTExtConvolutionFactory<Field, Fp2<Field>>> rsf(fft, F);

    ZkProof<Field> zk(*art->circuit, kLigeroRate, kLigeroNreq);
    ZkProver<Field, decltype(rsf)> prover(*art->circuit, F, rsf);

    Transcript tp(seed_buf, seed_len, /*version=*/4);
    SeededRandomEngine rng(seed_buf, seed_len);

    prover.commit(zk, *witness->all, tp, rng);
    bool ok = prover.prove(zk, *witness->all, tp);
    if (!ok) {
        lerror(L, "prove_circuit: proof generation failed");
        return 0;
    }

    std::vector<uint8_t> buf;
    zk.write(buf, F);
    push_buffer_to_octet(L, reinterpret_cast<char*>(buf.data()), buf.size());
    return 1;
}

// Verify proof
int lua_verify_circuit(lua_State* L) {
    sol::state_view lua(L);
    sol::table opts = sol::stack::get<sol::table>(L, 1);

    LuaCircuitArtifact* art = opts["circuit"];
    LuaWitnessInputs* witness = opts["public_inputs"];

    if (!art || !art->circuit) {
        lerror(L, "verify_circuit: missing circuit");
        return 0;
    }
    if (!witness || !witness->pub) {
        lerror(L, "verify_circuit: missing public inputs");
        return 0;
    }

    // Seed handling
    uint8_t seed_buf[kSHA256DigestSize] = {0};
    size_t seed_len = sizeof(seed_buf);
    if (opts["seed"].valid()) {
        opts["seed"].push();
        const octet* s = o_arg(L, -1);
        if (s) {
            size_t copy_len = o_len(s) < seed_len ? o_len(s) : seed_len;
            memcpy(seed_buf, o_val(s), copy_len);
            o_free(L, s);
        }
        lua_pop(L, 1);
    }

    using Field = Fp256Base;
    const Field& F = witness->field ? *witness->field : art->field;
    Fp2<Field> F2(F);
    auto omega = F2.of_string(kRootX, kRootY);
    FFTExtConvolutionFactory<Field, Fp2<Field>> fft(F, F2, omega, 1ull << 31);
    ReedSolomonFactory<Field, FFTExtConvolutionFactory<Field, Fp2<Field>>> rsf(fft, F);

    // Deserialize proof
    opts["proof"].push();
    const octet* proof_oct = o_arg(L, -1);
    if (!proof_oct) {
        lua_pop(L, 1);
        lerror(L, "verify_circuit: missing proof");
        return 0;
    }
    ReadBuffer rb(reinterpret_cast<const uint8_t*>(o_val(proof_oct)), o_len(proof_oct));
    ZkProof<Field> zk(*art->circuit, kLigeroRate, kLigeroNreq);
    bool read_ok = zk.read(rb, F);
    o_free(L, proof_oct);
    lua_pop(L, 1);
    if (!read_ok) {
        lerror(L, "verify_circuit: failed to parse proof");
        return 0;
    }

    Transcript tv(seed_buf, seed_len, /*version=*/4);
    ZkVerifier<Field, decltype(rsf)> verifier(*art->circuit, rsf, kLigeroRate, kLigeroNreq, F);
    verifier.recv_commitment(zk, tv);
    bool ok = verifier.verify(zk, *witness->pub, tv);

    lua_pushboolean(L, ok);
    return 1;
}

void register_zk_bindings(sol::state_view& lua) {
    
    // ========================================================================
    // Wire Wrapper (for operator overloading)
    // ========================================================================
    
    auto wire = lua.new_usertype<LuaWire>("Wire",
        sol::constructors<>(),
        
        // Operators
        sol::meta_function::addition, &LuaWire::operator+,
        sol::meta_function::subtraction, &LuaWire::operator-,
        sol::meta_function::multiplication, &LuaWire::operator*,
        sol::meta_function::to_string, &LuaWire::to_string,
        
        // Access wire ID
        "id", &LuaWire::id,
        "to_string", &LuaWire::to_string
    );
    
    // ========================================================================
    // Circuit Template (for building circuits)
    // ========================================================================
    
    auto circuit_template = lua.new_usertype<LuaCircuitTemplate>("CircuitTemplate",
        sol::constructors<LuaCircuitTemplate()>(),
        
        // Wire creation
        "input_wire", &LuaCircuitTemplate::input_wire,
        "private_input", &LuaCircuitTemplate::private_input,
        "begin_full_field", &LuaCircuitTemplate::begin_full_field,
        
        // Arithmetic operations
        "add", &LuaCircuitTemplate::add,
        "sub", &LuaCircuitTemplate::sub,
        "mul", sol::overload(
            &LuaCircuitTemplate::mul,
            &LuaCircuitTemplate::mul_scalar,
            &LuaCircuitTemplate::mul_scaled
        ),
        
        "linear", sol::overload(
            &LuaCircuitTemplate::linear,
            &LuaCircuitTemplate::linear_scaled
        ),
        
        "konst", &LuaCircuitTemplate::konst,
        "axpy", &LuaCircuitTemplate::axpy,
        "apy", &LuaCircuitTemplate::apy,
        
        // Constraints (accept both raw IDs and LuaWire)
        "assert0", sol::overload(
            &LuaCircuitTemplate::assert0,
            &LuaCircuitTemplate::assert0_wire
        ),
        
        // Output
        "output_wire", &LuaCircuitTemplate::output_wire,
        
        // Template metrics (before compilation)
        "ninput", sol::property(&LuaCircuitTemplate::ninput),
        "npub_input", sol::property(&LuaCircuitTemplate::npub_input),
        "noutput", sol::property(&LuaCircuitTemplate::noutput)
    );
    
    // ========================================================================
    // Circuit Artifact (compiled/loaded circuit)
    // ========================================================================
    
    auto circuit_artifact = lua.new_usertype<LuaCircuitArtifact>("CircuitArtifact",
        sol::no_constructor,
        
        // Export to OCTET
        "octet", &LuaCircuitArtifact::lua_octet,
        
        // Get circuit ID
        "circuit_id", &LuaCircuitArtifact::lua_circuit_id,
        
        // Input management
        "set_input", &LuaCircuitArtifact::lua_set_input,
        "get_input", &LuaCircuitArtifact::lua_get_input,
        
        // Metrics
        "ninput", sol::property(&LuaCircuitArtifact::ninput),
        "npub_input", sol::property(&LuaCircuitArtifact::npub_input),
        "depth", sol::property(&LuaCircuitArtifact::depth),
        "nwires", sol::property(&LuaCircuitArtifact::nwires),
        "nquad_terms", sol::property(&LuaCircuitArtifact::nquad_terms)
    );
    
    // Witness bundle
    auto witness_inputs = lua.new_usertype<LuaWitnessInputs>("WitnessInputs",
        sol::constructors<LuaWitnessInputs(size_t, size_t)>(),
        "ninputs", [](LuaWitnessInputs& w) { return w.all ? w.all->n1_ : 0; },
        "npub", [](LuaWitnessInputs& w) { return w.pub ? w.pub->n1_ : 0; }
    );

    // ========================================================================
    // High-Level Boolean Logic
    // ========================================================================
    
    // Register LuaBitW with operators
    auto bitw = lua.new_usertype<LuaBitW>("BitW",
        sol::constructors<>(),
        
        sol::meta_function::bitwise_and, &LuaBitW::land,
        sol::meta_function::bitwise_or, &LuaBitW::lor,
        sol::meta_function::bitwise_xor, &LuaBitW::lxor,
        sol::meta_function::bitwise_not, &LuaBitW::lnot,
        sol::meta_function::equal_to, &LuaBitW::eq,
        sol::meta_function::to_string, &LuaBitW::to_string,
        
        "land", &LuaBitW::land,
        "lor", &LuaBitW::lor,
        "lxor", &LuaBitW::lxor,
        "lnot", &LuaBitW::lnot,
        "eq", &LuaBitW::eq,
        "wire_id", &LuaBitW::wire_id,
        "to_string", &LuaBitW::to_string
    );
    
    // Register LuaEltW with operators
    auto eltw = lua.new_usertype<LuaEltW>("EltW",
        sol::constructors<>(),
        
        sol::meta_function::addition, &LuaEltW::add,
        sol::meta_function::subtraction, &LuaEltW::sub,
        sol::meta_function::multiplication, sol::overload(
            static_cast<LuaEltW(LuaEltW::*)(const LuaEltW&) const>(&LuaEltW::mul),
            static_cast<LuaEltW(LuaEltW::*)(const LuaFp256Elt&) const>(&LuaEltW::mul_scalar)
        ),
        sol::meta_function::equal_to, &LuaEltW::eq,
        sol::meta_function::to_string, &LuaEltW::to_string,
        
        "add", &LuaEltW::add,
        "sub", &LuaEltW::sub,
        "mul", &LuaEltW::mul,
        "mul_scalar", &LuaEltW::mul_scalar,
        "eq", &LuaEltW::eq,
        "wire_id", &LuaEltW::wire_id,
        "to_string", &LuaEltW::to_string
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
        sol::meta_function::length, &LuaBitVec<8>::size,
        sol::meta_function::to_string, &LuaBitVec<8>::to_string,
        
        "to_string", &LuaBitVec<8>::to_string
    );
    
    // BitVec32
    auto bitvec32 = lua.new_usertype<LuaBitVec<32>>("BitVec32",
        sol::constructors<>(),
        
        "get", &LuaBitVec<32>::get,
        "set", &LuaBitVec<32>::set,
        "size", &LuaBitVec<32>::size,
        
        sol::meta_function::index, &LuaBitVec<32>::get,
        sol::meta_function::new_index, &LuaBitVec<32>::set,
        sol::meta_function::length, &LuaBitVec<32>::size,
        sol::meta_function::to_string, &LuaBitVec<32>::to_string,
        
        "to_string", &LuaBitVec<32>::to_string
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
        "expr", &LuaLogic::expr,
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
        "private_inputs", &LuaLogic::private_inputs,
        "begin_full_field", &LuaLogic::begin_full_field,
        "PRIV", &LuaLogic::PRIV,
        "FULL", &LuaLogic::FULL,
        "compile", &LuaLogic::compile,
        
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
        "vmux8", &LuaLogic::vmux8,
        
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
        sol::meta_function::length, &LuaBitVecVar::size,
        sol::meta_function::to_string, &LuaBitVecVar::to_string,
        
        "to_string", &LuaBitVecVar::to_string
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
    // Version Information (will be added to returned table)
    // ========================================================================
}

}  // namespace lua
}  // namespace proofs

// ============================================================================
// Lua Module Entry Point
// ============================================================================

extern "C" {

int luaopen_zkcore(lua_State* L) {
    sol::state_view lua(L);
    lua.set_exception_handler(&proofs::lua::zk_exception_handler);
    proofs::lua::register_zk_bindings(lua);
    
    // Create a table to return (this will be the ZKCORE module)
    sol::table zkcore_table = lua.create_table();
    
    
    // Factory: create circuit template
    zkcore_table.set_function("new_circuit_template", []() -> proofs::lua::LuaCircuitTemplate* {
        return new proofs::lua::LuaCircuitTemplate();
    });
    
    // Factory: build circuit artifact from template
    zkcore_table["build_circuit_artifact"] = &proofs::lua::lua_build_circuit_artifact;
    
    // Factory: load circuit artifact from OCTET
    zkcore_table["load_circuit_artifact"] = &proofs::lua::LuaCircuitArtifact::lua_load_from_octet;
    
    zkcore_table.set_function("create_logic", []() -> proofs::lua::LuaLogic* {
        return new proofs::lua::LuaLogic();
    });
    // Alias: simpler entrypoint
    zkcore_table["logic"] = zkcore_table["create_logic"];
    
    zkcore_table.set_function("create_gf2128_logic", []() -> proofs::lua::LuaGF2128Logic* {
        return new proofs::lua::LuaGF2128Logic();
    });

    zkcore_table["build_witness_inputs"] = &proofs::lua::lua_build_witness_inputs;
    zkcore_table["prove_circuit"] = &proofs::lua::lua_prove_circuit;
    zkcore_table["verify_circuit"] = &proofs::lua::lua_verify_circuit;
    
    // Register witness bindings in the ZKCORE table
    // Push the zkcore_table to the stack first
    sol::stack::push(L, zkcore_table);
    
    // Now call luaopen_zk_witness which pushes witness table
    proofs::lua::luaopen_zk_witness(L);
    
    // Set witness table as a field of zkcore_table
    lua_setfield(L, -2, "witness");  // zkcore_table.witness = witness_module

    // Pop zkcore_table from stack (it's already in the SOL object)
    lua_pop(L, 1);
    
    // Add version information
    zkcore_table["SOL_VERSION"] = SOL_VERSION_STRING;
    zkcore_table["LONGFELLOW_ZK_VERSION"] = "0.1.0";
    
    // Return the table
    return sol::stack::push(L, zkcore_table);
}

}
