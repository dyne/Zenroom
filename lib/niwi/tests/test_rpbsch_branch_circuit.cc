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
#include "circuits/bip340/bip340_witness.h"
#include "circuits/logic/bit_plucker_encoder.h"
#include "circuits/rpbsch/rpbsch_relation_circuit.h"
#include "circuits/sha/flatsha256_witness.h"
#include "ec/p256k1.h"
#include "pbsch_commitment.h"
#include "relations/rpbsch_relation_internal.h"
#include "sumcheck/prover_layers.h"

namespace {

using Field = proofs::Fp256k1Base;
using Point = proofs::P256k1::ECPoint;
using ShaBlockWitness = proofs::FlatSHA256Witness::BlockWitness;

struct Fixture {
    uint8_t X[32];
    uint8_t X_prime[32];
    uint8_t m[32];
    uint8_t alpha[32];
    uint8_t beta[32];
    uint8_t rho_c[32];
    uint8_t rho_s[32];
    uint8_t nu_s[32];
    uint8_t nu_u[32];
    uint8_t nu_u_prime[32];
    uint8_t sigma[64];
    uint8_t sigma0[64];
    uint8_t sigma1[64];
    uint8_t R[32];
    uint8_t c[32];
    uint8_t C[33];
    uint8_t phi[32];
    uint8_t ck[32];
    uint8_t S[33];
};

int hex_nibble(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

template <size_t N>
void hex_to(const char *hex, uint8_t (&out)[N]) {
    assert(strlen(hex) == 2 * N);
    for (size_t i = 0; i < N; ++i) {
        int hi = hex_nibble(hex[2 * i]);
        int lo = hex_nibble(hex[2 * i + 1]);
        assert(hi >= 0 && lo >= 0);
        out[i] = static_cast<uint8_t>((hi << 4) | lo);
    }
}

Fixture fixture(void) {
    Fixture f{};
    hex_to("f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9", f.X);
    hex_to("dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659", f.X_prime);
    hex_to("dda81918e97215a795cbfa08384dffe06581e00208e5fa4917d3aa5ade7a305d", f.m);
    hex_to("e0a597a8a97746535e857f4adfb231a8db6046e5a37059fae94d56dd9cfb919c", f.alpha);
    hex_to("805bfca959effe24b79b936a5bd5ed54f68f7623a79ddd2ae38ab53d21655583", f.beta);
    hex_to("5150f55f07efd57972efec870468ea6c9e6da30d17748aa68085eee5f63fde33", f.rho_c);
    hex_to("c7c0eeba651adcb12b9f2afe780cfe6c4a764590a2faeb72735a303b92bd0150", f.rho_s);
    hex_to("ce70b6102bfb81dcdc408007c6c88f3e0a57a3e76add9801c0dceb5e07c7c23a", f.nu_s);
    hex_to("4cb6389a76e1132d7d8bf77a9460737b4491e17047b73d89ab03d61448c85c53", f.nu_u);
    hex_to("1866629c7598419c027842f55946be61b0e32c95f5eeaba23968e44779c3abea", f.nu_u_prime);
    hex_to("46f52f2a7f703d25fdbdf5900a6dc3ce116712a8af525dfd8c99f8915cf99ade"
           "b41f580ab787fec2df65775dd3675dfdec8b9500ed653605f154753b355f3985", f.sigma);
    hex_to("207803880c484f08b689d97cc117063f74b1bad588863e442a57361ec5ad6c83"
           "420a05235404f71100752d8f843e06f6c42a3a8b49a3793dc5199eed9c157faf", f.sigma0);
    hex_to("3c5a84b982b6b781f64b27e3c14750ffbf9e8b5a2545d2b3462519097d226718"
           "356ae521203a6ce3d6b44d06fbf73a977cab670e80c2bb4f6a85335481f9e888", f.sigma1);
    hex_to("46f52f2a7f703d25fdbdf5900a6dc3ce116712a8af525dfd8c99f8915cf99ade", f.R);
    hex_to("75d5a3f8f7cc132edf447d8f94ddc8b68f5bcca1c4d9225ff5519ff5b490f4e3", f.c);
    hex_to("0254a72c03e0b389196f79609e3984ea7172cc5038782c55c8f156959b4137ebf6", f.C);
    hex_to("8893ae505a90921b98606be66a15a2ff06e47351e81b05d9a605b990554a3dde", f.phi);
    hex_to("6f1e9359c07a77413e4f328b28ce411b7e0c1d8c4c1eda89dd75217b4c07abdf", f.ck);
    hex_to("026565c422f5b0d689127c9e9b390050ee6e58b2095ded12c0b2fb88fab97677e1", f.S);
    return f;
}

Field::N be32_to_nat(const uint8_t bytes[32]) {
    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) le[i] = bytes[31 - i];
    return Field::N::of_bytes(le);
}

Field::Elt field_from_be(const uint8_t bytes[32]) {
    return proofs::p256k1_base.to_montgomery(be32_to_nat(bytes));
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
    assert(nblocks == MaxBlocks);
    for (size_t i = 0; i < MaxBlocks; ++i) {
        fill_sha_block(filler, blocks[i]);
    }
}

Field::Elt sqrt_even(const Field::Elt& y2) {
    Field::N exp("0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffff0c");
    Field::Elt root = proofs::p256k1_base.one();
    Field::Elt base = y2;
    for (int i = 255; i >= 0; --i) {
        root = proofs::p256k1_base.mulf(root, root);
        if (exp.bit(i)) root = proofs::p256k1_base.mulf(root, base);
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
    if ((prefix & 1u) != 0) y = proofs::p256k1_base.negf(y);
    assert(proofs::p256k1_base.mulf(y, y) == y2);
    return y;
}

Point h_point(void) {
    uint8_t h_x[32];
    assert(niwi_pbsch_pedersen_h(h_x) == 0);
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
                           const uint8_t msg[32],
                           const uint8_t rho[32]) {
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

bool evaluates(const proofs::Circuit<Field>& circuit,
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

void fill_branch1_inputs(const Fixture& f, proofs::Dense<Field> *witness,
                         proofs::Dense<Field> *pub) {
    uint8_t c_msg[32];
    uint8_t s_msg[32];
    uint8_t c_preimage[niwi::rpbsch::kCMessagePreimageSize];
    uint8_t s_preimage[niwi::rpbsch::kSMessagePreimageSize];
    uint8_t phi_preimage[niwi::rpbsch::kStatementPhiPreimageSize];
    uint8_t bip_preimage[niwi::rpbsch::kBip340ChallengePreimageSize];
    niwi::rpbsch::encode_c_msg(f.m, f.alpha, f.beta, c_msg);
    niwi::rpbsch::encode_s_msg(f.sigma0, f.sigma1, f.nu_u, f.nu_u_prime,
                               f.nu_s, s_msg);
    niwi::rpbsch::build_c_message_preimage(f.m, f.alpha, f.beta, c_preimage);
    niwi::rpbsch::build_s_message_preimage(f.sigma0, f.sigma1, f.nu_u,
                                           f.nu_u_prime, f.nu_s, s_preimage);
    niwi::rpbsch::build_statement_phi_preimage(
        f.m, f.alpha, f.beta, f.nu_s, f.nu_u, f.nu_u_prime, phi_preimage);
    niwi::rpbsch::build_bip340_challenge_preimage(f.sigma, f.X, f.m,
                                                  bip_preimage);

    proofs::SHA256 sha;
    uint8_t c_digest[32];
    uint8_t s_digest[32];
    uint8_t phi_digest[32];
    uint8_t bip_digest[32];
    sha.Update(c_preimage, sizeof(c_preimage)); sha.DigestData(c_digest);
    proofs::SHA256 sha_s;
    sha_s.Update(s_preimage, sizeof(s_preimage)); sha_s.DigestData(s_digest);
    proofs::SHA256 sha_phi;
    sha_phi.Update(phi_preimage, sizeof(phi_preimage));
    sha_phi.DigestData(phi_digest);
    proofs::SHA256 sha_bip;
    sha_bip.Update(bip_preimage, sizeof(bip_preimage));
    sha_bip.DigestData(bip_digest);
    assert(memcmp(c_msg, c_digest, 32) == 0);
    assert(memcmp(s_msg, s_digest, 32) == 0);
    assert(memcmp(f.phi, phi_digest, 32) == 0);

    proofs::Bip340Witness bip(proofs::p256k1);
    assert(bip.compute(f.sigma, f.X, f.m, 32));

    proofs::DenseFiller<Field> pub_filler(*pub);
    pub_filler.push_back(proofs::p256k1_base.one());
    pub_filler.push_back(field_from_be(f.X));
    pub_filler.push_back(field_from_be(f.X_prime));
    pub_filler.push_back(field_from_be(f.R));
    pub_filler.push_back(field_from_be(f.c));
    pub_filler.push_back(proofs::p256k1_base.of_scalar(f.C[0]));
    pub_filler.push_back(field_from_be(f.C + 1));
    pub_filler.push_back(field_from_be(f.phi));
    pub_filler.push_back(field_from_be(f.ck));
    pub_filler.push_back(proofs::p256k1_base.of_scalar(f.S[0]));
    pub_filler.push_back(field_from_be(f.S + 1));
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> wf(*witness);
    for (size_t i = 0; i < pub->n1_; ++i) wf.push_back(pub->v_[i]);
    auto c_y = compressed_y(f.C[0], f.C + 1);
    wf.push_back(c_y);
    fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(c_y));
    auto s_y = compressed_y(f.S[0], f.S + 1);
    wf.push_back(s_y);
    fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(s_y));
    wf.push_back(field_from_be(f.m));
    wf.push_back(field_from_be(f.alpha));
    wf.push_back(field_from_be(f.beta));
    wf.push_back(field_from_be(f.rho_c));
    wf.push_back(field_from_be(f.rho_s));
    wf.push_back(field_from_be(f.nu_s));
    wf.push_back(field_from_be(f.nu_u));
    wf.push_back(field_from_be(f.nu_u_prime));
    wf.push_back(field_from_be(c_msg));
    wf.push_back(field_from_be(s_msg));
    fill_bytes(wf, f.m, 32);
    fill_bytes(wf, f.alpha, 32);
    fill_bytes(wf, f.beta, 32);
    fill_bytes(wf, f.rho_c, 32);
    fill_bytes(wf, f.rho_s, 32);
    fill_bytes(wf, f.nu_s, 32);
    fill_bytes(wf, f.nu_u, 32);
    fill_bytes(wf, f.nu_u_prime, 32);
    fill_bytes(wf, f.R, 32);
    fill_bytes(wf, f.X, 32);
    fill_bytes(wf, f.sigma0, 64);
    fill_bytes(wf, f.sigma1, 64);
    fill_digest_target(wf, c_digest);
    fill_digest_target(wf, s_digest);
    fill_digest_target(wf, phi_digest);
    fill_sha_witness<2>(wf, c_preimage, sizeof(c_preimage));
    fill_sha_witness<4>(wf, s_preimage, sizeof(s_preimage));
    fill_sha_witness<4>(wf, phi_preimage, sizeof(phi_preimage));
    fill_digest_target(wf, bip_digest);
    fill_sha_witness<3>(wf, bip_preimage, sizeof(bip_preimage));
    fill_bip340_witness(wf, bip);
    fill_pedersen_opening(wf, c_msg, f.rho_c);
    fill_pedersen_opening(wf, s_msg, f.rho_s);
    assert(wf.size() == witness->n1_);
}

void fill_branch2_inputs(const Fixture& f, proofs::Dense<Field> *witness,
                         proofs::Dense<Field> *pub) {
    uint8_t c_msg[32];
    uint8_t s_msg[32];
    uint8_t msg0[32];
    uint8_t msg1[32];
    uint8_t c_preimage[niwi::rpbsch::kCMessagePreimageSize];
    uint8_t s_preimage[niwi::rpbsch::kSMessagePreimageSize];
    uint8_t phi_preimage[niwi::rpbsch::kStatementPhiPreimageSize];
    uint8_t tuple0_preimage[niwi::rpbsch::kTupleMessagePreimageSize];
    uint8_t tuple1_preimage[niwi::rpbsch::kTupleMessagePreimageSize];
    uint8_t bip0_preimage[niwi::rpbsch::kBip340ChallengePreimageSize];
    uint8_t bip1_preimage[niwi::rpbsch::kBip340ChallengePreimageSize];
    niwi::rpbsch::encode_c_msg(f.m, f.alpha, f.beta, c_msg);
    niwi::rpbsch::encode_s_msg(f.sigma0, f.sigma1, f.nu_u, f.nu_u_prime,
                               f.nu_s, s_msg);
    niwi::rpbsch::tuple_message(f.nu_s, f.nu_u, msg0);
    niwi::rpbsch::tuple_message(f.nu_s, f.nu_u_prime, msg1);
    niwi::rpbsch::build_c_message_preimage(f.m, f.alpha, f.beta, c_preimage);
    niwi::rpbsch::build_s_message_preimage(f.sigma0, f.sigma1, f.nu_u,
                                           f.nu_u_prime, f.nu_s, s_preimage);
    niwi::rpbsch::build_statement_phi_preimage(
        f.m, f.alpha, f.beta, f.nu_s, f.nu_u, f.nu_u_prime, phi_preimage);
    niwi::rpbsch::build_tuple_message_preimage(f.nu_s, f.nu_u,
                                               tuple0_preimage);
    niwi::rpbsch::build_tuple_message_preimage(f.nu_s, f.nu_u_prime,
                                               tuple1_preimage);
    niwi::rpbsch::build_bip340_challenge_preimage(f.sigma0, f.X_prime, msg0,
                                                  bip0_preimage);
    niwi::rpbsch::build_bip340_challenge_preimage(f.sigma1, f.X_prime, msg1,
                                                  bip1_preimage);

    uint8_t c_digest[32];
    uint8_t s_digest[32];
    uint8_t phi_digest[32];
    uint8_t tuple0_digest[32];
    uint8_t tuple1_digest[32];
    uint8_t bip0_digest[32];
    uint8_t bip1_digest[32];
    proofs::SHA256 sha_c; sha_c.Update(c_preimage, sizeof(c_preimage)); sha_c.DigestData(c_digest);
    proofs::SHA256 sha_s; sha_s.Update(s_preimage, sizeof(s_preimage)); sha_s.DigestData(s_digest);
    proofs::SHA256 sha_phi; sha_phi.Update(phi_preimage, sizeof(phi_preimage)); sha_phi.DigestData(phi_digest);
    proofs::SHA256 sha_t0; sha_t0.Update(tuple0_preimage, sizeof(tuple0_preimage)); sha_t0.DigestData(tuple0_digest);
    proofs::SHA256 sha_t1; sha_t1.Update(tuple1_preimage, sizeof(tuple1_preimage)); sha_t1.DigestData(tuple1_digest);
    proofs::SHA256 sha_b0; sha_b0.Update(bip0_preimage, sizeof(bip0_preimage)); sha_b0.DigestData(bip0_digest);
    proofs::SHA256 sha_b1; sha_b1.Update(bip1_preimage, sizeof(bip1_preimage)); sha_b1.DigestData(bip1_digest);
    assert(memcmp(c_msg, c_digest, 32) == 0);
    assert(memcmp(s_msg, s_digest, 32) == 0);
    assert(memcmp(msg0, tuple0_digest, 32) == 0);
    assert(memcmp(msg1, tuple1_digest, 32) == 0);

    proofs::Bip340Witness bip0(proofs::p256k1);
    proofs::Bip340Witness bip1(proofs::p256k1);
    assert(bip0.compute(f.sigma0, f.X_prime, msg0, 32));
    assert(bip1.compute(f.sigma1, f.X_prime, msg1, 32));

    proofs::DenseFiller<Field> pub_filler(*pub);
    pub_filler.push_back(proofs::p256k1_base.one());
    pub_filler.push_back(field_from_be(f.X));
    pub_filler.push_back(field_from_be(f.X_prime));
    pub_filler.push_back(field_from_be(f.R));
    pub_filler.push_back(field_from_be(f.c));
    pub_filler.push_back(proofs::p256k1_base.of_scalar(f.C[0]));
    pub_filler.push_back(field_from_be(f.C + 1));
    pub_filler.push_back(field_from_be(f.phi));
    pub_filler.push_back(field_from_be(f.ck));
    pub_filler.push_back(proofs::p256k1_base.of_scalar(f.S[0]));
    pub_filler.push_back(field_from_be(f.S + 1));
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> wf(*witness);
    for (size_t i = 0; i < pub->n1_; ++i) wf.push_back(pub->v_[i]);
    auto c_y = compressed_y(f.C[0], f.C + 1);
    wf.push_back(c_y);
    fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(c_y));
    auto s_y = compressed_y(f.S[0], f.S + 1);
    wf.push_back(s_y);
    fill_bits_msb(wf, proofs::p256k1_base.from_montgomery(s_y));
    wf.push_back(field_from_be(f.m));
    wf.push_back(field_from_be(f.alpha));
    wf.push_back(field_from_be(f.beta));
    wf.push_back(field_from_be(f.rho_c));
    wf.push_back(field_from_be(f.rho_s));
    wf.push_back(field_from_be(f.nu_s));
    wf.push_back(field_from_be(f.nu_u));
    wf.push_back(field_from_be(f.nu_u_prime));
    wf.push_back(field_from_be(c_msg));
    wf.push_back(field_from_be(s_msg));
    wf.push_back(field_from_be(msg0));
    wf.push_back(field_from_be(msg1));
    wf.push_back(field_from_be(f.sigma0));
    wf.push_back(field_from_be(f.sigma1));
    wf.push_back(bip0.e_);
    wf.push_back(bip1.e_);
    fill_bytes(wf, f.m, 32);
    fill_bytes(wf, f.alpha, 32);
    fill_bytes(wf, f.beta, 32);
    fill_bytes(wf, f.rho_c, 32);
    fill_bytes(wf, f.rho_s, 32);
    fill_bytes(wf, f.nu_s, 32);
    fill_bytes(wf, f.nu_u, 32);
    fill_bytes(wf, f.nu_u_prime, 32);
    fill_bytes(wf, f.X_prime, 32);
    fill_bytes(wf, msg0, 32);
    fill_bytes(wf, msg1, 32);
    fill_bytes(wf, f.sigma0, 64);
    fill_bytes(wf, f.sigma1, 64);
    fill_digest_target(wf, c_digest);
    fill_digest_target(wf, s_digest);
    fill_digest_target(wf, phi_digest);
    fill_digest_target(wf, tuple0_digest);
    fill_digest_target(wf, tuple1_digest);
    fill_digest_target(wf, bip0_digest);
    fill_digest_target(wf, bip1_digest);
    fill_sha_witness<2>(wf, c_preimage, sizeof(c_preimage));
    fill_sha_witness<4>(wf, s_preimage, sizeof(s_preimage));
    fill_sha_witness<4>(wf, phi_preimage, sizeof(phi_preimage));
    fill_sha_witness<2>(wf, tuple0_preimage, sizeof(tuple0_preimage));
    fill_sha_witness<2>(wf, tuple1_preimage, sizeof(tuple1_preimage));
    fill_sha_witness<3>(wf, bip0_preimage, sizeof(bip0_preimage));
    fill_sha_witness<3>(wf, bip1_preimage, sizeof(bip1_preimage));
    fill_bip340_witness(wf, bip0);
    fill_bip340_witness(wf, bip1);
    fill_pedersen_opening(wf, c_msg, f.rho_c);
    fill_pedersen_opening(wf, s_msg, f.rho_s);
    assert(wf.size() == witness->n1_);
}

void fill_selector_inputs(const Fixture& f, uint8_t selector,
                          proofs::Dense<Field> *witness,
                          proofs::Dense<Field> *pub,
                          size_t *branch2_offset) {
    auto branch1_circuit = niwi::rpbsch::build_rpbsch_branch1_circuit();
    auto branch2_circuit = niwi::rpbsch::build_rpbsch_branch2_circuit();
    proofs::Dense<Field> branch1_witness(1, branch1_circuit->ninputs);
    proofs::Dense<Field> branch1_pub(1, branch1_circuit->npub_in);
    proofs::Dense<Field> branch2_witness(1, branch2_circuit->ninputs);
    proofs::Dense<Field> branch2_pub(1, branch2_circuit->npub_in);
    fill_branch1_inputs(f, &branch1_witness, &branch1_pub);
    fill_branch2_inputs(f, &branch2_witness, &branch2_pub);
    assert(branch1_pub.n1_ == pub->n1_);
    assert(branch2_pub.n1_ == pub->n1_);
    for (size_t i = 0; i < pub->n1_; ++i) {
        assert(branch1_pub.v_[i] == branch2_pub.v_[i]);
    }

    proofs::DenseFiller<Field> pub_filler(*pub);
    for (size_t i = 0; i < branch1_pub.n1_; ++i) {
        pub_filler.push_back(branch1_pub.v_[i]);
    }
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> wf(*witness);
    for (size_t i = 0; i < pub->n1_; ++i) wf.push_back(pub->v_[i]);
    wf.push_back(proofs::p256k1_base.of_scalar(selector));
    for (size_t i = branch1_circuit->npub_in; i < branch1_witness.n1_; ++i) {
        wf.push_back(branch1_witness.v_[i]);
    }
    if (branch2_offset) *branch2_offset = wf.size();
    for (size_t i = branch2_circuit->npub_in; i < branch2_witness.n1_; ++i) {
        wf.push_back(branch2_witness.v_[i]);
    }
    assert(wf.size() == witness->n1_);
}

void test_branch1_circuit_shape(void) {
    auto circuit = niwi::rpbsch::build_rpbsch_branch1_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 11);
    assert(circuit->ninputs > circuit->npub_in);
    std::printf("  PASS test_branch1_circuit_shape\n");
}

