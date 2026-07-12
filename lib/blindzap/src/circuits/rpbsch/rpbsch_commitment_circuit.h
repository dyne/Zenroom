/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_CIRCUITS_RPBSCH_COMMITMENT_CIRCUIT_H
#define NIWI_CIRCUITS_RPBSCH_COMMITMENT_CIRCUIT_H

#include <cstddef>

#include "circuits/secp256k1_circuit.h"
#include "secp256k1/secp256k1_curve.h"

namespace niwi::rpbsch {

/* Circuit helpers for RPBSch's current commitment profile.
 *
 * This is still the binding Pedersen profile, not the paper-exact
 * straight-line extractable Cmt. These helpers only make the current C/S
 * compressed secp256k1 encodings relation-visible before the Pedersen
 * opening equations are added.
 */
template <class LogicCircuit>
class RpbschCommitmentCircuit {
  using EltW = typename LogicCircuit::EltW;

  static constexpr size_t kBits = 256;

 public:
  struct Point {
    EltW x;
    EltW y;
    EltW z;
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

  explicit RpbschCommitmentCircuit(const LogicCircuit& lc)
      : lc_(lc), secp_(lc, niwi::secp256k1) {}

  /* Assert that prefix||x encodes the curve point opened by y/y_bits.
   *
   * Prefix 0x02 means even y; prefix 0x03 means odd y. The y_bits array is
   * big-endian, so y_bits[255] is the least-significant/parity bit.
   */
  void assert_compressed_point(EltW prefix, EltW x, EltW y,
                               const EltW y_bits[kBits]) const {
    secp_.assert_lift(x, y, y_bits);

    auto two = lc_.konst(lc_.elt(2));
    auto parity = lc_.sub(prefix, two);
    lc_.assert_is_bit(parity);
    lc_.assert_eq(parity, y_bits[kBits - 1]);
  }

  /* Assert Pedersen opening: C = msg*G + rho*H.
   *
   * The caller supplies the current profile's H point as constants or public
   * wires. This remains the binding Pedersen profile, not paper-exact Cmt.
   */
  void assert_pedersen_opening(EltW prefix, EltW c_x, EltW c_y,
                               const EltW c_y_bits[kBits],
                               EltW msg, EltW rho,
                               EltW h_x, EltW h_y,
                               const PedersenOpeningWitness& w) const {
    assert_compressed_point(prefix, c_x, c_y, c_y_bits);

    assert_field_from_bits_msb(w.msg.bits, msg);
    assert_field_from_bits_msb(w.rho.bits, rho);

    auto one = lc_.konst(lc_.one());
    auto gx = lc_.konst(niwi::secp256k1.gx_);
    auto gy = lc_.konst(niwi::secp256k1.gy_);

    auto msg_g = scalar_mult(gx, gy, one, w.msg);
    auto rho_h = scalar_mult(h_x, h_y, one, w.rho);
    assert_same_projective_point(msg_g, w.msg_point);
    assert_same_projective_point(rho_h, w.rho_point);
    Point sum;
    secp_.addE(sum.x, sum.y, sum.z,
               w.msg_point.x, w.msg_point.y, w.msg_point.z,
               w.rho_point.x, w.rho_point.y, w.rho_point.z);

    secp_.assert_nonzero(sum.z, w.sum_z_inv);
    lc_.assert_eq(lc_.mul(sum.x, w.sum_z_inv), c_x);
    lc_.assert_eq(lc_.mul(sum.y, w.sum_z_inv), c_y);
  }

 private:
  const LogicCircuit& lc_;
  niwi::Secp256k1Circuit<LogicCircuit> secp_;

  void assert_field_from_bits_msb(const EltW bits[kBits], EltW value) const {
    EltW check = lc_.konst(lc_.zero());
    for (size_t i = 0; i < kBits; ++i) {
      lc_.assert_is_bit(bits[i]);
      check = lc_.add(check, check);
      check = lc_.add(check, bits[i]);
    }
    lc_.assert_eq(check, value);
  }

  void assert_same_projective_point(const Point& a, const Point& b) const {
    lc_.assert_eq(lc_.mul(a.x, b.z), lc_.mul(b.x, a.z));
    lc_.assert_eq(lc_.mul(a.y, b.z), lc_.mul(b.y, a.z));
  }

  Point scalar_mult(EltW px, EltW py, EltW pz,
                    const ScalarMultWitness& w) const {
    auto zero = lc_.konst(lc_.zero());
    auto one = lc_.konst(lc_.one());
    Point acc{zero, one, zero};
    EltW started = zero;
    for (size_t i = 0; i < kBits; ++i) {
      typename LogicCircuit::BitW bit(w.bits[i], lc_.f_);
      lc_.assert_is_bit(bit);
      typename LogicCircuit::BitW started_bit(started, lc_.f_);

      Point doubled;
      secp_.doubleE(doubled.x, doubled.y, doubled.z,
                    acc.x, acc.y, acc.z);
      Point added;
      secp_.addE(added.x, added.y, added.z,
                 doubled.x, doubled.y, doubled.z, px, py, pz);

      Point selected{
          lc_.mux(bit, added.x, doubled.x),
          lc_.mux(bit, added.y, doubled.y),
          lc_.mux(bit, added.z, doubled.z),
      };
      Point first{
          lc_.mux(bit, px, zero),
          lc_.mux(bit, py, one),
          lc_.mux(bit, pz, zero),
      };
      selected = {
          lc_.mux(started_bit, selected.x, first.x),
          lc_.mux(started_bit, selected.y, first.y),
          lc_.mux(started_bit, selected.z, first.z),
      };
      started = lc_.add(started, lc_.mul(lc_.sub(one, started), w.bits[i]));
      if (i < kBits - 1) {
        lc_.assert_eq(selected.x, w.int_x[i]);
        lc_.assert_eq(selected.y, w.int_y[i]);
        lc_.assert_eq(selected.z, w.int_z[i]);
        acc = {w.int_x[i], w.int_y[i], w.int_z[i]};
      } else {
        acc = selected;
      }
    }
    return acc;
  }
};

}  // namespace niwi::rpbsch

#endif  // NIWI_CIRCUITS_RPBSCH_COMMITMENT_CIRCUIT_H
