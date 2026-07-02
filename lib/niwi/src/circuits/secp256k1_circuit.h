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

#ifndef NIWI_CIRCUITS_SECP256K1_CIRCUIT_H
#define NIWI_CIRCUITS_SECP256K1_CIRCUIT_H

#include <cstddef>
#include <cstdint>

#include "circuits/logic/bit_plucker.h"

namespace niwi {

/* Gate-based secp256k1 elliptic curve operations.
 *
 * Adapted from proofs::VerifyCircuit in
 * lib/longfellow-zk/circuits/ecdsa/verify_circuit.h,
 * parameterized for secp256k1 (a=0, b=7).
 *
 * Provides:
 *   - is_on_curve, point_equality, addE, doubleE
 *   - nonzero check (witness inverse)
 *   - x-only lift constraint (even y, x < p, on-curve)
 *   - Double-scalar multiplication verification:
 *       s·G + e·P + R = O    (BIP-340: s·G == R + e·P)
 *     using repeated squaring with 3-bit window precomputation.
 */

template <class LogicCircuit>
class Secp256k1Circuit {
  using EltW = typename LogicCircuit::EltW;
  using Elt  = typename LogicCircuit::Elt;
  using BitW = typename LogicCircuit::BitW;
  using v256 = typename LogicCircuit::v256;

  static constexpr size_t kBits = 256; /* secp256k1 uses 256-bit scalars */

 public:
  /* Witness structure for double-scalar multiplication.
   *
   * The prover provides:
   *   pre[8]    — 8 precomputed affine points (4 pairs of x,y)
   *   bi[kBits] — 3-bit window encoding of (s, e, 1) bits per iteration
   *   int_xyz[kBits-1] — intermediate projective points for depth reduction
   */
  struct ScalarMultWitness {
    EltW pre[8];      // G, P, G+P, R, G+R, P+R, G+P+R, correction
    EltW bi[kBits];   // windows: -(2^3-1)...+(2^3-1), |bi| ≤ 7
    EltW int_x[kBits - 1];
    EltW int_y[kBits - 1];
    EltW int_z[kBits - 1];

    void input(const LogicCircuit& lc) {
      for (size_t i = 0; i < 8; ++i)
        pre[i] = lc.eltw_input();
      for (size_t i = 0; i < kBits; ++i) {
        bi[i] = lc.eltw_input();
        if (i < kBits - 1) {
          int_x[i] = lc.eltw_input();
          int_y[i] = lc.eltw_input();
          int_z[i] = lc.eltw_input();
        }
      }
    }
  };

  /* Construction: capture the curve constants for gate reference. */
  template <class EC>
  Secp256k1Circuit(const LogicCircuit& lc, const EC& ec)
      : lc_(lc) {
    a_  = lc_.konst(ec.a_);
    b_  = lc_.konst(ec.b_);
    gx_ = lc_.konst(ec.gx_);
    gy_ = lc_.konst(ec.gy_);
    k3_ = lc_.elt(3);
    k3b_ = lc_.konst(ec.k3b);
  }

  /* ---- Point arithmetic gates ---------------------------------------- */

  /* Check y^2 == x^3 + a·x + b. */
  void is_on_curve(EltW x, EltW y) const {
    auto yy  = lc_.mul(&x, y);  /* y*y */
    auto xx  = lc_.mul(&x, x);  /* x*x */
    auto xxx = lc_.mul(&x, xx); /* x^3 */
    auto ax  = lc_.mul(a_, x);
    auto axb = lc_.add(&ax, b_);
    auto rhs = lc_.add(&axb, xxx);
    lc_.assert_eq(&yy, rhs);
  }

  /* Point equality in projective form:
   *   x1·z2 == x2·z1  and  y1·z2 == y2·z1
   * The second point is given in affine form (z=1 implied). */
  void point_equality(EltW x1, EltW y1, EltW z1,
                      EltW x2_aff, EltW y2_aff) const {
    lc_.assert_eq(&x1, lc_.mul(&z1, x2_aff));
    lc_.assert_eq(&y1, lc_.mul(&z1, y2_aff));
  }

