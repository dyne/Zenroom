// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_ECDSA_VERIFY_CIRCUIT_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_ECDSA_VERIFY_CIRCUIT_H_

#include <stddef.h>

#include "circuits/compiler/compiler.h"
#include "circuits/logic/bit_plucker.h"

namespace proofs {
// Verify ECDSA signature using triple scalar mult form.
//
// The field used by sumcheck is the base field of the elliptic curve.
// Compiled circuit: ecdsa verify
//  d: 7 wires: 21099 in: 1038 out:764 use:13911 ovh:7188 t:42963 cse:11351
//  notn:34724
//
template <class LogicCircuit, class Field, class EC>
class VerifyCircuit {
  using EltW = typename LogicCircuit::EltW;
  using BitW = typename LogicCircuit::BitW;
  using Elt = typename LogicCircuit::Elt;
  using Nat = typename Field::N;
  static constexpr size_t kBits = EC::kBits;
  using Bitvec = typename LogicCircuit::v256;

 public:
  struct Witness {
    EltW rx, ry;
    EltW pre[8];
    EltW rx_inv, s_inv, pk_inv;
    EltW bi[kBits];
    EltW int_x[kBits - 1];
    EltW int_y[kBits - 1];
    EltW int_z[kBits - 1];

    void input(QuadCircuit<Field>& Q) {
      rx = Q.input();
      ry = Q.input();
      rx_inv = Q.input();
      s_inv = Q.input();
      pk_inv = Q.input();
      for (size_t i = 0; i < 8; ++i) {
        pre[i] = Q.input();
      }
      for (size_t i = 0; i < kBits; ++i) {
        bi[i] = Q.input();
        if (i < kBits - 1) {
          int_x[i] = Q.input();
          int_y[i] = Q.input();
          int_z[i] = Q.input();
        }
      }
    }
  };

  VerifyCircuit(const LogicCircuit& lc, const EC& ec, const Nat& order)
      : lc_(lc), ec_(ec), k2_(lc_.elt(2)), k3_(lc_.elt(3)) {
    // Compute the bit representation of the order of the curve.
    for (size_t i = 0; i < ec.kBits; ++i) {
      bits_n_[i] = lc_.bit(order.bit(i));
    }
  }

