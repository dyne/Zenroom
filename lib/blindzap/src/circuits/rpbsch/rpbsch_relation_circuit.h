/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_CIRCUITS_RPBSCH_RELATION_CIRCUIT_H
#define NIWI_CIRCUITS_RPBSCH_RELATION_CIRCUIT_H

#include <cstddef>
#include <cstdint>
#include <array>
#include <memory>

#include "circuits/bip340/bip340_gadgets.h"
#include "circuits/bip340/bip340_verify.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/logic.h"
#include "circuits/rpbsch/rpbsch_hash_circuit.h"
#include "circuits/sha/flatsha256_circuit.h"
#include "ec/p256k1.h"
#include "pbsch_commitment.h"

namespace niwi::rpbsch {

template <class LogicCircuit, class BitPluckerT>
class RpbschRelationCircuit {
  using EltW = typename LogicCircuit::EltW;
  using v8 = typename LogicCircuit::v8;
  using v256 = typename LogicCircuit::v256;
  using FlatSha = proofs::FlatSHA256Circuit<LogicCircuit, BitPluckerT>;
  using Bip340Gadgets =
      proofs::Bip340Gadgets<LogicCircuit, proofs::Fp256k1Base,
                            proofs::P256k1>;
  using Bip340Verify =
      proofs::Bip340Verify<LogicCircuit, proofs::Fp256k1Base,
                           proofs::P256k1>;
  struct Point {
    EltW x;
    EltW y;
    EltW z;
  };

 public:
  static constexpr size_t kBits = 256;
  static constexpr size_t kCBlocks = 2;
  static constexpr size_t kSBlocks = 4;
  static constexpr size_t kPhiBlocks = 4;
  static constexpr size_t kBip340Blocks = 3;

  struct Bytes32 {
    v8 bytes[32];

    void input(const LogicCircuit& lc) {
      for (auto& b : bytes) {
        b = lc.template vinput<8>();
      }
    }
  };

  struct SignatureBytes {
    v8 bytes[64];

    void input(const LogicCircuit& lc) {
      for (auto& b : bytes) {
        b = lc.template vinput<8>();
      }
    }
  };

  struct Sha2Witness {
    typename FlatSha::BlockWitness blocks[2];

    void input(const LogicCircuit& lc) {
      for (auto& block : blocks) {
        block.input(lc);
      }
    }
  };

  struct Sha3Witness {
    typename FlatSha::BlockWitness blocks[3];

    void input(const LogicCircuit& lc) {
      for (auto& block : blocks) {
        block.input(lc);
      }
    }
  };

  struct Sha4Witness {
    typename FlatSha::BlockWitness blocks[4];

    void input(const LogicCircuit& lc) {
      for (auto& block : blocks) {
        block.input(lc);
      }
    }
  };

  struct ScalarMultWitness {
    EltW bits[kBits];
    EltW int_x[kBits];
    EltW int_y[kBits];
    EltW int_z[kBits];

    void input(const LogicCircuit& lc) {
      for (size_t i = 0; i < kBits; ++i) {
        bits[i] = lc.eltw_input();
        if (i < kBits - 1) {
          int_x[i] = lc.eltw_input();
          int_y[i] = lc.eltw_input();
          int_z[i] = lc.eltw_input();
        }
      }
    }
  };

  struct PedersenOpeningWitness {
    ScalarMultWitness msg;
    ScalarMultWitness rho;
    Point msg_point;
    Point rho_point;
    EltW sum_z_inv;

    void input(const LogicCircuit& lc) {
      msg.input(lc);
      rho.input(lc);
      msg_point = {lc.eltw_input(), lc.eltw_input(), lc.eltw_input()};
      rho_point = {lc.eltw_input(), lc.eltw_input(), lc.eltw_input()};
      sum_z_inv = lc.eltw_input();
    }
  };

  struct Branch1Witness {
    EltW c_y;
    EltW c_y_bits[kBits];
    EltW s_y;
    EltW s_y_bits[kBits];
    EltW m;
    EltW alpha;
    EltW beta;
    EltW rho_c;
    EltW rho_s;
    EltW nu_s;
    EltW nu_u;
    EltW nu_u_prime;
    EltW c_msg;
    EltW s_msg;
    Bytes32 m_bytes;
    Bytes32 alpha_bytes;
    Bytes32 beta_bytes;
    Bytes32 rho_c_bytes;
    Bytes32 rho_s_bytes;
    Bytes32 nu_s_bytes;
    Bytes32 nu_u_bytes;
    Bytes32 nu_u_prime_bytes;
    Bytes32 r_bytes;
    Bytes32 x_bytes;
    SignatureBytes sigma0;
    SignatureBytes sigma1;
    v256 c_digest;
    v256 s_digest;
    v256 phi_digest;
    Sha2Witness c_sha;
    Sha4Witness s_sha;
    Sha4Witness phi_sha;
    v256 bip340_digest;
    Sha3Witness bip340_sha;
    typename Bip340Verify::Witness bip340;
    PedersenOpeningWitness c_opening;
    PedersenOpeningWitness s_opening;

    void input(const LogicCircuit& lc) {
      c_y = lc.eltw_input();
      for (auto& bit : c_y_bits) bit = lc.eltw_input();
      s_y = lc.eltw_input();
      for (auto& bit : s_y_bits) bit = lc.eltw_input();
      m = lc.eltw_input();
      alpha = lc.eltw_input();
      beta = lc.eltw_input();
      rho_c = lc.eltw_input();
      rho_s = lc.eltw_input();
      nu_s = lc.eltw_input();
      nu_u = lc.eltw_input();
      nu_u_prime = lc.eltw_input();
      c_msg = lc.eltw_input();
      s_msg = lc.eltw_input();
      m_bytes.input(lc);
      alpha_bytes.input(lc);
      beta_bytes.input(lc);
      rho_c_bytes.input(lc);
      rho_s_bytes.input(lc);
      nu_s_bytes.input(lc);
      nu_u_bytes.input(lc);
      nu_u_prime_bytes.input(lc);
      r_bytes.input(lc);
      x_bytes.input(lc);
      sigma0.input(lc);
      sigma1.input(lc);
      c_digest = lc.template vinput<256>();
      s_digest = lc.template vinput<256>();
      phi_digest = lc.template vinput<256>();
      c_sha.input(lc);
      s_sha.input(lc);
      phi_sha.input(lc);
      bip340_digest = lc.template vinput<256>();
      bip340_sha.input(lc);
      bip340.input(lc);
      c_opening.input(lc);
      s_opening.input(lc);
    }
  };