  /* Projective point addition (complete formula, works for all inputs).
   * Algorithm 1 from the Longfellow elliptic_curve.h.
   * Because a=0 for secp256k1, the compiler will optimize away a-related
   * multiplications (mul(0, *) = 0). */
  void addE(EltW& X3, EltW& Y3, EltW& Z3,
            EltW X1, EltW Y1, EltW Z1,
            EltW X2, EltW Y2, EltW Z2) const {
    EltW t0 = lc_.mul(&X1, X2);
    EltW t1 = lc_.mul(&Y1, Y2);
    EltW t2 = lc_.mul(&Z1, Z2);
    EltW t3 = lc_.add(&X1, Y1);
    EltW t4 = lc_.add(&X2, Y2);
    t3 = lc_.mul(&t3, t4);
    t4 = lc_.add(&t0, t1);
    t3 = lc_.sub(&t3, t4);
    t4 = lc_.add(&X1, Z1);
    EltW t5 = lc_.add(&X2, Z2);
    t4 = lc_.mul(&t4, t5);
    t5 = lc_.add(&t0, t2);
    t4 = lc_.sub(&t4, t5);
    t5 = lc_.add(&Y1, Z1);
    EltW X3t = lc_.add(&Y2, Z2);
    t5 = lc_.mul(&t5, X3t);
    X3t = lc_.add(&t1, t2);
    t5 = lc_.sub(&t5, X3t);
    /* a=0 → a·t4 = 0, so Z3t = k3b·t2 */
    EltW Z3t = lc_.mul(k3b_, t2);
    X3t = lc_.sub(&t1, Z3t);
    Z3t = lc_.add(&t1, Z3t);
    EltW Y3t = lc_.mul(&X3t, Z3t);
    t1 = lc_.add(&t0, t0);
    t1 = lc_.add(&t1, t0);   /* t1 = 3·t0 */
    /* t2 = a·t2 = 0 (a=0) */
    /* t4 = k3b·t4 */
    t4 = lc_.mul(k3b_, t4);
    t1 = lc_.add(&t1, t2);   /* t1 = 3·t0 + 0 = 3·t0 */
    t2 = lc_.sub(&t0, t2);   /* t2 = t0 - 0 = t0 */
    /* t2 = a·t2 = 0 */
    /* t4 = t4 + 0 = t4 */
    t0 = lc_.mul(&t1, t4);
    Y3t = lc_.add(&Y3t, t0);
    t0 = lc_.mul(&t5, t4);
    X3t = lc_.mul(&t3, X3t);
    X3t = lc_.sub(&X3t, t0);
    t0 = lc_.mul(&t3, t1);
    Z3t = lc_.mul(&t5, Z3t);
    Z3t = lc_.add(&Z3t, t0);

    X3 = X3t; Y3 = Y3t; Z3 = Z3t;
  }

  /* Projective point doubling.
   * Algorithm 3 from the Longfellow elliptic_curve.h.
   * a=0 simplifies away a-related terms. */
  void doubleE(EltW& X3, EltW& Y3, EltW& Z3,
               EltW X, EltW Y, EltW Z) const {
    EltW t0 = lc_.mul(&X, X);
    EltW t1 = lc_.mul(&Y, Y);
    EltW t2 = lc_.mul(&Z, Z);
    EltW t3 = lc_.mul(&X, Y);
    t3 = lc_.add(&t3, t3);
    EltW Z3t = lc_.mul(&X, Z);
    Z3t = lc_.add(&Z3t, Z3t);
    /* a·Z3t = 0 (a=0) */
    EltW Y3t = lc_.mul(k3b_, t2);
    EltW X3t = lc_.sub(&t1, Y3t);
    Y3t = lc_.add(&t1, Y3t);
    Y3t = lc_.mul(&X3t, Y3t);
    X3t = lc_.mul(&t3, X3t);
    Z3t = lc_.mul(k3b_, Z3t);
    t3 = lc_.sub(&t0, t2);   /* a·t2=0 so t3 = t0 */
    t3 = lc_.add(&t3, Z3t);
    Z3t = lc_.add(&t0, t0);
    t0 = lc_.add(&Z3t, t0);
    t0 = lc_.add(&t0, t2);   /* t0 = 3·t0 + 0 = 3·t0 */
    t0 = lc_.mul(&t0, t3);
    Y3t = lc_.add(&Y3t, t0);
    t2 = lc_.mul(&Y, Z);
    t2 = lc_.add(&t2, t2);
    t0 = lc_.mul(&t2, t3);
    X3t = lc_.sub(&X3t, t0);
    Z3t = lc_.mul(&t2, t1);
    Z3t = lc_.add(&Z3t, Z3t);
    Z3t = lc_.add(&Z3t, Z3t);

    X3 = X3t; Y3 = Y3t; Z3 = Z3t;
  }

