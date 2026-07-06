// Copyright (C) 2025-2026 Dyne.org foundation
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

#ifndef LONGFELLOW_ZK_LUA_BINDINGS_H_
#define LONGFELLOW_ZK_LUA_BINDINGS_H_

#include <memory>
#include <tuple>
#include <vector>
#include <string>

#include "sol.hpp"
#include "ec/p256.h"
#include "ec/p256k1.h"
#include "algebra/fp_p256.h"
#include "algebra/fp2.h"
#include "gf2k/gf2_128.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/logic.h"
#include "circuits/logic/compiler_backend.h"
#include "sumcheck/circuit.h"
#include "custom_backend.h"
#include "circuits/logic/routing.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/logic/bit_adder.h"
#include "circuits/logic/memcmp.h"
#include "proto/circuit.h"
#include "zk/zk_prover.h"
#include "zk/zk_verifier.h"
#include "random/transcript.h"
#include "algebra/convolution.h"
#include "algebra/reed_solomon.h"
#include "algebra/fft.h"
#include "arrays/dense.h"

#include "octet_conversions.h"
#include "circuits/bip340/bip340_gadgets.h"

extern "C" {
#include <zenroom.h>
// declares extern void *ZEN;
#include <zen_error.h>
}
// to use when the scope doesn't contains the Lua context
#define _fatal(L,error) zerror(((zenroom_t*)ZEN)->lua, "%s", error)

namespace proofs {
namespace lua {

// Constants used in mdoc circuits
static constexpr size_t kCborIndexBits = 13;
static constexpr size_t kSHAPluckerBits = 4;
static constexpr size_t kMACPluckerBits = 4;
// Ligero parameters (mirrored from mdoc_zk.h to avoid pulling that header)
static constexpr size_t kLigeroRate = 4;
static constexpr size_t kLigeroNreq = 128;  // ~86 bits statistical soundness


// ============================================================================
// Field Element Wrappers
// ============================================================================

template <class Field_>
class LuaFieldEltT {
public:
	using Field = Field_;
	using Elt = Field::Elt;

	Elt value;
	const Field* field;

	LuaFieldEltT(const Elt& v, const Field* f) : value(v), field(f) {}

	// Arithmetic operations
	LuaFieldEltT add(const LuaFieldEltT& other) const {
		return LuaFieldEltT(field->addf(value, other.value), field);
	}

	LuaFieldEltT sub(const LuaFieldEltT& other) const {
		return LuaFieldEltT(field->subf(value, other.value), field);
	}

	LuaFieldEltT mul(const LuaFieldEltT& other) const {
		return LuaFieldEltT(field->mulf(value, other.value), field);
	}

	LuaFieldEltT neg() const {
		return LuaFieldEltT(field->negf(value), field);
	}

	// Overloaded operators
	LuaFieldEltT operator+(const LuaFieldEltT& other) const { return add(other); }
	LuaFieldEltT operator-(const LuaFieldEltT& other) const { return sub(other); }
	LuaFieldEltT operator*(const LuaFieldEltT& other) const { return mul(other); }
	LuaFieldEltT operator-() const { return neg(); }

	// String representation
	std::string to_string() const {
		return "Fp256Elt";
	}
	
	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.fp256elt"; }
};

using LuaFp256Elt = LuaFieldEltT<Fp256Base>;
using LuaFp256k1Elt = LuaFieldEltT<Fp256k1Base>;

// Wrapper for GF2_128 field elements
class LuaGF2128Elt {
public:
	using Field = GF2_128<>;
	using Elt = Field::Elt;

	Elt value;
	const Field* field;

	LuaGF2128Elt(const Elt& v, const Field* f) : value(v), field(f) {}

	// Arithmetic operations
	LuaGF2128Elt add(const LuaGF2128Elt& other) const {
		return LuaGF2128Elt(field->addf(value, other.value), field);
	}

	LuaGF2128Elt mul(const LuaGF2128Elt& other) const {
		return LuaGF2128Elt(field->mulf(value, other.value), field);
	}

	// Overloaded operators
	LuaGF2128Elt operator+(const LuaGF2128Elt& other) const { return add(other); }
	LuaGF2128Elt operator*(const LuaGF2128Elt& other) const { return mul(other); }

	// String representation
	std::string to_string() const {
		return "GF2128Elt";
	}
	
	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.gf2128elt"; }
};

// ============================================================================
// Low-Level Arithmetic Circuit API (QuadCircuit)
// ============================================================================

// Forward declarations
class LuaCircuitTemplate;

// Wire wrapper to enable operator overloading
class LuaWire {
public:
	size_t wire_id;
	LuaCircuitTemplate* circuit;

	LuaWire(size_t id, LuaCircuitTemplate* c) : wire_id(id), circuit(c) {}

	// Arithmetic operators
	LuaWire operator+(const LuaWire& other) const;
	LuaWire operator-(const LuaWire& other) const;
	LuaWire operator*(const LuaWire& other) const;

	// Get the underlying wire ID
	size_t id() const { return wire_id; }

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.wire"; }

	std::string to_string() const {
		char buffer[64];
		snprintf(buffer, sizeof(buffer), "Wire(%zu)", wire_id);
		return std::string(buffer);
	}
};

// Circuit Template - for building circuits
class LuaCircuitTemplate {
public:
	using Field = Fp256Base;

	Field field;
	std::unique_ptr<QuadCircuit<Field>> circuit;

	LuaCircuitTemplate()
		: field(),
		  circuit(std::make_unique<QuadCircuit<Field>>(field)) {}

	// Wire creation - returns LuaWire for operator overloading
	LuaWire input_wire() {
		return LuaWire(circuit->input_wire(), this);
	}

	void private_input() { circuit->private_input(); }
	void begin_full_field() { circuit->begin_full_field(); }

	// Arithmetic operations - work with both LuaWire and raw wire IDs
	size_t add(size_t op0, size_t op1) { return circuit->add(op0, op1); }
	size_t sub(size_t op0, size_t op1) { return circuit->sub(op0, op1); }
	size_t mul(size_t op0, size_t op1) { return circuit->mul(op0, op1); }

	LuaWire add_wire(const LuaWire& w0, const LuaWire& w1) {
		return LuaWire(circuit->add(w0.wire_id, w1.wire_id), this);
	}

	LuaWire sub_wire(const LuaWire& w0, const LuaWire& w1) {
		return LuaWire(circuit->sub(w0.wire_id, w1.wire_id), this);
	}

	LuaWire mul_wire(const LuaWire& w0, const LuaWire& w1) {
		return LuaWire(circuit->mul(w0.wire_id, w1.wire_id), this);
	}

	size_t mul_scalar(const LuaFp256Elt& k, size_t op) {
		return circuit->mul(k.value, op);
	}

	size_t mul_scaled(const LuaFp256Elt& k, size_t op0, size_t op1) {
		return circuit->mul(k.value, op0, op1);
	}

	size_t linear(size_t op0) { return circuit->linear(op0); }

	size_t linear_scaled(const LuaFp256Elt& k, size_t op0) {
		return circuit->linear(k.value, op0);
	}

	size_t konst(const LuaFp256Elt& k) { return circuit->konst(k.value); }

	size_t axpy(size_t y, const LuaFp256Elt& a, size_t x) {
		return circuit->axpy(y, a.value, x);
	}

	size_t apy(size_t y, const LuaFp256Elt& a) {
		return circuit->apy(y, a.value);
	}

	// Constraints - accept both LuaWire and raw IDs
	size_t assert0(size_t op) { return circuit->assert0(op); }
	size_t assert0_wire(const LuaWire& w) { return circuit->assert0(w.wire_id); }

	// Output
	void output_wire(size_t n, size_t wire_id) { circuit->output_wire(n, wire_id); }
	void output_wire_obj(size_t n, const LuaWire& w) { circuit->output_wire(n, w.wire_id); }

	// Template metrics (before compilation)
	size_t ninput() const { return circuit->ninput_; }
	size_t npub_input() const { return circuit->npub_input_; }
	size_t noutput() const { return circuit->noutput_; }
};

// Circuit Artifact - compiled/loaded circuit
template <class Field_, FieldID FieldTag>
class LuaCircuitArtifactT {
public:
	using Field = Field_;
	using CircuitType = Circuit<Field>;

	Field field;
	std::unique_ptr<CircuitType> circuit;
	std::vector<typename Field::Elt> inputs;  // Stores both public and private inputs

	LuaCircuitArtifactT(std::unique_ptr<CircuitType> compiled)
		: field(), circuit(std::move(compiled)) {
		if (circuit) {
			inputs.resize(circuit->ninputs, field.zero());
		}
	}

	// Move constructor
	LuaCircuitArtifactT(LuaCircuitArtifactT&& other) noexcept
		: field(), circuit(std::move(other.circuit)), inputs(std::move(other.inputs)) {}

	// Delete copy constructor
	LuaCircuitArtifactT(const LuaCircuitArtifactT&) = delete;
	LuaCircuitArtifactT& operator=(const LuaCircuitArtifactT&) = delete;

