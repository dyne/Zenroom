// Copyright 2026 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BIP340_BIP340_GADGETS_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BIP340_BIP340_GADGETS_H_

#include <stddef.h>

namespace proofs {

/// Reusable BIP340 / secp256k1 circuit gadget primitives.
///
/// These are the production-tested EC formulas extracted from the monolithic
/// Bip340Verify circuit.  Lua authors the verification sequence by calling
/// these gadgets; C++ emits the constraints.
///
/// Template parameters match Bip340Verify so both the native monolithic
/// circuit and the Lua-authored circuit use exactly one implementation of
/// each formula.
///
/// Usage from native Bip340Verify:
///   Bip340Gadgets<LogicCircuit, Field, EC> g(lc, ec);
///   g.assert_point_on_curve(px, py);
///   g.scalar_mult(sgx, sgy, sgz, gx, gy, one, w.bits_s, ...);
///
/// Usage from Lua bindings (via LuaLogicBip340 methods):
///   L:bip340_assert_point_on_curve(px, py)
///   local R = L:bip340_addE(sgx, sgy, sgz, epx, neg_epy, epz)
template <class LogicCircuit, class Field, class EC>
class Bip340Gadgets {
  using EltW = typename LogicCircuit::EltW;
  using Elt = typename LogicCircuit::Elt;
  using Nat = typename Field::N;
  using Bitvec = typename LogicCircuit::v256;
  static constexpr size_t kBits = EC::kBits;

 public:
  /// Writable output of scalar_mult: the final projective point (x, y, z)
  /// after processing all kBits iterations.  Callers read these wires to
  /// chain further gadget calls.
  struct ScalarMultResult {
    EltW x;
    EltW y;
    EltW z;
  };

  Bip340Gadgets(const LogicCircuit& lc, const EC& ec) : lc_(lc), ec_(ec) {
    Nat order(
        "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");
    for (size_t i = 0; i < kBits; ++i) {
      bits_n_[i] = lc_.bit(order.bit(i));
    }
  }

  /// Verify that (x, y) is on the secp256k1 curve: y² = x³ + 7.
  void assert_point_on_curve(EltW x, EltW y) const {
    auto y2 = lc_.mul(y, y);
    auto x2 = lc_.mul(x, x);
    auto x3 = lc_.mul(x, x2);
    auto b = lc_.konst(ec_.b_);
    auto rhs = lc_.add(x3, b);  // secp256k1: a = 0
    lc_.assert_eq(y2, rhs);
  }

  /// Complete projective point addition (Algorithm 1 from Renes-Costello-Batina).
  /// Returns {x, y, z} as a ScalarMultResult struct for convenience.
  ScalarMultResult addE(EltW X1, EltW Y1, EltW Z1,
                         EltW X2, EltW Y2, EltW Z2) const {
    ScalarMultResult out;
    addE(out.x, out.y, out.z, X1, Y1, Z1, X2, Y2, Z2);
    return out;
  }

  /// Complete projective point doubling (Algorithm 3 from Renes-Costello-Batina).
  ScalarMultResult doubleE(EltW X, EltW Y, EltW Z) const {
    ScalarMultResult out;
    doubleE(out.x, out.y, out.z, X, Y, Z);
    return out;
  }

  /// Double-and-add scalar multiplication with witnessed intermediate points.
  ///
  /// bits[kBits]: MSB-first scalar bits.
  /// int_{x,y,z}[kBits]: witnessed intermediate projective points.
  ///                      int_*[kBits-1] is the final result.
  ///
  /// Returns the final point (last intermediate).
  ScalarMultResult scalar_mult(EltW px, EltW py, EltW pz,
                                const EltW bits[kBits],
                                const EltW int_x[kBits],
                                const EltW int_y[kBits],
                                const EltW int_z[kBits]) const {
    ScalarMultResult out;
    scalar_mult(out.x, out.y, out.z, px, py, pz, bits,
                int_x, int_y, int_z);
    return out;
  }