  struct Branch2Witness {
    EltW c_y;
    EltW c_y_bits[kBits];
    EltW s_y;
    EltW s_y_bits[kBits];
    EltW m;
    EltW alpha;
    EltW beta;
    EltW rho_c;
    EltW rho_s;
    EltW nu_s;
    EltW nu_u;
    EltW nu_u_prime;
    EltW c_msg;
    EltW s_msg;
    EltW msg0;
    EltW msg1;
    EltW r0;
    EltW r1;
    EltW e0;
    EltW e1;
    Bytes32 m_bytes;
    Bytes32 alpha_bytes;
    Bytes32 beta_bytes;
    Bytes32 rho_c_bytes;
    Bytes32 rho_s_bytes;
    Bytes32 nu_s_bytes;
    Bytes32 nu_u_bytes;
    Bytes32 nu_u_prime_bytes;
    Bytes32 x_prime_bytes;
    Bytes32 msg0_bytes;
    Bytes32 msg1_bytes;
    SignatureBytes sigma0;
    SignatureBytes sigma1;
    v256 c_digest;
    v256 s_digest;
    v256 phi_digest;
    v256 tuple0_digest;
    v256 tuple1_digest;
    v256 bip340_0_digest;
    v256 bip340_1_digest;
    Sha2Witness c_sha;
    Sha4Witness s_sha;
    Sha4Witness phi_sha;
    Sha2Witness tuple0_sha;
    Sha2Witness tuple1_sha;
    Sha3Witness bip340_0_sha;
    Sha3Witness bip340_1_sha;
    typename Bip340Verify::Witness bip340_0;
    typename Bip340Verify::Witness bip340_1;
    PedersenOpeningWitness c_opening;
    PedersenOpeningWitness s_opening;

    void input(const LogicCircuit& lc) {
      c_y = lc.eltw_input();
      for (auto& bit : c_y_bits) bit = lc.eltw_input();
      s_y = lc.eltw_input();
      for (auto& bit : s_y_bits) bit = lc.eltw_input();
      m = lc.eltw_input();
      alpha = lc.eltw_input();
      beta = lc.eltw_input();
      rho_c = lc.eltw_input();
      rho_s = lc.eltw_input();
      nu_s = lc.eltw_input();
      nu_u = lc.eltw_input();
      nu_u_prime = lc.eltw_input();
      c_msg = lc.eltw_input();
      s_msg = lc.eltw_input();
      msg0 = lc.eltw_input();
      msg1 = lc.eltw_input();
      r0 = lc.eltw_input();
      r1 = lc.eltw_input();
      e0 = lc.eltw_input();
      e1 = lc.eltw_input();
      m_bytes.input(lc);
      alpha_bytes.input(lc);
      beta_bytes.input(lc);
      rho_c_bytes.input(lc);
      rho_s_bytes.input(lc);
      nu_s_bytes.input(lc);
      nu_u_bytes.input(lc);
      nu_u_prime_bytes.input(lc);
      x_prime_bytes.input(lc);
      msg0_bytes.input(lc);
      msg1_bytes.input(lc);
      sigma0.input(lc);
      sigma1.input(lc);
      c_digest = lc.template vinput<256>();
      s_digest = lc.template vinput<256>();
      phi_digest = lc.template vinput<256>();
      tuple0_digest = lc.template vinput<256>();
      tuple1_digest = lc.template vinput<256>();
      bip340_0_digest = lc.template vinput<256>();
      bip340_1_digest = lc.template vinput<256>();
      c_sha.input(lc);
      s_sha.input(lc);
      phi_sha.input(lc);
      tuple0_sha.input(lc);
      tuple1_sha.input(lc);
      bip340_0_sha.input(lc);
      bip340_1_sha.input(lc);
      bip340_0.input(lc);
      bip340_1.input(lc);
      c_opening.input(lc);
      s_opening.input(lc);
    }
  };

  RpbschRelationCircuit(const LogicCircuit& lc, const FlatSha& sha)
      : lc_(lc),
        sha_(sha),
        gadgets_(lc, proofs::p256k1),
        verifier_(lc, proofs::p256k1) {}

  void assert_branch1(EltW X, EltW X_prime, EltW R, EltW c, EltW C_prefix,
                      EltW C_x, EltW phi, EltW ck, EltW S_prefix, EltW S_x,
                      const Branch1Witness& w) const {
    (void)X_prime;
    assert_bytes32_field(w.m_bytes, w.m);
    assert_bytes32_field(w.alpha_bytes, w.alpha);
    assert_bytes32_field(w.beta_bytes, w.beta);
    assert_bytes32_field(w.rho_c_bytes, w.rho_c);
    assert_bytes32_field(w.rho_s_bytes, w.rho_s);
    assert_bytes32_field(w.nu_s_bytes, w.nu_s);
    assert_bytes32_field(w.nu_u_bytes, w.nu_u);
    assert_bytes32_field(w.nu_u_prime_bytes, w.nu_u_prime);

    assert_c_message(w.c_digest, w.m_bytes, w.alpha_bytes, w.beta_bytes,
                     w.c_sha);
    assert_digest_field(w.c_digest, w.c_msg);
    assert_s_message(w.s_digest, w.sigma0, w.sigma1, w.nu_u_bytes,
                     w.nu_u_prime_bytes, w.nu_s_bytes, w.s_sha);
    assert_digest_field(w.s_digest, w.s_msg);
    assert_phi_message(w.phi_digest, w.m_bytes, w.alpha_bytes, w.beta_bytes,
                       w.nu_s_bytes, w.nu_u_bytes, w.nu_u_prime_bytes,
                       w.phi_sha);
    assert_digest_field(w.phi_digest, phi);

    auto h = h_point();
    lc_.assert_eq(ck, h.x);
    assert_pedersen_opening(C_prefix, C_x, w.c_y, w.c_y_bits, w.c_msg,
                            w.rho_c, h.x, h.y, w.c_opening);
    assert_pedersen_opening(S_prefix, S_x, w.s_y, w.s_y_bits, w.s_msg,
                            w.rho_s, h.x, h.y, w.s_opening);

    assert_bip340_challenge(w.bip340_digest, R, X, w.r_bytes, w.x_bytes,
                            w.m_bytes, w.bip340_sha);
    gadgets_.assert_challenge_scalar_from_digest(w.bip340_digest, c);
    verifier_.assert_verify(R, X, c, w.bip340);
  }