void test_branch2_circuit_shape(void) {
    auto circuit = niwi::rpbsch::build_rpbsch_branch2_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 11);
    assert(circuit->ninputs > circuit->npub_in);
    std::printf("  PASS test_branch2_circuit_shape\n");
}

void test_selector_circuit_shape(void) {
    auto circuit = niwi::rpbsch::build_rpbsch_selector_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 11);
    assert(circuit->ninputs > circuit->npub_in);
    std::printf("  PASS test_selector_circuit_shape\n");
}

void test_branch1_valid_and_negative_statement_fields(void) {
    auto circuit = niwi::rpbsch::build_rpbsch_branch1_circuit();
    Fixture f = fixture();

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    fill_branch1_inputs(f, &witness, &pub);
    assert(evaluates(*circuit, witness));

    auto bad_x = witness.clone();
    bad_x->v_[1] = proofs::p256k1_base.addf(bad_x->v_[1],
                                            proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_x));

    auto bad_r = witness.clone();
    bad_r->v_[3] = proofs::p256k1_base.addf(bad_r->v_[3],
                                            proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_r));

    auto bad_c = witness.clone();
    bad_c->v_[4] = proofs::p256k1_base.addf(bad_c->v_[4],
                                            proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_c));

    auto bad_C = witness.clone();
    bad_C->v_[6] = proofs::p256k1_base.addf(bad_C->v_[6],
                                            proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_C));

    auto bad_phi = witness.clone();
    bad_phi->v_[7] = proofs::p256k1_base.addf(bad_phi->v_[7],
                                              proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_phi));

    auto bad_S = witness.clone();
    bad_S->v_[10] = proofs::p256k1_base.addf(bad_S->v_[10],
                                             proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_S));

    std::printf("  PASS test_branch1_valid_and_negative_statement_fields\n");
}

