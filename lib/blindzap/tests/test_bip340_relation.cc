/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "niwi.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <vector>

#include "circuits/logic/bit_plucker_encoder.h"
#include "circuits/bip340/bip340_witness.h"
#include "circuits/sha/flatsha256_witness.h"
#include "ec/p256k1.h"
#include "relations/bip340_relation.h"
#include "relations/rpbsch_relation_internal.h"

using proofs::Bip340Witness;
using proofs::p256k1;
using proofs::p256k1_base;

static int hex_nibble(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static std::vector<uint8_t> hex_to_bytes(const char *hex) {
    size_t len = strlen(hex);
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

static void append_field(std::vector<uint8_t>& out,
                         const proofs::Fp256k1Base::Elt& elt) {
    uint8_t buf[32];
    auto nat = p256k1_base.from_montgomery(elt);
    nat.to_bytes(buf);
    out.insert(out.end(), buf, buf + sizeof(buf));
}

static void append_bit(std::vector<uint8_t>& out, uint8_t bit) {
    append_field(out, p256k1_base.of_scalar(bit & 1u));
}

static void append_u32_bits(std::vector<uint8_t>& out, uint32_t word) {
    for (size_t i = 0; i < 32; ++i) {
        append_bit(out, static_cast<uint8_t>((word >> i) & 1u));
    }
}

static void append_byte_bits(std::vector<uint8_t>& out, uint8_t byte) {
    for (size_t i = 0; i < 8; ++i) {
        append_bit(out, static_cast<uint8_t>((byte >> i) & 1u));
    }
}

static void append_digest_target(std::vector<uint8_t>& out,
                                 const uint8_t digest[32]) {
    for (size_t j = 0; j < 8; ++j) {
        append_u32_bits(out, proofs::SHA256_ru32be(digest + 4 * (7 - j)));
    }
}

static void append_sha_block(
    std::vector<uint8_t>& out,
    const proofs::FlatSHA256Witness::BlockWitness& bw) {
    proofs::BitPluckerEncoder<proofs::Fp256k1Base, 4> encoder(p256k1_base);
    for (size_t k = 0; k < 48; ++k) {
        for (const auto& elt : encoder.mkpacked_v32(bw.outw[k])) {
            append_field(out, elt);
        }
    }
    for (size_t k = 0; k < 64; ++k) {
        for (const auto& elt : encoder.mkpacked_v32(bw.oute[k])) {
            append_field(out, elt);
        }
        for (const auto& elt : encoder.mkpacked_v32(bw.outa[k])) {
            append_field(out, elt);
        }
    }
    for (size_t k = 0; k < 8; ++k) {
        for (const auto& elt : encoder.mkpacked_v32(bw.h1[k])) {
            append_field(out, elt);
        }
    }
}

static void append_bip340_witness(std::vector<uint8_t>& out,
                                  const Bip340Witness& witness) {
    for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
        append_field(out, witness.bits_s_[i]);
        if (i < Bip340Witness::kBits - 1) {
            append_field(out, witness.int_sx_[i]);
            append_field(out, witness.int_sy_[i]);
            append_field(out, witness.int_sz_[i]);
        }
    }
    for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
        append_field(out, witness.bits_e_[i]);
        if (i < Bip340Witness::kBits - 1) {
            append_field(out, witness.int_ex_[i]);
            append_field(out, witness.int_ey_[i]);
            append_field(out, witness.int_ez_[i]);
        }
    }
    append_field(out, witness.py_);
    append_field(out, witness.ry_);
    append_field(out, witness.rz_inv_);
    for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
        append_field(out, witness.bits_ry_[i]);
    }
}

static size_t find_tag(const uint8_t *buf, size_t len, const char tag[4]) {
    if (!buf || len < 4) return len;
    for (size_t i = 0; i + 4 <= len; ++i) {
        if (memcmp(buf + i, tag, 4) == 0) return i;
    }
    return len;
}

