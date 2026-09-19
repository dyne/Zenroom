/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <memory>
#include <vector>

#include "algebra/crt.h"
#include "algebra/crt_convolution.h"
#include "algebra/reed_solomon.h"
#include "arrays/dense.h"
#include "circuits/bip340/bip340_guard.h"
#include "circuits/bip340/bip340_verify.h"
#include "circuits/bip340/bip340_witness.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/logic.h"
#include "ec/p256k1.h"
#include "random/random.h"
#include "random/transcript.h"
#include "util/crypto.h"
#include "util/readbuffer.h"
#include "zk/zk_proof.h"
#include "zk/zk_prover.h"
#include "zk/zk_verifier.h"

namespace {

using Field = proofs::Fp256k1Base;
using Backend = proofs::CompilerBackend<Field>;
using Logic = proofs::Logic<Field, Backend>;
using Verify = proofs::Bip340Verify<Logic, Field, proofs::P256k1>;
using Crt = proofs::CRT256<Field>;
using ConvolutionFactory = proofs::CrtConvolutionFactory<Crt, Field>;
using RSFactory = proofs::ReedSolomonFactory<Field, ConvolutionFactory>;

constexpr size_t kLigeroRate = 4;
constexpr size_t kLigeroNreq = 128;
constexpr size_t kEltBytes = 32;

class SeededRandomEngine : public proofs::RandomEngine {
 public:
    explicit SeededRandomEngine(const uint8_t *seed, size_t len) {
        proofs::SHA256 sha;
        sha.Update(seed, len);
        sha.DigestData(key_);
        prf_ = std::make_unique<proofs::FSPRF>(key_);
    }

    void bytes(uint8_t *buf, size_t n) override {
        prf_->bytes(buf, n);
    }

 private:
    uint8_t key_[proofs::kPRFKeySize];
    std::unique_ptr<proofs::FSPRF> prf_;
};

int hex_nibble(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

std::vector<uint8_t> hex_to_bytes(const char *hex) {
    size_t len = std::strlen(hex);
    assert((len % 2) == 0);
    std::vector<uint8_t> out(len / 2);
    for (size_t i = 0; i < out.size(); ++i) {
        int hi = hex_nibble(hex[2 * i]);
        int lo = hex_nibble(hex[2 * i + 1]);
        assert(hi >= 0 && lo >= 0);
        out[i] = static_cast<uint8_t>((hi << 4) | lo);
    }
    return out;
}

void append_field(std::vector<uint8_t>& out, const Field::Elt& elt) {
    uint8_t buf[kEltBytes];
    auto nat = proofs::p256k1_base.from_montgomery(elt);
    nat.to_bytes(buf);
    out.insert(out.end(), buf, buf + sizeof(buf));
}

std::unique_ptr<proofs::Circuit<Field>> build_bip340_circuit(void) {
    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, proofs::p256k1_base);
    Verify verify(logic, proofs::p256k1);

    auto rx = logic.eltw_input();
    auto px = logic.eltw_input();
    auto e = logic.eltw_input();

    Verify::Witness witness;
    q.private_input();
    witness.input(logic);
    verify.assert_verify(rx, px, e, witness);
    return q.mkcircuit(1);
}

void build_vector0_inputs(std::vector<uint8_t>& public_inputs,
                          std::vector<uint8_t>& private_inputs) {
    const auto sig = hex_to_bytes(
        "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215"
        "25F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0");
    const auto pk = hex_to_bytes(
        "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9");
    const auto msg = hex_to_bytes(
        "0000000000000000000000000000000000000000000000000000000000000000");

    proofs::Bip340Witness witness(proofs::p256k1);
    assert(witness.compute(sig.data(), pk.data(), msg.data(), msg.size()));

    auto rx_nat = proofs::Bip340Witness::nat_from_be_bytes(sig.data());
    auto px_nat = proofs::Bip340Witness::nat_from_be_bytes(pk.data());
    auto rx = proofs::p256k1_base.to_montgomery(rx_nat);
    auto px = proofs::p256k1_base.to_montgomery(px_nat);

    private_inputs.clear();
    public_inputs.clear();
    private_inputs.reserve(2305 * kEltBytes);
    public_inputs.reserve(4 * kEltBytes);

    append_field(private_inputs, proofs::p256k1_base.one());
    append_field(private_inputs, rx);
    append_field(private_inputs, px);
    append_field(private_inputs, witness.e_);
    public_inputs.assign(private_inputs.begin(), private_inputs.end());

    for (size_t i = 0; i < proofs::Bip340Witness::kBits; ++i) {
        append_field(private_inputs, witness.bits_s_[i]);
        if (i < proofs::Bip340Witness::kBits - 1) {
            append_field(private_inputs, witness.int_sx_[i]);
            append_field(private_inputs, witness.int_sy_[i]);
            append_field(private_inputs, witness.int_sz_[i]);
        }
    }
    for (size_t i = 0; i < proofs::Bip340Witness::kBits; ++i) {
        append_field(private_inputs, witness.bits_e_[i]);
        if (i < proofs::Bip340Witness::kBits - 1) {
            append_field(private_inputs, witness.int_ex_[i]);
            append_field(private_inputs, witness.int_ey_[i]);
            append_field(private_inputs, witness.int_ez_[i]);
        }
    }
    append_field(private_inputs, witness.py_);
    append_field(private_inputs, witness.ry_);
    append_field(private_inputs, witness.rz_inv_);
    for (size_t i = 0; i < proofs::Bip340Witness::kBits; ++i) {
        append_field(private_inputs, witness.bits_ry_[i]);
    }
}

bool decode_dense(const std::vector<uint8_t>& encoded,
                  size_t expected_elts,
                  proofs::Dense<Field> *out) {
    if (!out || encoded.size() != expected_elts * kEltBytes) return false;
    for (size_t i = 0; i < expected_elts; ++i) {
        Field::N nat = Field::N::of_bytes(encoded.data() + i * kEltBytes);
        auto elt = proofs::p256k1_base.to_montgomery(nat);
        if (!(proofs::p256k1_base.from_montgomery(elt) == nat)) return false;
        out->v_[i] = elt;
    }
    return true;
}

void test_bip340_longfellow_ligero_roundtrip(void) {
    auto circuit = build_bip340_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 4);
    assert(circuit->ninputs == 2305);