  void assert_branch2(EltW X, EltW X_prime, EltW R, EltW c, EltW C_prefix,
                      EltW C_x, EltW phi, EltW ck, EltW S_prefix, EltW S_x,
                      const Branch2Witness& w) const {
    (void)X;
    (void)R;
    (void)c;
    assert_common_statement(C_prefix, C_x, phi, ck, S_prefix, S_x,
                            w.c_y, w.c_y_bits, w.s_y, w.s_y_bits,
                            w.m, w.alpha, w.beta, w.rho_c, w.rho_s,
                            w.nu_s, w.nu_u, w.nu_u_prime, w.c_msg,
                            w.s_msg, w.m_bytes, w.alpha_bytes, w.beta_bytes,
                            w.rho_c_bytes, w.rho_s_bytes, w.nu_s_bytes,
                            w.nu_u_bytes, w.nu_u_prime_bytes, w.sigma0,
                            w.sigma1, w.c_digest, w.s_digest, w.phi_digest,
                            w.c_sha, w.s_sha, w.phi_sha, w.c_opening,
                            w.s_opening);
    assert_bytes32_field(w.x_prime_bytes, X_prime);
    assert_tuple_message(w.tuple0_digest, w.nu_s_bytes, w.nu_u_bytes,
                         w.tuple0_sha);
    assert_tuple_message(w.tuple1_digest, w.nu_s_bytes, w.nu_u_prime_bytes,
                         w.tuple1_sha);
    assert_digest_field(w.tuple0_digest, w.msg0);
    assert_digest_field(w.tuple1_digest, w.msg1);
    assert_bytes32_field(w.msg0_bytes, w.msg0);
    assert_bytes32_field(w.msg1_bytes, w.msg1);
    assert_signature_prefix_field(w.sigma0, w.r0);
    assert_signature_prefix_field(w.sigma1, w.r1);

    assert_bip340_challenge_for_signature(w.bip340_0_digest, w.sigma0, w.r0,
                                          X_prime, w.x_prime_bytes,
                                          w.msg0_bytes, w.bip340_0_sha);
    assert_bip340_challenge_for_signature(w.bip340_1_digest, w.sigma1, w.r1,
                                          X_prime, w.x_prime_bytes,
                                          w.msg1_bytes, w.bip340_1_sha);
    gadgets_.assert_challenge_scalar_from_digest(w.bip340_0_digest, w.e0);
    gadgets_.assert_challenge_scalar_from_digest(w.bip340_1_digest, w.e1);
    verifier_.assert_verify(w.r0, X_prime, w.e0, w.bip340_0);
    verifier_.assert_verify(w.r1, X_prime, w.e1, w.bip340_1);
  }

  void assert_selector_or(typename LogicCircuit::BitW selector_bit, EltW X,
                          EltW X_prime, EltW R, EltW c, EltW C_prefix,
                          EltW C_x, EltW phi, EltW ck, EltW S_prefix,
                          EltW S_x, const Branch1Witness& b1,
                          const Branch2Witness& b2) const {
    Bytes32 m = mux(selector_bit, b2.m_bytes, b1.m_bytes);
    Bytes32 alpha = mux(selector_bit, b2.alpha_bytes, b1.alpha_bytes);
    Bytes32 beta = mux(selector_bit, b2.beta_bytes, b1.beta_bytes);
    Bytes32 rho_c_bytes = mux(selector_bit, b2.rho_c_bytes, b1.rho_c_bytes);
    Bytes32 rho_s_bytes = mux(selector_bit, b2.rho_s_bytes, b1.rho_s_bytes);
    Bytes32 nu_s = mux(selector_bit, b2.nu_s_bytes, b1.nu_s_bytes);
    Bytes32 nu_u = mux(selector_bit, b2.nu_u_bytes, b1.nu_u_bytes);
    Bytes32 nu_u_prime =
        mux(selector_bit, b2.nu_u_prime_bytes, b1.nu_u_prime_bytes);
    SignatureBytes sigma0 = mux(selector_bit, b2.sigma0, b1.sigma0);
    SignatureBytes sigma1 = mux(selector_bit, b2.sigma1, b1.sigma1);
    Sha2Witness c_sha = mux(selector_bit, b2.c_sha, b1.c_sha);
    Sha4Witness s_sha = mux(selector_bit, b2.s_sha, b1.s_sha);
    Sha4Witness phi_sha = mux(selector_bit, b2.phi_sha, b1.phi_sha);
    PedersenOpeningWitness c_opening =
        mux(selector_bit, b2.c_opening, b1.c_opening);
    PedersenOpeningWitness s_opening =
        mux(selector_bit, b2.s_opening, b1.s_opening);
    auto c_y_bits = mux_array(selector_bit, b2.c_y_bits, b1.c_y_bits);
    auto s_y_bits = mux_array(selector_bit, b2.s_y_bits, b1.s_y_bits);

    assert_common_statement(
        C_prefix, C_x, phi, ck, S_prefix, S_x,
        mux(selector_bit, b2.c_y, b1.c_y),
        c_y_bits.data(),
        mux(selector_bit, b2.s_y, b1.s_y),
        s_y_bits.data(),
        mux(selector_bit, b2.m, b1.m),
        mux(selector_bit, b2.alpha, b1.alpha),
        mux(selector_bit, b2.beta, b1.beta),
        mux(selector_bit, b2.rho_c, b1.rho_c),
        mux(selector_bit, b2.rho_s, b1.rho_s),
        mux(selector_bit, b2.nu_s, b1.nu_s),
        mux(selector_bit, b2.nu_u, b1.nu_u),
        mux(selector_bit, b2.nu_u_prime, b1.nu_u_prime),
        mux(selector_bit, b2.c_msg, b1.c_msg),
        mux(selector_bit, b2.s_msg, b1.s_msg), m, alpha, beta, rho_c_bytes,
        rho_s_bytes, nu_s, nu_u, nu_u_prime, sigma0, sigma1,
        mux(selector_bit, b2.c_digest, b1.c_digest),
        mux(selector_bit, b2.s_digest, b1.s_digest),
        mux(selector_bit, b2.phi_digest, b1.phi_digest), c_sha, s_sha,
        phi_sha, c_opening, s_opening);

    Bytes32 b2_r0 = signature_prefix_bytes(b2.sigma0);
    Bytes32 b2_r1 = signature_prefix_bytes(b2.sigma1);
    assert_selected_bip340(selector_bit,
                           mux(selector_bit, b2.r0, R),
                           mux(selector_bit, X_prime, X),
                           mux(selector_bit, b2.e0, c),
                           mux(selector_bit, b2_r0, b1.r_bytes),
                           mux(selector_bit, b2.x_prime_bytes, b1.x_bytes),
                           mux(selector_bit, b2.msg0_bytes, b1.m_bytes),
                           mux(selector_bit, b2.bip340_0_digest,
                               b1.bip340_digest),
                           mux(selector_bit, b2.bip340_0_sha,
                               b1.bip340_sha),
                           mux(selector_bit, b2.bip340_0, b1.bip340));

    assert_selected_bip340(selector_bit,
                           mux(selector_bit, b2.r1, R),
                           mux(selector_bit, X_prime, X),
                           mux(selector_bit, b2.e1, c),
                           mux(selector_bit, b2_r1, b1.r_bytes),
                           mux(selector_bit, b2.x_prime_bytes, b1.x_bytes),
                           mux(selector_bit, b2.msg1_bytes, b1.m_bytes),
                           mux(selector_bit, b2.bip340_1_digest,
                               b1.bip340_digest),
                           mux(selector_bit, b2.bip340_1_sha,
                               b1.bip340_sha),
                           mux(selector_bit, b2.bip340_1, b1.bip340));
  }

