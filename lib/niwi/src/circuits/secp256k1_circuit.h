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
 * All field constants are stored as native Elt; wire constants are
 * converted via lc_.konst() only where the circuit needs them.
 */

template <class LogicCircuit>
class Secp256k1Circuit {
  using EltW = typename LogicCircuit::EltW;
  using Elt  = typename LogicCircuit::Elt;

  static constexpr size_t kBits = 256;

 public:
  struct ScalarMultWitness {
    EltW pre[8];
    EltW bi[kBits];         /* window: bi[i] = b_s + 2·b_ec + 4·b_c */
    EltW int_x[kBits - 1];
    EltW int_y[kBits - 1];
    EltW int_z[kBits - 1];

    void input(const LogicCircuit& lc) {
      for (size_t i = 0; i < 8; ++i) pre[i] = lc.eltw_input();
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

  template <class EC>
  Secp256k1Circuit(const LogicCircuit& lc, const EC& ec)
      : lc_(lc),
        a_(ec.a_), b_(ec.b_),
        gx_(ec.gx_), gy_(ec.gy_),
        k2_(ec.f_.of_scalar(2)),
        k3_(ec.f_.of_scalar(3)),
        k3b_(ec.k3b) {}

  /* ---- Point arithmetic gates ---- */

  void is_on_curve(EltW x, EltW y) const {
    auto yy  = lc_.mul(&y, y);    /* y*y */
    auto xx  = lc_.mul(&x, x);    /* x*x */
    auto xxx = lc_.mul(&x, xx);   /* x^3 */
    /* a·x + b (a=0 for secp256k1, kept for generality) */
    auto a_w = lc_.konst(a_);
    auto b_w = lc_.konst(b_);
    auto ax  = lc_.mul(a_w, x);
    auto axb = lc_.add(&ax, b_w);
    auto rhs = lc_.add(&axb, xxx);
    lc_.assert_eq(&yy, rhs);
  }

  void point_equality(EltW x1, EltW y1, EltW z1,
                      EltW x2_aff, EltW y2_aff) const {
    lc_.assert_eq(&x1, lc_.mul(&z1, x2_aff));
    lc_.assert_eq(&y1, lc_.mul(&z1, y2_aff));
  }

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
    auto k3b_w = lc_.konst(k3b_);
    EltW Z3t = lc_.mul(k3b_w, t2);
    X3t = lc_.sub(&t1, Z3t);
    Z3t = lc_.add(&t1, Z3t);
    EltW Y3t = lc_.mul(&X3t, Z3t);
    t1 = lc_.add(&t0, t0);
    t1 = lc_.add(&t1, t0);
    t4 = lc_.mul(k3b_w, t4);
    t2 = lc_.konst(a_); (void)t2; /* a=0 → a*t2 = 0 */
    t1 = lc_.add(&t1, t2);
    t2 = lc_.sub(&t0, t2);
    auto a_w = lc_.konst(a_);
    t2 = lc_.mul(a_w, t2);
    t4 = lc_.add(&t4, t2);
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

  void doubleE(EltW& X3, EltW& Y3, EltW& Z3,
               EltW X, EltW Y, EltW Z) const {
    EltW t0 = lc_.mul(&X, X);
    EltW t1 = lc_.mul(&Y, Y);
    EltW t2 = lc_.mul(&Z, Z);
    EltW t3 = lc_.mul(&X, Y);
    t3 = lc_.add(&t3, t3);
    EltW Z3t = lc_.mul(&X, Z);
    Z3t = lc_.add(&Z3t, Z3t);
    auto k3b_w = lc_.konst(k3b_);
    EltW Y3t = lc_.mul(k3b_w, t2);
    EltW X3t = lc_.sub(&t1, Y3t);
    Y3t = lc_.add(&t1, Y3t);
    Y3t = lc_.mul(&X3t, Y3t);
    X3t = lc_.mul(&t3, X3t);
    Z3t = lc_.mul(k3b_w, Z3t);
    t3 = lc_.sub(&t0, t2);
    t3 = lc_.add(&t3, Z3t);
    Z3t = lc_.add(&t0, t0);
    t0 = lc_.add(&Z3t, t0);
    t0 = lc_.add(&t0, t2);
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

  void assert_nonzero(EltW x, EltW inv) const {
    auto one = lc_.konst(lc_.one());
    lc_.assert_eq(&one, lc_.mul(&x, inv));
  }

  void x_only_lift(EltW x, EltW y_witness) const {
    is_on_curve(x, y_witness);
    /* parity check TODO */
  }

  /* ---- Double-scalar multiplication --------------------------
   * Verifies: s·G + e_neg·P + c·R = O
   *
   * For BIP-340: s·G == R + e·P
   *   → s·G + (-e)·P + (-1)·R = O
   *   → s·G + e_neg·P + c·R = O
   * where e_neg = n - e,  c = n - 1  (both positive scalars < n).
   *
   * Window encoding: bi[i] = b_s + 2·b_ec + 4·b_c
   * where b_s, b_ec, b_c are the i-th bits of s, e_neg, c.
   * The witness generator computes e_neg and c natively;
   * the circuit uses actual bits (no complement tricks).
   */
  void verify_double_scalar(EltW s_wire, EltW e_neg_wire, EltW c_wire,
                            EltW P_x, EltW P_y,
                            EltW R_x, EltW R_y,
                            const ScalarMultWitness& w) const {
    EltW zero  = lc_.konst(lc_.zero());
    EltW one   = lc_.konst(lc_.one());
    EltW gx_w  = lc_.konst(gx_);
    EltW gy_w  = lc_.konst(gy_);
    EltW k2_w  = lc_.konst(k2_);

    enum { GP_X=0, GP_Y=1, GR_X=2, GR_Y=3, PR_X=4, PR_Y=5, GPR_X=6, GPR_Y=7 };

    EltW c_gp_x, c_gp_y, c_gp_z;
    EltW c_gr_x, c_gr_y, c_gr_z;
    EltW c_pr_x, c_pr_y, c_pr_z;
    EltW c_gpr_x, c_gpr_y, c_gpr_z;

    addE(c_gp_x, c_gp_y, c_gp_z,  gx_w, gy_w, one, P_x, P_y, one);
    addE(c_gr_x, c_gr_y, c_gr_z,  R_x,  R_y,  one, gx_w, gy_w, one);
    addE(c_pr_x, c_pr_y, c_pr_z,  R_x,  R_y,  one, P_x, P_y, one);
    addE(c_gpr_x, c_gpr_y, c_gpr_z, gx_w, gy_w, one,
         w.pre[PR_X], w.pre[PR_Y], one);

    point_equality(c_gp_x, c_gp_y, c_gp_z,  w.pre[GP_X], w.pre[GP_Y]);
    point_equality(c_gr_x, c_gr_y, c_gr_z,  w.pre[GR_X], w.pre[GR_Y]);
    point_equality(c_pr_x, c_pr_y, c_pr_z,  w.pre[PR_X], w.pre[PR_Y]);
    point_equality(c_gpr_x, c_gpr_y, c_gpr_z, w.pre[GPR_X], w.pre[GPR_Y]);

    EltW arr_x[] = {zero, gx_w, P_x,  w.pre[GP_X],
                    R_x,  w.pre[GR_X], w.pre[PR_X], w.pre[GPR_X]};
    EltW arr_y[] = {one,  gy_w, P_y,  w.pre[GP_Y],
                    R_y,  w.pre[GR_Y], w.pre[PR_Y], w.pre[GPR_Y]};
    EltW arr_z[] = {zero, one,  one,  one, one, one, one, one};

    proofs::EltMuxer<LogicCircuit, 8> mm_x(lc_, arr_x);
    proofs::EltMuxer<LogicCircuit, 8> mm_y(lc_, arr_y);
    proofs::EltMuxer<LogicCircuit, 8> mm_z(lc_, arr_z);

    EltW has_G[] = {zero, one,  zero, one,  zero, one,  zero, one};
    EltW has_P[] = {zero, zero, one,  one,  zero, zero, one,  one};
    EltW has_R[] = {zero, zero, zero, zero, one,  one,  one,  one};
    proofs::EltMuxer<LogicCircuit, 8> mg(lc_, has_G);
    proofs::EltMuxer<LogicCircuit, 8> mp(lc_, has_P);
    proofs::EltMuxer<LogicCircuit, 8> mr(lc_, has_R);

    EltW arr_v[] = {zero, zero, zero, zero, zero, zero, zero, zero, one};
    proofs::EltMuxer<LogicCircuit, 9, 8> vv(lc_, arr_v);

    EltW s_sum = zero, e_sum = zero, c_sum = zero;
    EltW ax = zero, ay = one, az = zero;

    for (size_t i = 0; i < kBits; ++i) {
      EltW tx = mm_x.mux(w.bi[i]);
      EltW ty = mm_y.mux(w.bi[i]);
      EltW tz = mm_z.mux(w.bi[i]);

      EltW b_s  = mg.mux(w.bi[i]);
      EltW b_ec = mp.mux(w.bi[i]);
      EltW b_c  = mr.mux(w.bi[i]);

      s_sum = lc_.add(&b_s,  lc_.mul(k2_w, s_sum));
      e_sum = lc_.add(&b_ec, lc_.mul(k2_w, e_sum));
      c_sum = lc_.add(&b_c,  lc_.mul(k2_w, c_sum));

      EltW range = vv.mux(w.bi[i]);
      lc_.assert0(range);

      if (i > 0) doubleE(ax, ay, az, ax, ay, az);
      addE(ax, ay, az, ax, ay, az, tx, ty, tz);

      if (i < kBits - 1) {
        lc_.assert_eq(&ax, w.int_x[i]);
        lc_.assert_eq(&ay, w.int_y[i]);
        lc_.assert_eq(&az, w.int_z[i]);
        ax = w.int_x[i]; ay = w.int_y[i]; az = w.int_z[i];
      }
    }

    lc_.assert0(ax);
    lc_.assert0(az);
    lc_.assert_eq(&s_sum, s_wire);
    lc_.assert_eq(&e_sum, e_neg_wire);
    lc_.assert_eq(&c_sum, c_wire);
  }

  const LogicCircuit& lc() const { return lc_; }

 private:
  const LogicCircuit& lc_;
  Elt a_, b_, gx_, gy_;
  Elt k2_, k3_, k3b_;
};

}  // namespace niwi

#endif  // NIWI_CIRCUITS_SECP256K1_CIRCUIT_H
