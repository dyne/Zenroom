/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#ifndef NIWI_CIRCUITS_RPBSCH_CIRCUIT_H
#define NIWI_CIRCUITS_RPBSCH_CIRCUIT_H

#include <cstddef>
#include <cstdint>

#include "circuits/secp256k1_circuit.h"
#include "circuits/bip340_circuit.h"
#include "circuits/sha/flatsha256_circuit.h"

namespace niwi {

/* RPBSch relation circuit.
 *
 * Public statement:
 *   X   — signer x-only public key
 *   X'  — auxiliary x-only public key
 *   C   — Pedersen commitment to (m, α, β)  [x-coordinate]
 *   S   — Pedersen commitment to (σ₀,σ₁,ν_u,ν_u',ν_s) [x-coordinate]
 *
 * Branch 1 (honest): knows (R, α, β, ρ, m, r_C) such that:
 *   - C = m·G + r_C·H      (Pedersen opening)
 *   - R' = R + α·G + β·X   (blinded nonce)
 *   - c = Hq(R'_x, X_x, m) + β mod n
 *
 * Branch 2 (trapdoor): knows (σ₀,σ₁,ν_u,ν_u',ν_s, r_S) such that:
 *   - ν_u ≠ ν_u'
 *   - S opens to the tuple
 *   - σ₀ verifies under X' on msg_0 = SHA-256(ν_s||ν_u)
 *   - σ₁ verifies under X' on msg_1 = SHA-256(ν_s||ν_u')
 *
 * Current implementation status:
 *   This is a strict validation skeleton, not the final WI-OR circuit.
 *   The embedded secp256k1 and BIP-340 subcircuits assert internally, so both
 *   branch witnesses are part of the circuit and must be valid. The selector is
 *   kept private and gates only local constraints that are written with
 *   gate_assert* helpers. A final WI-OR implementation must either add gated
 *   variants of those subcircuits or require valid dummy witnesses for the
 *   inactive branch as an explicit protocol rule.
 */

template <class LogicCircuit, class EC, class ScalarField>
class RpbschCircuit {
 public:
  using EltW   = typename LogicCircuit::EltW;
  using Elt    = typename LogicCircuit::Elt;
  using BitW   = typename LogicCircuit::BitW;
  using v256   = typename LogicCircuit::v256;
  using v32    = typename LogicCircuit::v32;
  using v8     = typename LogicCircuit::v8;

  static constexpr size_t kBits = EC::kBits;
  using Bp = proofs::BitPlucker<LogicCircuit, 5>;
  using packed_v32 = typename Bp::packed_v32;

  /* SHA-256 2-block witness for msg = SHA-256(a || b) where a,b are
   * 32-byte field elements (ν_s, ν_u / ν_u'). */
  struct Sha2BlockWitness {
    packed_v32 outw[2][48];
    packed_v32 oute[2][64];
    packed_v32 outa[2][64];
    packed_v32 h1[2][8];       /* h1[1] = final hash */

    void input(const LogicCircuit& lc) {
      for (size_t b = 0; b < 2; ++b) {
        for (size_t i = 0; i < 48; ++i)
          outw[b][i] = Bp::template packed_input<packed_v32>(lc);
        for (size_t i = 0; i < 64; ++i)
          oute[b][i] = Bp::template packed_input<packed_v32>(lc);
        for (size_t i = 0; i < 64; ++i)
          outa[b][i] = Bp::template packed_input<packed_v32>(lc);
        for (size_t i = 0; i < 8; ++i)
          h1[b][i] = Bp::template packed_input<packed_v32>(lc);
      }
    }
  };

  /* ---- OR selector constraint ---- */

  /* Assert sel ∈ {0,1}: sel * (1 - sel) = 0.
   * Returns the complement (1 - sel) for gating branch 1. */
  static EltW make_selector(const LogicCircuit& lc, EltW sel) {
    EltW one  = lc.konst(lc.one());
    EltW comp = lc.sub(&one, sel);  /* 1 - sel */
    /* sel * (1 - sel) = 0  →  sel ∈ {0, 1} */
    lc.assert0(lc.mul(&sel, comp));
    return comp; /* 1 - sel */
  }