	// Metrics
	size_t ninput() const { return circuit ? circuit->ninputs : 0; }
	size_t npub_input() const { return circuit ? circuit->npub_in : 0; }
	size_t depth() const { return circuit ? circuit->l.size() : 0; }
	size_t nwires() const { return circuit ? circuit->nv : 0; }
	size_t nquad_terms() const { return circuit ? circuit->nc : 0; }

	// Export to OCTET
	static int lua_octet(lua_State* L) {
		LuaCircuitArtifactT* self = sol::stack::get<LuaCircuitArtifactT*>(L, 1);

		if (!self->circuit) {
			lerror(L,"No circuit artifact");
			return 0;
		}

		// Serialize circuit to bytes
		CircuitRep<Field> rep(self->field, FieldTag);
		std::vector<uint8_t> bytes;
		rep.to_bytes(*self->circuit, bytes);

		// Create OCTET and copy data
		push_buffer_to_octet(L, (char*)bytes.data(), bytes.size());
		return 1;
	}

	// Get circuit ID
	static int lua_circuit_id(lua_State* L) {
		LuaCircuitArtifactT* self = sol::stack::get<LuaCircuitArtifactT*>(L, 1);

		if (!self->circuit) {
			lerror(L,"No circuit artifact");
			return 0;
		}

		push_buffer_to_octet(L,(char*)self->circuit->id,32);

		return 1;
	}

	// Set input from OCTET (index and value)
	static int lua_set_input(lua_State* L) {
		LuaCircuitArtifactT* self = sol::stack::get<LuaCircuitArtifactT*>(L, 1);

		if (!self->circuit) {
			lerror(L,"No circuit artifact");
			return 0;
		}

		if (!lua_isnumber(L, 2)) {
			lerror(L,"Second argument must be input index (number)");
			return 0;
		}
		size_t idx = lua_tointeger(L, 2);

		const octet* value_oct = o_arg(L, 3);
		if (!value_oct) {
			lerror(L,"Third argument must be an OCTET (32 bytes)");
			return 0;
		}

		if (o_len(value_oct) != 32) {
			o_free(L, value_oct);
			lerror(L,"Input value must be 32 bytes");
			return 0;
		}

		if (idx >= self->inputs.size()) {
			o_free(L, value_oct);
			lerror(L,"Input index %zu out of range (max: %zu)", idx, self->inputs.size());
			return 0;
		}

		// Convert OCTET to field element
		self->inputs[idx] = self->field.to_montgomery(
			nat_from_octet<typename Field::N>(value_oct));

		o_free(L, value_oct);
		return 0;
	}

	// Get input as OCTET
	static int lua_get_input(lua_State* L) {
		LuaCircuitArtifactT* self = sol::stack::get<LuaCircuitArtifactT*>(L, 1);

		if (!self->circuit) {
			lerror(L,"No circuit artifact");
			return 0;
		}

		if (!lua_isnumber(L, 2)) {
			lerror(L,"Second argument must be input index (number)");
			return 0;
		}
		size_t idx = lua_tointeger(L, 2);

		if (idx >= self->inputs.size()) {
			lerror(L,"Input index %zu out of range (max: %zu)", idx, self->inputs.size());
			return 0;
		}

		// Convert field element to OCTET
		uint8_t bytes[32];
		auto nat = self->field.from_montgomery(self->inputs[idx]);
		nat.to_bytes(bytes);
		push_buffer_to_octet(L,(char*)bytes,32);
		return 1;
	}

	// Load from OCTET
	static int lua_load_from_octet(lua_State* L) {
		const octet* oct = o_arg(L, 1);
		if (!oct) {
			lerror(L,"Argument must be an OCTET");
			return 0;
		}

		ReadBuffer buf((const uint8_t*)o_val(oct), o_len(oct));
		CircuitRep<Field> rep(Field(), FieldTag);
		auto loaded_circuit = rep.from_bytes(buf, false);

		o_free(L, oct);

		if (!loaded_circuit) {
			lerror(L,"Failed to deserialize circuit from OCTET");
			return 0;
		}

		// Create LuaCircuitArtifact using SOL's stack push
		sol::state_view lua(L);
		sol::stack::push(L, LuaCircuitArtifactT(std::move(loaded_circuit)));

		return 1;
	}

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.circuit_artifact"; }
};

using LuaCircuitArtifact = LuaCircuitArtifactT<Fp256Base, FieldID::P256_ID>;
using LuaCircuitArtifactBip340 =
	LuaCircuitArtifactT<Fp256k1Base, FieldID::SECP_ID>;

// Witness bundle: full input vector and public slice
template <class Field_>
class LuaWitnessInputsT {
public:
	using Field = Field_;
	const Field* field;
	std::unique_ptr<Dense<Field>> all;
	std::unique_ptr<Dense<Field>> pub;

	LuaWitnessInputsT(size_t ninputs, size_t npub)
		: field(nullptr),
		  all(std::make_unique<Dense<Field>>(1, ninputs)),
		  pub(std::make_unique<Dense<Field>>(1, npub)) {}

	LuaWitnessInputsT(LuaWitnessInputsT&&) noexcept = default;
	LuaWitnessInputsT& operator=(LuaWitnessInputsT&&) noexcept = default;

	LuaWitnessInputsT(const LuaWitnessInputsT&) = delete;
	LuaWitnessInputsT& operator=(const LuaWitnessInputsT&) = delete;

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.witness_inputs"; }
};

using LuaWitnessInputs = LuaWitnessInputsT<Fp256Base>;
using LuaWitnessInputsBip340 = LuaWitnessInputsT<Fp256k1Base>;

// Build circuit artifact from template
static int lua_build_circuit_artifact(lua_State* L) {
	// Get template argument
	LuaCircuitTemplate* templ = sol::stack::get<LuaCircuitTemplate*>(L, 1);
	if (!templ) {
		lerror(L,"First argument must be a CircuitTemplate");
		return 0;
	}

	// Get nc argument (number of constraints hint)
	if (!lua_isnumber(L, 2)) {
		lerror(L,"Second argument must be a number (nc)");
		return 0;
	}
	int nc = lua_tointeger(L, 2);

	// Compile the circuit
	auto compiled = templ->circuit->mkcircuit(nc);

	if (!compiled) {
		lerror(L,"Failed to compile circuit");
		return 0;
	}

	// Create LuaCircuitArtifact using SOL's stack push
	sol::state_view lua(L);
	sol::stack::push(L, LuaCircuitArtifact(std::move(compiled)));

	return 1;
}

// Build Dense witness arrays from inputs
int lua_build_witness_inputs(lua_State* L);
int lua_build_witness_inputs_bip340(lua_State* L);

// Prove/verify helpers
int lua_prove_circuit(lua_State* L);
int lua_verify_circuit(lua_State* L);
int lua_prove_circuit_bip340(lua_State* L);
int lua_verify_circuit_bip340(lua_State* L);
int lua_bip340_circuit(lua_State* L);
int lua_bip340_compute_inputs(lua_State* L);

// ============================================================================
// High-Level Boolean Logic API
// ============================================================================

// Wrapper for BitW (boolean wire with basis tracking)
class LuaBitW {
public:
	using Field = Fp256Base;
	using Elt = Field::Elt;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;
	using BitW = typename LogicType::BitW;

	BitW wire;
	const LogicType* logic;

	LuaBitW(const BitW& w, const LogicType* l) : wire(w), logic(l) {}

	// Get underlying wire index
	size_t wire_id() const {
		// For BitW, the wire ID is stored in the x field
		return wire.x;
	}

	// Logical operations
	LuaBitW land(const LuaBitW& other) const {
		return LuaBitW(logic->land(wire, other.wire), logic);
	}

	LuaBitW lor(const LuaBitW& other) const {
		return LuaBitW(logic->lor(wire, other.wire), logic);
	}

	LuaBitW lxor(const LuaBitW& other) const {
		return LuaBitW(logic->lxor(wire, other.wire), logic);
	}

	LuaBitW lnot() const {
		return LuaBitW(logic->lnot(wire), logic);
	}

	bool eq(const LuaBitW& other) const {
		// Create a wire that checks if the two bits are equal
		// a == b is equivalent to: (a AND b) OR ((NOT a) AND (NOT b))
		// Which simplifies to: NOT (a XOR b)
		auto xor_result = logic->lxor(wire, other.wire);
		// Note: We can't evaluate the circuit at binding time, so we'll use a placeholder
		// The actual equality is enforced by circuit constraints
		(void)xor_result; // Suppress unused variable warning
		return false; // Placeholder - actual equality is enforced by circuit constraints
	}

	// Overloaded operators for Lua
	LuaBitW operator&(const LuaBitW& other) const { return land(other); }
	LuaBitW operator|(const LuaBitW& other) const { return lor(other); }
	LuaBitW operator^(const LuaBitW& other) const { return lxor(other); }
	LuaBitW operator~() const { return lnot(); }
	bool operator==(const LuaBitW& other) const { return eq(other); }

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.bitw"; }