static void build_vector0_inputs(std::vector<uint8_t>& public_inputs,
                                 std::vector<uint8_t>& private_inputs) {
    const auto sig = hex_to_bytes(
        "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215"
        "25F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0");
    const auto pk = hex_to_bytes(
        "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9");
    const auto msg = hex_to_bytes(
        "0000000000000000000000000000000000000000000000000000000000000000");

    Bip340Witness witness(p256k1);
    assert(witness.compute(sig.data(), pk.data(), msg.data(), msg.size()));

    auto rx_nat = Bip340Witness::nat_from_be_bytes(sig.data());
    auto px_nat = Bip340Witness::nat_from_be_bytes(pk.data());
    auto rx = p256k1_base.to_montgomery(rx_nat);
    auto px = p256k1_base.to_montgomery(px_nat);

    private_inputs.clear();
    public_inputs.clear();
    private_inputs.reserve(2305 * 32);
    public_inputs.reserve(4 * 32);

    append_field(private_inputs, p256k1_base.one());
    append_field(private_inputs, rx);
    append_field(private_inputs, px);
    append_field(private_inputs, witness.e_);
    public_inputs.assign(private_inputs.begin(), private_inputs.end());

    append_bip340_witness(private_inputs, witness);

    assert(public_inputs.size() == 4 * 32);
    assert(private_inputs.size() == 2305 * 32);
}

static void build_vector0_full_challenge_inputs(
    std::vector<uint8_t>& public_inputs,
    std::vector<uint8_t>& private_inputs) {
    const auto sig = hex_to_bytes(
        "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215"
        "25F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0");
    const auto pk = hex_to_bytes(
        "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9");
    const auto msg = hex_to_bytes(
        "0000000000000000000000000000000000000000000000000000000000000000");

    Bip340Witness witness(p256k1);
    assert(witness.compute(sig.data(), pk.data(), msg.data(), msg.size()));

    auto rx = p256k1_base.to_montgomery(
        Bip340Witness::nat_from_be_bytes(sig.data()));
    auto px = p256k1_base.to_montgomery(
        Bip340Witness::nat_from_be_bytes(pk.data()));

    public_inputs.clear();
    private_inputs.clear();
    append_field(private_inputs, p256k1_base.one());
    append_field(private_inputs, rx);
    append_field(private_inputs, px);
    public_inputs.assign(private_inputs.begin(), private_inputs.end());
    append_field(private_inputs, witness.e_);

    uint8_t digest[32];
    uint8_t preimage[niwi::rpbsch::kBip340ChallengePreimageSize];
    niwi::rpbsch::build_bip340_challenge_preimage(sig.data(), pk.data(),
                                                  msg.data(), preimage);
    niwi::rpbsch::compute_bip340_challenge(sig.data(), pk.data(), msg.data(),
                                           digest);
    append_digest_target(private_inputs, digest);

    uint8_t nblocks = 0;
    uint8_t padded[3 * 64];
    proofs::FlatSHA256Witness::BlockWitness blocks[3];
    proofs::FlatSHA256Witness::transform_and_witness_message(
        sizeof(preimage), preimage, 3, nblocks, padded, blocks);
    assert(nblocks == 3);
    for (size_t i = 64; i < sizeof(padded); ++i) {
        append_byte_bits(private_inputs, padded[i]);
    }
    for (const auto& block : blocks) {
        append_sha_block(private_inputs, block);
    }
    append_bip340_witness(private_inputs, witness);
}

