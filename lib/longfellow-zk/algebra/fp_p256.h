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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_P256_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_P256_H_

#include <array>
#include <cstdint>

#include "algebra/fp_generic.h"
#include "algebra/nat.h"
#include "algebra/sysdep.h"

namespace proofs {
// Optimized implementation of
// Fp(115792089210356248762697446949407573530086143415290314195533631308867097853951)

/*
This struct contains an optimized reduction step for the chosen field.
*/
struct Fp256Reduce {
  // Harcoded base_64 modulus.
  static const constexpr std::array<uint64_t, 4> kModulus = {
      0xFFFFFFFFFFFFFFFFu,
      0xFFFFFFFFu,
      0,
      0xFFFFFFFF00000001u,
  };

  static inline void reduction_step(uint64_t a[], uint64_t mprime,
                                    const Nat<4>& m) {
    uint64_t r = a[0];
    uint64_t l[5] = {r, 0, 0, r << 32, r >> 32};
    negaccum(6, a, 5, l);
    uint64_t h[4] = {r << 32, r >> 32, r, r};
    accum(5, a + 1, 4, h);
  }

  static inline void reduction_step(uint32_t a[], uint32_t mprime,
                                    const Nat<4>& m) {
    uint32_t r = a[0];
    uint32_t l[8] = {r, 0, 0, 0, 0, 0, 0, r};
    negaccum(10, a, 8, l);
    uint32_t h[6] = {r, 0, 0, r, 0, r};
    accum(7, a + 3, 6, h);
  }
};

template <bool optimized_mul = false>
using Fp256 = FpGeneric<4, optimized_mul, Fp256Reduce>;
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_P256_H_