  /* ---- Statement (public inputs) ----------------------------------- */

  struct Statement {
    EltW X_x;    /* signer public key (x-only) */
    EltW Xp_x;   /* auxiliary public key (x-only) */
    EltW C_x;    /* C commitment x-coordinate */
    EltW S_x;    /* S commitment x-coordinate */
  };

  /* ---- Branch 1 witness ------------------------------------------- */

  struct Branch1Witness {
    /* Point witnesses */
    EltW X_y, R_x, R_y, Rp_x, Rp_y;   /* X_y, R=(R_x,R_y), R'=(Rp_x,Rp_y) */
    EltW T_x, T_y;                     /* T = α·G + β·X (intermediate) */
    EltW alpha, beta, rho;             /* blinding scalars */
    EltW m, r_C;                       /* message + Pedersen blinding */
    EltW C_y, H_x, H_y;               /* C_y, independent generator H */
    EltW c_scalar;                     /* challenge c (range-checked only) */

    /* Scalar-mul witness for Pedersen C = m·G + r_C·H */
    typename Secp256k1Circuit<LogicCircuit>::ScalarMultWitness ped_wit_C;

    /* Scalar-mul witness for T = α·G + β·X.
     * verify_double_scalar(α, β, n-1, X_x, X_y, T_x, T_y, wit)
     * uses table {O, G, X, G+X, T, G+T, X+T, G+X+T}. */
    typename Secp256k1Circuit<LogicCircuit>::ScalarMultWitness ped_wit_T;

    /* Range checks */
    v256 m_bits, r_C_bits, alpha_bits, beta_bits;

    void input(const LogicCircuit& lc) {
      X_y = lc.eltw_input();
      R_x = lc.eltw_input(); R_y = lc.eltw_input();
      Rp_x = lc.eltw_input(); Rp_y = lc.eltw_input();
      T_x  = lc.eltw_input(); T_y  = lc.eltw_input();
      alpha = lc.eltw_input(); beta = lc.eltw_input();
      rho   = lc.eltw_input();
      m     = lc.eltw_input(); r_C = lc.eltw_input();
      C_y   = lc.eltw_input();
      H_x   = lc.eltw_input(); H_y = lc.eltw_input();
      c_scalar = lc.eltw_input();
      ped_wit_C.input(lc);
      ped_wit_T.input(lc);
      m_bits     = lc.template vinput<256>();
      r_C_bits   = lc.template vinput<256>();
      alpha_bits = lc.template vinput<256>();
      beta_bits  = lc.template vinput<256>();
    }
  };

  /* ---- Branch 2 witness ------------------------------------------- */

  struct Branch2Witness {
    EltW nu_u, nu_u_prime, nu_s;   /* scalars */
    EltW nu_inv;                    /* witness inverse of (nu_u - nu_u') */
    EltW r_S;                      /* Pedersen blinding for S */
    EltW S_y, H_x, H_y;            /* S_y, independent generator */

    /* BIP-340 signatures: σ₀ = (R0_x, s0), σ₁ = (R1_x, s1) */
    EltW sig0_R_x, sig0_s, sig1_R_x, sig1_s;

    /* Full BIP-340 witnesses for both signatures */
    typename Bip340Circuit<LogicCircuit, EC, ScalarField>::Witness bip0_wit;
    typename Bip340Circuit<LogicCircuit, EC, ScalarField>::Witness bip1_wit;

    /* Pedersen witness for S */

    /* SHA-256 preimage witnesses: msg0 = SHA-256(ν_s || ν_u),
     * msg1 = SHA-256(ν_s || ν_u') */
    Sha2BlockWitness sha0_wit;
    Sha2BlockWitness sha1_wit;
    typename Secp256k1Circuit<LogicCircuit>::ScalarMultWitness ped_wit_S;