 private:
  const LogicCircuit& lc_;
  const FlatSha& sha_;
  Bip340Gadgets gadgets_;
  Bip340Verify verifier_;
  Point h_point(void) const {
    uint8_t h_x_bytes[32];
    (void)niwi_pbsch_pedersen_h(h_x_bytes);
    auto x = field_from_be(h_x_bytes);
    auto xx = proofs::p256k1_base.mulf(x, x);
    auto xxx = proofs::p256k1_base.mulf(x, xx);
    auto y2 = proofs::p256k1_base.addf(
        xxx, proofs::p256k1_base.of_scalar(7));
    auto y = sqrt_even(y2);
    return {lc_.konst(x), lc_.konst(y), lc_.konst(lc_.one())};
  }

  static proofs::Fp256k1Base::Elt field_from_be(const uint8_t bytes[32]) {
    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) le[i] = bytes[31 - i];
    return proofs::p256k1_base.to_montgomery(
        proofs::Fp256k1Base::N::of_bytes(le));
  }

  void assert_common_statement(
      EltW C_prefix, EltW C_x, EltW phi, EltW ck, EltW S_prefix, EltW S_x,
      EltW c_y, const EltW c_y_bits[kBits], EltW s_y,
      const EltW s_y_bits[kBits], EltW m, EltW alpha, EltW beta, EltW rho_c,
      EltW rho_s, EltW nu_s, EltW nu_u, EltW nu_u_prime, EltW c_msg,
      EltW s_msg, const Bytes32& m_bytes, const Bytes32& alpha_bytes,
      const Bytes32& beta_bytes, const Bytes32& rho_c_bytes,
      const Bytes32& rho_s_bytes, const Bytes32& nu_s_bytes,
      const Bytes32& nu_u_bytes, const Bytes32& nu_u_prime_bytes,
      const SignatureBytes& sigma0, const SignatureBytes& sigma1,
      const v256& c_digest, const v256& s_digest, const v256& phi_digest,
      const Sha2Witness& c_sha, const Sha4Witness& s_sha,
      const Sha4Witness& phi_sha, const PedersenOpeningWitness& c_opening,
      const PedersenOpeningWitness& s_opening) const {
    assert_bytes32_field(m_bytes, m);
    assert_bytes32_field(alpha_bytes, alpha);
    assert_bytes32_field(beta_bytes, beta);
    assert_bytes32_field(rho_c_bytes, rho_c);
    assert_bytes32_field(rho_s_bytes, rho_s);
    assert_bytes32_field(nu_s_bytes, nu_s);
    assert_bytes32_field(nu_u_bytes, nu_u);
    assert_bytes32_field(nu_u_prime_bytes, nu_u_prime);

    assert_c_message(c_digest, m_bytes, alpha_bytes, beta_bytes, c_sha);
    assert_digest_field(c_digest, c_msg);
    assert_s_message(s_digest, sigma0, sigma1, nu_u_bytes,
                     nu_u_prime_bytes, nu_s_bytes, s_sha);
    assert_digest_field(s_digest, s_msg);
    assert_phi_message(phi_digest, m_bytes, alpha_bytes, beta_bytes,
                       nu_s_bytes, nu_u_bytes, nu_u_prime_bytes, phi_sha);
    assert_digest_field(phi_digest, phi);

    auto h = h_point();
    lc_.assert_eq(ck, h.x);
    assert_pedersen_opening(C_prefix, C_x, c_y, c_y_bits, c_msg, rho_c,
                            h.x, h.y, c_opening);
    assert_pedersen_opening(S_prefix, S_x, s_y, s_y_bits, s_msg, rho_s,
                            h.x, h.y, s_opening);
  }