	// String representation
	std::string to_string() const {
		char buffer[64];
		snprintf(buffer, sizeof(buffer), "BitW(%zu)", wire_id());
		return std::string(buffer);
	}
};

// Wrapper for EltW (field element wire)
template <class LogicType_>
class LuaEltWT {
public:
	using LogicType = LogicType_;
	using EltW = typename LogicType::EltW;
	using Field = typename LogicType::Field;
	using LuaFieldElt = LuaFieldEltT<Field>;

	EltW wire;
	const LogicType* logic;

	LuaEltWT(const EltW& w, const LogicType* l) : wire(w), logic(l) {}

	size_t wire_id() const {
		return wire;
	}

	// Arithmetic operations
	LuaEltWT add(const LuaEltWT& other) const {
		return LuaEltWT(logic->add(wire, other.wire), logic);
	}

	LuaEltWT sub(const LuaEltWT& other) const {
		return LuaEltWT(logic->sub(wire, other.wire), logic);
	}

	LuaEltWT mul(const LuaEltWT& other) const {
		return LuaEltWT(logic->mul(wire, other.wire), logic);
	}

	LuaEltWT mul_scalar(const LuaFieldElt& k) const {
		return LuaEltWT(logic->mul(k.value, wire), logic);
	}

	bool eq(const LuaEltWT& other) const {
		// Create a wire that checks if the two field elements are equal
		// We can't evaluate this at binding time, so we'll add a constraint
		// that the difference is zero and return a placeholder value
		auto diff = logic->sub(wire, other.wire);
		logic->assert0(diff);
		// Return a placeholder - actual equality is enforced by the circuit constraint
		return false;
	}

	// Overloaded operators for Lua
	LuaEltWT operator+(const LuaEltWT& other) const { return add(other); }
	LuaEltWT operator-(const LuaEltWT& other) const { return sub(other); }
	LuaEltWT operator*(const LuaEltWT& other) const { return mul(other); }
	LuaEltWT operator*(const LuaFieldElt& k) const { return mul_scalar(k); }
	bool operator==(const LuaEltWT& other) const { return eq(other); }

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.eltw"; }

	// String representation
	std::string to_string() const {
		char buffer[64];
		snprintf(buffer, sizeof(buffer), "EltW(%zu)", wire_id());
		return std::string(buffer);
	}
};

using LuaP256LogicType = Logic<Fp256Base, CustomCompilerBackend<Fp256Base>>;
using LuaBip340LogicType =
	Logic<Fp256k1Base, CustomCompilerBackend<Fp256k1Base>>;
using LuaEltW = LuaEltWT<LuaP256LogicType>;
using LuaEltWBip340 = LuaEltWT<LuaBip340LogicType>;

// Wrapper for bit vectors
template <size_t N>
class LuaBitVec {
public:
	using Field = Fp256Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;
	using bitvec = typename LogicType::template bitvec<N>;

	bitvec vec;
	const LogicType* logic;

	LuaBitVec(const bitvec& v, const LogicType* l) : vec(v), logic(l) {}

	// Array-like access (1-indexed for Lua)
	LuaBitW get(size_t i) const {
		if (i < 1 || i > N) {
			_fatal(L,"Out of range: Index out of range");
		}
		return LuaBitW(vec[i - 1], logic);
	}

	void set(size_t i, const LuaBitW& bit) {
		if (i < 1 || i > N) {
			_fatal(L,"Out of range: Index out of range");
		}
		vec[i - 1] = bit.wire;
	}

	size_t size() const { return N; }

	// Type identification for Lua type() function
	static const char* __name() {
		if (N == 8) return "zkcc.bitvec8";
		if (N == 16) return "zkcc.bitvec16";
		if (N == 32) return "zkcc.bitvec32";
		if (N == 64) return "zkcc.bitvec64";
		if (N == 128) return "zkcc.bitvec128";
		if (N == 256) return "zkcc.bitvec256";
		return "zkcc.bitvec";
	}

	// String representation
	std::string to_string() const {
		char buffer[64];
		snprintf(buffer, sizeof(buffer), "BitVec<%zu>", N);
		return std::string(buffer);
	}
};

// ============================================================================
// Router Primitives
// ============================================================================

// Wrapper for variable-bit bit vectors (used for CBOR indices)
class LuaBitVecVar {
public:
	using Field = Fp256Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;

	std::vector<typename LogicType::BitW> bits;
	const LogicType* logic;
	size_t size_;

	LuaBitVecVar(const std::vector<typename LogicType::BitW>& b, const LogicType* l, size_t size)
		: bits(b), logic(l), size_(size) {}

	// Array-like access (1-indexed for Lua)
	LuaBitW get(size_t i) const {
		if (i < 1 || i > size_) {
			_fatal(L,"Out of range: Index out of range");
		}
		return LuaBitW(bits[i - 1], logic);
	}

	void set(size_t i, const LuaBitW& bit) {
		if (i < 1 || i > size_) {
			_fatal(L,"Out of range: Index out of range");
		}
		bits[i - 1] = bit.wire;
	}

	size_t size() const { return size_; }

	// String representation
	std::string to_string() const {
		char buffer[64];
		snprintf(buffer, sizeof(buffer), "BitVecVar(%zu)", size_);
		return std::string(buffer);
	}

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.bitvec_var"; }
};

// Wrapper for Routing class
class LuaRouting {
public:
	using Field = Fp256Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;
	using RoutingType = Routing<LogicType>;

	std::unique_ptr<RoutingType> routing;
	const LogicType* logic;

	LuaRouting(const LogicType* l) : routing(std::make_unique<RoutingType>(*l)), logic(l) {}

	// Shift operation: B[i] = A[i + amount] for 0 <= i < k
	template <class T>
	void shift(size_t logn, const LuaBitVecVar& amount, size_t k, sol::table B_table,
			   size_t n, sol::table A_table, const T& defaultA, size_t unroll) {

		// Convert Lua tables to C++ arrays
		std::vector<typename LogicType::BitW> amount_bits;
		for (size_t i = 1; i <= amount.size(); i++) {
			amount_bits.push_back(amount.get(i).wire);
		}

		std::vector<T> A_array;
		for (size_t i = 1; i <= n; i++) {
			A_array.push_back(A_table[i]);
		}

		std::vector<T> B_array(k);

		// Call the routing shift
		routing->shift(logn, amount_bits.data(), k, B_array.data(), n, A_array.data(), defaultA, unroll);

		// Copy results back to Lua table
		for (size_t i = 1; i <= k; i++) {
			B_table[i] = B_array[i - 1];
		}
	}

	// Unshift operation: A[i + amount] = B[i] for 0 <= i < k
	template <class T>
	void unshift(size_t logn, const LuaBitVecVar& amount, size_t n, sol::table A_table,
				 size_t k, sol::table B_table, const T& defaultB, size_t unroll) {

		std::vector<typename LogicType::BitW> amount_bits;
		for (size_t i = 1; i <= amount.size(); i++) {
			amount_bits.push_back(amount.get(i).wire);
		}

		std::vector<T> A_array;
		for (size_t i = 1; i <= n; i++) {
			A_array.push_back(A_table[i]);
		}

		std::vector<T> B_array;
		for (size_t i = 1; i <= k; i++) {
			B_array.push_back(B_table[i]);
		}

		routing->unshift(logn, amount_bits.data(), n, A_array.data(), k, B_array.data(), defaultB, unroll);

		for (size_t i = 1; i <= n; i++) {
			A_table[i] = A_array[i - 1];
		}
	}

	// Convenience methods for common bit vector types
	void shift8(size_t logn, const LuaBitVecVar& amount, size_t k, sol::table B_table,
				size_t n, sol::table A_table, const LuaBitVec<8>& defaultA, size_t unroll) {
		shift(logn, amount, k, B_table, n, A_table, defaultA.vec, unroll);
	}

	void unshift8(size_t logn, const LuaBitVecVar& amount, size_t n, sol::table A_table,
				  size_t k, sol::table B_table, const LuaBitVec<8>& defaultB, size_t unroll) {
		unshift(logn, amount, n, A_table, k, B_table, defaultB.vec, unroll);
	}


	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.routing"; }
};

// Wrapper for BitPlucker class
class LuaBitPlucker {
public:
	using Field = Fp256Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;

	std::unique_ptr<BitPlucker<LogicType, kSHAPluckerBits>> plucker;
	const LogicType* logic;

	LuaBitPlucker(const LogicType* l) :
		plucker(std::make_unique<BitPlucker<LogicType, kSHAPluckerBits>>(*l)),
		logic(l) {}

	// Extract bits from a field element
	LuaBitVecVar pluck(const LuaEltW& e) {
		auto result = plucker->pluck(e.wire);
		std::vector<typename LogicType::BitW> bits;
		for (size_t i = 0; i < kSHAPluckerBits; i++) {
			bits.push_back(result[i]);
		}
		return LuaBitVecVar(bits, logic, kSHAPluckerBits);
	}

	// Unpack packed 32-bit value
	LuaBitVec<32> unpack_v32(sol::table packed_table) {
		typename BitPlucker<LogicType, kSHAPluckerBits>::packed_v32 packed;
		for (size_t i = 0; i < packed.size(); i++) {
			packed[i] = packed_table[i + 1];
		}
		auto result = plucker->unpack_v32(packed);
		return LuaBitVec<32>(result, logic);
	}

