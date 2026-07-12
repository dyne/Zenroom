/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/rpbsch_ligero_relation.h"

#include "niwi.h"

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
#include "circuits/bip340/bip340_guard.h"
#include "circuits/bip340/bip340_witness.h"
#include "circuits/logic/bit_plucker_encoder.h"
#include "circuits/rpbsch/rpbsch_relation_circuit.h"
#include "circuits/sha/flatsha256_witness.h"
#include "ec/p256k1.h"
#include "pbsch_commitment.h"
#include "random/secure_random_engine.h"
#include "random/transcript.h"
#include "relations/rpbsch_relation.h"
#include "relations/rpbsch_relation_internal.h"
#include "sumcheck/prover_layers.h"
#include "util/crypto.h"
#include "util/readbuffer.h"
#include "zk/zk_proof.h"
#include "zk/zk_prover.h"
#include "zk/zk_verifier.h"

namespace {

using Field = proofs::Fp256k1Base;
using Point = proofs::P256k1::ECPoint;
using ShaBlockWitness = proofs::FlatSHA256Witness::BlockWitness;
using Crt = proofs::CRT256<Field>;
using ConvolutionFactory = proofs::CrtConvolutionFactory<Crt, Field>;
using RSFactory = proofs::ReedSolomonFactory<Field, ConvolutionFactory>;

constexpr size_t kEltBytes = 32;
constexpr size_t kLigeroRate = 4;
constexpr size_t kLigeroNreq = 128;

Field::N be32_to_nat(const uint8_t bytes[32]) {
    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) le[i] = bytes[31 - i];
    return Field::N::of_bytes(le);
}

Field::Elt field_from_be(const uint8_t bytes[32]) {
    return proofs::p256k1_base.to_montgomery(be32_to_nat(bytes));
}

bool decode_field(const uint8_t bytes[32], Field::Elt *out) {
    if (!out) return false;
    auto elt = field_from_be(bytes);
    Field::N back = proofs::p256k1_base.from_montgomery(elt);
    Field::N nat = be32_to_nat(bytes);
    if (!(nat == back)) return false;
    *out = elt;
    return true;
}

void fill_bits_msb(proofs::DenseFiller<Field>& filler, const Field::N& nat) {
    for (int i = 255; i >= 0; --i) {
        filler.push_back(proofs::p256k1_base.of_scalar(nat.bit(i) ? 1 : 0));
    }
}

void fill_byte(proofs::DenseFiller<Field>& filler, uint8_t byte) {
    filler.push_back(byte, 8, proofs::p256k1_base);
}

void fill_bytes(proofs::DenseFiller<Field>& filler, const uint8_t *bytes,
                size_t len) {
    for (size_t i = 0; i < len; ++i) fill_byte(filler, bytes[i]);
}