  // This verify takes the triple (pkx,pky,e) and checks that there exists
  //     (r=rx, ry, s) such that:
  //           identity = g*e + pk*r + (rx,ry)*-s
  // It performs this check using a witness table that includes
  // (g+pk, g+r, r+pk, g+r+pk), a correction element,
  // bits of exponents (e, r, -s) s.t. each triple of bits is packed into {0,7},
  // and intermediate ec points in (x,y,z) form.  The bits are used to index the
  // witness table in order to compute the right-hand side in a loop.  The loop
  // is sliced by providing the intermediate results in order reduce depth.
  //
  // An external constraint will need to ensure that e \neq 0 (e.g.,
  // either the verifier checks this as part of the public input, or
  // the hash that defines e is produced in the circuit).  In our mdoc case,
  // we use the later checks for both signatures.
  //
  // Other checks:
  //   r is interpreted as both in the base field and the scalar field.
  //   As a result, rx_inv is provided to ensure that r != 0.
  //   Similarly, s_inv is provided to ensure that s != 0.
  //
  //   (rx,ry) is verified to be on the curve.
  //
  //   (pkx, pky) \neq identity, because we set pk_z=1, we verify that
  //    pkx != 0, and we ensure that (pkx,pky) is on the curve.
  //
  void verify_signature3(EltW pk_x, EltW pk_y, EltW e, const Witness& w) const {
    EltW zero = lc_.konst(lc_.zero());
    EltW one = lc_.konst(lc_.one());
    EltW gx = lc_.konst(ec_.gx_), gy = lc_.konst(ec_.gy_);

    // indices for the pre[] table, don't change order
    enum PreIndex {
      GPK_X = 0,
      GPK_Y,
      GR_X,
      GR_Y,
      RPK_X,
      RPK_Y,
      GRPK_X,
      GRPK_Y
    };

    // These variables hold the (e,r) exponents which are computed from the
    // bits of advice (e,r,-s).  They are compared with their expected values.
    EltW est = zero, rst = zero, sst = zero;

    // initialize at the 0 point, but these indices are reset on each loop
    EltW ax = zero, ay = one, az = zero;

    // =========
    // Verify the values received in the table are correct.
    // By verifying these values in parallel with using them, we can reduce
    // the depth of the resulting circuit.
    EltW cg_pkx, cg_pky, cg_pkz;
    EltW cr_pkx, cr_pky, cr_pkz;
    EltW cr_gx, cr_gy, cr_gz;
    EltW cr_g_pkx, cr_g_pky, cr_g_pkz;
    addE(cg_pkx, cg_pky, cg_pkz, gx, gy, one, pk_x, pk_y, one);
    addE(cr_gx, cr_gy, cr_gz, w.rx, w.ry, one, gx, gy, one);
    addE(cr_pkx, cr_pky, cr_pkz, w.rx, w.ry, one, pk_x, pk_y, one);
    addE(cr_g_pkx, cr_g_pky, cr_g_pkz, gx, gy, one, w.pre[RPK_X], w.pre[RPK_Y],
         one);
    point_equality(cg_pkx, cg_pky, cg_pkz, w.pre[GPK_X], w.pre[GPK_Y]);
    point_equality(cr_gx, cr_gy, cr_gz, w.pre[GR_X], w.pre[GR_Y]);
    point_equality(cr_pkx, cr_pky, cr_pkz, w.pre[RPK_X], w.pre[RPK_Y]);
    point_equality(cr_g_pkx, cr_g_pky, cr_g_pkz, w.pre[GRPK_X], w.pre[GRPK_Y]);

    EltW arr_x[] = {zero, gx,          pk_x,         w.pre[GPK_X],
                    w.rx, w.pre[GR_X], w.pre[RPK_X], w.pre[GRPK_X]};
    EltW arr_y[] = {one,  gy,          pk_y,         w.pre[GPK_Y],
                    w.ry, w.pre[GR_Y], w.pre[RPK_Y], w.pre[GRPK_Y]};
    EltW arr_z[] = {zero, one, one, one, one, one, one, one};
    EltW arr_e[] = {zero, one, zero, one, zero, one, zero, one};
    EltW arr_r[] = {zero, zero, one, one, zero, zero, one, one};
    EltW arr_s[] = {zero, zero, zero, zero, one, one, one, one};
    EltW arr_v[] = {one, one, one, one, one, one, one, one};

    EltMuxer<LogicCircuit, 3> xx(lc_, arr_x);
    EltMuxer<LogicCircuit, 3> yy(lc_, arr_y);
    EltMuxer<LogicCircuit, 3> zz(lc_, arr_z);
    EltMuxer<LogicCircuit, 3> ee(lc_, arr_e);
    EltMuxer<LogicCircuit, 3> rr(lc_, arr_r);
    EltMuxer<LogicCircuit, 3> ss(lc_, arr_s);
    EltMuxer<LogicCircuit, 3> vv(lc_, arr_v);

    Bitvec r_bits, s_bits;

    // Traverses the bits of the scalar from high-order to low-order.
    for (size_t i = 0; i < kBits; ++i) {
      // Use the arr{X..V} arrays and the muxer to pick the correct point
      // slice based on the bits of advice in the witness.
      EltW tx = xx.mux(w.bi[i]);
      EltW ty = yy.mux(w.bi[i]);
      EltW tz = zz.mux(w.bi[i]);

      // Update the exponent.
      EltW e_bi = ee.mux(w.bi[i]);
      EltW r_bi = rr.mux(w.bi[i]);
      EltW s_bi = ss.mux(w.bi[i]);
      auto k2 = lc_.konst(k2_);
      est = lc_.add(&e_bi, lc_.mul(&k2, est));
      rst = lc_.add(&r_bi, lc_.mul(&k2, rst));
      sst = lc_.add(&s_bi, lc_.mul(&k2, sst));
      r_bits[kBits - i - 1] = BitW(r_bi, ec_.f_);
      s_bits[kBits - i - 1] = BitW(s_bi, ec_.f_);

      // Verify that the advice bit is in [0,7].
      EltW range = vv.mux(w.bi[i]);
      lc_.assert_eq(&range, one);

      // Perform the basic add-dbl step in repeated squaring using the
      // muxed point {tx, ty, tz}.
      if (i > 0) {
        doubleE(ax, ay, az, ax, ay, az);
      }
      addE(ax, ay, az, ax, ay, az, tx, ty, tz);

      if (i < kBits - 1) {
        // Ensure that the resulting point is equal to the intermediate
        // point provided as input. Performing an explicit equality check
        // ensures that all intermediate witness points are on the curve.
        // This follows by induction. The first (ax,ay,az) is on the curve.
        // The addition formula ensures that the i-th (ax,ay,az) is on the
        // curve; equality ensures that the i-th witness is on the curve.
        lc_.assert_eq(&ax, w.int_x[i]);
        lc_.assert_eq(&ay, w.int_y[i]);
        lc_.assert_eq(&az, w.int_z[i]);

        // Use the intermediate (x,y,z) point as the next input.
        ax = w.int_x[i];
        ay = w.int_y[i];
        az = w.int_z[i];
      }
    }

    // Check that the aX,aZ points are 0.
    lc_.assert0(ax);
    lc_.assert0(az);

    // Check that the bits used for {e,rx} correspond to the input {e, rx}.
    lc_.assert_eq(&est, e);
    lc_.assert_eq(&rst, w.rx);

    // Check that (pk,py), (rx,ry) satisfy the curve equation.
    is_on_curve(pk_x, pk_y);
    is_on_curve(w.rx, w.ry);

    // Verify that exponents (r,s) are not zero.
    //   A witness is provided to ensure that both values have inverses in F.
    //   A bitwise comparison is done to ensure both are < |order| of EC.
    assert_nonzero(w.rx, w.rx_inv);
    assert_nonzero(sst, w.s_inv);
    assert_nonzero(pk_x, w.pk_inv);
    auto r_range = lc_.vlt(&r_bits, bits_n_);
    auto s_range = lc_.vlt(&s_bits, bits_n_);
    lc_.assert1(r_range);
    lc_.assert1(s_range);
  }