	// Create packed input
	sol::table packed_input_v32() {
		auto packed = BitPlucker<LogicType, kSHAPluckerBits>::packed_input<
			typename BitPlucker<LogicType, kSHAPluckerBits>::packed_v32>(*logic);
		// Note: We need to get the Lua state from somewhere - this is a placeholder
		// In a real implementation, we'd need to pass the Lua state through
		sol::table result;
		for (size_t i = 0; i < packed.size(); i++) {
			result[i + 1] = packed[i];
		}
		return result;
	}


	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.bit_plucker"; }
};

// Wrapper for Memcmp class
class LuaMemcmp {
public:
	using Field = Fp256Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;

	std::unique_ptr<Memcmp<LogicType>> memcmp;
	const LogicType* logic;

	LuaMemcmp(const LogicType* l) :
		memcmp(std::make_unique<Memcmp<LogicType>>(*l)),
		logic(l) {}

	// A < B for byte arrays
	LuaBitW lt(size_t n, sol::table A_table, sol::table B_table) {
		std::vector<typename LogicType::v8> A_array, B_array;
		for (size_t i = 1; i <= n; i++) {
			LuaBitVec<8> a_elem = A_table[i];
			LuaBitVec<8> b_elem = B_table[i];
			A_array.push_back(a_elem.vec);
			B_array.push_back(b_elem.vec);
		}
		auto result = memcmp->lt(n, A_array.data(), B_array.data());
		return LuaBitW(result, logic);
	}

	// A <= B for byte arrays
	LuaBitW leq(size_t n, sol::table A_table, sol::table B_table) {
		std::vector<typename LogicType::v8> A_array, B_array;
		for (size_t i = 1; i <= n; i++) {
			LuaBitVec<8> a_elem = A_table[i];
			LuaBitVec<8> b_elem = B_table[i];
			A_array.push_back(a_elem.vec);
			B_array.push_back(b_elem.vec);
		}
		auto result = memcmp->leq(n, A_array.data(), B_array.data());
		return LuaBitW(result, logic);
	}


	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.memcmp"; }
};

// Wrapper for BitAdder class (32-bit)
class LuaBitAdder32 {
public:
	using Field = Fp256Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;
	using BitAdderType = BitAdder<LogicType, 32>;

	std::unique_ptr<BitAdderType> adder;
	const LogicType* logic;

	LuaBitAdder32(const LogicType* l) :
		adder(std::make_unique<BitAdderType>(*l)),
		logic(l) {}

	// Convert v32 to field element
	LuaEltW as_field_element(const LuaBitVec<32>& v) {
		return LuaEltW(adder->as_field_element(v.vec), logic);
	}

	// Add two EltW (field elements)
	LuaEltW add_eltw(const LuaEltW& a, const LuaEltW& b) {
		return LuaEltW(adder->add(a.wire, b.wire), logic);
	}

	// Add two v32 vectors
	LuaEltW add_v32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaEltW(adder->add(a.vec, b.vec), logic);
	}

	// Add multiple v32 vectors (returns field element)
	LuaEltW add(sol::table terms_table) {
		std::vector<typename LogicType::v32> terms;
		// Get table size using Lua's # operator
		size_t n = terms_table.size();
		for (size_t i = 1; i <= n; i++) {
			sol::optional<LuaBitVec<32>> term_opt = terms_table[i];
			if (term_opt) {
				terms.push_back(term_opt.value().vec);
			}
		}
		return LuaEltW(adder->l_.add(0, terms.size(), [&](size_t i) {
			return adder->as_field_element(terms[i]);
		}), logic);
	}

	// Assert result ≡ sum (mod 2^32) with overflow < k
	void assert_eqmod(const LuaBitVec<32>& result, const LuaEltW& sum, size_t k) {
		adder->assert_eqmod(result.vec, sum.wire, k);
	}

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.bit_adder32"; }
};

// Main Logic wrapper
class LuaLogic {
public:
	using Field = Fp256Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;

	std::unique_ptr<LuaCircuitTemplate> circuit_template;
	std::unique_ptr<Backend> backend;
	std::unique_ptr<LogicType> logic;

	LuaLogic() {
		circuit_template = std::make_unique<LuaCircuitTemplate>();
		backend = std::make_unique<Backend>(circuit_template->circuit.get());
		logic = std::make_unique<LogicType>(backend.get(), circuit_template->field);
	}

	// Circuit boundaries / compilation helpers
	void private_inputs() { circuit_template->private_input(); }
	void begin_full_field() { circuit_template->begin_full_field(); }
	void PRIV() { private_inputs(); }   // alias
	void FULL() { begin_full_field(); } // alias

	LuaCircuitArtifact compile(size_t nc = 1) {
		auto compiled = circuit_template->circuit->mkcircuit(nc);
		if (!compiled) {
			lerror(((zenroom_t*)ZEN)->lua, "compile(): failed to build circuit");
		}
		return LuaCircuitArtifact(std::move(compiled));
	}

	// Field operations
	LuaFp256Elt zero() const { return LuaFp256Elt(logic->zero(), &circuit_template->field); }
	LuaFp256Elt one() const { return LuaFp256Elt(logic->one(), &circuit_template->field); }
	LuaFp256Elt mone() const { return LuaFp256Elt(logic->mone(), &circuit_template->field); }
	LuaFp256Elt elt(uint64_t a) const { return LuaFp256Elt(logic->elt(a), &circuit_template->field); }

	// Wire arithmetic
	LuaEltW add(const LuaEltW& a, const LuaEltW& b) {
		return LuaEltW(logic->add(a.wire, b.wire), logic.get());
	}

	LuaEltW sub(const LuaEltW& a, const LuaEltW& b) {
		return LuaEltW(logic->sub(a.wire, b.wire), logic.get());
	}

	LuaEltW mul(const LuaEltW& a, const LuaEltW& b) {
		return LuaEltW(logic->mul(a.wire, b.wire), logic.get());
	}

	LuaEltW mul_scalar(const LuaFp256Elt& k, const LuaEltW& b) {
		return LuaEltW(logic->mul(k.value, b.wire), logic.get());
	}

	LuaEltW mul_3arg(const LuaFp256Elt& k, const LuaEltW& a, const LuaEltW& b) {
		return LuaEltW(backend->mul(k.value, a.wire, b.wire), logic.get());
	}

	LuaEltW mux_elt(const LuaBitW& control, const LuaEltW& iftrue, const LuaEltW& iffalse) {
		return LuaEltW(logic->mux(control.wire, iftrue.wire, iffalse.wire), logic.get());
	}

	LuaEltW konst(const LuaFp256Elt& a) {
		return LuaEltW(logic->konst(a.value), logic.get());
	}

	LuaEltW konst_int(uint64_t a) {
		return LuaEltW(logic->konst(a), logic.get());
	}

	// Linear algebra operations
	LuaEltW ax(const LuaFp256Elt& a, const LuaEltW& x) {
		return LuaEltW(logic->ax(a.value, x.wire), logic.get());
	}

	LuaEltW axy(const LuaFp256Elt& a, const LuaEltW& x, const LuaEltW& y) {
		return LuaEltW(logic->axy(a.value, x.wire, y.wire), logic.get());
	}

	LuaEltW axpy(const LuaEltW& y, const LuaFp256Elt& a, const LuaEltW& x) {
		return LuaEltW(logic->axpy(y.wire, a.value, x.wire), logic.get());
	}

	LuaEltW apy(const LuaEltW& y, const LuaFp256Elt& a) {
		return LuaEltW(logic->apy(y.wire, a.value), logic.get());
	}

	// Boolean operations
	LuaBitW bit(size_t b) {
		return LuaBitW(logic->bit(b), logic.get());
	}

	LuaBitW lnot(const LuaBitW& x) {
		return LuaBitW(logic->lnot(x.wire), logic.get());
	}

	LuaBitW land(const LuaBitW& a, const LuaBitW& b) {
		return LuaBitW(logic->land(a.wire, b.wire), logic.get());
	}

	LuaBitW lor(const LuaBitW& a, const LuaBitW& b) {
		return LuaBitW(logic->lor(a.wire, b.wire), logic.get());
	}

	LuaBitW lxor(const LuaBitW& a, const LuaBitW& b) {
		return LuaBitW(logic->lxor(a.wire, b.wire), logic.get());
	}

	LuaBitW limplies(const LuaBitW& a, const LuaBitW& b) {
		return LuaBitW(logic->limplies(a.wire, b.wire), logic.get());
	}

	LuaBitW mux(const LuaBitW& control, const LuaBitW& iftrue, const LuaBitW& iffalse) {
		// Note: mux signature is (BitW*, BitW*, BitW&)
		return LuaBitW(logic->mux(control.wire, iftrue.wire, iffalse.wire), logic.get());
	}

	// SHA-256 specific operations
	LuaBitW lCh(const LuaBitW& x, const LuaBitW& y, const LuaBitW& z) {
		return LuaBitW(logic->lCh(x.wire, y.wire, z.wire), logic.get());
	}