void fill_digest_target(proofs::DenseFiller<Field>& filler,
                        const uint8_t digest[32]) {
    for (size_t j = 0; j < 8; ++j) {
        const uint32_t word = proofs::SHA256_ru32be(digest + 4 * (7 - j));
        filler.push_back(word, 32, proofs::p256k1_base);
    }
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
void fill_sha_witness(proofs::DenseFiller<Field>& filler,
                      const uint8_t *preimage, size_t preimage_len) {
    uint8_t nblocks = 0;
    uint8_t padded[MaxBlocks * 64];
    ShaBlockWitness blocks[MaxBlocks];
    proofs::FlatSHA256Witness::transform_and_witness_message(
        preimage_len, preimage, MaxBlocks, nblocks, padded, blocks);
    for (size_t i = 0; i < MaxBlocks; ++i) fill_sha_block(filler, blocks[i]);
}

Field::Elt sqrt_even(const Field::Elt& y2) {
    Field::N exp("0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffff0c");
    Field::Elt root = proofs::p256k1_base.one();
    for (int i = 255; i >= 0; --i) {
        root = proofs::p256k1_base.mulf(root, root);
        if (exp.bit(i)) root = proofs::p256k1_base.mulf(root, y2);
    }
    Field::N nat = proofs::p256k1_base.from_montgomery(root);
    return nat.bit(0) ? proofs::p256k1_base.negf(root) : root;
}

Field::Elt compressed_y(uint8_t prefix, const uint8_t x_bytes[32]) {
    auto x = field_from_be(x_bytes);
    auto xx = proofs::p256k1_base.mulf(x, x);
    auto xxx = proofs::p256k1_base.mulf(x, xx);
    auto y2 = proofs::p256k1_base.addf(xxx, proofs::p256k1_base.of_scalar(7));
    auto y = sqrt_even(y2);
    return (prefix & 1u) ? proofs::p256k1_base.negf(y) : y;
}

Point h_point(void) {
    uint8_t h_x[32];
    if (niwi_pbsch_pedersen_h(h_x) != 0)
        return {proofs::p256k1_base.zero(), proofs::p256k1_base.one(),
                proofs::p256k1_base.zero()};
    return {field_from_be(h_x), compressed_y(0x02, h_x),
            proofs::p256k1_base.one()};
}

Point fill_scalar_mult_witness(proofs::DenseFiller<Field>& filler,
                               const Point& point, const Field::N& scalar) {
    const auto& F = proofs::p256k1_base;
    Point acc{F.zero(), F.one(), F.zero()};
    Field::Elt bits[256];
    Field::Elt int_x[256];
    Field::Elt int_y[256];
    Field::Elt int_z[256];
    for (size_t i = 0; i < 256; ++i) {
        const size_t bit_idx = 255 - i;
        const int bit = scalar.bit(bit_idx);
        bits[i] = F.of_scalar(bit);
        Point add = bit ? point : Point{F.zero(), F.one(), F.zero()};
        proofs::p256k1.doubleE(acc);
        proofs::p256k1.addE(acc, add);
        int_x[i] = acc.x;
        int_y[i] = acc.y;
        int_z[i] = acc.z;
    }
    for (size_t i = 0; i < 256; ++i) {
        filler.push_back(bits[i]);
        if (i < 255) {
            filler.push_back(int_x[i]);
            filler.push_back(int_y[i]);
            filler.push_back(int_z[i]);
        }
    }
    return {int_x[255], int_y[255], int_z[255]};
}

void fill_bip340_witness(proofs::DenseFiller<Field>& filler,
                         const proofs::Bip340Witness& w) {
    for (size_t i = 0; i < proofs::Bip340Witness::kBits; ++i) {
        filler.push_back(w.bits_s_[i]);
        if (i < proofs::Bip340Witness::kBits - 1) {
            filler.push_back(w.int_sx_[i]);
            filler.push_back(w.int_sy_[i]);
            filler.push_back(w.int_sz_[i]);
        }
    }
    for (size_t i = 0; i < proofs::Bip340Witness::kBits; ++i) {
        filler.push_back(w.bits_e_[i]);
        if (i < proofs::Bip340Witness::kBits - 1) {
            filler.push_back(w.int_ex_[i]);
            filler.push_back(w.int_ey_[i]);
            filler.push_back(w.int_ez_[i]);
        }
    }
    filler.push_back(w.py_);
    filler.push_back(w.ry_);
    filler.push_back(w.rz_inv_);
    for (size_t i = 0; i < proofs::Bip340Witness::kBits; ++i) {
        filler.push_back(w.bits_ry_[i]);
    }
}

void fill_pedersen_opening(proofs::DenseFiller<Field>& filler,
                           const uint8_t msg[32], const uint8_t rho[32]) {
    Point G{proofs::p256k1.gx_, proofs::p256k1.gy_, proofs::p256k1_base.one()};
    Point H = h_point();
    Point msg_g = fill_scalar_mult_witness(filler, G, be32_to_nat(msg));
    Point rho_h = fill_scalar_mult_witness(filler, H, be32_to_nat(rho));
    filler.push_back(msg_g.x);
    filler.push_back(msg_g.y);
    filler.push_back(msg_g.z);
    filler.push_back(rho_h.x);
    filler.push_back(rho_h.y);
    filler.push_back(rho_h.z);
    Point sum = msg_g;
    proofs::p256k1.addE(sum, rho_h);
    filler.push_back(proofs::p256k1_base.invertf(sum.z));
}

void fill_public_statement(const niwi::rpbsch::Statement& st,
                           proofs::Dense<Field> *pub) {
    proofs::DenseFiller<Field> f(*pub);
    f.push_back(proofs::p256k1_base.one());
    f.push_back(field_from_be(st.X));
    f.push_back(field_from_be(st.X_prime));
    f.push_back(field_from_be(st.R));
    f.push_back(field_from_be(st.c));
    f.push_back(proofs::p256k1_base.of_scalar(st.C[0]));
    f.push_back(field_from_be(st.C + 1));
    f.push_back(field_from_be(st.phi));
    f.push_back(field_from_be(st.ck));
    f.push_back(proofs::p256k1_base.of_scalar(st.S[0]));
    f.push_back(field_from_be(st.S + 1));
}

void fill_branch1_private(proofs::DenseFiller<Field>& wf,
                          const niwi::rpbsch::Statement& st,
                          const niwi::rpbsch::Witness& w) {
    uint8_t c_msg[32], s_msg[32], c_pre[niwi::rpbsch::kCMessagePreimageSize];
    uint8_t s_pre[niwi::rpbsch::kSMessagePreimageSize];
    uint8_t phi_pre[niwi::rpbsch::kStatementPhiPreimageSize];
    uint8_t bip_pre[niwi::rpbsch::kBip340ChallengePreimageSize];
    niwi::rpbsch::encode_c_msg(w.m, w.alpha, w.beta, c_msg);
    niwi::rpbsch::encode_s_msg(w.sigma0, w.sigma1, w.nu_u, w.nu_u_prime,
                               w.nu_s, s_msg);
    niwi::rpbsch::build_c_message_preimage(w.m, w.alpha, w.beta, c_pre);
    niwi::rpbsch::build_s_message_preimage(w.sigma0, w.sigma1, w.nu_u,
                                           w.nu_u_prime, w.nu_s, s_pre);
    niwi::rpbsch::build_statement_phi_preimage(
        w.m, w.alpha, w.beta, w.nu_s, w.nu_u, w.nu_u_prime, phi_pre);
    niwi::rpbsch::build_bip340_challenge_preimage(w.sigma, st.X, w.m, bip_pre);
    uint8_t c_digest[32], s_digest[32], phi_digest[32], bip_digest[32];
    proofs::SHA256 sha_c; sha_c.Update(c_pre, sizeof(c_pre)); sha_c.DigestData(c_digest);
    proofs::SHA256 sha_s; sha_s.Update(s_pre, sizeof(s_pre)); sha_s.DigestData(s_digest);
    proofs::SHA256 sha_phi; sha_phi.Update(phi_pre, sizeof(phi_pre)); sha_phi.DigestData(phi_digest);
    proofs::SHA256 sha_bip; sha_bip.Update(bip_pre, sizeof(bip_pre)); sha_bip.DigestData(bip_digest);
    proofs::Bip340Witness bip(proofs::p256k1);
    (void)bip.compute(w.sigma, st.X, w.m, 32);

    auto c_y = compressed_y(st.C[0], st.C + 1);
    wf.push_back(c_y); fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(c_y));
    auto s_y = compressed_y(st.S[0], st.S + 1);
    wf.push_back(s_y); fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(s_y));
    wf.push_back(field_from_be(w.m)); wf.push_back(field_from_be(w.alpha));
    wf.push_back(field_from_be(w.beta)); wf.push_back(field_from_be(w.rho_c));
    wf.push_back(field_from_be(w.rho_s)); wf.push_back(field_from_be(w.nu_s));
    wf.push_back(field_from_be(w.nu_u)); wf.push_back(field_from_be(w.nu_u_prime));
    wf.push_back(field_from_be(c_msg)); wf.push_back(field_from_be(s_msg));
    fill_bytes(wf, w.m, 32); fill_bytes(wf, w.alpha, 32);
    fill_bytes(wf, w.beta, 32); fill_bytes(wf, w.rho_c, 32);
    fill_bytes(wf, w.rho_s, 32); fill_bytes(wf, w.nu_s, 32);
    fill_bytes(wf, w.nu_u, 32); fill_bytes(wf, w.nu_u_prime, 32);
    fill_bytes(wf, st.R, 32); fill_bytes(wf, st.X, 32);
    fill_bytes(wf, w.sigma0, 64); fill_bytes(wf, w.sigma1, 64);
    fill_digest_target(wf, c_digest); fill_digest_target(wf, s_digest);
    fill_digest_target(wf, phi_digest);
    fill_sha_witness<2>(wf, c_pre, sizeof(c_pre));
    fill_sha_witness<4>(wf, s_pre, sizeof(s_pre));
    fill_sha_witness<4>(wf, phi_pre, sizeof(phi_pre));
    fill_digest_target(wf, bip_digest);
    fill_sha_witness<3>(wf, bip_pre, sizeof(bip_pre));
    fill_bip340_witness(wf, bip);
    fill_pedersen_opening(wf, c_msg, w.rho_c);
    fill_pedersen_opening(wf, s_msg, w.rho_s);
}