static void test_native_bip340_relation_prove_and_extract(void) {
    std::vector<uint8_t> pub;
    std::vector<uint8_t> priv;
    build_vector0_inputs(pub, priv);

    const uint8_t artifact[] = {'b', 'i', 'p', '3', '4', '0'};
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        artifact, sizeof(artifact), NIWI_RELATION_ZKCC_BIP340, nullptr, nullptr);
    assert(ctx != nullptr);

    uint8_t *proof = nullptr;
    uint8_t *gamma = nullptr;
    size_t proof_len = 0;
    size_t gamma_len = 0;

    assert(niwi_prove_observed(ctx, pub.data(), pub.size(),
                               priv.data(), priv.size(),
                               &proof, &proof_len, &gamma, &gamma_len) == 0);
    assert(proof != nullptr);
    assert(gamma != nullptr);
    size_t lzk0 = find_tag(proof, proof_len, "LZK0");
    assert(lzk0 != proof_len);
    assert(niwi_verify(ctx, proof, proof_len, pub.data(), pub.size()) == 0);

    proof[proof_len - 1] ^= 1u;
    assert(niwi_verify(ctx, proof, proof_len, pub.data(), pub.size()) != 0);
    proof[proof_len - 1] ^= 1u;

    uint8_t *extracted = nullptr;
    size_t extracted_len = 0;
    assert(niwi_extract(ctx, proof, proof_len, gamma, gamma_len,
                        pub.data(), pub.size(),
                        &extracted, &extracted_len) == 0);
    assert(extracted_len == priv.size());
    assert(memcmp(extracted, priv.data(), priv.size()) == 0);
    niwi_free_buffer(extracted);
    niwi_free_buffer(proof);
    niwi_free_buffer(gamma);

    std::vector<uint8_t> tampered = priv;
    tampered.back() ^= 1u;
    proof = nullptr;
    proof_len = 0;
    assert(niwi_prove(ctx, pub.data(), pub.size(),
                      tampered.data(), tampered.size(),
                      &proof, &proof_len) != 0);
    assert(proof == nullptr);

    niwi_ctx_free(ctx);
    printf("  PASS test_native_bip340_relation_prove_and_extract\n");
}

static void test_native_bip340_full_challenge_relation_validate(void) {
    std::vector<uint8_t> pub;
    std::vector<uint8_t> priv;
    build_vector0_full_challenge_inputs(pub, priv);

    assert(pub.size() == 3 * 32);
    assert(niwi_bip340_relation_validate(pub.data(), pub.size(),
                                         priv.data(), priv.size()) == 0);

    std::vector<uint8_t> tampered = priv;
    tampered[3 * 32 + 1] ^= 1u;  // e no longer matches the SHA digest.
    assert(niwi_bip340_relation_validate(pub.data(), pub.size(),
                                         tampered.data(),
                                         tampered.size()) != 0);

    tampered = priv;
    tampered[4 * 32 + 17 * 32] ^= 1u;  // Corrupt one private digest bit.
    assert(niwi_bip340_relation_validate(pub.data(), pub.size(),
                                         tampered.data(),
                                         tampered.size()) != 0);

    std::printf("  PASS test_native_bip340_full_challenge_relation_validate\n");
}

static void test_native_bip340_full_challenge_relation_prove(void) {
    std::vector<uint8_t> pub;
    std::vector<uint8_t> priv;
    build_vector0_full_challenge_inputs(pub, priv);

    const uint8_t artifact[] = {'b', 'i', 'p', '3', '4', '0'};
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        artifact, sizeof(artifact), NIWI_RELATION_ZKCC_BIP340, nullptr, nullptr);
    assert(ctx != nullptr);

    uint8_t *proof = nullptr;
    size_t proof_len = 0;
    int prove_rc = niwi_prove(ctx, pub.data(), pub.size(),
                              priv.data(), priv.size(),
                              &proof, &proof_len);
    if (prove_rc != 0) {
        const char *err = niwi_last_error(ctx);
        std::fprintf(stderr, "full challenge prove failed: %s\n",
                     err ? err : "(no error)");
    }
    assert(prove_rc == 0);
    assert(proof != nullptr);
    assert(find_tag(proof, proof_len, "LZK0") != proof_len);
    assert(niwi_verify(ctx, proof, proof_len, pub.data(), pub.size()) == 0);

    proof[proof_len - 1] ^= 1u;
    assert(niwi_verify(ctx, proof, proof_len, pub.data(), pub.size()) != 0);
    proof[proof_len - 1] ^= 1u;

    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    std::printf("  PASS test_native_bip340_full_challenge_relation_prove\n");
}

int main(void) {
    printf("lib/blindzap BIP340 native relation tests:\n");
    test_native_bip340_relation_prove_and_extract();
    test_native_bip340_full_challenge_relation_validate();
    test_native_bip340_full_challenge_relation_prove();
    printf("All BIP340 native relation tests passed.\n");
    return 0;
}
