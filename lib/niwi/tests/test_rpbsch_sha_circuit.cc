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

#include "arrays/dense.h"
#include "circuits/bip340/bip340_gadgets.h"
#include "circuits/bip340/bip340_verify.h"
#include "circuits/bip340/bip340_witness.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/logic/bit_plucker_encoder.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/logic.h"
#include "circuits/sha/flatsha256_circuit.h"
#include "circuits/sha/flatsha256_witness.h"
#include "ec/p256k1.h"
#include "relations/rpbsch_relation_internal.h"
#include "sumcheck/prover_layers.h"
#include "util/crypto.h"

namespace {

using Field = proofs::Fp256k1Base;
using Backend = proofs::CompilerBackend<Field>;
using Logic = proofs::Logic<Field, Backend>;
using BitPlucker = proofs::BitPlucker<Logic, 4>;
using FlatSha = proofs::FlatSHA256Circuit<Logic, BitPlucker>;
using ShaBlockWitness = proofs::FlatSHA256Witness::BlockWitness;
using Bip340Gadgets = proofs::Bip340Gadgets<Logic, Field, proofs::P256k1>;
using Bip340Verify = proofs::Bip340Verify<Logic, Field, proofs::P256k1>;

constexpr size_t kMaxBlocks = 3;
constexpr size_t kPaddedBytes = kMaxBlocks * 64;
constexpr size_t kTupleMaxBlocks = 2;
constexpr size_t kPhiMaxBlocks = 4;

void fill_byte(proofs::DenseFiller<Field>& filler, uint8_t byte) {
    filler.push_back(byte, 8, proofs::p256k1_base);
}

void fill_digest_target(proofs::DenseFiller<Field>& filler,
                        const uint8_t digest[32]) {
    for (size_t j = 0; j < 8; ++j) {
        const uint32_t word = proofs::SHA256_ru32be(digest + 4 * (7 - j));
        filler.push_back(word, 32, proofs::p256k1_base);
    }
}

void fill_one(proofs::DenseFiller<Field>& filler) {
    filler.push_back(proofs::p256k1_base.one());
}

int hex_nibble(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

void hex_to_32(const char *hex, uint8_t out[32]) {
    assert(strlen(hex) == 64);
    for (size_t i = 0; i < 32; ++i) {
        int hi = hex_nibble(hex[2 * i]);
        int lo = hex_nibble(hex[2 * i + 1]);
        assert(hi >= 0 && lo >= 0);
        out[i] = static_cast<uint8_t>((hi << 4) | lo);
    }
}

Field::Elt challenge_scalar_from_digest(const uint8_t digest[32]) {
    auto e = proofs::Bip340Witness::nat_from_be_bytes(digest);
    auto order = proofs::n256k1_order;
    if (!(e < order)) {
        e.sub(order);
    }
    return proofs::p256k1_base.to_montgomery(e);
}

void bip340_tag_hash(uint8_t out[32]) {
    static const char tag[] = "BIP0340/challenge";
    proofs::SHA256 sha;
    sha.Update(reinterpret_cast<const uint8_t *>(tag), strlen(tag));
    sha.DigestData(out);
}

void fill_sha_block(proofs::DenseFiller<Field>& filler,
                    const ShaBlockWitness& bw) {
    proofs::BitPluckerEncoder<Field, 4> encoder(proofs::p256k1_base);
    for (size_t k = 0; k < 48; ++k) {
        filler.push_back(encoder.mkpacked_v32(bw.outw[k]));
    }
    for (size_t k = 0; k < 64; ++k) {
        filler.push_back(encoder.mkpacked_v32(bw.oute[k]));
        filler.push_back(encoder.mkpacked_v32(bw.outa[k]));
    }
    for (size_t k = 0; k < 8; ++k) {
        filler.push_back(encoder.mkpacked_v32(bw.h1[k]));
    }
}

template <size_t MaxBlocks>
std::unique_ptr<proofs::Circuit<Field>> build_sha256_circuit(void) {
    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, proofs::p256k1_base);
    const FlatSha sha(logic);

    Logic::v256 target = logic.template vinput<256>();
    q.private_input();

    Logic::v8 preimage[MaxBlocks * 64];
    for (size_t i = 0; i < MaxBlocks * 64; ++i) {
        preimage[i] = logic.template vinput<8>();
    }

    FlatSha::BlockWitness bw[MaxBlocks];
    for (size_t i = 0; i < MaxBlocks; ++i) {
        bw[i].input(logic);
    }

    Logic::v8 blocks;
    logic.bits(8, blocks.data(), MaxBlocks);
    sha.assert_message_hash(MaxBlocks, blocks, preimage, target, bw);
    return q.mkcircuit(1);
}

std::unique_ptr<proofs::Circuit<Field>> build_challenge_reduction_circuit(void) {
    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, proofs::p256k1_base);
    const Bip340Gadgets gadgets(logic, proofs::p256k1);