  /// Assert that `bits` (MSB-first) represents a scalar < secp256k1 order n.
  /// Internally converts to LSB-first for Logic::vlt.
  void assert_scalar_lt_order(const EltW bits[kBits]) const {
    Bitvec bits_lsb;
    for (size_t i = 0; i < kBits; ++i) {
      bits_lsb[kBits - 1 - i] =
          typename LogicCircuit::BitW(bits[i], lc_.f_);
    }
    lc_.assert1(lc_.vlt(bits_lsb, bits_n_));
  }

  /// Assert that `bits` (MSB-first) reconstructs to the field element `value`.
  /// value = Σ bits[i] * 2^(kBits-1-i).
  void assert_field_from_bits_msb(const EltW bits[kBits],
                                  EltW value) const {
    EltW zero = lc_.konst(lc_.zero());
    EltW check = lc_.konst(lc_.zero());
    EltW pow = lc_.konst(lc_.one());  // 2^0
    for (int i = static_cast<int>(kBits) - 1; i >= 0; --i) {
      check = lc_.add(check, lc_.mul(bits[i], pow));
      pow = lc_.add(pow, pow);  // pow *= 2
    }
    lc_.assert_eq(check, value);
  }

  /// Assert that `bits` (MSB-first) represents an even value (LSB = 0).
  void assert_even_from_bits_msb(const EltW bits[kBits]) const {
    EltW zero = lc_.konst(lc_.zero());
    lc_.assert_eq(bits[kBits - 1], zero);
  }

  /// Verify the full bitness and parity of `ry` from its bits.
  /// Each bit ∈ {0,1}, reconstruction matches `ry`, and LSB=0.
  void assert_ry_bitness_and_even(const EltW bits_ry[kBits],
                                  EltW ry) const {
    EltW zero = lc_.konst(lc_.zero());
    EltW ry_check = lc_.konst(lc_.zero());
    for (size_t i = 0; i < kBits; ++i) {
      typename LogicCircuit::BitW b_bit(bits_ry[i], lc_.f_);
      lc_.assert_is_bit(b_bit);
      ry_check = lc_.add(ry_check, ry_check);  // ry_check *= 2
      ry_check = lc_.add(ry_check, bits_ry[i]);
    }
    lc_.assert_eq(ry_check, ry);
    // Assert LSB is zero (bits_ry[kBits-1] in MSB-first order).
    lc_.assert_eq(bits_ry[kBits - 1], zero);
  }

  // -- Access to construction-time fields (for generator, constants) -------
  const EC& ec() const { return ec_; }
  const LogicCircuit& lc() const { return lc_; }

 private:
  void addE(EltW& X3, EltW& Y3, EltW& Z3,
            EltW X1, EltW Y1, EltW Z1,
            EltW X2, EltW Y2, EltW Z2) const {
    EltW t0 = lc_.mul(X1, X2);
    EltW t1 = lc_.mul(Y1, Y2);
    EltW t2 = lc_.mul(Z1, Z2);
    EltW t3 = lc_.add(X1, Y1);
    EltW t4 = lc_.add(X2, Y2);
    t3 = lc_.mul(t3, t4);
    t4 = lc_.add(t0, t1);
    t3 = lc_.sub(t3, t4);
    t4 = lc_.add(X1, Z1);
    EltW t5 = lc_.add(X2, Z2);
    t4 = lc_.mul(t4, t5);
    t5 = lc_.add(t0, t2);
    t4 = lc_.sub(t4, t5);
    t5 = lc_.add(Y1, Z1);
    EltW X3t = lc_.add(Y2, Z2);
    t5 = lc_.mul(t5, X3t);
    X3t = lc_.add(t1, t2);
    t5 = lc_.sub(t5, X3t);
    auto a = lc_.konst(ec_.a_);
    EltW Z3t = lc_.mul(a, t4);
    auto k3b = lc_.konst(ec_.k3b);
    X3t = lc_.mul(k3b, t2);
    Z3t = lc_.add(X3t, Z3t);
    X3t = lc_.sub(t1, Z3t);
    Z3t = lc_.add(t1, Z3t);
    EltW Y3t = lc_.mul(X3t, Z3t);
    t1 = lc_.add(t0, t0);
    t1 = lc_.add(t1, t0);
    t2 = lc_.mul(a, t2);
    t4 = lc_.mul(k3b, t4);
    t1 = lc_.add(t1, t2);
    t2 = lc_.sub(t0, t2);
    t2 = lc_.mul(a, t2);
    t4 = lc_.add(t4, t2);
    t0 = lc_.mul(t1, t4);
    Y3t = lc_.add(Y3t, t0);
    t0 = lc_.mul(t5, t4);
    X3t = lc_.mul(t3, X3t);
    X3t = lc_.sub(X3t, t0);
    t0 = lc_.mul(t3, t1);
    Z3t = lc_.mul(t5, Z3t);
    Z3t = lc_.add(Z3t, t0);

    X3 = X3t;
    Y3 = Y3t;
    Z3 = Z3t;
  }

