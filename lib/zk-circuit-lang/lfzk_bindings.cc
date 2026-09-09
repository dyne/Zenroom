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

#include "lfzk_bindings.h"
#include "witness_bindings.h"
#include "circuits/bip340/bip340_guard.h"
#include "circuits/bip340/bip340_verify.h"
#include "circuits/bip340/bip340_witness.h"
#include "circuits/logic/bit_plucker_encoder.h"
#include "circuits/sha/flatsha256_witness.h"
#include "ec/p256k1.h"
#include "algebra/crt.h"
#include "algebra/crt_convolution.h"

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
	"84087994358540907695740461427818660560182168997182378749313018254450460212"
	"908";

template <class Artifact, class Witness>
static int lua_build_witness_inputs_impl(lua_State* L) {
	sol::state_view lua(L);
	sol::table opts = sol::stack::get<sol::table>(L, 1);

	Artifact* art = opts["circuit"];
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

	Witness witness(ninputs, npub);
	witness.field = &art->field;
	const auto& F = art->field;

	for (auto& v : witness.all->v_) v = F.zero();
	for (auto& v : witness.pub->v_) v = F.zero();
	if (ninputs > 0) {
		witness.all->v_[0] = F.one();
		if (npub > 0) {
			witness.pub->v_[0] = F.one();
		}
	}

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

		auto nat = nat_from_octet<typename Artifact::Field::N>(o);
		witness.all->v_[idx] = F.to_montgomery(nat);
		if (idx < npub) {
			witness.pub->v_[idx] = witness.all->v_[idx];
		}

		o_free(L, o);
		lua_pop(L, 1);
	}

	return sol::stack::push(L, std::move(witness));
}

// Build Dense witness arrays from Lua table of OCTETs
int lua_build_witness_inputs(lua_State* L) {
	return lua_build_witness_inputs_impl<LuaCircuitArtifact, LuaWitnessInputs>(L);
}

int lua_build_witness_inputs_bip340(lua_State* L) {
	return lua_build_witness_inputs_impl<LuaCircuitArtifactBip340,
										 LuaWitnessInputsBip340>(L);
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

	// Keep Longfellow RAII objects inside this scope. Proof failures are
	// expected for invalid witnesses, but lua_error longjmps past C++
	// destructors on this C binding boundary.
	std::vector<uint8_t> buf;
	bool ok = false;
	{
		ZkProof<Field> zk(*art->circuit, kLigeroRate, kLigeroNreq);
		ZkProver<Field, decltype(rsf)> prover(*art->circuit, F, rsf);

		Transcript tp(seed_buf, seed_len, /*version=*/4);
		SeededRandomEngine rng(seed_buf, seed_len);

		prover.commit(zk, *witness->all, tp, rng);
		ok = prover.prove(zk, *witness->all, tp);
		if (ok) {
			zk.write(buf, F);
		}
	}
	if (!ok) {
		lerror(L, "prove_circuit: proof generation failed");
		return 0;
	}

	push_buffer_to_octet(L, reinterpret_cast<char*>(buf.data()), buf.size());
	return 1;
}