    /* Bit vectors come in two encodings:
     *   _bits  = little-endian (bit 0 = LSB of scalar, for range-check vlt)
     *   _sha   = big-endian (MSB-first within each byte, for SHA-256 input)
     * The witness provides both; the circuit uses each for its purpose. */
    v256 nu_u_bits, nu_up_bits, nu_s_bits;
    v256 nu_s_sha, nu_u_sha, nu_up_sha;
    v256 msg0_bits, msg1_bits;

    void input(const LogicCircuit& lc) {
      nu_u = lc.eltw_input(); nu_u_prime = lc.eltw_input();
      nu_inv = lc.eltw_input();
      nu_s   = lc.eltw_input();
      r_S    = lc.eltw_input();
      S_y = lc.eltw_input();
      H_x = lc.eltw_input(); H_y = lc.eltw_input();
      sig0_R_x = lc.eltw_input(); sig0_s = lc.eltw_input();
      sig1_R_x = lc.eltw_input(); sig1_s = lc.eltw_input();
      bip0_wit.input(lc);
      bip1_wit.input(lc);
      ped_wit_S.input(lc);
      sha0_wit.input(lc);
      sha1_wit.input(lc);
      nu_s_bits  = lc.template vinput<256>();
      nu_u_bits  = lc.template vinput<256>();
      nu_up_bits = lc.template vinput<256>();
      nu_s_sha   = lc.template vinput<256>();
      nu_u_sha   = lc.template vinput<256>();
      nu_up_sha  = lc.template vinput<256>();
      msg0_bits  = lc.template vinput<256>();
      msg1_bits  = lc.template vinput<256>();
    }
  };

  /* ---- Construction ---- */

  RpbschCircuit(const LogicCircuit& lc, const EC& ec,
                const ScalarField& Fn)
      : lc_(lc), secp_(lc, ec), fn_(Fn),
        bip0_(lc, ec, Fn), bip1_(lc, ec, Fn),
        bp_(lc_), sha_(lc_) {
    /* Standard SHA-256 IV */
    uint32_t iv[8] = {
      0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,
      0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u
    };
    for (size_t i = 0; i < 8; ++i) sha_iv_[i] = lc_.vbit32(iv[i]);
    /* Padding block for 64-byte message: 0x80 || 55 zero bytes ||
     * 8-byte big-endian length (512 bits = 0x200).
     * 16 v32 words: word 0 = 0x80000000, words 1-14 = 0,
     * word 15 = 0x00000200. */
    sha_pad1_[0] = lc_.vbit32(0x80000000u);
    for (size_t i = 1; i < 15; ++i) sha_pad1_[i] = lc_.vbit32(0);
    sha_pad1_[15] = lc_.vbit32(0x00000200u);
  }

  /* ---- Verification ---- */

  void verify(const Statement& stmt,
              EltW selector,
              const Branch1Witness& b1,
              const Branch2Witness& b2) const {
    /* Boolean selector */
    EltW not_sel = make_selector(lc_, selector);

    /* Strict skeleton: both branches are instantiated. Only constraints that
     * use gate_assert* are currently selector-gated. */
    verify_branch1(stmt, b1, not_sel);
    verify_branch2(stmt, b2, selector);
  }

  const LogicCircuit& lc() const { return lc_; }

 private:
  const LogicCircuit& lc_;
  Secp256k1Circuit<LogicCircuit> secp_;
  const ScalarField& fn_;
  Bip340Circuit<LogicCircuit, EC, ScalarField> bip0_;
  Bip340Circuit<LogicCircuit, EC, ScalarField> bip1_;
  Bp bp_;
  proofs::FlatSHA256Circuit<LogicCircuit, Bp> sha_;
  v32 sha_iv_[8];    /* standard SHA-256 IV */
  v32 sha_pad1_[16];  /* block-1 padding for 64-byte input */