void test_branch2_valid_and_negative_statement_fields(void) {
    auto circuit = niwi::rpbsch::build_rpbsch_branch2_circuit();
    Fixture f = fixture();

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    fill_branch2_inputs(f, &witness, &pub);
    assert(evaluates(*circuit, witness));

    auto bad_x_prime = witness.clone();
    bad_x_prime->v_[2] = proofs::p256k1_base.addf(
        bad_x_prime->v_[2], proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_x_prime));

    auto bad_S = witness.clone();
    bad_S->v_[10] = proofs::p256k1_base.addf(bad_S->v_[10],
                                             proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_S));

    Fixture bad_nu = f;
    bad_nu.nu_u[31] ^= 1u;
    proofs::Dense<Field> bad_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_pub(1, circuit->npub_in);
    fill_branch2_inputs(bad_nu, &bad_witness, &bad_pub);
    assert(!evaluates(*circuit, bad_witness));

    std::printf("  PASS test_branch2_valid_and_negative_statement_fields\n");
}

void test_selector_valid_and_rejects_bad_slots(void) {
    auto circuit = niwi::rpbsch::build_rpbsch_selector_circuit();
    Fixture f = fixture();

    size_t branch2_offset = 0;
    proofs::Dense<Field> selector1(1, circuit->ninputs);
    proofs::Dense<Field> pub1(1, circuit->npub_in);
    fill_selector_inputs(f, 1, &selector1, &pub1, &branch2_offset);
    assert(evaluates(*circuit, selector1));

    proofs::Dense<Field> selector2(1, circuit->ninputs);
    proofs::Dense<Field> pub2(1, circuit->npub_in);
    fill_selector_inputs(f, 2, &selector2, &pub2, nullptr);
    assert(evaluates(*circuit, selector2));

    proofs::Dense<Field> bad_selector(1, circuit->ninputs);
    proofs::Dense<Field> bad_selector_pub(1, circuit->npub_in);
    fill_selector_inputs(f, 3, &bad_selector, &bad_selector_pub, nullptr);
    assert(!evaluates(*circuit, bad_selector));

    auto bad_branch1 = selector1.clone();
    bad_branch1->v_[circuit->npub_in + 1] = proofs::p256k1_base.addf(
        bad_branch1->v_[circuit->npub_in + 1], proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_branch1));

    auto bad_branch2_padding = selector1.clone();
    bad_branch2_padding->v_[branch2_offset] = proofs::p256k1_base.addf(
        bad_branch2_padding->v_[branch2_offset], proofs::p256k1_base.one());
    assert(!evaluates(*circuit, *bad_branch2_padding));

    std::printf("  PASS test_selector_valid_and_rejects_bad_slots\n");
}

}  // namespace

int main(void) {
    std::printf("lib/niwi RPBSch branch circuit tests:\n");
    test_branch1_circuit_shape();
    test_branch2_circuit_shape();
    test_selector_circuit_shape();
    test_branch1_valid_and_negative_statement_fields();
    test_branch2_valid_and_negative_statement_fields();
    test_selector_valid_and_rejects_bad_slots();
    std::printf("All RPBSch branch circuit tests passed.\n");
    return 0;
}