int lua_prove_circuit_bip340(lua_State* L) {
	sol::state_view lua(L);
	sol::table opts = sol::stack::get<sol::table>(L, 1);

	LuaCircuitArtifactBip340* art = opts["circuit"];
	LuaWitnessInputsBip340* witness = opts["inputs"];

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

	using Field = Fp256k1Base;
	using Crt = CRT256<Field>;
	using ConvolutionFactory = CrtConvolutionFactory<Crt, Field>;
	using RSFactory = ReedSolomonFactory<Field, ConvolutionFactory>;

	const Field& F = witness->field ? *witness->field : art->field;
	size_t block_enc = art->circuit->ninputs - art->circuit->npub_in +
					   art->circuit->nc + 1;
	auto err = check_crt_block_enc<Crt>(block_enc);
	if (!err.empty()) {
		lerror(L, "prove_circuit: %s", err.c_str());
		return 0;
	}

	ConvolutionFactory factory(F);
	RSFactory rsf(factory, F);

	// Keep Longfellow RAII objects inside this scope. Proof failures are
	// expected for invalid witnesses, but lua_error longjmps past C++
	// destructors on this C binding boundary.
	std::vector<uint8_t> buf;
	bool ok = false;
	{
		ZkProof<Field> zk(*art->circuit, kLigeroRate, kLigeroNreq, block_enc);
		ZkProver<Field, RSFactory> prover(*art->circuit, F, rsf);

		Transcript tp(seed_buf, seed_len, /*version=*/4);
		SeededRandomEngine rng(seed_buf, seed_len);

		prover.commit(zk, *witness->all, tp, rng);
		ok = prover.prove(zk, *witness->all, tp);
		if (ok) {
			zk.write(buf, F);
		}
	}
	if (!ok) {
		lerror(L, "prove_circuit: proof generation failed");
		return 0;
	}

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

int lua_verify_circuit_bip340(lua_State* L) {
	sol::state_view lua(L);
	sol::table opts = sol::stack::get<sol::table>(L, 1);

	LuaCircuitArtifactBip340* art = opts["circuit"];
	LuaWitnessInputsBip340* witness = opts["public_inputs"];

	if (!art || !art->circuit) {
		lerror(L, "verify_circuit: missing circuit");
		return 0;
	}
	if (!witness || !witness->pub) {
		lerror(L, "verify_circuit: missing public inputs");
		return 0;
	}

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

	using Field = Fp256k1Base;
	using Crt = CRT256<Field>;
	using ConvolutionFactory = CrtConvolutionFactory<Crt, Field>;
	using RSFactory = ReedSolomonFactory<Field, ConvolutionFactory>;

	const Field& F = witness->field ? *witness->field : art->field;
	size_t block_enc = art->circuit->ninputs - art->circuit->npub_in +
					   art->circuit->nc + 1;
	auto err = check_crt_block_enc<Crt>(block_enc);
	if (!err.empty()) {
		lerror(L, "verify_circuit: %s", err.c_str());
		return 0;
	}

	ConvolutionFactory factory(F);
	RSFactory rsf(factory, F);

	opts["proof"].push();
	const octet* proof_oct = o_arg(L, -1);
	if (!proof_oct) {
		lua_pop(L, 1);
		lerror(L, "verify_circuit: missing proof");
		return 0;
	}
	ReadBuffer rb(reinterpret_cast<const uint8_t*>(o_val(proof_oct)), o_len(proof_oct));
	ZkProof<Field> zk(*art->circuit, kLigeroRate, kLigeroNreq, block_enc);
	bool read_ok = zk.read(rb, F);
	o_free(L, proof_oct);
	lua_pop(L, 1);
	if (!read_ok) {
		lerror(L, "verify_circuit: failed to parse proof");
		return 0;
	}

	Transcript tv(seed_buf, seed_len, /*version=*/4);
	ZkVerifier<Field, RSFactory> verifier(*art->circuit, rsf, kLigeroRate,
										  kLigeroNreq, block_enc, F);
	verifier.recv_commitment(zk, tv);
	bool ok = verifier.verify(zk, *witness->pub, tv);

	lua_pushboolean(L, ok);
	return 1;
}

int lua_bip340_circuit(lua_State* L) {
	using Field = Fp256k1Base;
	using Backend = CompilerBackend<Field>;
	using LogicCircuit = Logic<Field, Backend>;
	using Verify = Bip340Verify<LogicCircuit, Field, P256k1>;

	QuadCircuit<Field> q(p256k1_base);
	std::unique_ptr<Circuit<Field>> circuit;
	{
		const Backend backend(&q);
		const LogicCircuit logic(&backend, p256k1_base);
		Verify verify(logic, p256k1);

		auto rx = logic.eltw_input();
		auto px = logic.eltw_input();
		auto e = logic.eltw_input();

		typename Verify::Witness witness;
		q.private_input();
		witness.input(logic);
		verify.assert_verify(rx, px, e, witness);
		circuit = q.mkcircuit(1);
	}

	if (!circuit) {
		lerror(L, "bip340_circuit: failed to build circuit");
		return 0;
	}

	sol::stack::push(L, LuaCircuitArtifactBip340(std::move(circuit)));
	return 1;
}

int lua_bip340_compute_inputs(lua_State* L) {
	sol::state_view lua(L);
	LuaCircuitArtifactBip340* art =
		sol::stack::get<LuaCircuitArtifactBip340*>(L, 1);
	if (!art || !art->circuit) {
		lerror(L, "bip340_compute_inputs: missing circuit");
		return 0;
	}

	const octet* sig_oct = o_arg(L, 2);
	const octet* pk_oct = o_arg(L, 3);
	const octet* msg_oct = o_arg(L, 4);
	if (!sig_oct || !pk_oct || !msg_oct) {
		if (sig_oct) o_free(L, sig_oct);
		if (pk_oct) o_free(L, pk_oct);
		if (msg_oct) o_free(L, msg_oct);
		lerror(L, "bip340_compute_inputs: expected circuit, signature, public key, message");
		return 0;
	}
	if (o_len(sig_oct) != 64) {
		o_free(L, sig_oct);
		o_free(L, pk_oct);
		o_free(L, msg_oct);
		lerror(L, "bip340_compute_inputs: signature must be 64 bytes");
		return 0;
	}
	if (o_len(pk_oct) != 32) {
		o_free(L, sig_oct);
		o_free(L, pk_oct);
		o_free(L, msg_oct);
		lerror(L, "bip340_compute_inputs: public key must be 32 bytes");
		return 0;
	}

	Bip340Witness bip340(p256k1);
	bool ok = bip340.compute(reinterpret_cast<const uint8_t*>(o_val(sig_oct)),
							 reinterpret_cast<const uint8_t*>(o_val(pk_oct)),
							 reinterpret_cast<const uint8_t*>(o_val(msg_oct)),
							 o_len(msg_oct));
	if (!ok) {
		o_free(L, sig_oct);
		o_free(L, pk_oct);
		o_free(L, msg_oct);
		lerror(L, "bip340_compute_inputs: witness computation failed");
		return 0;
	}

	auto rx_nat = Bip340Witness::nat_from_be_bytes(
		reinterpret_cast<const uint8_t*>(o_val(sig_oct)));
	auto px_nat = Bip340Witness::nat_from_be_bytes(
		reinterpret_cast<const uint8_t*>(o_val(pk_oct)));
	auto rx = art->field.to_montgomery(rx_nat);
	auto px = art->field.to_montgomery(px_nat);

	o_free(L, sig_oct);
	o_free(L, pk_oct);
	o_free(L, msg_oct);

	LuaWitnessInputsBip340 prover(art->circuit->ninputs, art->npub_input());
	LuaWitnessInputsBip340 verifier(art->circuit->ninputs, art->npub_input());
	prover.field = &art->field;
	verifier.field = &art->field;

	for (auto& v : prover.all->v_) v = art->field.zero();
	for (auto& v : prover.pub->v_) v = art->field.zero();
	for (auto& v : verifier.all->v_) v = art->field.zero();
	for (auto& v : verifier.pub->v_) v = art->field.zero();

	prover.all->v_[0] = art->field.one();
	prover.pub->v_[0] = art->field.one();
	verifier.all->v_[0] = art->field.one();
	verifier.pub->v_[0] = art->field.one();

	prover.all->v_[1] = rx;
	prover.all->v_[2] = px;
	prover.all->v_[3] = bip340.e_;
	prover.pub->v_[1] = rx;
	prover.pub->v_[2] = px;
	prover.pub->v_[3] = bip340.e_;
	verifier.all->v_[1] = rx;
	verifier.all->v_[2] = px;
	verifier.all->v_[3] = bip340.e_;
	verifier.pub->v_[1] = rx;
	verifier.pub->v_[2] = px;
	verifier.pub->v_[3] = bip340.e_;

	size_t idx = art->circuit->npub_in;
	auto push_private = [&](const auto& elt) {
		check(idx < prover.all->v_.size(), "bip340 witness index in range");
		prover.all->v_[idx++] = elt;
	};

	for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
		push_private(bip340.bits_s_[i]);
		if (i < Bip340Witness::kBits - 1) {
			push_private(bip340.int_sx_[i]);
			push_private(bip340.int_sy_[i]);
			push_private(bip340.int_sz_[i]);
		}
	}
	for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
		push_private(bip340.bits_e_[i]);
		if (i < Bip340Witness::kBits - 1) {
			push_private(bip340.int_ex_[i]);
			push_private(bip340.int_ey_[i]);
			push_private(bip340.int_ez_[i]);
		}
	}
	push_private(bip340.py_);
	push_private(bip340.ry_);
	push_private(bip340.rz_inv_);
	for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
		push_private(bip340.bits_ry_[i]);
	}

	if (idx != art->circuit->ninputs) {
		lerror(L, "bip340_compute_inputs: witness size mismatch");
		return 0;
	}

	sol::stack::push(L, std::move(prover));
	sol::stack::push(L, std::move(verifier));
	return 2;
}