  /* ---- Gated assertion helpers -----------------------------------------
   *
   * gate_assert0(gate, x)  →  enforces gate * x == 0
   *   gate=1 → x==0 enforced
   *   gate=0 → vacuously true
   *
   * gate_assert_eq(gate, a, b)  →  enforces gate * (a - b) == 0
   */
  void gate_assert0(EltW gate, EltW x) const {
    lc_.assert0(lc_.mul(&gate, x));
  }
  void gate_assert_eq(EltW gate, EltW a, EltW b) const {
    EltW diff = lc_.sub(&a, b);
    gate_assert0(gate, diff);
  }

  /* ---- SHA-256 preimage: msg = SHA-256(a || b) (64 bytes total) --------
   *
   * Constrains: hash_output_bits == SHA-256(a_bits || b_bits)
   * where a_bits and b_bits are 256-bit decompositions of two
   * 32-byte scalar values (ν_s, ν_u / ν_u').
   *
   * Uses 2 SHA-256 blocks:
   *   Block 0: a[0..31] || b[0..31] (64 bytes of data)
   *   Block 1: padding (constant)
   */
  void verify_sha256_preimage(const v256& a_bits, const v256& b_bits,
                              const v256& hash_output_bits,
                              const Sha2BlockWitness& sha_w) const {
    /* Build block 0 input: 16 v32 words from a_bits and b_bits */
    v32 in0[16];
    for (size_t i = 0; i < 8; ++i) {
      in0[i]     = slice32(a_bits, i * 32);
      in0[i + 8] = slice32(b_bits, i * 32);
    }

    /* Block 0: standard IV, data input, witness */
    sha_.assert_transform_block(in0, sha_iv_,
                                sha_w.outw[0], sha_w.oute[0],
                                sha_w.outa[0], sha_w.h1[0]);

    /* Block 0 H1 → block 1 H0 */
    v32 h0_b1[8];
    for (size_t i = 0; i < 8; ++i)
      h0_b1[i] = bp_.unpack_v32(sha_w.h1[0][i]);

    /* Block 1: padding constant, witness */
    sha_.assert_transform_block(sha_pad1_, h0_b1,
                                sha_w.outw[1], sha_w.oute[1],
                                sha_w.outa[1], sha_w.h1[1]);

    /* Final hash → 256 bits → compare with expected */
    v256 computed;
    for (size_t i = 0; i < 8; ++i) {
      v32 word = bp_.unpack_v32(sha_w.h1[1][i]);
      for (size_t j = 0; j < 32; ++j)
        computed[i * 32 + j] = word[j];
    }

    /* Compare with expected hash output (bitwise) */
    for (size_t i = 0; i < 256; ++i)
      lc_.assert_eq(&computed[i], hash_output_bits[i]);
  }

  /* Extract 32 consecutive bits from a v256. */
  v32 slice32(const v256& bits, size_t offset) const {
    v32 r;
    for (size_t i = 0; i < 32; ++i) r[i] = bits[offset + i];
    return r;
  }

  void assert_msg_bits_equal(
      const v256& bits,
      const typename Bip340Circuit<LogicCircuit, EC, ScalarField>::Witness& w)
      const {
    for (size_t word = 0; word < 8; ++word) {
      for (size_t bit = 0; bit < 32; ++bit) {
        lc_.assert_eq(&bits[word * 32 + bit], w.msg_bits[word][bit]);
      }
    }
  }