    std::vector<uint8_t> pub_bytes;
    std::vector<uint8_t> priv_bytes;
    build_vector0_inputs(pub_bytes, priv_bytes);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    assert(decode_dense(priv_bytes, circuit->ninputs, &witness));
    assert(decode_dense(pub_bytes, circuit->npub_in, &pub));

    size_t block_enc =
        circuit->ninputs - circuit->npub_in + circuit->nc + 1;
    assert(proofs::check_crt_block_enc<Crt>(block_enc).empty());

    ConvolutionFactory factory(proofs::p256k1_base);
    RSFactory rsf(factory, proofs::p256k1_base);

    proofs::ZkProof<Field> proof(*circuit, kLigeroRate, kLigeroNreq,
                                 block_enc);
    proofs::ZkProver<Field, RSFactory> prover(*circuit, proofs::p256k1_base,
                                              rsf);

    uint8_t seed[32] = {0};
    proofs::Transcript tp(seed, sizeof(seed), 4);
    SeededRandomEngine rng(seed, sizeof(seed));
    prover.commit(proof, witness, tp, rng);
    assert(prover.prove(proof, witness, tp));

    std::vector<uint8_t> serialized;
    proof.write(serialized, proofs::p256k1_base);
    assert(!serialized.empty());

    proofs::ReadBuffer rb(serialized.data(), serialized.size());
    proofs::ZkProof<Field> parsed(*circuit, kLigeroRate, kLigeroNreq,
                                  block_enc);
    assert(parsed.read(rb, proofs::p256k1_base));
    assert(rb.remaining() == 0);

    proofs::Transcript tv(seed, sizeof(seed), 4);
    proofs::ZkVerifier<Field, RSFactory> verifier(*circuit, rsf,
                                                  kLigeroRate, kLigeroNreq,
                                                  block_enc,
                                                  proofs::p256k1_base);
    verifier.recv_commitment(parsed, tv);
    assert(verifier.verify(parsed, pub, tv));

    serialized.back() ^= 1u;
    proofs::ReadBuffer bad_rb(serialized.data(), serialized.size());
    proofs::ZkProof<Field> bad(*circuit, kLigeroRate, kLigeroNreq,
                               block_enc);
    if (bad.read(bad_rb, proofs::p256k1_base)) {
        proofs::Transcript bad_tv(seed, sizeof(seed), 4);
        verifier.recv_commitment(bad, bad_tv);
        assert(!verifier.verify(bad, pub, bad_tv));
    }

    std::printf("  PASS test_bip340_longfellow_ligero_roundtrip\n");
}

}  // namespace

int main(void) {
    std::printf("lib/blindzap BIP340 Longfellow Ligero tests:\n");
    test_bip340_longfellow_ligero_roundtrip();
    std::printf("All BIP340 Longfellow Ligero tests passed.\n");
    return 0;
}