  static proofs::Fp256k1Base::Elt sqrt_even(
      const proofs::Fp256k1Base::Elt& y2) {
    proofs::Fp256k1Base::N exp(
        "0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffff0c");
    auto root = proofs::p256k1_base.one();
    auto base = y2;
    for (int i = 255; i >= 0; --i) {
      root = proofs::p256k1_base.mulf(root, root);
      if (exp.bit(i)) root = proofs::p256k1_base.mulf(root, base);
    }
    auto nat = proofs::p256k1_base.from_montgomery(root);
    return nat.bit(0) ? proofs::p256k1_base.negf(root) : root;
  }

  void assert_compressed_point(EltW prefix, EltW x, EltW y,
                               const EltW y_bits[kBits]) const {
    gadgets_.assert_point_on_curve(x, y);
    gadgets_.assert_field_from_bits_msb(y_bits, y);
    auto parity = lc_.sub(prefix, lc_.konst(2));
    lc_.assert_is_bit(typename LogicCircuit::BitW(parity, lc_.f_));
    lc_.assert_eq(parity, y_bits[kBits - 1]);
  }

  void assert_pedersen_opening(EltW prefix, EltW c_x, EltW c_y,
                               const EltW c_y_bits[kBits], EltW msg,
                               EltW rho, EltW h_x, EltW h_y,
                               const PedersenOpeningWitness& w) const {
    assert_compressed_point(prefix, c_x, c_y, c_y_bits);
    gadgets_.assert_field_from_bits_msb(w.msg.bits, msg);
    gadgets_.assert_field_from_bits_msb(w.rho.bits, rho);

    auto one = lc_.konst(lc_.one());
    auto msg_g = gadgets_.scalar_mult(lc_.konst(proofs::p256k1.gx_),
                                      lc_.konst(proofs::p256k1.gy_), one,
                                      w.msg.bits, w.msg.int_x, w.msg.int_y,
                                      w.msg.int_z);
    auto rho_h = gadgets_.scalar_mult(h_x, h_y, one, w.rho.bits,
                                      w.rho.int_x, w.rho.int_y, w.rho.int_z);
    assert_same_projective_point({msg_g.x, msg_g.y, msg_g.z}, w.msg_point);
    assert_same_projective_point({rho_h.x, rho_h.y, rho_h.z}, w.rho_point);

    auto sum = gadgets_.addE(w.msg_point.x, w.msg_point.y, w.msg_point.z,
                             w.rho_point.x, w.rho_point.y, w.rho_point.z);
    lc_.assert_eq(lc_.mul(sum.z, w.sum_z_inv), one);
    lc_.assert_eq(lc_.mul(sum.x, w.sum_z_inv), c_x);
    lc_.assert_eq(lc_.mul(sum.y, w.sum_z_inv), c_y);
  }

  void assert_same_projective_point(const Point& a, const Point& b) const {
    lc_.assert_eq(lc_.mul(a.x, b.z), lc_.mul(b.x, a.z));
    lc_.assert_eq(lc_.mul(a.y, b.z), lc_.mul(b.y, a.z));
  }

  void assert_bytes32_field(const Bytes32& bytes, EltW value) const {
    v256 bits;
    for (size_t i = 0; i < kBits; ++i) {
      bits[i] = bytes.bytes[31 - i / 8][i % 8];
    }
    gadgets_.assert_field_from_bits_lsb(bits, value);
  }

  void assert_signature_prefix_field(const SignatureBytes& sig,
                                     EltW value) const {
    v256 bits;
    for (size_t i = 0; i < kBits; ++i) {
      bits[i] = sig.bytes[31 - i / 8][i % 8];
    }
    gadgets_.assert_field_from_bits_lsb(bits, value);
  }

  void assert_digest_field(const v256& digest, EltW value) const {
    gadgets_.assert_field_from_bits_lsb(digest, value);
  }

  void set_byte(v8& out, uint8_t byte) const {
    for (size_t i = 0; i < 8; ++i) {
      out[i] = lc_.bit((byte >> i) & 1u);
    }
  }

  void assert_c_message(const v256& digest, const Bytes32& m,
                        const Bytes32& alpha, const Bytes32& beta,
                        const Sha2Witness& witness) const {
    static constexpr uint8_t tag[] = {
        'P', 'B', 'S', 'c', 'h', '/', 'C', '/', 'v', '1'};
    v8 preimage[kCBlocks * 64];
    size_t off = 0;
    for (uint8_t b : tag) set_byte(preimage[off++], b);
    copy_bytes(preimage, off, m);
    copy_bytes(preimage, off, alpha);
    copy_bytes(preimage, off, beta);
    pad_sha256(preimage, off);
    v8 blocks;
    set_byte(blocks, kCBlocks);
    sha_.assert_message_hash(kCBlocks, blocks, preimage, digest,
                             witness.blocks);
  }

  void assert_s_message(const v256& digest, const SignatureBytes& sigma0,
                        const SignatureBytes& sigma1, const Bytes32& nu_u,
                        const Bytes32& nu_u_prime, const Bytes32& nu_s,
                        const Sha4Witness& witness) const {
    v8 preimage[kSBlocks * 64];
    size_t off = 0;
    copy_sig(preimage, off, sigma0);
    copy_sig(preimage, off, sigma1);
    copy_bytes(preimage, off, nu_u);
    copy_bytes(preimage, off, nu_u_prime);
    copy_bytes(preimage, off, nu_s);
    pad_sha256(preimage, off);
    v8 blocks;
    set_byte(blocks, kSBlocks);
    sha_.assert_message_hash(kSBlocks, blocks, preimage, digest,
                             witness.blocks);
  }

  void assert_phi_message(const v256& digest, const Bytes32& m,
                          const Bytes32& alpha, const Bytes32& beta,
                          const Bytes32& nu_s, const Bytes32& nu_u,
                          const Bytes32& nu_u_prime,
                          const Sha4Witness& witness) const {
    static constexpr uint8_t tag[] = {
        'Z', 'e', 'n', 'r', 'o', 'o', 'm', '/', 'R', 'P', 'B', 'S', 'c', 'h',
        '/', 'p', 'h', 'i', '/', 'v', '1'};
    v8 preimage[kPhiBlocks * 64];
    size_t off = 0;
    for (uint8_t b : tag) set_byte(preimage[off++], b);
    copy_bytes(preimage, off, m);
    copy_bytes(preimage, off, alpha);
    copy_bytes(preimage, off, beta);
    copy_bytes(preimage, off, nu_s);
    copy_bytes(preimage, off, nu_u);
    copy_bytes(preimage, off, nu_u_prime);
    pad_sha256(preimage, off);
    v8 blocks;
    set_byte(blocks, kPhiBlocks);
    sha_.assert_message_hash(kPhiBlocks, blocks, preimage, digest,
                             witness.blocks);
  }