void fill_branch2_private(proofs::DenseFiller<Field>& wf,
                          const niwi::rpbsch::Statement& st,
                          const niwi::rpbsch::Witness& w) {
    uint8_t c_msg[32], s_msg[32], msg0[32], msg1[32];
    uint8_t c_pre[niwi::rpbsch::kCMessagePreimageSize];
    uint8_t s_pre[niwi::rpbsch::kSMessagePreimageSize];
    uint8_t phi_pre[niwi::rpbsch::kStatementPhiPreimageSize];
    uint8_t tuple0_pre[niwi::rpbsch::kTupleMessagePreimageSize];
    uint8_t tuple1_pre[niwi::rpbsch::kTupleMessagePreimageSize];
    uint8_t bip0_pre[niwi::rpbsch::kBip340ChallengePreimageSize];
    uint8_t bip1_pre[niwi::rpbsch::kBip340ChallengePreimageSize];
    niwi::rpbsch::encode_c_msg(w.m, w.alpha, w.beta, c_msg);
    niwi::rpbsch::encode_s_msg(w.sigma0, w.sigma1, w.nu_u, w.nu_u_prime,
                               w.nu_s, s_msg);
    niwi::rpbsch::tuple_message(w.nu_s, w.nu_u, msg0);
    niwi::rpbsch::tuple_message(w.nu_s, w.nu_u_prime, msg1);
    niwi::rpbsch::build_c_message_preimage(w.m, w.alpha, w.beta, c_pre);
    niwi::rpbsch::build_s_message_preimage(w.sigma0, w.sigma1, w.nu_u,
                                           w.nu_u_prime, w.nu_s, s_pre);
    niwi::rpbsch::build_statement_phi_preimage(
        w.m, w.alpha, w.beta, w.nu_s, w.nu_u, w.nu_u_prime, phi_pre);
    niwi::rpbsch::build_tuple_message_preimage(w.nu_s, w.nu_u, tuple0_pre);
    niwi::rpbsch::build_tuple_message_preimage(w.nu_s, w.nu_u_prime,
                                               tuple1_pre);
    niwi::rpbsch::build_bip340_challenge_preimage(w.sigma0, st.X_prime, msg0,
                                                  bip0_pre);
    niwi::rpbsch::build_bip340_challenge_preimage(w.sigma1, st.X_prime, msg1,
                                                  bip1_pre);
    uint8_t c_digest[32], s_digest[32], phi_digest[32], tuple0_digest[32];
    uint8_t tuple1_digest[32], bip0_digest[32], bip1_digest[32];
    proofs::SHA256 sha_c; sha_c.Update(c_pre, sizeof(c_pre)); sha_c.DigestData(c_digest);
    proofs::SHA256 sha_s; sha_s.Update(s_pre, sizeof(s_pre)); sha_s.DigestData(s_digest);
    proofs::SHA256 sha_phi; sha_phi.Update(phi_pre, sizeof(phi_pre)); sha_phi.DigestData(phi_digest);
    proofs::SHA256 sha_t0; sha_t0.Update(tuple0_pre, sizeof(tuple0_pre)); sha_t0.DigestData(tuple0_digest);
    proofs::SHA256 sha_t1; sha_t1.Update(tuple1_pre, sizeof(tuple1_pre)); sha_t1.DigestData(tuple1_digest);
    proofs::SHA256 sha_b0; sha_b0.Update(bip0_pre, sizeof(bip0_pre)); sha_b0.DigestData(bip0_digest);
    proofs::SHA256 sha_b1; sha_b1.Update(bip1_pre, sizeof(bip1_pre)); sha_b1.DigestData(bip1_digest);
    proofs::Bip340Witness bip0(proofs::p256k1), bip1(proofs::p256k1);
    (void)bip0.compute(w.sigma0, st.X_prime, msg0, 32);
    (void)bip1.compute(w.sigma1, st.X_prime, msg1, 32);

    auto c_y = compressed_y(st.C[0], st.C + 1);
    wf.push_back(c_y); fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(c_y));
    auto s_y = compressed_y(st.S[0], st.S + 1);
    wf.push_back(s_y); fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(s_y));
    wf.push_back(field_from_be(w.m)); wf.push_back(field_from_be(w.alpha));
    wf.push_back(field_from_be(w.beta)); wf.push_back(field_from_be(w.rho_c));
    wf.push_back(field_from_be(w.rho_s)); wf.push_back(field_from_be(w.nu_s));
    wf.push_back(field_from_be(w.nu_u)); wf.push_back(field_from_be(w.nu_u_prime));
    wf.push_back(field_from_be(c_msg)); wf.push_back(field_from_be(s_msg));
    wf.push_back(field_from_be(msg0)); wf.push_back(field_from_be(msg1));
    wf.push_back(field_from_be(w.sigma0)); wf.push_back(field_from_be(w.sigma1));
    wf.push_back(bip0.e_); wf.push_back(bip1.e_);
    fill_bytes(wf, w.m, 32); fill_bytes(wf, w.alpha, 32);
    fill_bytes(wf, w.beta, 32); fill_bytes(wf, w.rho_c, 32);
    fill_bytes(wf, w.rho_s, 32); fill_bytes(wf, w.nu_s, 32);
    fill_bytes(wf, w.nu_u, 32); fill_bytes(wf, w.nu_u_prime, 32);
    fill_bytes(wf, st.X_prime, 32); fill_bytes(wf, msg0, 32);
    fill_bytes(wf, msg1, 32); fill_bytes(wf, w.sigma0, 64);
    fill_bytes(wf, w.sigma1, 64);
    fill_digest_target(wf, c_digest); fill_digest_target(wf, s_digest);
    fill_digest_target(wf, phi_digest); fill_digest_target(wf, tuple0_digest);
    fill_digest_target(wf, tuple1_digest); fill_digest_target(wf, bip0_digest);
    fill_digest_target(wf, bip1_digest);
    fill_sha_witness<2>(wf, c_pre, sizeof(c_pre));
    fill_sha_witness<4>(wf, s_pre, sizeof(s_pre));
    fill_sha_witness<4>(wf, phi_pre, sizeof(phi_pre));
    fill_sha_witness<2>(wf, tuple0_pre, sizeof(tuple0_pre));
    fill_sha_witness<2>(wf, tuple1_pre, sizeof(tuple1_pre));
    fill_sha_witness<3>(wf, bip0_pre, sizeof(bip0_pre));
    fill_sha_witness<3>(wf, bip1_pre, sizeof(bip1_pre));
    fill_bip340_witness(wf, bip0); fill_bip340_witness(wf, bip1);
    fill_pedersen_opening(wf, c_msg, w.rho_c);
    fill_pedersen_opening(wf, s_msg, w.rho_s);
}

