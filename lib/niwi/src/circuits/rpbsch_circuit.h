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
    EltW alpha, beta, rho;             /* blinding scalars */
    EltW m, r_C;                       /* message + Pedersen blinding */
    EltW C_y, H_x, H_y;               /* C_y, independent generator H */
    EltW c_scalar;                     /* challenge c (range-checked only) */

    /* Scalar-mul witness for Pedersen C = m·G + r_C·H */
    typename Secp256k1Circuit<LogicCircuit>::ScalarMultWitness ped_wit_C;

    /* Scalar-mul witness for R' = R + α·G + β·X (triple-scalar) */
    typename Secp256k1Circuit<LogicCircuit>::ScalarMultWitness ped_wit_R;

    /* Range checks */
    v256 m_bits, r_C_bits, alpha_bits, beta_bits;

    void input(const LogicCircuit& lc) {
      X_y = lc.eltw_input();
      R_x = lc.eltw_input(); R_y = lc.eltw_input();
      Rp_x = lc.eltw_input(); Rp_y = lc.eltw_input();
      alpha = lc.eltw_input(); beta = lc.eltw_input();
      rho   = lc.eltw_input();
      m     = lc.eltw_input(); r_C = lc.eltw_input();
      C_y   = lc.eltw_input();
      H_x   = lc.eltw_input(); H_y = lc.eltw_input();
      c_scalar = lc.eltw_input();
      ped_wit_C.input(lc);
      ped_wit_R.input(lc);
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
    typename Secp256k1Circuit<LogicCircuit>::ScalarMultWitness ped_wit_S;

    v256 nu_u_bits, nu_up_bits, nu_s_bits;
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
      nu_u_bits  = lc.template vinput<256>();
      nu_up_bits = lc.template vinput<256>();
      nu_s_bits  = lc.template vinput<256>();
      msg0_bits  = lc.template vinput<256>();
      msg1_bits  = lc.template vinput<256>();
    }
  };

  /* ---- Construction ---- */

  RpbschCircuit(const LogicCircuit& lc, const EC& ec,
                const ScalarField& Fn)
      : lc_(lc), secp_(lc, ec), fn_(Fn),
        bip0_(lc, ec, Fn), bip1_(lc, ec, Fn) {}

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

    /* ---- 3. R' track (on-curve only for now) ---- */
    secp_.is_on_curve(w.R_x, w.R_y);
    secp_.is_on_curve(w.Rp_x, w.Rp_y);
    /* TODO: R' = R + α·G + β·X */

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

    /* ---- 4. BIP-340 message binding and verifications ---- */
    assert_msg_bits_equal(w.msg0_bits, w.bip0_wit);
    assert_msg_bits_equal(w.msg1_bits, w.bip1_wit);
    /* TODO: constrain msg0_bits = SHA-256(ν_s || ν_u) and
     * msg1_bits = SHA-256(ν_s || ν_u') once the RPBSch SHA preimage gadget is
     * added. For now the public message wires are at least bound to the
     * messages consumed by the BIP-340 verifier. */

    /* σ₀ verifies under X' on msg₀ */
    bip0_.verify(stmt.Xp_x, w.sig0_R_x, w.sig0_s, w.bip0_wit);
    /* σ₁ verifies under X' on msg₁ */
    bip1_.verify(stmt.Xp_x, w.sig1_R_x, w.sig1_s, w.bip1_wit);
  }
};

}  // namespace niwi

#endif  // NIWI_CIRCUITS_RPBSCH_CIRCUIT_H
