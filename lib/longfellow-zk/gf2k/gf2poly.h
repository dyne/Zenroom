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

#ifndef PRIVACY_PROOFS_ZK_LIB_GF2K_GF2POLY_H_
#define PRIVACY_PROOFS_ZK_LIB_GF2K_GF2POLY_H_

#include <array>
#include <cstddef>
#include <cstdint>

#include "algebra/limb.h"

namespace proofs {

// Rough equivalent of Nat<W64> but representing polynomials
// over GF2 instead of natural numbers.
template <size_t W64>
class GF2Poly : public Limb<W64> {
 public:
  using Super = Limb<W64>;
  using T = GF2Poly<W64>;
  using Super::kLimbs;
  using Super::kU64;
  using Super::limb_;

  GF2Poly() = default;  // uninitialized
  explicit GF2Poly(uint64_t x) : Super(x) {}

  explicit GF2Poly(const std::array<uint64_t, kU64>& a) : Super(a) {}

  bool operator<(const T& other) const {
    for (size_t i = kLimbs; i-- > 0;) {
      if (limb_[i] < other.limb_[i]) {
        return true;
      }
      if (limb_[i] > other.limb_[i]) {
        return false;
      }
    }
    return false;
  }

  // Interpret A[] as a little-endian nat
  static T of_bytes(const uint8_t a[/* kBytes */]) {
    T r;
    for (size_t i = 0; i < kLimbs; ++i) {
      a = Super::of_bytes(&r.limb_[i], a);
    }
    return r;
  }

  T& add(const T& y) {
    for (size_t i = 0; i < kLimbs; ++i) {
      limb_[i] ^= y.limb_[i];
    }
    return *this;
  }
  T& sub(const T& y) { return add(y); }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_GF2K_GF2POLY_H_