    auto e = logic.eltw_input();
    q.private_input();

    Logic::v256 digest = logic.template vinput<256>();
    gadgets.assert_challenge_scalar_from_digest(digest, e);
    return q.mkcircuit(1);
}

std::unique_ptr<proofs::Circuit<Field>> build_bip340_full_challenge_circuit(void) {
    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, proofs::p256k1_base);
    const FlatSha sha(logic);
    const Bip340Gadgets gadgets(logic, proofs::p256k1);
    const Bip340Verify verifier(logic, proofs::p256k1);

    auto rx = logic.eltw_input();
    auto px = logic.eltw_input();
    q.private_input();

    auto e = logic.eltw_input();
    Logic::v256 digest = logic.template vinput<256>();
    Logic::v8 preimage[kPaddedBytes];
    for (size_t i = 0; i < kPaddedBytes; ++i) {
        preimage[i] = logic.template vinput<8>();
    }
    FlatSha::BlockWitness sha_blocks[kMaxBlocks];
    for (size_t i = 0; i < kMaxBlocks; ++i) {
        sha_blocks[i].input(logic);
    }
    Bip340Verify::Witness bip340_witness;
    bip340_witness.input(logic);

    uint8_t tag_hash[32];
    bip340_tag_hash(tag_hash);
    for (size_t i = 0; i < 32; ++i) {
        logic.vassert_eq(preimage[i], tag_hash[i]);
        logic.vassert_eq(preimage[32 + i], tag_hash[i]);
    }

    Logic::v256 rx_bits;
    Logic::v256 px_bits;
    for (size_t i = 0; i < 256; ++i) {
        rx_bits[i] = preimage[64 + 31 - i / 8][i % 8];
        px_bits[i] = preimage[96 + 31 - i / 8][i % 8];
    }
    gadgets.assert_field_from_bits_lsb(rx_bits, rx);
    gadgets.assert_field_from_bits_lsb(px_bits, px);

    Logic::v8 blocks;
    logic.bits(8, blocks.data(), kMaxBlocks);
    sha.assert_message_hash(kMaxBlocks, blocks, preimage, digest, sha_blocks);
    gadgets.assert_challenge_scalar_from_digest(digest, e);
    verifier.assert_verify(rx, px, e, bip340_witness);
    return q.mkcircuit(1);
}

template <size_t MaxBlocks>
void build_inputs(const uint8_t digest[32], const uint8_t *preimage,
                  size_t preimage_len, proofs::Dense<Field> *witness,
                  proofs::Dense<Field> *pub) {
    assert(witness != nullptr);
    assert(pub != nullptr);

    uint8_t nblocks = 0;
    uint8_t padded[MaxBlocks * 64];
    ShaBlockWitness blocks[MaxBlocks];
    proofs::FlatSHA256Witness::transform_and_witness_message(
        preimage_len, preimage, MaxBlocks, nblocks, padded, blocks);
    assert(nblocks == MaxBlocks);

    proofs::DenseFiller<Field> pub_filler(*pub);
    fill_one(pub_filler);
    fill_digest_target(pub_filler, digest);
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> witness_filler(*witness);
    fill_one(witness_filler);
    fill_digest_target(witness_filler, digest);
    for (size_t i = 0; i < sizeof(padded); ++i) {
        fill_byte(witness_filler, padded[i]);
    }
    for (size_t i = 0; i < MaxBlocks; ++i) {
        fill_sha_block(witness_filler, blocks[i]);
    }
    assert(witness_filler.size() == witness->n1_);
}

