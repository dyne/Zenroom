/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/rpbsch_relation.h"
#include "relations/rpbsch_relation_internal.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "circuits/bip340/bip340_witness.h"
#include "ec/p256k1.h"
#include "pbsch_commitment.h"
#include "relations/bip340_relation.h"
#include "util/crypto.h"

namespace niwi::rpbsch {

uint32_t read_u32_be(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) |
           ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) |
           (uint32_t)p[3];
}

void sha256_raw(const uint8_t *data, size_t len, uint8_t out[32]) {
    proofs::SHA256 sha;
    sha.Update(data, len);
    sha.DigestData(out);
}

bool hash_concat3(const char *tag, const uint8_t *a,
                  const uint8_t *b, const uint8_t *c,
                  uint8_t out[32]) {
    const size_t tag_len = strlen(tag);
    uint8_t buf[16 + 32 * 3];
    if (tag_len > 16) return false;
    memcpy(buf, tag, tag_len);
    memcpy(buf + tag_len, a, 32);
    memcpy(buf + tag_len + 32, b, 32);
    memcpy(buf + tag_len + 64, c, 32);
    sha256_raw(buf, tag_len + 96, out);
    return true;
}

bool encode_c_msg(const uint8_t *m, const uint8_t *alpha,
                  const uint8_t *beta, uint8_t out[32]) {
    return hash_concat3("PBSch/C/v1", m, alpha, beta, out);
}

void encode_s_msg(const uint8_t *sigma0, const uint8_t *sigma1,
                  const uint8_t *nu_u, const uint8_t *nu_u_prime,
                  const uint8_t *nu_s, uint8_t out[32]) {
    uint8_t buf[64 + 64 + 32 + 32 + 32];
    size_t off = 0;
    memcpy(buf + off, sigma0, 64); off += 64;
    memcpy(buf + off, sigma1, 64); off += 64;
    memcpy(buf + off, nu_u, 32); off += 32;
    memcpy(buf + off, nu_u_prime, 32); off += 32;
    memcpy(buf + off, nu_s, 32); off += 32;
    sha256_raw(buf, sizeof(buf), out);
}

void tuple_message(const uint8_t *nu_s, const uint8_t *nu_u, uint8_t out[32]) {
    uint8_t buf[kTupleMessagePreimageSize];
    build_tuple_message_preimage(nu_s, nu_u, buf);
    sha256_raw(buf, sizeof(buf), out);
}

void build_tuple_message_preimage(const uint8_t *nu_s, const uint8_t *nu_u,
                                  uint8_t out[kTupleMessagePreimageSize]) {
    static const char tag[] = "Zenroom/RPBSch/tuple-message/v1";
    memcpy(out, tag, sizeof(tag) - 1);
    memcpy(out + sizeof(tag) - 1, nu_s, 32);
    memcpy(out + sizeof(tag) - 1 + 32, nu_u, 32);
}

void statement_phi(const Witness& w, uint8_t out[32]) {
    static const char tag[] = "Zenroom/RPBSch/phi/v1";
    uint8_t buf[sizeof(tag) - 1 + 32 * 6];
    size_t off = 0;
    memcpy(buf + off, tag, sizeof(tag) - 1); off += sizeof(tag) - 1;
    memcpy(buf + off, w.m, 32); off += 32;
    memcpy(buf + off, w.alpha, 32); off += 32;
    memcpy(buf + off, w.beta, 32); off += 32;
    memcpy(buf + off, w.nu_s, 32); off += 32;
    memcpy(buf + off, w.nu_u, 32); off += 32;
    memcpy(buf + off, w.nu_u_prime, 32);
    sha256_raw(buf, sizeof(buf), out);
}

bool parse_statement(const uint8_t *public_inputs, size_t pub_len,
                     Statement *st) {
    if (!public_inputs || !st || pub_len != kStatementSize) return false;
    size_t off = 0;
    st->X = public_inputs + off; off += 32;
    st->X_prime = public_inputs + off; off += 32;
    st->R = public_inputs + off; off += 32;
    st->c = public_inputs + off; off += 32;
    st->C = public_inputs + off; off += 33;
    st->phi = public_inputs + off; off += 32;
    st->ck = public_inputs + off; off += 32;
    st->S = public_inputs + off;
    return true;
}