namespace {

static constexpr size_t kBip340ChallengeBlocks = 3;
static constexpr size_t kBip340ChallengePreimageSize = 160;
static constexpr size_t kBip340ChallengePaddedBytes =
	kBip340ChallengeBlocks * 64;

void append_bip340_field(std::vector<Fp256k1Base::Elt>& out,
						 const Fp256k1Base::Elt& elt) {
	out.push_back(elt);
}

void append_bip340_bit(std::vector<Fp256k1Base::Elt>& out, uint8_t bit) {
	out.push_back(p256k1_base.of_scalar(bit & 1u));
}

void append_bip340_u32_bits(std::vector<Fp256k1Base::Elt>& out,
							uint32_t word) {
	for (size_t i = 0; i < 32; ++i) {
		append_bip340_bit(out, static_cast<uint8_t>((word >> i) & 1u));
	}
}

void append_bip340_byte_bits(std::vector<Fp256k1Base::Elt>& out,
							 uint8_t byte) {
	for (size_t i = 0; i < 8; ++i) {
		append_bip340_bit(out, static_cast<uint8_t>((byte >> i) & 1u));
	}
}

void append_bip340_digest_target(std::vector<Fp256k1Base::Elt>& out,
								 const uint8_t digest[32]) {
	for (size_t j = 0; j < 8; ++j) {
		append_bip340_u32_bits(out, SHA256_ru32be(digest + 4 * (7 - j)));
	}
}

void append_bip340_sha_block(
	std::vector<Fp256k1Base::Elt>& out,
	const FlatSHA256Witness::BlockWitness& bw) {
	BitPluckerEncoder<Fp256k1Base, 4> encoder(p256k1_base);
	for (size_t k = 0; k < 48; ++k) {
		for (const auto& elt : encoder.mkpacked_v32(bw.outw[k])) {
			append_bip340_field(out, elt);
		}
	}
	for (size_t k = 0; k < 64; ++k) {
		for (const auto& elt : encoder.mkpacked_v32(bw.oute[k])) {
			append_bip340_field(out, elt);
		}
		for (const auto& elt : encoder.mkpacked_v32(bw.outa[k])) {
			append_bip340_field(out, elt);
		}
	}
	for (size_t k = 0; k < 8; ++k) {
		for (const auto& elt : encoder.mkpacked_v32(bw.h1[k])) {
			append_bip340_field(out, elt);
		}
	}
}

void append_bip340_verify_witness(std::vector<Fp256k1Base::Elt>& out,
								  const Bip340Witness& witness) {
	for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
		append_bip340_field(out, witness.bits_s_[i]);
		if (i < Bip340Witness::kBits - 1) {
			append_bip340_field(out, witness.int_sx_[i]);
			append_bip340_field(out, witness.int_sy_[i]);
			append_bip340_field(out, witness.int_sz_[i]);
		}
	}
	for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
		append_bip340_field(out, witness.bits_e_[i]);
		if (i < Bip340Witness::kBits - 1) {
			append_bip340_field(out, witness.int_ex_[i]);
			append_bip340_field(out, witness.int_ey_[i]);
			append_bip340_field(out, witness.int_ez_[i]);
		}
	}
	append_bip340_field(out, witness.py_);
	append_bip340_field(out, witness.ry_);
	append_bip340_field(out, witness.rz_inv_);
	for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
		append_bip340_field(out, witness.bits_ry_[i]);
	}
}

