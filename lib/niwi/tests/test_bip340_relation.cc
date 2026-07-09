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

#include "circuits/bip340/bip340_witness.h"
#include "ec/p256k1.h"

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

    for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
        append_field(private_inputs, witness.bits_s_[i]);
        if (i < Bip340Witness::kBits - 1) {
            append_field(private_inputs, witness.int_sx_[i]);
            append_field(private_inputs, witness.int_sy_[i]);
            append_field(private_inputs, witness.int_sz_[i]);
        }
    }
    for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
        append_field(private_inputs, witness.bits_e_[i]);
        if (i < Bip340Witness::kBits - 1) {
            append_field(private_inputs, witness.int_ex_[i]);
            append_field(private_inputs, witness.int_ey_[i]);
            append_field(private_inputs, witness.int_ez_[i]);
        }
    }
    append_field(private_inputs, witness.py_);
    append_field(private_inputs, witness.ry_);
    append_field(private_inputs, witness.rz_inv_);
    for (size_t i = 0; i < Bip340Witness::kBits; ++i) {
        append_field(private_inputs, witness.bits_ry_[i]);
    }

    assert(public_inputs.size() == 4 * 32);
    assert(private_inputs.size() == 2305 * 32);
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

int main(void) {
    printf("lib/niwi BIP340 native relation tests:\n");
    test_native_bip340_relation_prove_and_extract();
    printf("All BIP340 native relation tests passed.\n");
    return 0;
}