bool parse_witness(const uint8_t *p, size_t len, Witness *w) {
    if (!p || !w || len < 4 + 4 + 8 * 32 + 3 * 64 + 4) return false;
    size_t off = 0;
    if (memcmp(p + off, "RPB1", 4) != 0) return false;
    off += 4;
    w->branch = read_u32_be(p + off); off += 4;
    w->m = p + off; off += 32;
    w->alpha = p + off; off += 32;
    w->beta = p + off; off += 32;
    w->rho_c = p + off; off += 32;
    w->rho_s = p + off; off += 32;
    w->nu_s = p + off; off += 32;
    w->nu_u = p + off; off += 32;
    w->nu_u_prime = p + off; off += 32;
    w->sigma = p + off; off += 64;
    w->sigma0 = p + off; off += 64;
    w->sigma1 = p + off; off += 64;
    w->check_count = read_u32_be(p + off); off += 4;
    if (w->check_count == 0 || w->check_count > 2) return false;
    for (uint32_t i = 0; i < w->check_count; ++i) {
        if (len - off < 4) return false;
        uint32_t pub_len = read_u32_be(p + off); off += 4;
        if ((pub_len != kBip340PublicSize &&
             pub_len != kBip340FullPublicSize) ||
            len - off < pub_len + 4)
            return false;
        w->check_pub[i] = p + off; off += pub_len;
        w->check_pub_len[i] = pub_len;
        uint32_t priv_len = read_u32_be(p + off); off += 4;
        if ((priv_len != kBip340PrivateSize &&
             priv_len != kBip340FullPrivateSize) ||
            len - off < priv_len)
            return false;
        w->check_priv[i] = p + off; off += priv_len;
        w->check_priv_len[i] = priv_len;
    }
    return off == len;
}

bool field_bytes_from_be(const uint8_t be[32], uint8_t out[32]) {
    auto nat = proofs::Bip340Witness::nat_from_be_bytes(be);
    auto elt = proofs::p256k1_base.to_montgomery(nat);
    auto back = proofs::p256k1_base.from_montgomery(elt);
    if (!(back == nat)) return false;
    back.to_bytes(out);
    return true;
}

void field_bytes_from_elt(const proofs::Fp256k1Base& field,
                          const proofs::Fp256k1Base::Elt& elt,
                          uint8_t out[32]) {
    auto nat = field.from_montgomery(elt);
    nat.to_bytes(out);
}

bool expected_bip340_public(const uint8_t sig[64], const uint8_t pk[32],
                            const uint8_t *msg, size_t msg_len,
                            uint8_t out[kBip340PublicSize]) {
    if (msg_len != 32) return false;
    proofs::Bip340Witness witness(proofs::p256k1);
    if (!witness.compute(sig, pk, msg, msg_len)) return false;
    uint8_t rx[32];
    uint8_t px[32];
    uint8_t e[32];
    if (!field_bytes_from_be(sig, rx)) return false;
    if (!field_bytes_from_be(pk, px)) return false;
    field_bytes_from_elt(proofs::p256k1_base, proofs::p256k1_base.one(), out);
    memcpy(out + 32, rx, 32);
    memcpy(out + 64, px, 32);
    field_bytes_from_elt(proofs::p256k1_base, witness.e_, e);
    memcpy(out + 96, e, 32);
    return true;
}

void build_bip340_challenge_preimage(
    const uint8_t sig[64], const uint8_t pk[32],
    const uint8_t msg[32], uint8_t out[kBip340ChallengePreimageSize]) {
    static const char tag[] = "BIP0340/challenge";
    uint8_t tag_hash[32];
    proofs::SHA256 tag_sha;
    tag_sha.Update(reinterpret_cast<const uint8_t *>(tag), strlen(tag));
    tag_sha.DigestData(tag_hash);

    size_t off = 0;
    memcpy(out + off, tag_hash, 32); off += 32;
    memcpy(out + off, tag_hash, 32); off += 32;
    memcpy(out + off, sig, 32); off += 32;
    memcpy(out + off, pk, 32); off += 32;
    memcpy(out + off, msg, 32);
}