bool fill_selector_witness(const niwi::rpbsch::Statement& st,
                           const niwi::rpbsch::Witness& w,
                           const proofs::Circuit<Field>& circuit,
                           proofs::Dense<Field> *witness,
                           proofs::Dense<Field> *pub) {
    if (!witness || !pub) return false;
    fill_public_statement(st, pub);
    proofs::DenseFiller<Field> wf(*witness);
    for (size_t i = 0; i < pub->n1_; ++i) wf.push_back(pub->v_[i]);
    wf.push_back(proofs::p256k1_base.of_scalar(w.branch));
    fill_branch1_private(wf, st, w);
    fill_branch2_private(wf, st, w);
    return wf.size() == circuit.ninputs;
}

bool evaluate_dense(const proofs::Circuit<Field>& circuit,
                    const proofs::Dense<Field>& witness) {
    proofs::ProverLayers<Field> layers(proofs::p256k1_base);
    proofs::ProverLayers<Field>::inputs inputs;
    auto final = layers.eval_circuit(&inputs, &circuit, witness.clone(),
                                     proofs::p256k1_base);
    if (final == nullptr) return false;
    for (size_t i = 0; i < final->n0_ * final->n1_; ++i) {
        if (final->v_[i] != proofs::p256k1_base.zero()) return false;
    }
    return true;
}

