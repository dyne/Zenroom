// Copyright 2025 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_ECDSA_VERIFY_WITNESS_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_ECDSA_VERIFY_WITNESS_H_

#include <cstddef>

#include "algebra/utility.h"
#include "arrays/dense.h"
#include "util/panic.h"

/*
Methods to help prepare witnesses for use in assertions about ecdsa.
*/
namespace proofs {

template <class EC, class ScalarField>
class VerifyWitness3 {
  using Field = typename EC::Field;
  using Elt = typename Field::Elt;
  using Nat = typename Field::N;
  using Point = typename EC::ECPoint;
  using Scalar = typename ScalarField::Elt;

 public:
  constexpr static size_t kBits = EC::kBits;
  const ScalarField& fn_;
  const EC& ec_;
  Elt rx_, ry_;
  Elt rx_inv_;
  Elt s_inv_;
  Elt pk_inv_;
  Elt pre_[8];
  Elt bi_[kBits];
  Elt int_x_[kBits];   /* Intermediate x,y elliptic curve points */
  Elt int_y_[kBits];   /* encountered during the scalar mult loop. */
  Elt int_z_[kBits];   /* z-coordinate of the intermediate points */

  VerifyWitness3(const ScalarField& Fn, const EC& ec) : fn_(Fn), ec_(ec) {}

  void fill_witness(DenseFiller<Field>& filler) const {
    filler.push_back(rx_);
    filler.push_back(ry_);
    filler.push_back(rx_inv_);
    filler.push_back(s_inv_);
    filler.push_back(pk_inv_);
    for (size_t i = 0; i < 8; ++i) {
      filler.push_back(pre_[i]);
    }
    for (size_t i = 0; i < kBits; ++i) {
      filler.push_back(bi_[i]);
      if (i < kBits - 1) {
        filler.push_back(int_x_[i]);
        filler.push_back(int_y_[i]);
        filler.push_back(int_z_[i]);
      }
    }
  }

  // Produces witnesses to support the verification of the equation
  //     id = g*e + pk*r + (rx,ry)*-s
  // Note that the same rx is interpreted in scalar field as r.
  bool compute_witness(const Elt pkX, const Elt pkY, const Nat e, const Nat r,
                       const Nat s) {
    const Field& F = ec_.f_;
    const Scalar _s = fn_.invertf(fn_.to_montgomery(s));
    const Scalar tms = fn_.negf(fn_.to_montgomery(s));

    // Because Fp does not have a sqrt method, compute ry via the
    // elliptic curve point g*(e/s) + pk*(r/s).
    auto te_s = fn_.mulf(fn_.to_montgomery(e), _s);
    auto tr_s = fn_.mulf(fn_.to_montgomery(r), _s);
    const Nat nes = fn_.from_montgomery(te_s);
    const Nat nrs = fn_.from_montgomery(tr_s);
    Point bases[] = {ec_.generator(), Point(pkX, pkY, F.one())};
    Nat scalars[] = {nes, nrs};
    auto pr = ec_.scalar_multf(2, bases, scalars);
    ec_.normalize(pr);

    rx_ = F.to_montgomery(r);
    ry_ = pr.y;

    // In the case of a malicious input with rx=0 or s=0, the proof will fail.
    if (rx_ != F.zero()) {
      rx_inv_ = F.invertf(rx_);
      check(F.mulf(rx_, rx_inv_) == F.one(), "bad inv");
    }

    s_inv_ = F.to_montgomery(fn_.from_montgomery(tms));
    if (s_inv_ != F.zero()) {
      F.invert(s_inv_);
    }

    if (pkX != F.zero()) {
      pk_inv_ = F.invertf(pkX);
    }

    const Nat nms = fn_.from_montgomery(tms);   /* -s */

    // Produce the table of pre-computed g,r,pk sums.
    const Elt one = F.one(), gX = ec_.gx_, gY = ec_.gy_;
    const Elt lh[] = {gX, gY, gX, gY, pkX, pkY};
    const Elt rh[] = {pkX, pkY, rx_, ry_, rx_, ry_};
    Elt zi;
    for (size_t i = 0; i < 3; ++i) {
      ec_.addE(pre_[2 * i], pre_[2 * i + 1], zi,
               lh[2 * i], lh[2 * i + 1], one,
               rh[2 * i], rh[2 * i + 1], one);

      // This invert cannot fail because both the generator and pk are
      // trusted inputs, so the above addition is not the identity.
      // In the case that it is, the proof will fail (and it should, since
      // the system is unsound with sk=-1).
      if (zi != F.zero()) {
        F.invert(zi);
      }
      F.mul(pre_[2 * i], zi);
      F.mul(pre_[2 * i + 1], zi);
    }
    // rgpk
    ec_.addE(pre_[6], pre_[7], zi, pre_[2], pre_[3], one, pkX, pkY, one);
    if (zi != F.zero()) {
      F.invert(zi);
    }
    F.mul(pre_[6], zi);
    F.mul(pre_[7], zi);

    Elt aX = F.zero(), aY = one, aZ = F.zero();

    // Compute b[], and intermediate points, encode b as:
    //  1:g  2:pk  3: gpk  4: r  5: r+g  6: r+pk  7:g+r+pk
    // Elt int_z[kBits];
    size_t b[kBits];
    // bool early_zero = false;   /* indicates if any intermediate z is zero */
    for (size_t i = 0; i < kBits; ++i) {
      b[i] = e.bit(kBits - i - 1) + 2 * r.bit(kBits - i - 1) +
             4 * nms.bit(kBits - i - 1);

      // Manually compute standard (-n...n representation).
      bi_[i] = F.subf(F.of_scalar(2 * b[i]), F.of_scalar(7));

      if (i > 0) {
        ec_.doubleE(aX, aY, aZ, aX, aY, aZ);
      }
      switch (b[i]) {
        case 0:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, F.zero(), F.one(), F.zero());
          break;
        case 1:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, gX, gY, one);
          break;
        case 2:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, pkX, pkY, one);
          break;
        case 3:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, pre_[0], pre_[1], one);
          break;
        case 4:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, rx_, ry_, one);
          break;
        case 5:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, pre_[2], pre_[3], one);
          break;
        case 6:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, pre_[4], pre_[5], one);
          break;
        case 7:
          ec_.addE(aX, aY, aZ, aX, aY, aZ, pre_[6], pre_[7], one);
          break;
      }

      int_x_[i] = aX;
      int_y_[i] = aY;
      int_z_[i] = aZ;
    }

    if (aX != F.zero()) {
      return false;
    }
    if (aZ != F.zero()) {
      return false;
    }

    return true;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_ECDSA_VERIFY_WITNESS_H_