void bip340_challenge_preimage(const uint8_t sig[64], const uint8_t pk[32],
							   const uint8_t msg[32],
							   uint8_t out[kBip340ChallengePreimageSize]) {
	static const char tag[] = "BIP0340/challenge";
	uint8_t tag_hash[32];
	SHA256 tag_sha;
	tag_sha.Update(reinterpret_cast<const uint8_t*>(tag), strlen(tag));
	tag_sha.DigestData(tag_hash);

	size_t off = 0;
	memcpy(out + off, tag_hash, 32); off += 32;
	memcpy(out + off, tag_hash, 32); off += 32;
	memcpy(out + off, sig, 32); off += 32;
	memcpy(out + off, pk, 32); off += 32;
	memcpy(out + off, msg, 32);
}

void bip340_challenge_digest(const uint8_t sig[64], const uint8_t pk[32],
							 const uint8_t msg[32], uint8_t out[32]) {
	uint8_t preimage[kBip340ChallengePreimageSize];
	bip340_challenge_preimage(sig, pk, msg, preimage);
	SHA256 sha;
	sha.Update(preimage, sizeof(preimage));
	sha.DigestData(out);
}

}  // namespace

int lua_bip340_compute_full_challenge_inputs(lua_State* L) {
	const octet* sig_oct = o_arg(L, 1);
	const octet* pk_oct = o_arg(L, 2);
	const octet* msg_oct = o_arg(L, 3);
	if (!sig_oct || !pk_oct || !msg_oct) {
		if (sig_oct) o_free(L, sig_oct);
		if (pk_oct) o_free(L, pk_oct);
		if (msg_oct) o_free(L, msg_oct);
		lerror(L, "bip340_compute_full_challenge_inputs: expected signature, public key, 32-byte message");
		return 0;
	}
	if (o_len(sig_oct) != 64 || o_len(pk_oct) != 32 || o_len(msg_oct) != 32) {
		o_free(L, sig_oct);
		o_free(L, pk_oct);
		o_free(L, msg_oct);
		lerror(L, "bip340_compute_full_challenge_inputs: expected 64-byte signature, 32-byte public key, 32-byte message");
		return 0;
	}

	const auto* sig = reinterpret_cast<const uint8_t*>(o_val(sig_oct));
	const auto* pk = reinterpret_cast<const uint8_t*>(o_val(pk_oct));
	const auto* msg = reinterpret_cast<const uint8_t*>(o_val(msg_oct));

	Bip340Witness bip340(p256k1);
	if (!bip340.compute(sig, pk, msg, o_len(msg_oct))) {
		o_free(L, sig_oct);
		o_free(L, pk_oct);
		o_free(L, msg_oct);
		lerror(L, "bip340_compute_full_challenge_inputs: witness computation failed");
		return 0;
	}

	auto rx = p256k1_base.to_montgomery(Bip340Witness::nat_from_be_bytes(sig));
	auto px = p256k1_base.to_montgomery(Bip340Witness::nat_from_be_bytes(pk));

	std::vector<Fp256k1Base::Elt> values;
	values.reserve(8192);
	append_bip340_field(values, p256k1_base.one());
	append_bip340_field(values, rx);
	append_bip340_field(values, px);
	const size_t npub = values.size();
	append_bip340_field(values, bip340.e_);

	uint8_t digest[32];
	uint8_t preimage[kBip340ChallengePreimageSize];
	bip340_challenge_preimage(sig, pk, msg, preimage);
	bip340_challenge_digest(sig, pk, msg, digest);
	append_bip340_digest_target(values, digest);

	uint8_t nblocks = 0;
	uint8_t padded[kBip340ChallengePaddedBytes];
	FlatSHA256Witness::BlockWitness blocks[kBip340ChallengeBlocks];
	FlatSHA256Witness::transform_and_witness_message(
		sizeof(preimage), preimage, kBip340ChallengeBlocks, nblocks, padded,
		blocks);
	if (nblocks != kBip340ChallengeBlocks) {
		o_free(L, sig_oct);
		o_free(L, pk_oct);
		o_free(L, msg_oct);
		lerror(L, "bip340_compute_full_challenge_inputs: SHA witness block count mismatch");
		return 0;
	}
	for (size_t i = 64; i < sizeof(padded); ++i) {
		append_bip340_byte_bits(values, padded[i]);
	}
	for (const auto& block : blocks) {
		append_bip340_sha_block(values, block);
	}
	append_bip340_verify_witness(values, bip340);

	o_free(L, sig_oct);
	o_free(L, pk_oct);
	o_free(L, msg_oct);

	LuaWitnessInputsBip340 prover(values.size(), npub);
	LuaWitnessInputsBip340 verifier(values.size(), npub);
	prover.field = &p256k1_base;
	verifier.field = &p256k1_base;
	for (size_t i = 0; i < values.size(); ++i) {
		prover.all->v_[i] = values[i];
		verifier.all->v_[i] = i < npub ? values[i] : p256k1_base.zero();
	}
	for (size_t i = 0; i < npub; ++i) {
		prover.pub->v_[i] = values[i];
		verifier.pub->v_[i] = values[i];
	}

	sol::stack::push(L, std::move(prover));
	sol::stack::push(L, std::move(verifier));
	return 2;
}