  void doubleE(EltW& X3, EltW& Y3, EltW& Z3,
               EltW X, EltW Y, EltW Z) const {
    EltW t0 = lc_.mul(X, X);
    EltW t1 = lc_.mul(Y, Y);
    EltW t2 = lc_.mul(Z, Z);
    EltW t3 = lc_.mul(X, Y);
    t3 = lc_.add(t3, t3);
    EltW Z3t = lc_.mul(X, Z);
    Z3t = lc_.add(Z3t, Z3t);
    auto a = lc_.konst(ec_.a_);
    auto k3b = lc_.konst(ec_.k3b);
    EltW X3t = lc_.mul(a, Z3t);
    EltW Y3t = lc_.mul(k3b, t2);
    Y3t = lc_.add(X3t, Y3t);
    X3t = lc_.sub(t1, Y3t);
    Y3t = lc_.add(t1, Y3t);
    Y3t = lc_.mul(X3t, Y3t);
    X3t = lc_.mul(t3, X3t);
    Z3t = lc_.mul(k3b, Z3t);
    t2 = lc_.mul(a, t2);
    t3 = lc_.sub(t0, t2);
    t3 = lc_.mul(a, t3);
    t3 = lc_.add(t3, Z3t);
    Z3t = lc_.add(t0, t0);
    t0 = lc_.add(Z3t, t0);
    t0 = lc_.add(t0, t2);
    t0 = lc_.mul(t0, t3);
    Y3t = lc_.add(Y3t, t0);
    t2 = lc_.mul(Y, Z);
    t2 = lc_.add(t2, t2);
    t0 = lc_.mul(t2, t3);
    X3t = lc_.sub(X3t, t0);
    Z3t = lc_.mul(t2, t1);
    Z3t = lc_.add(Z3t, Z3t);
    Z3t = lc_.add(Z3t, Z3t);

    X3 = X3t;
    Y3 = Y3t;
    Z3 = Z3t;
  }

  void scalar_mult(EltW& rx, EltW& ry, EltW& rz,
                   EltW px, EltW py, EltW pz,
                   const EltW bits[kBits],
                   const EltW int_x[kBits],
                   const EltW int_y[kBits],
                   const EltW int_z[kBits]) const {
    EltW zero = lc_.konst(lc_.zero());
    EltW one = lc_.konst(lc_.one());

    // Accumulator starts at point at infinity (0, 1, 0).
    EltW ax = zero, ay = one, az = zero;

    for (size_t i = 0; i < kBits; ++i) {
      typename LogicCircuit::BitW b_bit(bits[i], lc_.f_);
      lc_.assert_is_bit(b_bit);

      // Select point to add: if bit == 1 → P, else → infinity.
      EltW tx = lc_.mux(b_bit, px, zero);
      EltW ty = lc_.mux(b_bit, py, one);
      EltW tz = lc_.mux(b_bit, pz, zero);

      // Double accumulator.
      doubleE(ax, ay, az, ax, ay, az);

      // Add selected point.
      addE(ax, ay, az, ax, ay, az, tx, ty, tz);

      // Check against intermediate witness (except last iteration).
      if (i < kBits - 1) {
        lc_.assert_eq(ax, int_x[i]);
        lc_.assert_eq(ay, int_y[i]);
        lc_.assert_eq(az, int_z[i]);

        ax = int_x[i];
        ay = int_y[i];
        az = int_z[i];
      }
    }

    rx = ax;
    ry = ay;
    rz = az;
  }

  const LogicCircuit& lc_;
  const EC& ec_;
  Bitvec bits_n_;
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BIP340_BIP340_GADGETS_H_
