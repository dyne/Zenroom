/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/rpbsch_relation_internal.h"

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstring>

#include "util/crypto.h"

namespace {

void sha256_raw(const uint8_t *data, size_t len, uint8_t out[32]) {
    proofs::SHA256 sha;
    sha.Update(data, len);
    sha.DigestData(out);
}

void fill_seq(uint8_t *out, size_t len, uint8_t start) {
    for (size_t i = 0; i < len; ++i) out[i] = static_cast<uint8_t>(start + i);
}

void test_bip340_challenge_preimage_layout(void) {
    uint8_t sig[64];
    uint8_t pk[32];
    uint8_t msg[32];
    uint8_t tag_hash[32];
    uint8_t preimage[niwi::rpbsch::kBip340ChallengePreimageSize];
    fill_seq(sig, sizeof(sig), 1);
    fill_seq(pk, sizeof(pk), 80);
    fill_seq(msg, sizeof(msg), 160);

    uint8_t helper[32];
    uint8_t reference[32];
    proofs::SHA256 tag_sha;
    static const char tag[] = "BIP0340/challenge";
    tag_sha.Update(reinterpret_cast<const uint8_t *>(tag), sizeof(tag) - 1);
    tag_sha.DigestData(tag_hash);

    niwi::rpbsch::build_bip340_challenge_preimage(sig, pk, msg, preimage);
    niwi::rpbsch::compute_bip340_challenge(sig, pk, msg, helper);
    sha256_raw(preimage, sizeof(preimage), reference);
    assert(memcmp(helper, reference, sizeof(helper)) == 0);
    assert(memcmp(preimage, tag_hash, sizeof(tag_hash)) == 0);
    assert(memcmp(preimage + 32, tag_hash, sizeof(tag_hash)) == 0);
    assert(memcmp(preimage + 64, sig, 32) == 0);
    assert(memcmp(preimage + 96, pk, 32) == 0);
    assert(memcmp(preimage + 128, msg, 32) == 0);
    std::printf("  PASS test_bip340_challenge_preimage_layout\n");
}

void test_tuple_message_preimage_matches_relation_hash(void) {
    uint8_t nu_s[32];
    uint8_t nu_u[32];
    uint8_t preimage[niwi::rpbsch::kTupleMessagePreimageSize];
    uint8_t helper[32];
    uint8_t reference[32];
    fill_seq(nu_s, sizeof(nu_s), 3);
    fill_seq(nu_u, sizeof(nu_u), 90);

    niwi::rpbsch::build_tuple_message_preimage(nu_s, nu_u, preimage);
    sha256_raw(preimage, sizeof(preimage), helper);
    niwi::rpbsch::tuple_message(nu_s, nu_u, reference);
    assert(memcmp(helper, reference, sizeof(helper)) == 0);
    std::printf("  PASS test_tuple_message_preimage_matches_relation_hash\n");
}

void test_c_message_preimage_matches_relation_hash(void) {
    uint8_t m[32];
    uint8_t alpha[32];
    uint8_t beta[32];
    uint8_t preimage[niwi::rpbsch::kCMessagePreimageSize];
    uint8_t helper[32];
    uint8_t reference[32];
    fill_seq(m, sizeof(m), 9);
    fill_seq(alpha, sizeof(alpha), 51);
    fill_seq(beta, sizeof(beta), 93);

    niwi::rpbsch::build_c_message_preimage(m, alpha, beta, preimage);
    sha256_raw(preimage, sizeof(preimage), helper);
    assert(niwi::rpbsch::encode_c_msg(m, alpha, beta, reference));
    assert(memcmp(helper, reference, sizeof(helper)) == 0);
    std::printf("  PASS test_c_message_preimage_matches_relation_hash\n");
}

void test_s_message_preimage_matches_relation_hash(void) {
    uint8_t sigma0[64];
    uint8_t sigma1[64];
    uint8_t nu_u[32];
    uint8_t nu_u_prime[32];
    uint8_t nu_s[32];
    uint8_t preimage[niwi::rpbsch::kSMessagePreimageSize];
    uint8_t helper[32];
    uint8_t reference[32];
    fill_seq(sigma0, sizeof(sigma0), 11);
    fill_seq(sigma1, sizeof(sigma1), 77);
    fill_seq(nu_u, sizeof(nu_u), 143);
    fill_seq(nu_u_prime, sizeof(nu_u_prime), 177);
    fill_seq(nu_s, sizeof(nu_s), 211);

    niwi::rpbsch::build_s_message_preimage(
        sigma0, sigma1, nu_u, nu_u_prime, nu_s, preimage);
    sha256_raw(preimage, sizeof(preimage), helper);
    niwi::rpbsch::encode_s_msg(sigma0, sigma1, nu_u, nu_u_prime, nu_s,
                               reference);
    assert(memcmp(helper, reference, sizeof(helper)) == 0);
    std::printf("  PASS test_s_message_preimage_matches_relation_hash\n");
}

void test_statement_phi_preimage_matches_relation_hash(void) {
    uint8_t m[32];
    uint8_t alpha[32];
    uint8_t beta[32];
    uint8_t nu_s[32];
    uint8_t nu_u[32];
    uint8_t nu_u_prime[32];
    uint8_t preimage[niwi::rpbsch::kStatementPhiPreimageSize];
    uint8_t helper[32];
    uint8_t reference[32];
    fill_seq(m, sizeof(m), 7);
    fill_seq(alpha, sizeof(alpha), 40);
    fill_seq(beta, sizeof(beta), 73);
    fill_seq(nu_s, sizeof(nu_s), 106);
    fill_seq(nu_u, sizeof(nu_u), 139);
    fill_seq(nu_u_prime, sizeof(nu_u_prime), 172);

    niwi::rpbsch::Witness w{};
    w.m = m;
    w.alpha = alpha;
    w.beta = beta;
    w.nu_s = nu_s;
    w.nu_u = nu_u;
    w.nu_u_prime = nu_u_prime;

    niwi::rpbsch::build_statement_phi_preimage(
        m, alpha, beta, nu_s, nu_u, nu_u_prime, preimage);
    sha256_raw(preimage, sizeof(preimage), helper);
    niwi::rpbsch::statement_phi(w, reference);
    assert(memcmp(helper, reference, sizeof(helper)) == 0);
    std::printf("  PASS test_statement_phi_preimage_matches_relation_hash\n");
}

}  // namespace

int main(void) {
    std::printf("lib/blindzap RPBSch adapter tests:\n");
    test_bip340_challenge_preimage_layout();
    test_tuple_message_preimage_matches_relation_hash();
    test_c_message_preimage_matches_relation_hash();
    test_s_message_preimage_matches_relation_hash();
    test_statement_phi_preimage_matches_relation_hash();
    std::printf("All RPBSch adapter tests passed.\n");
    return 0;
}