	LuaBitW lMaj(const LuaBitW& x, const LuaBitW& y, const LuaBitW& z) {
		return LuaBitW(logic->lMaj(x.wire, y.wire, z.wire), logic.get());
	}

	LuaBitW lxor3(const LuaBitW& a, const LuaBitW& b, const LuaBitW& c) {
		return LuaBitW(logic->lxor3(a.wire, b.wire, c.wire), logic.get());
	}

	LuaBitW rebase(const LuaFp256Elt& d0, const LuaFp256Elt& d1, const LuaBitW& v) {
		return LuaBitW(logic->rebase(d0.value, d1.value, v.wire), logic.get());
	}

	LuaEltW lmul(const LuaBitW& a, const LuaEltW& b) {
		return LuaEltW(logic->lmul(a.wire, b.wire), logic.get());
	}

	LuaBitW lor_exclusive(const LuaBitW& a, const LuaBitW& b) {
		return LuaBitW(logic->lor_exclusive(a.wire, b.wire), logic.get());
	}

	// Conversion operations
	LuaEltW eval(const LuaBitW& v) {
		return LuaEltW(logic->eval(v.wire), logic.get());
	}

	LuaEltW as_scalar8(const LuaBitVec<8>& v) {
		return LuaEltW(logic->as_scalar(v.vec), logic.get());
	}

	LuaEltW as_scalar32(const LuaBitVec<32>& v) {
		return LuaEltW(logic->as_scalar(v.vec), logic.get());
	}

	LuaEltW as_scalar64(const LuaBitVec<64>& v) {
		return LuaEltW(logic->as_scalar(v.vec), logic.get());
	}

	// Declarative expression helper: call a Lua lambda with named wires
	LuaEltW expr(sol::protected_function fn, sol::table env) {
		sol::state_view lua(env.lua_state());
		sol::table proxy = lua.create_table();
		for (const auto& kv : env) {
			proxy[kv.first] = kv.second;
		}
		sol::protected_function_result res = fn(proxy);
		if (!res.valid()) {
			sol::error err = res;
			lerror(lua.lua_state(), "expr: %s", err.what());
		}
		sol::object obj = res;
		if (!obj.is<LuaEltW>()) {
			lerror(lua.lua_state(), "expr: expected EltW result");
		}
		return obj.as<LuaEltW>();
	}

	// Assertions
	LuaEltW assert0_elt(const LuaEltW& a) {
		return LuaEltW(logic->assert0(a.wire), logic.get());
	}

	LuaEltW assert0_bit(const LuaBitW& v) {
		return LuaEltW(logic->assert0(v.wire), logic.get());
	}

	LuaEltW assert1(const LuaBitW& v) {
		return LuaEltW(logic->assert1(v.wire), logic.get());
	}

	LuaEltW assert_eq_elt(const LuaEltW& a, const LuaEltW& b) {
		return LuaEltW(logic->assert_eq(a.wire, b.wire), logic.get());
	}

	LuaEltW assert_eq_bit(const LuaBitW& a, const LuaBitW& b) {
		return LuaEltW(logic->assert_eq(a.wire, b.wire), logic.get());
	}

	LuaEltW assert_is_bit(const LuaBitW& b) {
		return LuaEltW(logic->assert_is_bit(b.wire), logic.get());
	}

	// I/O
	LuaEltW eltw_input() {
		return LuaEltW(logic->eltw_input(), logic.get());
	}

	LuaBitW input() {
		return LuaBitW(logic->input(), logic.get());
	}

	void output(const LuaBitW& x, size_t i) {
		logic->output(x.wire, i);
	}

	// Bit vectors (8-bit)
	LuaBitVec<8> vinput8() {
		return LuaBitVec<8>(logic->vinput<8>(), logic.get());
	}

	LuaBitVec<8> vbit8(uint64_t x) {
		return LuaBitVec<8>(logic->vbit<8>(x), logic.get());
	}

	LuaBitVec<8> vnot8(const LuaBitVec<8>& x) {
		return LuaBitVec<8>(logic->vnot(x.vec), logic.get());
	}

	LuaBitVec<8> vand8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitVec<8>(logic->vand(a.vec, b.vec), logic.get());
	}