bool evaluates(const proofs::Circuit<Field>& circuit,
               const proofs::Dense<Field>& witness) {
    proofs::ProverLayers<Field> layers(proofs::p256k1_base);
    proofs::ProverLayers<Field>::inputs inputs;
    auto final = layers.eval_circuit(&inputs, &circuit, witness.clone(),
                                     proofs::p256k1_base);
    return final != nullptr;
}

void build_reduction_inputs(const uint8_t digest[32], Field::Elt e,
                            proofs::Dense<Field> *witness,
                            proofs::Dense<Field> *pub) {
    assert(witness != nullptr);
    assert(pub != nullptr);

    proofs::DenseFiller<Field> pub_filler(*pub);
    fill_one(pub_filler);
    pub_filler.push_back(e);
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> witness_filler(*witness);
    fill_one(witness_filler);
    witness_filler.push_back(e);
    fill_digest_target(witness_filler, digest);
    assert(witness_filler.size() == witness->n1_);
}

void fill_bip340_challenge_sha_witness(proofs::DenseFiller<Field>& filler,
                                       const uint8_t preimage[160],
                                       const uint8_t digest[32]) {
    fill_digest_target(filler, digest);

    uint8_t nblocks = 0;
    uint8_t padded[kPaddedBytes];
    ShaBlockWitness blocks[kMaxBlocks];
    proofs::FlatSHA256Witness::transform_and_witness_message(
        160, preimage, kMaxBlocks, nblocks, padded, blocks);
    assert(nblocks == kMaxBlocks);
    for (size_t i = 0; i < sizeof(padded); ++i) {
        fill_byte(filler, padded[i]);
    }
    for (size_t i = 0; i < kMaxBlocks; ++i) {
        fill_sha_block(filler, blocks[i]);
    }
}

void test_bip340_challenge_sha_circuit(void) {
    auto circuit = build_sha256_circuit<kMaxBlocks>();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 257);

    uint8_t sig[64];
    uint8_t pk[32];
    uint8_t msg[32];
    for (size_t i = 0; i < sizeof(sig); ++i) {
        sig[i] = static_cast<uint8_t>(0x31u + i * 3u);
    }
    for (size_t i = 0; i < sizeof(pk); ++i) {
        pk[i] = static_cast<uint8_t>(0x42u + i * 5u);
        msg[i] = static_cast<uint8_t>(0x53u + i * 7u);
    }

    uint8_t digest[32];
    niwi::rpbsch::compute_bip340_challenge(sig, pk, msg, digest);
    uint8_t preimage[niwi::rpbsch::kBip340ChallengePreimageSize];
    niwi::rpbsch::build_bip340_challenge_preimage(sig, pk, msg, preimage);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    build_inputs<kMaxBlocks>(digest, preimage, sizeof(preimage), &witness,
                             &pub);
    for (size_t i = 0; i < pub.n1_; ++i) {
        assert(witness.v_[i] == pub.v_[i]);
    }
    assert(evaluates(*circuit, witness));

    uint8_t bad_digest[32];
    memcpy(bad_digest, digest, sizeof(bad_digest));
    bad_digest[0] ^= 0x80u;
    proofs::Dense<Field> bad_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_pub(1, circuit->npub_in);
    build_inputs<kMaxBlocks>(bad_digest, preimage, sizeof(preimage),
                             &bad_witness, &bad_pub);
    assert(!evaluates(*circuit, bad_witness));

    std::printf("  PASS test_bip340_challenge_sha_circuit\n");
}

void test_tuple_message_sha_circuit(void) {
    auto circuit = build_sha256_circuit<kTupleMaxBlocks>();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 257);

    uint8_t nu_s[32];
    uint8_t nu_u[32];
    for (size_t i = 0; i < sizeof(nu_s); ++i) {
        nu_s[i] = static_cast<uint8_t>(0x64u + i * 11u);
        nu_u[i] = static_cast<uint8_t>(0x75u + i * 13u);
    }

    uint8_t digest[32];
    niwi::rpbsch::tuple_message(nu_s, nu_u, digest);
    uint8_t preimage[niwi::rpbsch::kTupleMessagePreimageSize];
    niwi::rpbsch::build_tuple_message_preimage(nu_s, nu_u, preimage);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    build_inputs<kTupleMaxBlocks>(digest, preimage, sizeof(preimage),
                                  &witness, &pub);
    for (size_t i = 0; i < pub.n1_; ++i) {
        assert(witness.v_[i] == pub.v_[i]);
    }
    assert(evaluates(*circuit, witness));

    uint8_t bad_digest[32];
    memcpy(bad_digest, digest, sizeof(bad_digest));
    bad_digest[31] ^= 0x01u;
    proofs::Dense<Field> bad_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_pub(1, circuit->npub_in);
    build_inputs<kTupleMaxBlocks>(bad_digest, preimage, sizeof(preimage),
                                  &bad_witness, &bad_pub);
    assert(!evaluates(*circuit, bad_witness));

    std::printf("  PASS test_tuple_message_sha_circuit\n");
}