 private:
  void assert_nonzero(EltW x, EltW witness) const {
    auto maybe_one = lc_.mul(&x, witness);
    auto one = lc_.konst(lc_.one());
    lc_.assert_eq(&maybe_one, one);
  }

  void point_equality(EltW x, EltW y, EltW z, EltW p_x, EltW p_y) const {
    lc_.assert_eq(&x, lc_.mul(&z, p_x));
    lc_.assert_eq(&y, lc_.mul(&z, p_y));
  }

  void is_on_curve(EltW x, EltW y) const {
    // Check that y^2 = x^3 + ax + b
    auto yy = lc_.mul(&y, y);
    auto xx = lc_.mul(&x, x);
    auto xxx = lc_.mul(&x, xx);
    auto ax = lc_.mul(ec_.a_, x);
    auto b = lc_.konst(ec_.b_);
    auto axb = lc_.add(&ax, b);
    auto rhs = lc_.add(&axb, xxx);
    lc_.assert_eq(&yy, rhs);
  }

  void addE(EltW& X3, EltW& Y3, EltW& Z3, EltW X1, EltW Y1, EltW Z1, EltW X2,
            EltW Y2, EltW Z2) const {
    // The general case.
    // Algorithm 1: Complete, projective point addition for arbitrary prime
    // order short Weierstrass curves E/Fq : y^2 = x^3 + ax + b
    // The compiler seems to optimize the cases when Z1,Z2=1.
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
    auto a = lc_.konst(ec_.a_);
    EltW Z3t = lc_.mul(&a, t4);
    auto k3b = lc_.konst(ec_.k3b);
    X3t = lc_.mul(&k3b, t2);
    Z3t = lc_.add(&X3t, Z3t);
    X3t = lc_.sub(&t1, Z3t);
    Z3t = lc_.add(&t1, Z3t);
    EltW Y3t = lc_.mul(&X3t, Z3t);
    t1 = lc_.add(&t0, t0);
    t1 = lc_.add(&t1, t0);
    t2 = lc_.mul(&a, t2);
    t4 = lc_.mul(&k3b, t4);
    t1 = lc_.add(&t1, t2);
    t2 = lc_.sub(&t0, t2);
    t2 = lc_.mul(&a, t2);
    t4 = lc_.add(&t4, t2);
    t0 = lc_.mul(&t1, t4);
    Y3t = lc_.add(&Y3t, t0);
    t0 = lc_.mul(&t5, t4);
    X3t = lc_.mul(&t3, X3t);
    X3t = lc_.sub(&X3t, t0);
    t0 = lc_.mul(&t3, t1);
    Z3t = lc_.mul(&t5, Z3t);
    Z3t = lc_.add(&Z3t, t0);

    X3 = X3t;
    Y3 = Y3t;
    Z3 = Z3t;
  }

  void doubleE(EltW& X3, EltW& Y3, EltW& Z3, EltW X, EltW Y, EltW Z) const {
    // The general case.
    // Algorithm 3: Exception-free point doubling for arbitrary prime order
    // short Weierstrass curves E/Fq : y^2 = x^3 + ax + b.
    // The compiler will presumably optimize away 0 mults when a=0 and 1
    // mults when Z = 1.
    EltW t0 = lc_.mul(&X, X);
    EltW t1 = lc_.mul(&Y, Y);
    EltW t2 = lc_.mul(&Z, Z);
    EltW t3 = lc_.mul(&X, Y);
    t3 = lc_.add(&t3, t3);
    EltW Z3t = lc_.mul(&X, Z);
    Z3t = lc_.add(&Z3t, Z3t);
    auto a = lc_.konst(ec_.a_);
    auto k3b = lc_.konst(ec_.k3b);
    EltW X3t = lc_.mul(&a, Z3t);
    EltW Y3t = lc_.mul(&k3b, t2);
    Y3t = lc_.add(&X3t, Y3t);
    X3t = lc_.sub(&t1, Y3t);
    Y3t = lc_.add(&t1, Y3t);
    Y3t = lc_.mul(&X3t, Y3t);
    X3t = lc_.mul(&t3, X3t);
    Z3t = lc_.mul(&k3b, Z3t);
    t2 = lc_.mul(&a, t2);
    t3 = lc_.sub(&t0, t2);
    t3 = lc_.mul(&a, t3);
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

    X3 = X3t;
    Y3 = Y3t;
    Z3 = Z3t;
  }

  const LogicCircuit& lc_;
  const EC& ec_;

  Elt k2_, k3_;
  Bitvec bits_n_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_ECDSA_VERIFY_CIRCUIT_H_