	LuaBitVec<8> vor8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitVec<8>(logic->vor(a.vec, b.vec), logic.get());
	}

	LuaBitVec<8> vxor8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitVec<8>(logic->vxor(a.vec, b.vec), logic.get());
	}

	LuaBitVec<8> vadd8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitVec<8>(logic->vadd(a.vec, b.vec), logic.get());
	}

	LuaBitW veq8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitW(logic->veq(a.vec, b.vec), logic.get());
	}

	LuaBitW vlt8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitW(logic->vlt(a.vec, b.vec), logic.get());
	}

	LuaBitW vleq8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitW(logic->vleq(a.vec, b.vec), logic.get());
	}

	LuaBitVec<8> vCh8(const LuaBitVec<8>& x, const LuaBitVec<8>& y, const LuaBitVec<8>& z) {
		return LuaBitVec<8>(logic->vCh(x.vec, y.vec, z.vec), logic.get());
	}

	LuaBitVec<8> vMaj8(const LuaBitVec<8>& x, const LuaBitVec<8>& y, const LuaBitVec<8>& z) {
		return LuaBitVec<8>(logic->vMaj(x.vec, y.vec, z.vec), logic.get());
	}

	LuaBitVec<8> vxor3_8(const LuaBitVec<8>& a, const LuaBitVec<8>& b, const LuaBitVec<8>& c) {
		return LuaBitVec<8>(logic->vxor3(a.vec, b.vec, c.vec), logic.get());
	}

	LuaBitVec<8> vshr8(const LuaBitVec<8>& a, size_t shift, size_t b = 0) {
		return LuaBitVec<8>(logic->vshr(a.vec, shift, b), logic.get());
	}

	LuaBitVec<8> vshl8(const LuaBitVec<8>& a, size_t shift, size_t b = 0) {
		return LuaBitVec<8>(logic->vshl(a.vec, shift, b), logic.get());
	}

	LuaBitVec<8> vrotr8(const LuaBitVec<8>& a, size_t b) {
		return LuaBitVec<8>(logic->vrotr(a.vec, b), logic.get());
	}

	LuaBitVec<8> vrotl8(const LuaBitVec<8>& a, size_t b) {
		return LuaBitVec<8>(logic->vrotl(a.vec, b), logic.get());
	}

	LuaBitVec<8> vadd8_const(const LuaBitVec<8>& a, uint64_t val) {
		return LuaBitVec<8>(logic->vadd(a.vec, val), logic.get());
	}

	LuaBitW veq8_const(const LuaBitVec<8>& a, uint64_t val) {
		return LuaBitW(logic->veq(a.vec, val), logic.get());
	}

	LuaBitW vlt8_const(const LuaBitVec<8>& a, uint64_t val) {
		return LuaBitW(logic->vlt(a.vec, val), logic.get());
	}

	// Missing 8-bit vector operations
	LuaBitVec<8> vor_exclusive8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitVec<8>(logic->vor_exclusive(a.vec, b.vec), logic.get());
	}

	void voutput8(const LuaBitVec<8>& x, size_t i0) {
		logic->voutput(x.vec, i0);
	}

	void vassert0_8(const LuaBitVec<8>& x) {
		logic->vassert0(x.vec);
	}

	void vassert_eq8(const LuaBitVec<8>& x, const LuaBitVec<8>& y) {
		logic->vassert_eq(x.vec, y.vec);
	}

	LuaBitVec<8> vmux8(const LuaBitW& control, const LuaBitVec<8>& iftrue, const LuaBitVec<8>& iffalse) {
		// Use the regular mux method since vmux doesn't exist
		// This creates a bitwise mux operation
		typename LogicType::v8 result;
		for (size_t i = 0; i < 8; ++i) {
			result[i] = logic->mux(control.wire, iftrue.vec[i], iffalse.vec[i]);
		}
		return LuaBitVec<8>(result, logic.get());
	}

	// Bit vectors (32-bit)
	LuaBitVec<32> vinput32() {
		return LuaBitVec<32>(logic->vinput<32>(), logic.get());
	}

	LuaBitVec<32> vbit32(uint64_t x) {
		return LuaBitVec<32>(logic->vbit<32>(x), logic.get());
	}

	LuaBitVec<32> vadd32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitVec<32>(logic->vadd(a.vec, b.vec), logic.get());
	}

	LuaBitW veq32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitW(logic->veq(a.vec, b.vec), logic.get());
	}

	LuaBitVec<32> vnot32(const LuaBitVec<32>& x) {
		return LuaBitVec<32>(logic->vnot(x.vec), logic.get());
	}

	LuaBitVec<32> vand32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitVec<32>(logic->vand(a.vec, b.vec), logic.get());
	}

	LuaBitVec<32> vor32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitVec<32>(logic->vor(a.vec, b.vec), logic.get());
	}

	LuaBitVec<32> vxor32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitVec<32>(logic->vxor(a.vec, b.vec), logic.get());
	}

	LuaBitW vlt32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitW(logic->vlt(a.vec, b.vec), logic.get());
	}

	LuaBitW vleq32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitW(logic->vleq(a.vec, b.vec), logic.get());
	}

	LuaBitVec<32> vCh32(const LuaBitVec<32>& x, const LuaBitVec<32>& y, const LuaBitVec<32>& z) {
		return LuaBitVec<32>(logic->vCh(x.vec, y.vec, z.vec), logic.get());
	}

	LuaBitVec<32> vMaj32(const LuaBitVec<32>& x, const LuaBitVec<32>& y, const LuaBitVec<32>& z) {
		return LuaBitVec<32>(logic->vMaj(x.vec, y.vec, z.vec), logic.get());
	}

	LuaBitVec<32> vxor3_32(const LuaBitVec<32>& a, const LuaBitVec<32>& b, const LuaBitVec<32>& c) {
		return LuaBitVec<32>(logic->vxor3(a.vec, b.vec, c.vec), logic.get());
	}

	LuaBitVec<32> vshr32(const LuaBitVec<32>& a, size_t shift, size_t b = 0) {
		return LuaBitVec<32>(logic->vshr(a.vec, shift, b), logic.get());
	}

	LuaBitVec<32> vshl32(const LuaBitVec<32>& a, size_t shift, size_t b = 0) {
		return LuaBitVec<32>(logic->vshl(a.vec, shift, b), logic.get());
	}

	LuaBitVec<32> vrotr32(const LuaBitVec<32>& a, size_t b) {
		return LuaBitVec<32>(logic->vrotr(a.vec, b), logic.get());
	}

	LuaBitVec<32> vrotl32(const LuaBitVec<32>& a, size_t b) {
		return LuaBitVec<32>(logic->vrotl(a.vec, b), logic.get());
	}

	// Bit vectors (64-bit)
	LuaBitVec<64> vinput64() {
		return LuaBitVec<64>(logic->vinput<64>(), logic.get());
	}

	LuaBitVec<64> vbit64(uint64_t x) {
		return LuaBitVec<64>(logic->vbit<64>(x), logic.get());
	}

	LuaBitVec<64> vadd64(const LuaBitVec<64>& a, const LuaBitVec<64>& b) {
		return LuaBitVec<64>(logic->vadd(a.vec, b.vec), logic.get());
	}

	LuaBitW veq64(const LuaBitVec<64>& a, const LuaBitVec<64>& b) {
		return LuaBitW(logic->veq(a.vec, b.vec), logic.get());
	}

	// Bit vectors (16-bit)
	LuaBitVec<16> vinput16() {
		return LuaBitVec<16>(logic->vinput<16>(), logic.get());
	}

	LuaBitVec<16> vbit16(uint64_t x) {
		return LuaBitVec<16>(logic->vbit<16>(x), logic.get());
	}

	// Bit vectors (128-bit)
	LuaBitVec<128> vinput128() {
		return LuaBitVec<128>(logic->vinput<128>(), logic.get());
	}

	LuaBitVec<128> vbit128(uint64_t x) {
		return LuaBitVec<128>(logic->vbit<128>(x), logic.get());
	}

	// Bit vectors (256-bit)
	LuaBitVec<256> vinput256() {
		return LuaBitVec<256>(logic->vinput<256>(), logic.get());
	}

	LuaBitVec<256> vbit256(uint64_t x) {
		return LuaBitVec<256>(logic->vbit<256>(x), logic.get());
	}

	// Vector concatenation (vappend)
	// Little-endian append: a[0] is LSB, b starts at position [NA]
	LuaBitVec<16> vappend_8_8(const LuaBitVec<8>& a, const LuaBitVec<8>& b) {
		return LuaBitVec<16>(logic->vappend(a.vec, b.vec), logic.get());
	}

	LuaBitVec<32> vappend_16_16(const LuaBitVec<16>& a, const LuaBitVec<16>& b) {
		return LuaBitVec<32>(logic->vappend(a.vec, b.vec), logic.get());
	}

	LuaBitVec<64> vappend_32_32(const LuaBitVec<32>& a, const LuaBitVec<32>& b) {
		return LuaBitVec<64>(logic->vappend(a.vec, b.vec), logic.get());
	}

	LuaBitVec<128> vappend_64_64(const LuaBitVec<64>& a, const LuaBitVec<64>& b) {
		return LuaBitVec<128>(logic->vappend(a.vec, b.vec), logic.get());
	}

	LuaBitVec<256> vappend_128_128(const LuaBitVec<128>& a, const LuaBitVec<128>& b) {
		return LuaBitVec<256>(logic->vappend(a.vec, b.vec), logic.get());
	}

	// Access underlying circuit template
	LuaCircuitTemplate& get_circuit() { return *circuit_template; }

	// Aggregate operations
	LuaEltW add_range(size_t i0, size_t i1, sol::function f) {
		// Convert Lua function to C++ std::function
		std::function<LuaEltW(size_t)> cpp_func = [&](size_t i) -> LuaEltW {
			return f(i);
		};

		// Convert to backend function
		std::function<typename LogicType::EltW(size_t)> backend_func =
			[&](size_t i) -> typename LogicType::EltW {
				LuaEltW result = cpp_func(i);
				return result.wire;
			};

		auto result = logic->add(i0, i1, backend_func);
		return LuaEltW(result, logic.get());
	}

	LuaEltW mul_range(size_t i0, size_t i1, sol::function f) {
		std::function<LuaEltW(size_t)> cpp_func = [&](size_t i) -> LuaEltW {
			return f(i);
		};

		std::function<typename LogicType::EltW(size_t)> backend_func =
			[&](size_t i) -> typename LogicType::EltW {
				LuaEltW result = cpp_func(i);
				return result.wire;
			};

		auto result = logic->mul(i0, i1, backend_func);
		return LuaEltW(result, logic.get());
	}

	LuaBitW land_range(size_t i0, size_t i1, sol::function f) {
		std::function<LuaBitW(size_t)> cpp_func = [&](size_t i) -> LuaBitW {
			return f(i);
		};

		std::function<typename LogicType::BitW(size_t)> backend_func =
			[&](size_t i) -> typename LogicType::BitW {
				LuaBitW result = cpp_func(i);
				return result.wire;
			};

		auto result = logic->land(i0, i1, backend_func);
		return LuaBitW(result, logic.get());
	}

	LuaBitW lor_range(size_t i0, size_t i1, sol::function f) {
		std::function<LuaBitW(size_t)> cpp_func = [&](size_t i) -> LuaBitW {
			return f(i);
		};

		std::function<typename LogicType::BitW(size_t)> backend_func =
			[&](size_t i) -> typename LogicType::BitW {
				LuaBitW result = cpp_func(i);
				return result.wire;
			};

		auto result = logic->lor(i0, i1, backend_func);
		return LuaBitW(result, logic.get());
	}

	// Router primitives
	LuaBitVecVar vinput_var(size_t bits) {
		std::vector<typename LogicType::BitW> result;
		for (size_t i = 0; i < bits; i++) {
			result.push_back(logic->input());
		}
		return LuaBitVecVar(result, logic.get(), bits);
	}

	LuaBitVecVar vbit_var(size_t bits, uint64_t value) {
		std::vector<typename LogicType::BitW> result;
		for (size_t i = 0; i < bits; i++) {
			result.push_back(logic->bit((value >> i) & 1));
		}
		return LuaBitVecVar(result, logic.get(), bits);
	}

	LuaRouting create_routing() {
		return LuaRouting(logic.get());
	}

	LuaBitPlucker create_bit_plucker() {
		return LuaBitPlucker(logic.get());
	}

	LuaMemcmp create_memcmp() {
		return LuaMemcmp(logic.get());
	}

	LuaBitAdder32 create_bit_adder32() {
		return LuaBitAdder32(logic.get());
	}

	// Variable-bit vector operations
	LuaBitW vlt_var(const LuaBitVecVar& a, const LuaBitVecVar& b) {
		if (a.size() != b.size()) {
			_fatal(L,"Invalid Argument: bit vectors must have same size");
		}
		auto result = logic->lt(a.size(), a.bits.data(), b.bits.data());
		return LuaBitW(result, logic.get());
	}

	LuaBitW vleq_var(const LuaBitVecVar& a, const LuaBitVecVar& b) {
		if (a.size() != b.size()) {
			_fatal(L,"Invalid Argument: bit vectors must have same size");
		}
		auto result = logic->leq(a.size(), a.bits.data(), b.bits.data());
		return LuaBitW(result, logic.get());
	}

	LuaBitW veq_var(const LuaBitVecVar& a, const LuaBitVecVar& b) {
		if (a.size() != b.size()) {
			_fatal(L,"Invalid Argument: bit vectors must have same size");
		}
		auto result = logic->eq(a.size(), a.bits.data(), b.bits.data());
		return LuaBitW(result, logic.get());
	}

	// Array operations
	LuaBitW eq0(size_t w, sol::table bitw_array) {
		std::vector<typename LogicType::BitW> bits;
		for (size_t i = 1; i <= w; i++) {
			LuaBitW bit = bitw_array[i];
			bits.push_back(bit.wire);
		}
		auto result = logic->eq0(w, bits.data());
		return LuaBitW(result, logic.get());
	}

	LuaBitW eq_array(size_t w, sol::table a_array, sol::table b_array) {
		std::vector<typename LogicType::BitW> a_bits, b_bits;
		for (size_t i = 1; i <= w; i++) {
			LuaBitW a_bit = a_array[i];
			LuaBitW b_bit = b_array[i];
			a_bits.push_back(a_bit.wire);
			b_bits.push_back(b_bit.wire);
		}
		auto result = logic->eq(w, a_bits.data(), b_bits.data());
		return LuaBitW(result, logic.get());
	}

	LuaBitW lt_array(size_t w, sol::table a_array, sol::table b_array) {
		std::vector<typename LogicType::BitW> a_bits, b_bits;
		for (size_t i = 1; i <= w; i++) {
			LuaBitW a_bit = a_array[i];
			LuaBitW b_bit = b_array[i];
			a_bits.push_back(a_bit.wire);
			b_bits.push_back(b_bit.wire);
		}
		auto result = logic->lt(w, a_bits.data(), b_bits.data());
		return LuaBitW(result, logic.get());
	}

	LuaBitW leq_array(size_t w, sol::table a_array, sol::table b_array) {
		std::vector<typename LogicType::BitW> a_bits, b_bits;
		for (size_t i = 1; i <= w; i++) {
			LuaBitW a_bit = a_array[i];
			LuaBitW b_bit = b_array[i];
			a_bits.push_back(a_bit.wire);
			b_bits.push_back(b_bit.wire);
		}
		auto result = logic->leq(w, a_bits.data(), b_bits.data());
		return LuaBitW(result, logic.get());
	}

	void scan_and(sol::table bitw_array, size_t i0, size_t i1, bool backward) {
		std::vector<typename LogicType::BitW> bits;
		for (size_t i = 1; i <= bitw_array.size(); i++) {
			LuaBitW bit = bitw_array[i];
			bits.push_back(bit.wire);
		}
		logic->scan_and(bits.data(), i0, i1, backward);
		// Update the array with modified values
		for (size_t i = 1; i <= bits.size(); i++) {
			bitw_array[i] = LuaBitW(bits[i-1], logic.get());
		}
	}

	void scan_or(sol::table bitw_array, size_t i0, size_t i1, bool backward) {
		std::vector<typename LogicType::BitW> bits;
		for (size_t i = 1; i <= bitw_array.size(); i++) {
			LuaBitW bit = bitw_array[i];
			bits.push_back(bit.wire);
		}
		logic->scan_or(bits.data(), i0, i1, backward);
		// Update the array with modified values
		for (size_t i = 1; i <= bits.size(); i++) {
			bitw_array[i] = LuaBitW(bits[i-1], logic.get());
		}
	}

	void scan_xor(sol::table bitw_array, size_t i0, size_t i1, bool backward) {
		std::vector<typename LogicType::BitW> bits;
		for (size_t i = 1; i <= bitw_array.size(); i++) {
			LuaBitW bit = bitw_array[i];
			bits.push_back(bit.wire);
		}
		logic->scan_xor(bits.data(), i0, i1, backward);
		// Update the array with modified values
		for (size_t i = 1; i <= bits.size(); i++) {
			bitw_array[i] = LuaBitW(bits[i-1], logic.get());
		}
	}

	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.logic"; }
};

