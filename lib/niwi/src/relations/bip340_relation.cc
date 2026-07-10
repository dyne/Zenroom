/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/bip340_relation.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <vector>

#include "algebra/crt.h"
#include "algebra/crt_convolution.h"
#include "algebra/fp_p256k1.h"
#include "algebra/reed_solomon.h"
#include "arrays/dense.h"
#include "circuits/bip340/bip340_gadgets.h"
#include "circuits/bip340/bip340_guard.h"
#include "circuits/bip340/bip340_verify.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/evaluation_backend.h"
#include "circuits/logic/logic.h"
#include "circuits/sha/flatsha256_circuit.h"
#include "ec/p256k1.h"
#include "random/secure_random_engine.h"
#include "random/transcript.h"
#include "sumcheck/prover_layers.h"
#include "util/crypto.h"
#include "util/readbuffer.h"
#include "zk/zk_proof.h"
#include "zk/zk_prover.h"
#include "zk/zk_verifier.h"

namespace {

using Field = proofs::Fp256k1Base;
using Backend = proofs::EvaluationBackend<Field>;
using Logic = proofs::Logic<Field, Backend>;
using Verify = proofs::Bip340Verify<Logic, Field, proofs::P256k1>;
using Elt = Field::Elt;
using EltW = Logic::EltW;
using CompileBackend = proofs::CompilerBackend<Field>;
using CompileLogic = proofs::Logic<Field, CompileBackend>;
using CompileVerify =
    proofs::Bip340Verify<CompileLogic, Field, proofs::P256k1>;
using CompileGadgets =
    proofs::Bip340Gadgets<CompileLogic, Field, proofs::P256k1>;
using CompileBitPlucker = proofs::BitPlucker<CompileLogic, 4>;
using CompileFlatSha =
    proofs::FlatSHA256Circuit<CompileLogic, CompileBitPlucker>;
using Crt = proofs::CRT256<Field>;
using ConvolutionFactory = proofs::CrtConvolutionFactory<Crt, Field>;
using RSFactory = proofs::ReedSolomonFactory<Field, ConvolutionFactory>;

constexpr size_t kEltBytes = 32;
constexpr size_t kPublicElts = 4;
constexpr size_t kInputElts = 2305;
constexpr size_t kFullPublicElts = 3;
constexpr size_t kBip340ChallengeBlocks = 3;
constexpr size_t kBip340ChallengePaddedBytes = kBip340ChallengeBlocks * 64;
constexpr size_t kBits = proofs::P256k1::kBits;
constexpr size_t kLigeroRate = 4;
constexpr size_t kLigeroNreq = 128;

bool decode_field(const uint8_t *bytes, Elt *out) {
    Field::N nat = Field::N::of_bytes(bytes);
    Elt elt = proofs::p256k1_base.to_montgomery(nat);
    Field::N back = proofs::p256k1_base.from_montgomery(elt);
    if (!(nat == back)) return false;
    *out = elt;
    return true;
}

bool decode_dense(const uint8_t *bytes, size_t len, size_t expected_elts,
                  proofs::Dense<Field> *out) {
    if (!bytes || !out || len != expected_elts * kEltBytes) return false;
    for (size_t i = 0; i < expected_elts; ++i) {
        Elt elt;
        if (!decode_field(bytes + i * kEltBytes, &elt)) return false;
        out->v_[i] = elt;
    }
    return true;
}

std::unique_ptr<proofs::Circuit<Field>> build_bip340_circuit(void) {
    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const CompileBackend backend(&q);
    const CompileLogic logic(&backend, proofs::p256k1_base);
    CompileVerify verifier(logic, proofs::p256k1);

    auto rx = logic.eltw_input();
    auto px = logic.eltw_input();
    auto e = logic.eltw_input();

    CompileVerify::Witness witness;
    q.private_input();
    witness.input(logic);
    verifier.assert_verify(rx, px, e, witness);
    return q.mkcircuit(1);
}

void bip340_tag_hash(uint8_t out[32]) {
    static const char tag[] = "BIP0340/challenge";
    proofs::SHA256 sha;
    sha.Update(reinterpret_cast<const uint8_t *>(tag), strlen(tag));
    sha.DigestData(out);
}

std::unique_ptr<proofs::Circuit<Field>> build_bip340_full_challenge_circuit(void) {
    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const CompileBackend backend(&q);
    const CompileLogic logic(&backend, proofs::p256k1_base);
    const CompileFlatSha sha(logic);
    const CompileGadgets gadgets(logic, proofs::p256k1);
    const CompileVerify verifier(logic, proofs::p256k1);

    auto rx = logic.eltw_input();
    auto px = logic.eltw_input();
    q.private_input();

    auto e = logic.eltw_input();
    CompileLogic::v256 digest = logic.template vinput<256>();
    CompileLogic::v8 preimage[kBip340ChallengePaddedBytes];
    uint8_t tag_hash[32];
    bip340_tag_hash(tag_hash);
    for (size_t i = 0; i < 32; ++i) {
        preimage[i] = logic.template vbit<8>(tag_hash[i]);
        preimage[32 + i] = logic.template vbit<8>(tag_hash[i]);
    }
    for (size_t i = 64; i < kBip340ChallengePaddedBytes; ++i) {
        preimage[i] = logic.template vinput<8>();
    }
    CompileFlatSha::BlockWitness sha_blocks[kBip340ChallengeBlocks];
    for (size_t i = 0; i < kBip340ChallengeBlocks; ++i) {
        sha_blocks[i].input(logic);
    }
    CompileVerify::Witness witness;
    witness.input(logic);

    CompileLogic::v256 rx_bits;
    CompileLogic::v256 px_bits;
    for (size_t i = 0; i < kBits; ++i) {
        rx_bits[i] = preimage[64 + 31 - i / 8][i % 8];
        px_bits[i] = preimage[96 + 31 - i / 8][i % 8];
    }
    gadgets.assert_field_from_bits_lsb(rx_bits, rx);
    gadgets.assert_field_from_bits_lsb(px_bits, px);

    CompileLogic::v8 blocks;
    logic.bits(8, blocks.data(), kBip340ChallengeBlocks);
    sha.assert_message_hash(kBip340ChallengeBlocks, blocks, preimage, digest,
                            sha_blocks);
    gadgets.assert_challenge_scalar_from_digest(digest, e);
    verifier.assert_verify(rx, px, e, witness);
    return q.mkcircuit(1);
}

enum class Bip340Profile {
    kPublicChallenge,
    kFullChallenge,
};

bool build_ligero_context(Bip340Profile profile,
                          std::unique_ptr<proofs::Circuit<Field>> *circuit,
                          size_t *block_enc,
                          std::unique_ptr<ConvolutionFactory> *factory,
                          std::unique_ptr<RSFactory> *rsf) {
    if (!circuit || !block_enc || !factory || !rsf) return false;
    *circuit = profile == Bip340Profile::kFullChallenge
        ? build_bip340_full_challenge_circuit()
        : build_bip340_circuit();
    if (!*circuit)
        return false;
    if (profile == Bip340Profile::kPublicChallenge &&
        ((*circuit)->npub_in != kPublicElts ||
         (*circuit)->ninputs != kInputElts))
        return false;
    if (profile == Bip340Profile::kFullChallenge &&
        (*circuit)->npub_in != kFullPublicElts)
        return false;

    *block_enc = (*circuit)->ninputs - (*circuit)->npub_in +
                 (*circuit)->nc + 1;
    if (!proofs::check_crt_block_enc<Crt>(*block_enc).empty())
        return false;

    *factory = std::make_unique<ConvolutionFactory>(proofs::p256k1_base);
    *rsf = std::make_unique<RSFactory>(**factory, proofs::p256k1_base);
    return true;
}

bool evaluate_dense(const proofs::Circuit<Field>& circuit,
                    const proofs::Dense<Field>& witness) {
    proofs::ProverLayers<Field> layers(proofs::p256k1_base);
    proofs::ProverLayers<Field>::inputs inputs;
    auto final = layers.eval_circuit(&inputs, &circuit, witness.clone(),
                                     proofs::p256k1_base);
    return final != nullptr;
}

bool read_field(const uint8_t *inputs, size_t n_elts, size_t *idx, EltW *out) {
    if (*idx >= n_elts) return false;
    Elt elt;
    if (!decode_field(inputs + (*idx * kEltBytes), &elt)) return false;
    *out = EltW{elt};
    ++*idx;
    return true;
}

bool read_field_array(const uint8_t *inputs, size_t n_elts, size_t *idx,
                      EltW out[kBits], size_t count) {
    for (size_t i = 0; i < count; ++i) {
        if (!read_field(inputs, n_elts, idx, &out[i])) return false;
    }
    return true;
}

}  // namespace