void test_statement_phi_sha_circuit(void) {
    auto circuit = build_sha256_circuit<kPhiMaxBlocks>();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 257);

    uint8_t m[32];
    uint8_t alpha[32];
    uint8_t beta[32];
    uint8_t nu_s[32];
    uint8_t nu_u[32];
    uint8_t nu_u_prime[32];
    for (size_t i = 0; i < sizeof(m); ++i) {
        m[i] = static_cast<uint8_t>(0x10u + i);
        alpha[i] = static_cast<uint8_t>(0x30u + i * 3u);
        beta[i] = static_cast<uint8_t>(0x50u + i * 5u);
        nu_s[i] = static_cast<uint8_t>(0x70u + i * 7u);
        nu_u[i] = static_cast<uint8_t>(0x90u + i * 11u);
        nu_u_prime[i] = static_cast<uint8_t>(0xb0u + i * 13u);
    }

    niwi::rpbsch::Witness w{};
    w.m = m;
    w.alpha = alpha;
    w.beta = beta;
    w.nu_s = nu_s;
    w.nu_u = nu_u;
    w.nu_u_prime = nu_u_prime;

    uint8_t digest[32];
    niwi::rpbsch::statement_phi(w, digest);
    uint8_t preimage[niwi::rpbsch::kStatementPhiPreimageSize];
    niwi::rpbsch::build_statement_phi_preimage(m, alpha, beta, nu_s, nu_u,
                                               nu_u_prime, preimage);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    build_inputs<kPhiMaxBlocks>(digest, preimage, sizeof(preimage),
                                &witness, &pub);
    for (size_t i = 0; i < pub.n1_; ++i) {
        assert(witness.v_[i] == pub.v_[i]);
    }
    assert(evaluates(*circuit, witness));

    uint8_t bad_preimage[sizeof(preimage)];
    memcpy(bad_preimage, preimage, sizeof(preimage));
    bad_preimage[sizeof(bad_preimage) - 1] ^= 0x01u;
    proofs::Dense<Field> bad_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_pub(1, circuit->npub_in);
    build_inputs<kPhiMaxBlocks>(digest, bad_preimage, sizeof(bad_preimage),
                                &bad_witness, &bad_pub);
    assert(!evaluates(*circuit, bad_witness));

    std::printf("  PASS test_statement_phi_sha_circuit\n");
}

void test_bip340_challenge_reduction_circuit(void) {
    auto circuit = build_challenge_reduction_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 2);

    uint8_t digest[32];
    hex_to_32("000000000000000000000000000000000000000000000000000000000000002a",
              digest);
    Field::Elt e = challenge_scalar_from_digest(digest);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    build_reduction_inputs(digest, e, &witness, &pub);
    assert(evaluates(*circuit, witness));

    uint8_t digest_over_order[32];
    hex_to_32("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364142",
              digest_over_order);
    Field::Elt one = proofs::p256k1_base.one();
    proofs::Dense<Field> over_witness(1, circuit->ninputs);
    proofs::Dense<Field> over_pub(1, circuit->npub_in);
    build_reduction_inputs(digest_over_order, one, &over_witness, &over_pub);
    assert(evaluates(*circuit, over_witness));

    Field::Elt bad_e = proofs::p256k1_base.of_scalar(2);
    proofs::Dense<Field> bad_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_pub(1, circuit->npub_in);
    build_reduction_inputs(digest_over_order, bad_e, &bad_witness, &bad_pub);
    assert(!evaluates(*circuit, bad_witness));

    std::printf("  PASS test_bip340_challenge_reduction_circuit\n");
}