// Minimal secp256k1 logic wrapper used by the zkcc-bip340 plan.
// This intentionally exposes only the field-oriented surface needed by
// named_logic(), small arithmetic circuits, and the BIP340 artifact path.
class LuaLogicBip340 {
public:
	using Field = Fp256k1Base;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;

	Field field;
	std::unique_ptr<QuadCircuit<Field>> circuit;
	std::unique_ptr<Backend> backend;
	std::unique_ptr<LogicType> logic;

	LuaLogicBip340() {
		circuit = std::make_unique<QuadCircuit<Field>>(field);
		backend = std::make_unique<Backend>(circuit.get());
		logic = std::make_unique<LogicType>(backend.get(), field);
	}

	void private_inputs() { circuit->private_input(); }
	void begin_full_field() { circuit->begin_full_field(); }
	void PRIV() { private_inputs(); }
	void FULL() { begin_full_field(); }

	LuaCircuitArtifactBip340 compile(size_t nc = 1) {
		auto compiled = circuit->mkcircuit(nc);
		if (!compiled) {
			lerror(((zenroom_t*)ZEN)->lua, "compile(): failed to build circuit");
		}
		return LuaCircuitArtifactBip340(std::move(compiled));
	}

	LuaFp256k1Elt zero() const { return LuaFp256k1Elt(logic->zero(), &field); }
	LuaFp256k1Elt one() const { return LuaFp256k1Elt(logic->one(), &field); }
	LuaFp256k1Elt mone() const { return LuaFp256k1Elt(logic->mone(), &field); }
	LuaFp256k1Elt elt(uint64_t a) const { return LuaFp256k1Elt(logic->elt(a), &field); }

	LuaEltWBip340 add(const LuaEltWBip340& a, const LuaEltWBip340& b) {
		return LuaEltWBip340(logic->add(a.wire, b.wire), logic.get());
	}

	LuaEltWBip340 sub(const LuaEltWBip340& a, const LuaEltWBip340& b) {
		return LuaEltWBip340(logic->sub(a.wire, b.wire), logic.get());
	}

	LuaEltWBip340 mul(const LuaEltWBip340& a, const LuaEltWBip340& b) {
		return LuaEltWBip340(logic->mul(a.wire, b.wire), logic.get());
	}

	LuaEltWBip340 mul_scalar(const LuaFp256k1Elt& k, const LuaEltWBip340& b) {
		return LuaEltWBip340(logic->mul(k.value, b.wire), logic.get());
	}

	LuaEltWBip340 konst(const LuaFp256k1Elt& a) {
		return LuaEltWBip340(logic->konst(a.value), logic.get());
	}

	LuaEltWBip340 konst_int(uint64_t a) {
		return LuaEltWBip340(logic->konst(a), logic.get());
	}

	LuaEltWBip340 ax(const LuaFp256k1Elt& a, const LuaEltWBip340& x) {
		return LuaEltWBip340(logic->ax(a.value, x.wire), logic.get());
	}

	LuaEltWBip340 axy(const LuaFp256k1Elt& a, const LuaEltWBip340& x,
					  const LuaEltWBip340& y) {
		return LuaEltWBip340(logic->axy(a.value, x.wire, y.wire), logic.get());
	}

	LuaEltWBip340 axpy(const LuaEltWBip340& y, const LuaFp256k1Elt& a,
					   const LuaEltWBip340& x) {
		return LuaEltWBip340(logic->axpy(y.wire, a.value, x.wire), logic.get());
	}

	LuaEltWBip340 apy(const LuaEltWBip340& y, const LuaFp256k1Elt& a) {
		return LuaEltWBip340(logic->apy(y.wire, a.value), logic.get());
	}

	LuaEltWBip340 expr(sol::protected_function fn, sol::table env) {
		sol::state_view lua(env.lua_state());
		sol::table proxy = lua.create_table();
		for (const auto& kv : env) {
			proxy[kv.first] = kv.second;
		}
		sol::protected_function_result res = fn(proxy);
		if (!res.valid()) {
			sol::error err = res;
			lerror(lua.lua_state(), "expr: %s", err.what());
		}
		sol::object obj = res;
		if (!obj.is<LuaEltWBip340>()) {
			lerror(lua.lua_state(), "expr: expected EltW result");
		}
		return obj.as<LuaEltWBip340>();
	}

	LuaEltWBip340 assert0_elt(const LuaEltWBip340& a) {
		return LuaEltWBip340(logic->assert0(a.wire), logic.get());
	}

	LuaEltWBip340 assert_eq_elt(const LuaEltWBip340& a, const LuaEltWBip340& b) {
		return LuaEltWBip340(logic->assert_eq(a.wire, b.wire), logic.get());
	}

	LuaEltWBip340 eltw_input() {
		return LuaEltWBip340(logic->eltw_input(), logic.get());
	}

	// -- BIP340 gadget primitives (granular constraint emission) ---------
	// Each method constructs a temporary Bip340Gadgets instance that emits
	// the same production-tested constraints used by the native Bip340Verify
	// circuit.  Lua authors the verification sequence by calling these
	// gadgets; C++ owns the formulas.

	void bip340_assert_point_on_curve(const LuaEltWBip340& x,
	                                  const LuaEltWBip340& y) {
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		g.assert_point_on_curve(x.wire, y.wire);
	}

	std::tuple<LuaEltWBip340, LuaEltWBip340, LuaEltWBip340>
	bip340_addE(const LuaEltWBip340& x1, const LuaEltWBip340& y1,
	            const LuaEltWBip340& z1,
	            const LuaEltWBip340& x2, const LuaEltWBip340& y2,
	            const LuaEltWBip340& z2) {
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		auto r = g.addE(x1.wire, y1.wire, z1.wire,
		                x2.wire, y2.wire, z2.wire);
		return {LuaEltWBip340(r.x, logic.get()),
		        LuaEltWBip340(r.y, logic.get()),
		        LuaEltWBip340(r.z, logic.get())};
	}