extern "C" int niwi_bip340_relation_validate(
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len) {
    if (!public_inputs || !private_inputs) return -1;
    if (pub_len == kFullPublicElts * kEltBytes) {
        try {
            std::unique_ptr<proofs::Circuit<Field>> circuit =
                build_bip340_full_challenge_circuit();
            if (!circuit || priv_len != circuit->ninputs * kEltBytes)
                return -1;
            if (memcmp(public_inputs, private_inputs, pub_len) != 0)
                return -1;

            uint8_t one_bytes[kEltBytes];
            Field::N one_nat = proofs::p256k1_base.from_montgomery(
                proofs::p256k1_base.one());
            one_nat.to_bytes(one_bytes);
            if (memcmp(public_inputs, one_bytes, sizeof(one_bytes)) != 0)
                return -1;

            proofs::Dense<Field> witness(1, circuit->ninputs);
            if (!decode_dense(private_inputs, priv_len, circuit->ninputs,
                              &witness))
                return -1;
            return evaluate_dense(*circuit, witness) ? 0 : -1;
        } catch (...) {
            return -1;
        }
    }

    if (pub_len != kPublicElts * kEltBytes) return -1;
    if (priv_len != kInputElts * kEltBytes) return -1;
    if (memcmp(public_inputs, private_inputs, pub_len) != 0) return -1;

    uint8_t one_bytes[kEltBytes];
    Field::N one_nat = proofs::p256k1_base.from_montgomery(
        proofs::p256k1_base.one());
    one_nat.to_bytes(one_bytes);
    if (memcmp(public_inputs, one_bytes, sizeof(one_bytes)) != 0) return -1;

    Backend backend(proofs::p256k1_base, /*panic_on_assertion_failure=*/false);
    Logic logic(&backend, proofs::p256k1_base);
    Verify verifier(logic, proofs::p256k1);

    size_t idx = 0;
    EltW one;
    EltW rx;
    EltW px;
    EltW e;
    Verify::Witness witness;

    if (!read_field(private_inputs, kInputElts, &idx, &one)) return -1;
    if (one.elt() != proofs::p256k1_base.one()) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &rx)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &px)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &e)) return -1;

    for (size_t i = 0; i < kBits; ++i) {
        if (!read_field(private_inputs, kInputElts, &idx, &witness.bits_s[i]))
            return -1;
        if (i < kBits - 1) {
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_sx[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_sy[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_sz[i]))
                return -1;
        }
    }
    for (size_t i = 0; i < kBits; ++i) {
        if (!read_field(private_inputs, kInputElts, &idx, &witness.bits_e[i]))
            return -1;
        if (i < kBits - 1) {
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_ex[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_ey[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_ez[i]))
                return -1;
        }
    }
    if (!read_field(private_inputs, kInputElts, &idx, &witness.py)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &witness.ry)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &witness.rz_inv)) return -1;
    if (!read_field_array(private_inputs, kInputElts, &idx, witness.bits_ry,
                          kBits)) {
        return -1;
    }
    if (idx != kInputElts) return -1;

    verifier.assert_verify(rx, px, e, witness);
    return backend.assertion_failed() ? -1 : 0;
}