void test_bip340_full_challenge_circuit(void) {
    auto circuit = build_bip340_full_challenge_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 3);

    uint8_t sig[64] = {
        0xE9, 0x07, 0x83, 0x1F, 0x80, 0x84, 0x8D, 0x10,
        0x69, 0xA5, 0x37, 0x1B, 0x40, 0x24, 0x10, 0x36,
        0x4B, 0xDF, 0x1C, 0x5F, 0x83, 0x07, 0xB0, 0x08,
        0x4C, 0x55, 0xF1, 0xCE, 0x2D, 0xCA, 0x82, 0x15,
        0x25, 0xF6, 0x6A, 0x4A, 0x85, 0xEA, 0x8B, 0x71,
        0xE4, 0x82, 0xA7, 0x4F, 0x38, 0x2D, 0x2C, 0xE5,
        0xEB, 0xEE, 0xE8, 0xFD, 0xB2, 0x17, 0x2F, 0x47,
        0x7D, 0xF4, 0x90, 0x0D, 0x31, 0x05, 0x36, 0xC0,
    };
    uint8_t pk[32] = {
        0xF9, 0x30, 0x8A, 0x01, 0x92, 0x58, 0xC3, 0x10,
        0x49, 0x34, 0x4F, 0x85, 0xF8, 0x9D, 0x52, 0x29,
        0xB5, 0x31, 0xC8, 0x45, 0x83, 0x6F, 0x99, 0xB0,
        0x86, 0x01, 0xF1, 0x13, 0xBC, 0xE0, 0x36, 0xF9,
    };
    uint8_t msg[32] = {0};

    uint8_t digest[32];
    uint8_t preimage[niwi::rpbsch::kBip340ChallengePreimageSize];
    niwi::rpbsch::build_bip340_challenge_preimage(sig, pk, msg, preimage);
    niwi::rpbsch::compute_bip340_challenge(sig, pk, msg, digest);

    proofs::Bip340Witness bip340_witness(proofs::p256k1);
    assert(bip340_witness.compute(sig, pk, msg, sizeof(msg)));

    auto rx = proofs::p256k1_base.to_montgomery(
        proofs::Bip340Witness::nat_from_be_bytes(sig));
    auto px = proofs::p256k1_base.to_montgomery(
        proofs::Bip340Witness::nat_from_be_bytes(pk));

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);

    proofs::DenseFiller<Field> pub_filler(pub);
    fill_one(pub_filler);
    pub_filler.push_back(rx);
    pub_filler.push_back(px);
    assert(pub_filler.size() == pub.n1_);

    proofs::DenseFiller<Field> witness_filler(witness);
    fill_one(witness_filler);
    witness_filler.push_back(rx);
    witness_filler.push_back(px);
    witness_filler.push_back(bip340_witness.e_);
    fill_bip340_challenge_sha_witness(witness_filler, preimage, digest);
    bip340_witness.fill_witness(witness_filler);
    assert(witness_filler.size() == witness.n1_);
    assert(evaluates(*circuit, witness));

    uint8_t bad_preimage[sizeof(preimage)];
    memcpy(bad_preimage, preimage, sizeof(preimage));
    bad_preimage[96] ^= 0x01u;
    proofs::Dense<Field> bad_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_pub(1, circuit->npub_in);
    proofs::DenseFiller<Field> bad_pub_filler(bad_pub);
    fill_one(bad_pub_filler);
    bad_pub_filler.push_back(rx);
    bad_pub_filler.push_back(px);
    proofs::DenseFiller<Field> bad_witness_filler(bad_witness);
    fill_one(bad_witness_filler);
    bad_witness_filler.push_back(rx);
    bad_witness_filler.push_back(px);
    bad_witness_filler.push_back(bip340_witness.e_);
    fill_bip340_challenge_sha_witness(bad_witness_filler, bad_preimage,
                                      digest);
    bip340_witness.fill_witness(bad_witness_filler);
    assert(!evaluates(*circuit, bad_witness));

    std::printf("  PASS test_bip340_full_challenge_circuit\n");
}

}  // namespace

int main(void) {
    std::printf("lib/niwi RPBSch SHA circuit tests:\n");
    test_bip340_challenge_sha_circuit();
    test_tuple_message_sha_circuit();
    test_statement_phi_sha_circuit();
    test_bip340_challenge_reduction_circuit();
    test_bip340_full_challenge_circuit();
    std::printf("All RPBSch SHA circuit tests passed.\n");
    return 0;
}