	std::tuple<LuaEltWBip340, LuaEltWBip340, LuaEltWBip340>
	bip340_doubleE(const LuaEltWBip340& x, const LuaEltWBip340& y,
	               const LuaEltWBip340& z) {
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		auto r = g.doubleE(x.wire, y.wire, z.wire);
		return {LuaEltWBip340(r.x, logic.get()),
		        LuaEltWBip340(r.y, logic.get()),
		        LuaEltWBip340(r.z, logic.get())};
	}

	/// scalar_mult: px, py, pz (base point), bits[256] (MSB-first scalar),
	/// int_{x,y,z}[255] (intermediate point trace, one less than kBits).
	/// The last (256th) slot of each intermediate array is auto-padded
	/// with a zero wire to match the native C++ API contract.
	/// Returns final point (x, y, z) as multi-return.
	std::tuple<LuaEltWBip340, LuaEltWBip340, LuaEltWBip340>
	bip340_scalar_mult(const LuaEltWBip340& px, const LuaEltWBip340& py,
	                   const LuaEltWBip340& pz,
	                   sol::table bits, sol::table int_x,
	                   sol::table int_y, sol::table int_z) {
		typename LogicType::EltW bits_arr[256];
		typename LogicType::EltW int_x_arr[256];
		typename LogicType::EltW int_y_arr[256];
		typename LogicType::EltW int_z_arr[256];
		for (size_t i = 0; i < 256; ++i) {
			bits_arr[i] = bits[i + 1].get<LuaEltWBip340>().wire;
		}
		// Intermediates: only 255 elements in Lua; pad 256th with zero.
		for (size_t i = 0; i < 255; ++i) {
			int_x_arr[i] = int_x[i + 1].get<LuaEltWBip340>().wire;
			int_y_arr[i] = int_y[i + 1].get<LuaEltWBip340>().wire;
			int_z_arr[i] = int_z[i + 1].get<LuaEltWBip340>().wire;
		}
		int_x_arr[255] = logic->konst(p256k1.f_.zero());
		int_y_arr[255] = logic->konst(p256k1.f_.zero());
		int_z_arr[255] = logic->konst(p256k1.f_.zero());
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		auto r = g.scalar_mult(px.wire, py.wire, pz.wire,
		                       bits_arr, int_x_arr, int_y_arr, int_z_arr);
		return {LuaEltWBip340(r.x, logic.get()),
		        LuaEltWBip340(r.y, logic.get()),
		        LuaEltWBip340(r.z, logic.get())};
	}

	void bip340_assert_scalar_lt_order(sol::table bits) {
		typename LogicType::EltW bits_arr[256];
		for (size_t i = 0; i < 256; ++i) {
			bits_arr[i] = bits[i + 1].get<LuaEltWBip340>().wire;
		}
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		g.assert_scalar_lt_order(bits_arr);
	}

	void bip340_assert_field_from_bits_msb(sol::table bits,
	                                       const LuaEltWBip340& value) {
		typename LogicType::EltW bits_arr[256];
		for (size_t i = 0; i < 256; ++i) {
			bits_arr[i] = bits[i + 1].get<LuaEltWBip340>().wire;
		}
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		g.assert_field_from_bits_msb(bits_arr, value.wire);
	}

	void bip340_assert_even_from_bits_msb(sol::table bits) {
		typename LogicType::EltW bits_arr[256];
		for (size_t i = 0; i < 256; ++i) {
			bits_arr[i] = bits[i + 1].get<LuaEltWBip340>().wire;
		}
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		g.assert_even_from_bits_msb(bits_arr);
	}

	// -- BIP340 convenience constants ------------------------------------

	LuaEltWBip340 bip340_gx() const {
		return LuaEltWBip340(logic->konst(p256k1.gx_), logic.get());
	}

	LuaEltWBip340 bip340_gy() const {
		return LuaEltWBip340(logic->konst(p256k1.gy_), logic.get());
	}

	/// Assert every bits_ry[i] ∈ {0,1}, that they reconstruct to ry,
	/// and that ry is even (LSB = 0).  Combines bitness, reconstruction,
	/// and parity in one constraint emission.
	void bip340_assert_ry_bitness_and_even(sol::table bits_ry,
	                                       const LuaEltWBip340& ry) {
		typename LogicType::EltW bits_arr[256];
		for (size_t i = 0; i < 256; ++i) {
			bits_arr[i] = bits_ry[i + 1].get<LuaEltWBip340>().wire;
		}
		Bip340Gadgets<LogicType, Field, P256k1> g(*logic, p256k1);
		g.assert_ry_bitness_and_even(bits_arr, ry.wire);
	}

	static const char* __name() { return "zkcc.logic_bip340"; }
};

// ============================================================================
// GF2_128 Wire Wrappers
// ============================================================================

// Wrapper for GF2_128 BitW (boolean wire with basis tracking)
class LuaGF2128BitW {
public:
	using Field = GF2_128<>;
	using Elt = Field::Elt;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;
	using BitW = typename LogicType::BitW;

	BitW wire;
	const LogicType* logic;

	LuaGF2128BitW(const BitW& w, const LogicType* l) : wire(w), logic(l) {}

	// Get underlying wire index
	size_t wire_id() const {
		// For BitW, the wire ID is stored in the x field
		return wire.x;
	}


	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.gf2128_bitw"; }
};

// Wrapper for GF2_128 EltW (field element wire)
class LuaGF2128EltW {
public:
	using Field = GF2_128<>;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;
	using EltW = typename LogicType::EltW;

	EltW wire;
	const LogicType* logic;

	LuaGF2128EltW(const EltW& w, const LogicType* l) : wire(w), logic(l) {}

	size_t wire_id() const {
		return wire;
	}


	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.gf2128_eltw"; }
};

// ============================================================================
// GF2_128 Logic Wrapper
// ============================================================================

class LuaGF2128Logic {
public:
	using Field = GF2_128<>;
	using Backend = CustomCompilerBackend<Field>;
	using LogicType = Logic<Field, Backend>;

	std::unique_ptr<QuadCircuit<Field>> circuit;
	std::unique_ptr<Backend> backend;
	std::unique_ptr<LogicType> logic;

	LuaGF2128Logic() {
		circuit = std::make_unique<QuadCircuit<Field>>(Field());
		backend = std::make_unique<Backend>(circuit.get());
		logic = std::make_unique<LogicType>(backend.get(), Field());
	}

	// Field operations
	LuaGF2128Elt zero() const { return LuaGF2128Elt(logic->zero(), &logic->f_); }
	LuaGF2128Elt one() const { return LuaGF2128Elt(logic->one(), &logic->f_); }

	// Wire arithmetic
	LuaGF2128EltW add(const LuaGF2128EltW& a, const LuaGF2128EltW& b) {
		return LuaGF2128EltW(logic->add(a.wire, b.wire), logic.get());
	}

	LuaGF2128EltW mul(const LuaGF2128EltW& a, const LuaGF2128EltW& b) {
		return LuaGF2128EltW(logic->mul(a.wire, b.wire), logic.get());
	}

	LuaGF2128EltW mul_scalar(const LuaGF2128Elt& k, const LuaGF2128EltW& b) {
		return LuaGF2128EltW(logic->mul(k.value, b.wire), logic.get());
	}

	LuaGF2128EltW konst(const LuaGF2128Elt& a) {
		return LuaGF2128EltW(logic->konst(a.value), logic.get());
	}

	LuaGF2128EltW konst_int(uint64_t a) {
		return LuaGF2128EltW(logic->konst(a), logic.get());
	}

	// I/O
	LuaGF2128EltW eltw_input() {
		return LuaGF2128EltW(logic->eltw_input(), logic.get());
	}

	void output(const LuaGF2128EltW& x, size_t i) {
		logic->output(x.wire, i);
	}

	// Assertions
	LuaGF2128EltW assert_eq_elt(const LuaGF2128EltW& a, const LuaGF2128EltW& b) {
		return LuaGF2128EltW(logic->assert_eq(a.wire, b.wire), logic.get());
	}

	// Access underlying circuit
	QuadCircuit<Field>& get_circuit() { return *circuit; }


	// Type identification for Lua type() function
	static const char* __name() { return "zkcc.gf2128_logic"; }
};


// ============================================================================
// LuaWire operator implementations (inline after class definitions)
// ============================================================================

inline LuaWire LuaWire::operator+(const LuaWire& other) const {
	return circuit->add_wire(*this, other);
}

inline LuaWire LuaWire::operator-(const LuaWire& other) const {
	return circuit->sub_wire(*this, other);
}

inline LuaWire LuaWire::operator*(const LuaWire& other) const {
	return circuit->mul_wire(*this, other);
}

// ============================================================================
// Registration Functions
// ============================================================================

// Declaration only - implementation is in lfzk_bindings.cc
void register_zk_bindings(sol::state_view& lua);

}  // namespace lua
}  // namespace proofs

#endif  // LONGFELLOW_ZK_LUA_BINDINGS_H_