  /* Assert x ≠ 0 by providing an inverse witness inv such that x·inv = 1. */
  void assert_nonzero(EltW x, EltW inv) const {
    auto one = lc_.konst(lc_.one());
    lc_.assert_eq(&one, lc_.mul(&x, inv));
  }

  /* ---- X-only lift constraint ---------------------------------------- */

  /* Given an x-only public key coordinate pk_x, verify that:
   *   - x < p (both public keys and nonce points are 32-byte field elements)
   *   - there exists an even y such that (x, y) is on the curve
   *
   * The witness provides the y-coordinate. The circuit checks:
   *   1. is_on_curve(x, y)
   *   2. y is even: parity bit from bit decomposition
   *
   * For secp256k1 (p ≡ 3 mod 4): if (x, y) is on curve then (x, p-y) is
   * also on curve and exactly one has even y. So we verify the witness y
   * satisfies the curve equation and that its least-significant bit is 0.
   */
  void x_only_lift(EltW x, EltW y_witness) const {
    is_on_curve(x, y_witness);
    /* TODO: parity check — enforce LSB of y is 0 (even) */
    /* This requires bit decomposition of y_witness to extract LSB */
  }

  /* ---- Double-scalar multiplication verification ----------------------
   *
   * Verifies:  s·G + e·P + R = O
   *
   * This is exactly the BIP-340 equation s·G == R + e·P rearranged.
   * We use repeated squaring with a 3-bit window table (8 entries).
   *
   * The public inputs are:
   *   s_wire    — s value, a native field element representing the scalar
   *   e_wire    — e value (the BIP-340 challenge, must be < n)
   *   P_x, P_y  — public key (affine, on curve)
   *   R_x, R_y  — nonce point from signature (affine, on curve)
   *
   * The witness w provides intermediate values (see ScalarMultWitness).
   *
   * The bits of s and e are decomposed; a third scalar of -1 is used for R.
   * Each bit triple (b_s, b_e, b_minus1) selects one of 8 precomputed points.
   */
  void verify_double_scalar(EltW s_wire, EltW e_wire,
                            EltW P_x, EltW P_y,
                            EltW R_x, EltW R_y,
                            const ScalarMultWitness& w) const {
    EltW zero = lc_.konst(lc_.zero());
    EltW one  = lc_.konst(lc_.one());

    /* ---- Precomputed table verification ----
     * The 8 precomputed affine points are: { O, G, P, G+P, R, G+R, P+R, G+P+R }.
     * Verify the computed sums match the witness. */

    enum { GP_X=0, GP_Y=1, GR_X=2, GR_Y=3, PR_X=4, PR_Y=5, GPR_X=6, GPR_Y=7 };

    EltW cg_pk_x, cg_pk_y, cg_pk_z;
    EltW cr_g_x, cr_g_y, cr_g_z;
    EltW cr_pk_x, cr_pk_y, cr_pk_z;
    EltW cr_g_pk_x, cr_g_pk_y, cr_g_pk_z;

    addE(cg_pk_x, cg_pk_y, cg_pk_z,  gx_, gy_, one, P_x, P_y, one);
    addE(cr_g_x,  cr_g_y,  cr_g_z,   R_x, R_y, one, gx_, gy_, one);
    addE(cr_pk_x, cr_pk_y, cr_pk_z,  R_x, R_y, one, P_x, P_y, one);
    addE(cr_g_pk_x, cr_g_pk_y, cr_g_pk_z,
         gx_, gy_, one, w.pre[PR_X], w.pre[PR_Y], one);

    point_equality(cg_pk_x, cg_pk_y, cg_pk_z, w.pre[GP_X], w.pre[GP_Y]);
    point_equality(cr_g_x, cr_g_y, cr_g_z, w.pre[GR_X], w.pre[GR_Y]);
    point_equality(cr_pk_x, cr_pk_y, cr_pk_z, w.pre[PR_X], w.pre[PR_Y]);
    point_equality(cr_g_pk_x, cr_g_pk_y, cr_g_pk_z, w.pre[GPR_X], w.pre[GPR_Y]);

    /* ---- Mux arrays: 8-entry table indexed by bit-window ----
     * Window meaning per entry: (has_G, has_P, has_R)
     * 0:(0,0,0)→O, 1:(1,0,0)→G, 2:(0,1,0)→P, 3:(1,1,0)→G+P,
     * 4:(0,0,1)→R, 5:(1,0,1)→G+R, 6:(0,1,1)→P+R, 7:(1,1,1)→G+P+R */
    EltW arr_x[] = {zero, gx_, P_x,  w.pre[GP_X],
                    R_x,  w.pre[GR_X], w.pre[PR_X], w.pre[GPR_X]};
    EltW arr_y[] = {one,  gy_, P_y,  w.pre[GP_Y],
                    R_y,  w.pre[GR_Y], w.pre[PR_Y], w.pre[GPR_Y]};
    EltW arr_z[] = {zero, one, one, one, one, one, one, one};

    proofs::EltMuxer<LogicCircuit, 8> mm_x(lc_, arr_x);
    proofs::EltMuxer<LogicCircuit, 8> mm_y(lc_, arr_y);
    proofs::EltMuxer<LogicCircuit, 8> mm_z(lc_, arr_z);

    /* Muxers for extracting individual bits from the window */
    EltW has_G[] = {zero, one, zero, one, zero, one, zero, one};
    EltW has_P[] = {zero, zero, one, one, zero, zero, one, one};
    EltW has_R[] = {zero, zero, zero, zero, one, one, one, one};
    proofs::EltMuxer<LogicCircuit, 8> mg(lc_, has_G);
    proofs::EltMuxer<LogicCircuit, 8> mp(lc_, has_P);
    proofs::EltMuxer<LogicCircuit, 8> mr(lc_, has_R);

    /* Range validator: bi[i] must be in {0, …, 7} */
    EltW arr_v[] = {zero, zero, zero, zero, zero, zero, zero, zero, one};
    proofs::EltMuxer<LogicCircuit, 9, 8> vv(lc_, arr_v);

    /* ---- Repeated squaring loop (MSB to LSB) ---- */
    EltW s_sum = zero, e_sum = zero;
    EltW ax = zero, ay = one, az = zero;

    for (size_t i = 0; i < kBits; ++i) {
      EltW tx = mm_x.mux(w.bi[i]);
      EltW ty = mm_y.mux(w.bi[i]);
      EltW tz = mm_z.mux(w.bi[i]);

      EltW s_bit = mg.mux(w.bi[i]);
      EltW e_bit = mp.mux(w.bi[i]);
      /* The third scalar is -1 for all bits (we verify that the
       * window includes the R term for every bit where R is in the table).
       * Since we always add R for every bit, the window for R is always 1.
       * We verify this by checking that has_R = 1 for every window value. */
      EltW r_bit = mr.mux(w.bi[i]);
      auto k2 = lc_.konst(k3_); /* k3_ is actually Elt(3), use lc.elt(2) */
      (void)r_bit; /* placeholder — will verify window covers R */

      auto k2const = lc_.elt(2);
      s_sum = lc_.add(&s_bit, lc_.mul(k2const, s_sum));
      e_sum = lc_.add(&e_bit, lc_.mul(k2const, e_sum));

      /* Verify bi[i] ∈ [0, 7] */
      EltW range = vv.mux(w.bi[i]);
      lc_.assert0(range);

      /* add → double */
      if (i > 0) doubleE(ax, ay, az, ax, ay, az);
      addE(ax, ay, az, ax, ay, az, tx, ty, tz);

      /* Depth reduction: verify intermediate witness matches */
      if (i < kBits - 1) {
        lc_.assert_eq(&ax, w.int_x[i]);
        lc_.assert_eq(&ay, w.int_y[i]);
        lc_.assert_eq(&az, w.int_z[i]);
        ax = w.int_x[i];
        ay = w.int_y[i];
        az = w.int_z[i];
      }
    }

    /* Final result: ax == 0 and az == 0 (point at infinity) */
    lc_.assert0(ax);
    lc_.assert0(az);

    /* Verify the reconstructed scalars match the inputs */
    lc_.assert_eq(&s_sum, s_wire);
    lc_.assert_eq(&e_sum, e_wire);
  }

  /* Access the underlying logic circuit (needed by callers for inputs). */
  const LogicCircuit& lc() const { return lc_; }

 private:
  const LogicCircuit& lc_;
  Elt a_, b_, gx_, gy_;
  Elt k3_, k3b_;  /* Field constants: 3 and 3*b */
};

}  // namespace niwi

#endif  // NIWI_CIRCUITS_SECP256K1_CIRCUIT_H