  void assert_tuple_message(const v256& digest, const Bytes32& nu_s,
                            const Bytes32& nu_u,
                            const Sha2Witness& witness) const {
    static constexpr uint8_t tag[] = {
        'Z', 'e', 'n', 'r', 'o', 'o', 'm', '/', 'R', 'P', 'B', 'S', 'c', 'h',
        '/', 't', 'u', 'p', 'l', 'e', '-', 'm', 'e', 's', 's', 'a', 'g', 'e',
        '/', 'v', '1'};
    v8 preimage[kCBlocks * 64];
    size_t off = 0;
    for (uint8_t b : tag) set_byte(preimage[off++], b);
    copy_bytes(preimage, off, nu_s);
    copy_bytes(preimage, off, nu_u);
    pad_sha256(preimage, off);
    v8 blocks;
    set_byte(blocks, kCBlocks);
    sha_.assert_message_hash(kCBlocks, blocks, preimage, digest,
                             witness.blocks);
  }

  void assert_bip340_challenge(const v256& digest, EltW R, EltW X,
                               const Bytes32& r_bytes,
                               const Bytes32& x_bytes, const Bytes32& m,
                               const Sha3Witness& witness) const {
    uint8_t tag_hash[32];
    detail::bip340_tag_hash(tag_hash);
    v8 preimage[kBip340Blocks * 64];
    size_t off = 0;
    for (uint8_t b : tag_hash) set_byte(preimage[off++], b);
    for (uint8_t b : tag_hash) set_byte(preimage[off++], b);
    assert_bytes32_field(r_bytes, R);
    assert_bytes32_field(x_bytes, X);
    copy_bytes(preimage, off, r_bytes);
    copy_bytes(preimage, off, x_bytes);
    copy_bytes(preimage, off, m);
    pad_sha256(preimage, off);
    v8 blocks;
    set_byte(blocks, kBip340Blocks);
    sha_.assert_message_hash(kBip340Blocks, blocks, preimage, digest,
                             witness.blocks);
  }

  void assert_bip340_challenge_for_signature(
      const v256& digest, const SignatureBytes& sig, EltW R, EltW X,
      const Bytes32& x_bytes, const Bytes32& msg,
      const Sha3Witness& witness) const {
    uint8_t tag_hash[32];
    detail::bip340_tag_hash(tag_hash);
    v8 preimage[kBip340Blocks * 64];
    size_t off = 0;
    for (uint8_t b : tag_hash) set_byte(preimage[off++], b);
    for (uint8_t b : tag_hash) set_byte(preimage[off++], b);
    assert_signature_prefix_field(sig, R);
    assert_bytes32_field(x_bytes, X);
    for (size_t i = 0; i < 32; ++i) preimage[off++] = sig.bytes[i];
    copy_bytes(preimage, off, x_bytes);
    copy_bytes(preimage, off, msg);
    pad_sha256(preimage, off);
    v8 blocks;
    set_byte(blocks, kBip340Blocks);
    sha_.assert_message_hash(kBip340Blocks, blocks, preimage, digest,
                             witness.blocks);
  }

  void assert_selected_bip340(
      typename LogicCircuit::BitW selector_bit, EltW selected_R,
      EltW selected_X, EltW selected_e, const Bytes32& selected_r_bytes,
      const Bytes32& selected_x_bytes, const Bytes32& selected_msg,
      const v256& selected_digest, const Sha3Witness& selected_sha,
      const typename Bip340Verify::Witness& selected_witness) const {
    (void)selector_bit;
    assert_bip340_challenge(selected_digest, selected_R, selected_X,
                            selected_r_bytes, selected_x_bytes, selected_msg,
                            selected_sha);
    gadgets_.assert_challenge_scalar_from_digest(selected_digest, selected_e);
    verifier_.assert_verify(selected_R, selected_X, selected_e,
                            selected_witness);
  }

  EltW mux(typename LogicCircuit::BitW selector_bit, EltW if_branch2,
           EltW if_branch1) const {
    return lc_.mux(selector_bit, if_branch2, if_branch1);
  }

  v8 mux(typename LogicCircuit::BitW selector_bit, const v8& if_branch2,
         const v8& if_branch1) const {
    v8 out;
    for (size_t i = 0; i < 8; ++i) {
      out[i] = lc_.mux(selector_bit, if_branch2[i], if_branch1[i]);
    }
    return out;
  }

  v256 mux(typename LogicCircuit::BitW selector_bit, const v256& if_branch2,
           const v256& if_branch1) const {
    v256 out;
    for (size_t i = 0; i < kBits; ++i) {
      out[i] = lc_.mux(selector_bit, if_branch2[i], if_branch1[i]);
    }
    return out;
  }

  template <size_t N>
  std::array<EltW, N> mux(typename LogicCircuit::BitW selector_bit,
                          const std::array<EltW, N>& if_branch2,
                          const std::array<EltW, N>& if_branch1) const {
    std::array<EltW, N> out;
    for (size_t i = 0; i < N; ++i) {
      out[i] = mux(selector_bit, if_branch2[i], if_branch1[i]);
    }
    return out;
  }

  Bytes32 mux(typename LogicCircuit::BitW selector_bit,
              const Bytes32& if_branch2, const Bytes32& if_branch1) const {
    Bytes32 out;
    for (size_t i = 0; i < 32; ++i) {
      out.bytes[i] = mux(selector_bit, if_branch2.bytes[i],
                         if_branch1.bytes[i]);
    }
    return out;
  }

  SignatureBytes mux(typename LogicCircuit::BitW selector_bit,
                     const SignatureBytes& if_branch2,
                     const SignatureBytes& if_branch1) const {
    SignatureBytes out;
    for (size_t i = 0; i < 64; ++i) {
      out.bytes[i] = mux(selector_bit, if_branch2.bytes[i],
                         if_branch1.bytes[i]);
    }
    return out;
  }