bool build_ligero_context(std::unique_ptr<proofs::Circuit<Field>> *circuit,
                          size_t *block_enc,
                          std::unique_ptr<ConvolutionFactory> *factory,
                          std::unique_ptr<RSFactory> *rsf) {
    if (!circuit || !block_enc || !factory || !rsf) return false;
    *circuit = niwi::rpbsch::build_rpbsch_selector_circuit();
    if (!*circuit || (*circuit)->npub_in != 11) return false;
    *block_enc = (*circuit)->ninputs - (*circuit)->npub_in +
                 (*circuit)->nc + 1;
    if (!proofs::check_crt_block_enc<Crt>(*block_enc).empty()) return false;
    *factory = std::make_unique<ConvolutionFactory>(proofs::p256k1_base);
    *rsf = std::make_unique<RSFactory>(**factory, proofs::p256k1_base);
    return true;
}

}  // namespace

extern "C" int niwi_rpbsch_ligero_prove(
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len,
    uint8_t **proof_out, size_t *proof_len) {
    if (!public_inputs || !private_inputs || !proof_out || !proof_len)
        return -1;
    *proof_out = nullptr;
    *proof_len = 0;
    niwi::rpbsch::Statement st;
    niwi::rpbsch::Witness w;
    if (!niwi::rpbsch::parse_statement(public_inputs, pub_len, &st) ||
        !niwi::rpbsch::parse_witness(private_inputs, priv_len, &w) ||
        niwi_rpbsch_relation_validate(public_inputs, pub_len,
                                      private_inputs, priv_len) != 0)
        return -1;

    std::unique_ptr<proofs::Circuit<Field>> circuit;
    std::unique_ptr<ConvolutionFactory> factory;
    std::unique_ptr<RSFactory> rsf;
    size_t block_enc = 0;
    if (!build_ligero_context(&circuit, &block_enc, &factory, &rsf))
            return -1;
        proofs::Dense<Field> witness(1, circuit->ninputs);
        proofs::Dense<Field> pub(1, circuit->npub_in);
        if (!fill_selector_witness(st, w, *circuit, &witness, &pub) ||
            !evaluate_dense(*circuit, witness))
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
        uint8_t *out = static_cast<uint8_t *>(malloc(serialized.size()));
        if (!out) return -1;
        memcpy(out, serialized.data(), serialized.size());
        *proof_out = out;
        *proof_len = serialized.size();
        return 0;
}

extern "C" int niwi_rpbsch_ligero_verify(
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *proof, size_t proof_len) {
    if (!public_inputs || !proof || proof_len <= 32) return -1;
    niwi::rpbsch::Statement st;
    if (!niwi::rpbsch::parse_statement(public_inputs, pub_len, &st))
        return -1;

    std::unique_ptr<proofs::Circuit<Field>> circuit;
    std::unique_ptr<ConvolutionFactory> factory;
    std::unique_ptr<RSFactory> rsf;
    size_t block_enc = 0;
    if (!build_ligero_context(&circuit, &block_enc, &factory, &rsf))
            return -1;
        proofs::Dense<Field> pub(1, circuit->npub_in);
        fill_public_statement(st, &pub);

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
}