void register_zk_bindings(sol::state_view& lua) {
	// ========================================================================
	// Wire Wrapper (for operator overloading)
	// ========================================================================

	lua_State* L = lua.lua_state();

	auto wire = lua.new_usertype<LuaWire>("Wire",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaWire::__name),

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

		// Type identification field
		"__name", sol::property(&LuaCircuitArtifact::__name),

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

		// Type identification field
		"__name", sol::property(&LuaWitnessInputs::__name),

		"octet", &LuaWitnessInputs::lua_octet,
		"public_octet", &LuaWitnessInputs::lua_public_octet,
		"ninputs", [](LuaWitnessInputs& w) { return w.all ? w.all->n1_ : 0; },
		"npub", [](LuaWitnessInputs& w) { return w.pub ? w.pub->n1_ : 0; }
	);

	auto circuit_artifact_bip340 =
		lua.new_usertype<LuaCircuitArtifactBip340>("CircuitArtifactBip340",
			sol::no_constructor,

			"__name", sol::property(&LuaCircuitArtifactBip340::__name),
			"octet", &LuaCircuitArtifactBip340::lua_octet,
			"circuit_id", &LuaCircuitArtifactBip340::lua_circuit_id,
			"set_input", &LuaCircuitArtifactBip340::lua_set_input,
			"get_input", &LuaCircuitArtifactBip340::lua_get_input,
			"ninput", sol::property(&LuaCircuitArtifactBip340::ninput),
			"npub_input", sol::property(&LuaCircuitArtifactBip340::npub_input),
			"depth", sol::property(&LuaCircuitArtifactBip340::depth),
			"nwires", sol::property(&LuaCircuitArtifactBip340::nwires),
			"nquad_terms", sol::property(&LuaCircuitArtifactBip340::nquad_terms)
		);

	auto witness_inputs_bip340 =
		lua.new_usertype<LuaWitnessInputsBip340>("WitnessInputsBip340",
			sol::constructors<LuaWitnessInputsBip340(size_t, size_t)>(),

			"__name", sol::property(&LuaWitnessInputsBip340::__name),
			"octet", &LuaWitnessInputsBip340::lua_octet,
			"public_octet", &LuaWitnessInputsBip340::lua_public_octet,
			"ninputs", [](LuaWitnessInputsBip340& w) { return w.all ? w.all->n1_ : 0; },
			"npub", [](LuaWitnessInputsBip340& w) { return w.pub ? w.pub->n1_ : 0; }
		);

	// ========================================================================
	// High-Level Boolean Logic
	// ========================================================================

	// Register LuaBitW with operators
	auto bitw = lua.new_usertype<LuaBitW>("BitW",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaBitW::__name),

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

		// Type identification field
		"__name", sol::property(&LuaEltW::__name),

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

	auto eltw_bip340 = lua.new_usertype<LuaEltWBip340>("EltWBip340",
		sol::constructors<>(),

		"__name", sol::property(&LuaEltWBip340::__name),
		sol::meta_function::addition, &LuaEltWBip340::add,
		sol::meta_function::subtraction, &LuaEltWBip340::sub,
		sol::meta_function::multiplication, sol::overload(
			static_cast<LuaEltWBip340(LuaEltWBip340::*)(const LuaEltWBip340&) const>(
				&LuaEltWBip340::mul),
			static_cast<LuaEltWBip340(LuaEltWBip340::*)(const LuaFp256k1Elt&) const>(
				&LuaEltWBip340::mul_scalar)
		),
		sol::meta_function::equal_to, &LuaEltWBip340::eq,
		sol::meta_function::to_string, &LuaEltWBip340::to_string,

		"add", &LuaEltWBip340::add,
		"sub", &LuaEltWBip340::sub,
		"mul", &LuaEltWBip340::mul,
		"mul_scalar", &LuaEltWBip340::mul_scalar,
		"eq", &LuaEltWBip340::eq,
		"wire_id", &LuaEltWBip340::wire_id,
		"to_string", &LuaEltWBip340::to_string
	);

	// BitVec8
	auto bitvec8 = lua.new_usertype<LuaBitVec<8>>("BitVec8",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaBitVec<8>::__name),

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

		// Type identification field
		"__name", sol::property(&LuaBitVec<32>::__name),

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

		// Type identification field
		"__name", sol::property(&LuaBitVec<64>::__name),

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

		// Type identification field
		"__name", sol::property(&LuaBitVec<16>::__name),

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

		// Type identification field
		"__name", sol::property(&LuaBitVec<128>::__name),

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

		// Type identification field
		"__name", sol::property(&LuaBitVec<256>::__name),

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

		// Type identification field
		"__name", sol::property(&LuaLogic::__name),

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

		// Vector concatenation (vappend)
		"vappend_8_8", &LuaLogic::vappend_8_8,
		"vappend_16_16", &LuaLogic::vappend_16_16,
		"vappend_32_32", &LuaLogic::vappend_32_32,
		"vappend_64_64", &LuaLogic::vappend_64_64,
		"vappend_128_128", &LuaLogic::vappend_128_128,

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
		"create_bit_adder32", &LuaLogic::create_bit_adder32,
		"vlt_var", &LuaLogic::vlt_var,
		"vleq_var", &LuaLogic::vleq_var,
		"veq_var", &LuaLogic::veq_var
	);

	auto logic_bip340 = lua.new_usertype<LuaLogicBip340>("LogicBip340",
		sol::constructors<LuaLogicBip340()>(),

		"__name", sol::property(&LuaLogicBip340::__name),
		"zero", &LuaLogicBip340::zero,
		"one", &LuaLogicBip340::one,
		"mone", &LuaLogicBip340::mone,
		"elt", &LuaLogicBip340::elt,
		"add", &LuaLogicBip340::add,
		"sub", &LuaLogicBip340::sub,
		"mul", sol::overload(
			&LuaLogicBip340::mul,
			&LuaLogicBip340::mul_scalar
		),
		"mul_scalar", &LuaLogicBip340::mul_scalar,
		"konst", sol::overload(
			&LuaLogicBip340::konst,
			&LuaLogicBip340::konst_int
		),
		"ax", &LuaLogicBip340::ax,
		"axy", &LuaLogicBip340::axy,
		"axpy", &LuaLogicBip340::axpy,
		"apy", &LuaLogicBip340::apy,
		"expr", &LuaLogicBip340::expr,
		"assert0", &LuaLogicBip340::assert0_elt,
		"assert_eq", &LuaLogicBip340::assert_eq_elt,
		"eltw_input", &LuaLogicBip340::eltw_input,
		"private_inputs", &LuaLogicBip340::private_inputs,
		"begin_full_field", &LuaLogicBip340::begin_full_field,
		"PRIV", &LuaLogicBip340::PRIV,
		"FULL", &LuaLogicBip340::FULL,
		"compile", &LuaLogicBip340::compile,

		// BIP340 granular gadget primitives
		"bip340_assert_point_on_curve",
			&LuaLogicBip340::bip340_assert_point_on_curve,
		"bip340_addE", &LuaLogicBip340::bip340_addE,
		"bip340_doubleE", &LuaLogicBip340::bip340_doubleE,
		"bip340_scalar_mult", &LuaLogicBip340::bip340_scalar_mult,
		"bip340_assert_scalar_lt_order",
			&LuaLogicBip340::bip340_assert_scalar_lt_order,
		"bip340_assert_field_from_bits_msb",
			&LuaLogicBip340::bip340_assert_field_from_bits_msb,
		"bip340_assert_even_from_bits_msb",
			&LuaLogicBip340::bip340_assert_even_from_bits_msb,
		"bip340_gx", &LuaLogicBip340::bip340_gx,
		"bip340_gy", &LuaLogicBip340::bip340_gy,
		"bip340_assert_ry_bitness_and_even",
			&LuaLogicBip340::bip340_assert_ry_bitness_and_even
	);

	// ========================================================================
	// Router Primitives
	// ========================================================================

	// Variable-bit bit vector
	auto bitvec_var = lua.new_usertype<LuaBitVecVar>("BitVecVar",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaBitVecVar::__name),

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

		// Type identification field
		"__name", sol::property(&LuaRouting::__name),

		"shift8", &LuaRouting::shift8,
		"unshift8", &LuaRouting::unshift8
	);

	// BitPlucker class
	auto bit_plucker = lua.new_usertype<LuaBitPlucker>("BitPlucker",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaBitPlucker::__name),

		"pluck", &LuaBitPlucker::pluck,
		"unpack_v32", &LuaBitPlucker::unpack_v32,
		"packed_input_v32", &LuaBitPlucker::packed_input_v32
	);

	// Memcmp class
	auto memcmp = lua.new_usertype<LuaMemcmp>("Memcmp",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaMemcmp::__name),

		"lt", &LuaMemcmp::lt,
		"leq", &LuaMemcmp::leq
	);

	auto bit_adder32 = lua.new_usertype<LuaBitAdder32>("BitAdder32",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaBitAdder32::__name),

		"as_field_element", &LuaBitAdder32::as_field_element,
		"add", &LuaBitAdder32::add,
		"add_v32", &LuaBitAdder32::add_v32,
		"add_eltw", &LuaBitAdder32::add_eltw,
		"assert_eqmod", &LuaBitAdder32::assert_eqmod
	);

	// GF2_128 Wire Wrappers
	auto gf2128_bitw = lua.new_usertype<LuaGF2128BitW>("GF2128BitW",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaGF2128BitW::__name),
		"wire_id", &LuaGF2128BitW::wire_id
	);

	auto gf2128_eltw = lua.new_usertype<LuaGF2128EltW>("GF2128EltW",
		sol::constructors<>(),

		// Type identification field
		"__name", sol::property(&LuaGF2128EltW::__name),
		"wire_id", &LuaGF2128EltW::wire_id
	);

	// GF2_128 Logic (high-level API for GF2_128)
	auto gf2128_logic = lua.new_usertype<LuaGF2128Logic>("GF2128Logic",
		sol::constructors<LuaGF2128Logic()>(),

		// Type identification field
		"__name", sol::property(&LuaGF2128Logic::__name),

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
	zkcore_table.set_function("new_circuit_template",
		sol::factories([]() { return std::make_unique<proofs::lua::LuaCircuitTemplate>(); }));

	// Factory: build circuit artifact from template
	zkcore_table["build_circuit_artifact"] = &proofs::lua::lua_build_circuit_artifact;

	// Factory: load circuit artifact from OCTET
	zkcore_table["load_circuit_artifact"] = &proofs::lua::LuaCircuitArtifact::lua_load_from_octet;
	zkcore_table["load_circuit_artifact_bip340"] =
		&proofs::lua::LuaCircuitArtifactBip340::lua_load_from_octet;

	zkcore_table.set_function("create_logic_p256",
		sol::factories([]() { return std::make_unique<proofs::lua::LuaLogic>(); }));
	zkcore_table.set_function("create_logic_bip340",
		sol::factories([]() { return std::make_unique<proofs::lua::LuaLogicBip340>(); }));
	zkcore_table["create_logic"] = zkcore_table["create_logic_p256"];
	zkcore_table["logic"] = zkcore_table["create_logic"];

	zkcore_table.set_function("create_gf2128_logic",
		sol::factories([]() { return std::make_unique<proofs::lua::LuaGF2128Logic>(); }));

	zkcore_table["build_witness_inputs"] = &proofs::lua::lua_build_witness_inputs;
	zkcore_table["build_witness_inputs_bip340"] =
		&proofs::lua::lua_build_witness_inputs_bip340;
	zkcore_table["prove_circuit"] = &proofs::lua::lua_prove_circuit;
	zkcore_table["prove_circuit_bip340"] = &proofs::lua::lua_prove_circuit_bip340;
	zkcore_table["verify_circuit"] = &proofs::lua::lua_verify_circuit;
	zkcore_table["verify_circuit_bip340"] = &proofs::lua::lua_verify_circuit_bip340;
	zkcore_table["bip340_circuit_native"] = &proofs::lua::lua_bip340_circuit;
	zkcore_table["bip340_compute_inputs_native"] =
		&proofs::lua::lua_bip340_compute_inputs;
	zkcore_table["bip340_compute_full_challenge_inputs_native"] =
		&proofs::lua::lua_bip340_compute_full_challenge_inputs;

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
	zkcore_table["LONGFELLOW_ZK_VERSION"] = "1.0.0";

	// Return the table
	return sol::stack::push(L, zkcore_table);
}

}