extern "C" int niwi_bip340_ligero_prove(
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len,
    uint8_t **proof_out, size_t *proof_len) {
    if (!public_inputs || !private_inputs || !proof_out || !proof_len)
        return -1;
    *proof_out = nullptr;
    *proof_len = 0;
    Bip340Profile profile = Bip340Profile::kPublicChallenge;
    if (pub_len == kFullPublicElts * kEltBytes) {
        profile = Bip340Profile::kFullChallenge;
    } else if (pub_len != kPublicElts * kEltBytes) {
        return -1;
    }
    if (memcmp(public_inputs, private_inputs, pub_len) != 0)
        return -1;

    try {
        std::unique_ptr<proofs::Circuit<Field>> circuit;
        std::unique_ptr<ConvolutionFactory> factory;
        std::unique_ptr<RSFactory> rsf;
        size_t block_enc = 0;
        if (!build_ligero_context(profile, &circuit, &block_enc, &factory,
                                  &rsf))
            return -1;
        if (priv_len != circuit->ninputs * kEltBytes)
            return -1;

        proofs::Dense<Field> witness(1, circuit->ninputs);
        if (!decode_dense(private_inputs, priv_len, circuit->ninputs,
                          &witness))
            return -1;

        proofs::ZkProof<Field> zk(*circuit, kLigeroRate, kLigeroNreq,
                                  block_enc);
        proofs::ZkProver<Field, RSFactory> prover(*circuit,
                                                  proofs::p256k1_base,
                                                  *rsf);

        uint8_t seed[32] = {0};
        proofs::SecureRandomEngine rng;
        rng.bytes(seed, sizeof(seed));
        proofs::Transcript tp(seed, sizeof(seed), 4);
        prover.commit(zk, witness, tp, rng);
        if (!prover.prove(zk, witness, tp)) return -1;

        std::vector<uint8_t> serialized;
        serialized.insert(serialized.end(), seed, seed + sizeof(seed));
        zk.write(serialized, proofs::p256k1_base);
        if (serialized.empty() || serialized.size() > SIZE_MAX)
            return -1;

        uint8_t *out = static_cast<uint8_t *>(malloc(serialized.size()));
        if (!out) return -1;
        memcpy(out, serialized.data(), serialized.size());
        *proof_out = out;
        *proof_len = serialized.size();
        return 0;
    } catch (...) {
        return -1;
    }
}