void compute_bip340_challenge(const uint8_t sig[64], const uint8_t pk[32],
                              const uint8_t msg[32], uint8_t out[32]) {
    uint8_t preimage[kBip340ChallengePreimageSize];
    build_bip340_challenge_preimage(sig, pk, msg, preimage);
    sha256_raw(preimage, sizeof(preimage), out);
}

bool validate_bip340_check(const uint8_t *pub, size_t pub_len,
                           const uint8_t *priv, size_t priv_len,
                           const uint8_t sig[64], const uint8_t pk[32],
                           const uint8_t *msg, size_t msg_len) {
    uint8_t expected[kBip340PublicSize];
    if (!expected_bip340_public(sig, pk, msg, msg_len, expected))
        return false;
    if (pub_len == kBip340PublicSize &&
        memcmp(pub, expected, kBip340PublicSize) != 0)
        return false;
    if (pub_len == kBip340FullPublicSize &&
        memcmp(pub, expected, kBip340FullPublicSize) != 0)
        return false;
    if (pub_len != kBip340PublicSize && pub_len != kBip340FullPublicSize)
        return false;
    return niwi_bip340_relation_validate(pub, pub_len, priv, priv_len) == 0;
}

bool validate_commitments(const Statement& st, const Witness& w) {
    uint8_t ck[32];
    if (niwi_pbsch_pedersen_h(ck) != 0) return false;
    if (memcmp(st.ck, ck, 32) != 0) return false;

    uint8_t c_msg[32];
    uint8_t s_msg[32];
    uint8_t phi[32];
    if (!encode_c_msg(w.m, w.alpha, w.beta, c_msg)) return false;
    encode_s_msg(w.sigma0, w.sigma1, w.nu_u, w.nu_u_prime, w.nu_s, s_msg);
    statement_phi(w, phi);
    if (memcmp(st.phi, phi, 32) != 0) return false;
    if (niwi_pbsch_pedersen_verify(st.C, c_msg, w.rho_c) != 0)
        return false;
    if (niwi_pbsch_pedersen_verify(st.S, s_msg, w.rho_s) != 0)
        return false;
    return true;
}

bool validate_selected_branch(const Statement& st, const Witness& w) {
    if (w.branch == kBranchHonest) {
        if (w.check_count != 2) return false;
        if (memcmp(w.sigma, st.R, 32) != 0) return false;
        uint8_t expected_c[32];
        uint8_t expected_x[32];
        if (!field_bytes_from_be(st.c, expected_c) ||
            !field_bytes_from_be(st.X, expected_x))
            return false;
        uint8_t expected_pub[kBip340PublicSize];
        if (!expected_bip340_public(w.sigma, st.X, w.m, 32, expected_pub))
            return false;
        if (memcmp(expected_pub + 64, expected_x, 32) != 0 ||
            memcmp(expected_pub + 96, expected_c, 32) != 0)
            return false;
        return validate_bip340_check(w.check_pub[0], w.check_pub_len[0],
                                     w.check_priv[0], w.check_priv_len[0],
                                     w.sigma, st.X, w.m, 32);
    }

    if (w.branch == kBranchTrapdoor) {
        if (w.check_count != 2) return false;
        uint8_t msg0[32];
        uint8_t msg1[32];
        tuple_message(w.nu_s, w.nu_u, msg0);
        tuple_message(w.nu_s, w.nu_u_prime, msg1);
        return validate_bip340_check(w.check_pub[0], w.check_pub_len[0],
                                     w.check_priv[0], w.check_priv_len[0],
                                     w.sigma0, st.X_prime, msg0, 32) &&
               validate_bip340_check(w.check_pub[1], w.check_pub_len[1],
                                     w.check_priv[1], w.check_priv_len[1],
                                     w.sigma1, st.X_prime, msg1, 32);
    }

    return false;
}

}  // namespace niwi::rpbsch

extern "C" int niwi_rpbsch_relation_validate(
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len) {
    niwi::rpbsch::Statement st;
    niwi::rpbsch::Witness w;
    if (!niwi::rpbsch::parse_statement(public_inputs, pub_len, &st))
        return -1;
    if (!niwi::rpbsch::parse_witness(private_inputs, priv_len, &w))
        return -1;
    if (!niwi::rpbsch::validate_commitments(st, w))
        return -1;
    return niwi::rpbsch::validate_selected_branch(st, w) ? 0 : -1;
}