  Sha2Witness mux(typename LogicCircuit::BitW selector_bit,
                  const Sha2Witness& if_branch2,
                  const Sha2Witness& if_branch1) const {
    Sha2Witness out;
    for (size_t i = 0; i < 2; ++i) {
      out.blocks[i] = mux(selector_bit, if_branch2.blocks[i],
                          if_branch1.blocks[i]);
    }
    return out;
  }

  Sha3Witness mux(typename LogicCircuit::BitW selector_bit,
                  const Sha3Witness& if_branch2,
                  const Sha3Witness& if_branch1) const {
    Sha3Witness out;
    for (size_t i = 0; i < 3; ++i) {
      out.blocks[i] = mux(selector_bit, if_branch2.blocks[i],
                          if_branch1.blocks[i]);
    }
    return out;
  }

  Sha4Witness mux(typename LogicCircuit::BitW selector_bit,
                  const Sha4Witness& if_branch2,
                  const Sha4Witness& if_branch1) const {
    Sha4Witness out;
    for (size_t i = 0; i < 4; ++i) {
      out.blocks[i] = mux(selector_bit, if_branch2.blocks[i],
                          if_branch1.blocks[i]);
    }
    return out;
  }

  typename FlatSha::BlockWitness mux(
      typename LogicCircuit::BitW selector_bit,
      const typename FlatSha::BlockWitness& if_branch2,
      const typename FlatSha::BlockWitness& if_branch1) const {
    typename FlatSha::BlockWitness out;
    for (size_t i = 0; i < 48; ++i) {
      out.outw[i] = mux(selector_bit, if_branch2.outw[i],
                        if_branch1.outw[i]);
    }
    for (size_t i = 0; i < 64; ++i) {
      out.oute[i] = mux(selector_bit, if_branch2.oute[i],
                        if_branch1.oute[i]);
      out.outa[i] = mux(selector_bit, if_branch2.outa[i],
                        if_branch1.outa[i]);
    }
    for (size_t i = 0; i < 8; ++i) {
      out.h1[i] = mux(selector_bit, if_branch2.h1[i], if_branch1.h1[i]);
    }
    return out;
  }

  ScalarMultWitness mux(typename LogicCircuit::BitW selector_bit,
                        const ScalarMultWitness& if_branch2,
                        const ScalarMultWitness& if_branch1) const {
    ScalarMultWitness out;
    for (size_t i = 0; i < kBits; ++i) {
      out.bits[i] = mux(selector_bit, if_branch2.bits[i],
                        if_branch1.bits[i]);
      if (i < kBits - 1) {
        out.int_x[i] = mux(selector_bit, if_branch2.int_x[i],
                           if_branch1.int_x[i]);
        out.int_y[i] = mux(selector_bit, if_branch2.int_y[i],
                           if_branch1.int_y[i]);
        out.int_z[i] = mux(selector_bit, if_branch2.int_z[i],
                           if_branch1.int_z[i]);
      }
    }
    return out;
  }

  Point mux(typename LogicCircuit::BitW selector_bit, const Point& if_branch2,
            const Point& if_branch1) const {
    return {mux(selector_bit, if_branch2.x, if_branch1.x),
            mux(selector_bit, if_branch2.y, if_branch1.y),
            mux(selector_bit, if_branch2.z, if_branch1.z)};
  }

  PedersenOpeningWitness mux(typename LogicCircuit::BitW selector_bit,
                             const PedersenOpeningWitness& if_branch2,
                             const PedersenOpeningWitness& if_branch1) const {
    return {mux(selector_bit, if_branch2.msg, if_branch1.msg),
            mux(selector_bit, if_branch2.rho, if_branch1.rho),
            mux(selector_bit, if_branch2.msg_point, if_branch1.msg_point),
            mux(selector_bit, if_branch2.rho_point, if_branch1.rho_point),
            mux(selector_bit, if_branch2.sum_z_inv,
                if_branch1.sum_z_inv)};
  }

  typename Bip340Verify::Witness mux(
      typename LogicCircuit::BitW selector_bit,
      const typename Bip340Verify::Witness& if_branch2,
      const typename Bip340Verify::Witness& if_branch1) const {
    typename Bip340Verify::Witness out;
    for (size_t i = 0; i < kBits; ++i) {
      out.bits_s[i] = mux(selector_bit, if_branch2.bits_s[i],
                          if_branch1.bits_s[i]);
      out.bits_e[i] = mux(selector_bit, if_branch2.bits_e[i],
                          if_branch1.bits_e[i]);
      out.bits_ry[i] = mux(selector_bit, if_branch2.bits_ry[i],
                           if_branch1.bits_ry[i]);
      if (i < kBits - 1) {
        out.int_sx[i] = mux(selector_bit, if_branch2.int_sx[i],
                            if_branch1.int_sx[i]);
        out.int_sy[i] = mux(selector_bit, if_branch2.int_sy[i],
                            if_branch1.int_sy[i]);
        out.int_sz[i] = mux(selector_bit, if_branch2.int_sz[i],
                            if_branch1.int_sz[i]);
        out.int_ex[i] = mux(selector_bit, if_branch2.int_ex[i],
                            if_branch1.int_ex[i]);
        out.int_ey[i] = mux(selector_bit, if_branch2.int_ey[i],
                            if_branch1.int_ey[i]);
        out.int_ez[i] = mux(selector_bit, if_branch2.int_ez[i],
                            if_branch1.int_ez[i]);
      }
    }
    out.py = mux(selector_bit, if_branch2.py, if_branch1.py);
    out.ry = mux(selector_bit, if_branch2.ry, if_branch1.ry);
    out.rz_inv = mux(selector_bit, if_branch2.rz_inv, if_branch1.rz_inv);
    return out;
  }

  template <size_t N>
  std::array<EltW, N> mux_array(typename LogicCircuit::BitW selector_bit,
                                const EltW (&if_branch2)[N],
                                const EltW (&if_branch1)[N]) const {
    std::array<EltW, N> out;
    for (size_t i = 0; i < N; ++i) {
      out[i] = mux(selector_bit, if_branch2[i], if_branch1[i]);
    }
    return out;
  }