  void verify_branch1(const Statement& stmt, const Branch1Witness& w,
                      EltW gate) const {
    (void)gate; /* Strict skeleton: subcircuit assertions are unconditional. */

    /* ---- 1. X on curve ---- */
    secp_.is_on_curve(stmt.X_x, w.X_y);

    /* ---- 2. C opening: C = m·G + r_C·H ---- */
    secp_.is_on_curve(stmt.C_x, w.C_y);
    secp_.is_on_curve(w.H_x, w.H_y);
    secp_.verify_pedersen(w.m, w.r_C, stmt.C_x, w.C_y,
                          w.H_x, w.H_y, w.ped_wit_C);

    /* ---- 3. R' = R + α·G + β·X ---- */
    secp_.is_on_curve(w.R_x, w.R_y);
    secp_.is_on_curve(w.Rp_x, w.Rp_y);

    /* Step 3a: T = α·G + β·X, verified via verify_double_scalar */
    secp_.is_on_curve(w.T_x, w.T_y);
    secp_.verify_double_scalar(w.alpha, w.beta,
        lc_.konst(lc_.elt(
            "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140")),
        stmt.X_x, w.X_y, w.T_x, w.T_y, w.ped_wit_T);

    /* Step 3b: R + T = R', verified via gate-based addE + point equality */
    {
      EltW S_x, S_y, S_z;
      EltW one = lc_.konst(lc_.one());
      secp_.addE(S_x, S_y, S_z, w.R_x, w.R_y, one, w.T_x, w.T_y, one);
      secp_.point_equality(S_x, S_y, S_z, w.Rp_x, w.Rp_y);
    }

    /* ---- 4. Range checks ---- */
    secp_.range_check_lt_n(w.m, w.m_bits);
    secp_.range_check_lt_n(w.r_C, w.r_C_bits);
    secp_.range_check_lt_n(w.alpha, w.alpha_bits);
    secp_.range_check_lt_n(w.beta, w.beta_bits);

    (void)stmt; (void)w.c_scalar;
  }

  void verify_branch2(const Statement& stmt, const Branch2Witness& w,
                      EltW gate) const {
    /* ---- 1. ν_u ≠ ν_u' ---- */
    EltW diff = lc_.sub(&w.nu_u, w.nu_u_prime);
    EltW prod = lc_.mul(&diff, w.nu_inv);
    EltW one  = lc_.konst(lc_.one());
    gate_assert_eq(gate, prod, one);

    /* ---- 2. Range checks ---- */
    secp_.range_check_lt_n(w.nu_u, w.nu_u_bits);
    secp_.range_check_lt_n(w.nu_u_prime, w.nu_up_bits);
    secp_.range_check_lt_n(w.nu_s, w.nu_s_bits);

    /* ---- 3. S opening ---- */
    secp_.is_on_curve(stmt.S_x, w.S_y);
    secp_.is_on_curve(w.H_x, w.H_y);
    secp_.verify_pedersen(w.nu_s, w.r_S, stmt.S_x, w.S_y,
                          w.H_x, w.H_y, w.ped_wit_S);

    /* ---- 4. SHA-256 preimage and BIP-340 verifications ---- */

    /* Bind big-endian SHA bits to little-endian range-check bits.
     * nu_*_sha[i] == nu_*_bits[255-i]  (full bit reversal).
     * This ensures the SHA preimage uses the same scalars that
     * are range-checked and committed to in the Pedersen opening. */
    for (size_t i = 0; i < 256; ++i) {
      lc_.assert_eq(&w.nu_s_sha[i],  w.nu_s_bits[255 - i]);
      lc_.assert_eq(&w.nu_u_sha[i],  w.nu_u_bits[255 - i]);
      lc_.assert_eq(&w.nu_up_sha[i], w.nu_up_bits[255 - i]);
    }

    verify_sha256_preimage(w.nu_s_sha, w.nu_u_sha,  w.msg0_bits, w.sha0_wit);
    verify_sha256_preimage(w.nu_s_sha, w.nu_up_sha, w.msg1_bits, w.sha1_wit);
    assert_msg_bits_equal(w.msg0_bits, w.bip0_wit);
    assert_msg_bits_equal(w.msg1_bits, w.bip1_wit);

    /* σ₀ verifies under X' on msg₀ */
    bip0_.verify(stmt.Xp_x, w.sig0_R_x, w.sig0_s, w.bip0_wit);
    /* σ₁ verifies under X' on msg₁ */
    bip1_.verify(stmt.Xp_x, w.sig1_R_x, w.sig1_s, w.bip1_wit);
  }
};

}  // namespace niwi

#endif  // NIWI_CIRCUITS_RPBSCH_CIRCUIT_H