extern "C" int niwi_bip340_ligero_verify(
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *proof, size_t proof_len) {
    if (!public_inputs || !proof || proof_len <= 32)
        return -1;
    Bip340Profile profile = Bip340Profile::kPublicChallenge;
    if (pub_len == kFullPublicElts * kEltBytes) {
        profile = Bip340Profile::kFullChallenge;
    } else if (pub_len != kPublicElts * kEltBytes) {
        return -1;
    }

    try {
        std::unique_ptr<proofs::Circuit<Field>> circuit;
        std::unique_ptr<ConvolutionFactory> factory;
        std::unique_ptr<RSFactory> rsf;
        size_t block_enc = 0;
        if (!build_ligero_context(profile, &circuit, &block_enc, &factory,
                                  &rsf))
            return -1;

        proofs::Dense<Field> pub(1, circuit->npub_in);
        if (!decode_dense(public_inputs, pub_len, circuit->npub_in, &pub))
            return -1;

        proofs::ReadBuffer rb(proof + 32, proof_len - 32);
        proofs::ZkProof<Field> zk(*circuit, kLigeroRate, kLigeroNreq,
                                  block_enc);
        if (!zk.read(rb, proofs::p256k1_base) || rb.remaining() != 0)
            return -1;

        proofs::Transcript tv(proof, 32, 4);
        proofs::ZkVerifier<Field, RSFactory> verifier(*circuit, *rsf,
                                                      kLigeroRate,
                                                      kLigeroNreq,
                                                      block_enc,
                                                      proofs::p256k1_base);
        verifier.recv_commitment(zk, tv);
        return verifier.verify(zk, pub, tv) ? 0 : -1;
    } catch (...) {
        return -1;
    }
}