  Bytes32 signature_prefix_bytes(const SignatureBytes& sig) const {
    Bytes32 out;
    for (size_t i = 0; i < 32; ++i) out.bytes[i] = sig.bytes[i];
    return out;
  }

  void copy_bytes(v8 *out, size_t& off, const Bytes32& bytes) const {
    for (const auto& byte : bytes.bytes) out[off++] = byte;
  }

  void copy_sig(v8 *out, size_t& off, const SignatureBytes& sig) const {
    for (const auto& byte : sig.bytes) out[off++] = byte;
  }

  template <size_t N>
  void pad_sha256(v8 (&out)[N], size_t msg_len) const {
    set_byte(out[msg_len], 0x80);
    for (size_t i = msg_len + 1; i + 8 < N; ++i) set_byte(out[i], 0);
    const uint64_t bit_len = static_cast<uint64_t>(msg_len) * 8u;
    for (size_t i = 0; i < 8; ++i) {
      const auto shift = static_cast<unsigned>((7 - i) * 8);
      set_byte(out[N - 8 + i], static_cast<uint8_t>(bit_len >> shift));
    }
  }
};

inline std::unique_ptr<proofs::Circuit<proofs::Fp256k1Base>>
build_rpbsch_branch1_circuit(void) {
  using Field = proofs::Fp256k1Base;
  using Backend = proofs::CompilerBackend<Field>;
  using Logic = proofs::Logic<Field, Backend>;
  using BitPlucker = proofs::BitPlucker<Logic, 4>;
  using FlatSha = proofs::FlatSHA256Circuit<Logic, BitPlucker>;

  proofs::QuadCircuit<Field> q(proofs::p256k1_base);
  const Backend backend(&q);
  const Logic logic(&backend, proofs::p256k1_base);
  const FlatSha sha(logic);
  const RpbschRelationCircuit<Logic, BitPlucker> relation(logic, sha);

  auto X = logic.eltw_input();
  auto X_prime = logic.eltw_input();
  auto R = logic.eltw_input();
  auto c = logic.eltw_input();
  auto C_prefix = logic.eltw_input();
  auto C_x = logic.eltw_input();
  auto phi = logic.eltw_input();
  auto ck = logic.eltw_input();
  auto S_prefix = logic.eltw_input();
  auto S_x = logic.eltw_input();
  q.private_input();

  typename RpbschRelationCircuit<Logic, BitPlucker>::Branch1Witness witness;
  witness.input(logic);
  relation.assert_branch1(X, X_prime, R, c, C_prefix, C_x, phi, ck,
                          S_prefix, S_x, witness);
  return q.mkcircuit(1);
}

inline std::unique_ptr<proofs::Circuit<proofs::Fp256k1Base>>
build_rpbsch_branch2_circuit(void) {
  using Field = proofs::Fp256k1Base;
  using Backend = proofs::CompilerBackend<Field>;
  using Logic = proofs::Logic<Field, Backend>;
  using BitPlucker = proofs::BitPlucker<Logic, 4>;
  using FlatSha = proofs::FlatSHA256Circuit<Logic, BitPlucker>;

  proofs::QuadCircuit<Field> q(proofs::p256k1_base);
  const Backend backend(&q);
  const Logic logic(&backend, proofs::p256k1_base);
  const FlatSha sha(logic);
  const RpbschRelationCircuit<Logic, BitPlucker> relation(logic, sha);

  auto X = logic.eltw_input();
  auto X_prime = logic.eltw_input();
  auto R = logic.eltw_input();
  auto c = logic.eltw_input();
  auto C_prefix = logic.eltw_input();
  auto C_x = logic.eltw_input();
  auto phi = logic.eltw_input();
  auto ck = logic.eltw_input();
  auto S_prefix = logic.eltw_input();
  auto S_x = logic.eltw_input();
  q.private_input();

  typename RpbschRelationCircuit<Logic, BitPlucker>::Branch2Witness witness;
  witness.input(logic);
  relation.assert_branch2(X, X_prime, R, c, C_prefix, C_x, phi, ck,
                          S_prefix, S_x, witness);
  return q.mkcircuit(1);
}

inline std::unique_ptr<proofs::Circuit<proofs::Fp256k1Base>>
build_rpbsch_selector_circuit(void) {
  using Field = proofs::Fp256k1Base;
  using Backend = proofs::CompilerBackend<Field>;
  using Logic = proofs::Logic<Field, Backend>;
  using BitPlucker = proofs::BitPlucker<Logic, 4>;
  using FlatSha = proofs::FlatSHA256Circuit<Logic, BitPlucker>;

  proofs::QuadCircuit<Field> q(proofs::p256k1_base);
  const Backend backend(&q);
  const Logic logic(&backend, proofs::p256k1_base);
  const FlatSha sha(logic);
  const RpbschRelationCircuit<Logic, BitPlucker> relation(logic, sha);

  auto X = logic.eltw_input();
  auto X_prime = logic.eltw_input();
  auto R = logic.eltw_input();
  auto c = logic.eltw_input();
  auto C_prefix = logic.eltw_input();
  auto C_x = logic.eltw_input();
  auto phi = logic.eltw_input();
  auto ck = logic.eltw_input();
  auto S_prefix = logic.eltw_input();
  auto S_x = logic.eltw_input();
  q.private_input();

  auto selector = logic.eltw_input();
  auto selector_zero_based = logic.sub(selector, logic.konst(1));
  typename Logic::BitW selector_bit(selector_zero_based, logic.f_);
  logic.assert_is_bit(selector_bit);

  typename RpbschRelationCircuit<Logic, BitPlucker>::Branch1Witness branch1;
  typename RpbschRelationCircuit<Logic, BitPlucker>::Branch2Witness branch2;
  branch1.input(logic);
  branch2.input(logic);

  relation.assert_selector_or(selector_bit, X, X_prime, R, c, C_prefix,
                              C_x, phi, ck, S_prefix, S_x, branch1,
                              branch2);
  return q.mkcircuit(1);
}

}  // namespace niwi::rpbsch

#endif  // NIWI_CIRCUITS_RPBSCH_RELATION_CIRCUIT_H
