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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BIP340_BIP340_VERIFY_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BIP340_BIP340_VERIFY_H_

#include <stddef.h>

#include "circuits/bip340/bip340_gadgets.h"

namespace proofs {

/// Production BIP-340 / Schnorr signature verification over secp256k1.
///
///   s·G = R + e·P
///
/// This class now delegates all EC-formula and constraint emission to
/// Bip340Gadgets so there is exactly one C++ implementation of each
/// formula, shared by the native monolithic circuit and the Lua-authored
/// gadget circuit.
///
/// --- In-circuit (proven) ---
///
/// Public field inputs, in order: rx, px, e.
///   rx : R.x (x-only, 32 bytes after BIP-340 parse).
///   px : P.x (x-only public key).
///   e  : Fiat-Shamir challenge scalar (field element).
///
/// Private witness: bits_s[256], int_s_{x,y,z}[255] for s·G;
///   bits_e[256], int_e_{x,y,z}[255] for e·P;
///   py (P.y, the even square root);
///   ry (affine R.y); rz_inv (R.z inverse); ry_bits[256].
///
/// --- Outside the circuit (witness/verifier validation) ---
///
/// Witness generation checks before building the circuit:
///   - Byte-length validation: sig 64 bytes, pk 32 bytes.
///   - rx < p, s < n, px < p.
///   - px is liftable (curve point exists with even y).
///   - e is computed from BIP-340 tagged SHA-256 hash.
///
/// Tagged SHA-256 is deliberately NOT proven in this circuit.
template <class LogicCircuit, class Field, class EC>
class Bip340Verify {
  using EltW = typename LogicCircuit::EltW;
  using Elt = typename LogicCircuit::Elt;
  static constexpr size_t kBits = EC::kBits;

 public:
  struct Witness {
    EltW bits_s[kBits];
    EltW int_sx[kBits];
    EltW int_sy[kBits];
    EltW int_sz[kBits];

    EltW bits_e[kBits];
    EltW int_ex[kBits];
    EltW int_ey[kBits];
    EltW int_ez[kBits];

    EltW py;          // affine P.y (the even square root)
    EltW ry;          // affine R.y (witnessed even value)
    EltW rz_inv;      // inverse of R.z (proves R finite)
    EltW bits_ry[kBits];  // affine ry bits, MSB-first

    void input(const LogicCircuit& lc) {
      for (size_t i = 0; i < kBits; ++i) {
        bits_s[i] = lc.eltw_input();
        if (i < kBits - 1) {
          int_sx[i] = lc.eltw_input();
          int_sy[i] = lc.eltw_input();
          int_sz[i] = lc.eltw_input();
        }
      }
      for (size_t i = 0; i < kBits; ++i) {
        bits_e[i] = lc.eltw_input();
        if (i < kBits - 1) {
          int_ex[i] = lc.eltw_input();
          int_ey[i] = lc.eltw_input();
          int_ez[i] = lc.eltw_input();
        }
      }
      py = lc.eltw_input();
      ry = lc.eltw_input();
      rz_inv = lc.eltw_input();
      for (size_t i = 0; i < kBits; ++i) {
        bits_ry[i] = lc.eltw_input();
      }
    }
  };

  Bip340Verify(const LogicCircuit& lc, const EC& ec)
      : lc_(lc), g_(lc, ec) {}

  /// Verify the BIP-340 relation: s·G - e·P = R, with R.x == rx.
  void assert_verify(EltW rx, EltW px, EltW e, const Witness& w) const {
    EltW zero = lc_.konst(lc_.zero());
    EltW one = lc_.konst(lc_.one());

    // -- 0. Verify e matches bits_e decomposition (MSB-first) ------------
    g_.assert_field_from_bits_msb(w.bits_e, e);

    // -- 1. Verify s is a canonical secp256k1 scalar (0 <= s < n) --------
    g_.assert_scalar_lt_order(w.bits_s);

    // -- 2. Lift P: verify py² = px³ + 7 --------------------------------
    g_.assert_point_on_curve(px, w.py);

    // -- 3. Compute s·G ---------------------------------------------------
    EltW gx = lc_.konst(g_.ec().gx_);
    EltW gy = lc_.konst(g_.ec().gy_);
    auto sG = g_.scalar_mult(gx, gy, one,
                             w.bits_s, w.int_sx, w.int_sy, w.int_sz);

    // -- 4. Compute e·P  (P = (px, py, 1)) -------------------------------
    auto eP = g_.scalar_mult(px, w.py, one,
                             w.bits_e, w.int_ex, w.int_ey, w.int_ez);

    // -- 5. Compute R = sG - eP = sG + (-eP) ------------------------------
    EltW neg_epy = lc_.sub(zero, eP.y);
    auto R = g_.addE(sG.x, sG.y, sG.z, eP.x, neg_epy, eP.z);

    // -- 6. Verify R is on the curve and finite --------------------------
    g_.assert_point_on_curve(rx, w.ry);

    // R.z * rz_inv = 1  ⟺  R is not the point at infinity.
    lc_.assert_eq(lc_.mul(R.z, w.rz_inv), one);

    // -- 7. Check R.x == rx (projective) ---------------------------------
    lc_.assert_eq(R.x, lc_.mul(rx, R.z));   // R.x * 1 == rx * R.z

    // -- 8. Check R.y == ry (projective) ---------------------------------
    lc_.assert_eq(R.y, lc_.mul(w.ry, R.z));  // R.y * 1 == ry * R.z

    // -- 9. Verify ry bitness and even parity ----------------------------
    g_.assert_ry_bitness_and_even(w.bits_ry, w.ry);
  }

 private:
  const LogicCircuit& lc_;
  Bip340Gadgets<LogicCircuit, Field, EC> g_;
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BIP340_BIP340_VERIFY_H_
