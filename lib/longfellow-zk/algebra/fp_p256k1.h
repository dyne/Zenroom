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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_P256K1_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_P256K1_H_

#include <array>
#include <cstdint>

#include "algebra/fp_generic.h"
#include "algebra/nat.h"
#include "algebra/sysdep.h"

namespace proofs {
// Optimized implementation of Fp(2^256 - 2^32 - 977)
//  = 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1
// Secp256k1 base field.

/*
This struct contains an optimized reduction step for the chosen field.
*/
struct Fp256k1Reduce {
  // Hardcoded modulus (little endian)
  static const constexpr std::array<uint64_t, 4> kModulus = {
      0xFFFFFFFEFFFFFC2Fu,
      0xFFFFFFFFFFFFFFFFu,
      0xFFFFFFFFFFFFFFFFu,
      0xFFFFFFFFFFFFFFFFu,
  };

#ifndef SYSDEP_MULQ64_NOT_DEFINED
  static inline void reduction_step(uint64_t a[], uint64_t mprime,
                                    const Nat<4>& m) {
    // This step computes a += (mprime * a0) * p
    // The modulus is P = 2^256 - S, where S = 2^32 + 977.
    //
    // The standard Montgomery reduction step computes u such that
    // A + u * P is divisible by 2^64.
    // u = a[0] * mprime mod 2^64.
    //
    // Then we compute A + u * P = A + u * (2^256 - S)
    //                           = A + u * 2^256 - u * S.
    //
    // The division by 2^64 is implicit because we will just ignore the
    // lower 64 bits (which are guaranteed to be zero) and shift the rest.
    //
    // So the steps are:
    // 1. Calculate u = a[0] * mprime.
    // 2. Calculate X = u * S.
    //    S = 2^32 + 977, so X = u * 2^32 + u * 977.
    // 3. Subtract X from A (A -= u * S).
    // 4. Add u * 2^256 to A (A += u * 2^256).
    //    Since 2^256 is 4 words shifted, this means adding u to a[4].
    //
    // The result is (A - u * S + u * 2^256) / 2^64.
    uint64_t u = a[0] * mprime;

    // Calculate u * S = u * (2^32 + 977)
    uint64_t x_lo, x_hi;
    mulq(&x_lo, &x_hi, u, (1ULL << 32) + 977);

    // l = u * S
    uint64_t l[2] = {x_lo, x_hi};

    // Subtract l from a.
    negaccum(6, a, 2, l);

    // Add u * 2^256
    // This adds u to a[4].
    uint64_t h[1] = {u};
    // We add u to a[4] and propagate the carry.
    // a[4] corresponds to the 2^256 term.
    // The carry can propagate to a[5].
    // Since we are adding u (one limb) to a[4], the carry will at most be 1.
    accum(2, a + 4, 1, h);
  }
#endif

  static inline void reduction_step(uint32_t a[], uint32_t mprime,
                                    const Nat<4>& m) {
    uint32_t u = a[0] * mprime;
    uint32_t h[1] = {u};

    // S = 2^32 + 977
    // u * S = u * 2^32 + u * 977
    // u * 977 fits in 64 bits.
    uint64_t u977 = (uint64_t)u * 977;
    uint32_t s0 = (uint32_t)u977;
    uint32_t s1 = (uint32_t)(u977 >> 32);

    // Add u << 32 (which is effectively adding u to s1 position?)
    // u * 2^32 means u is effectively at limb 1.
    // So s1 += u.
    uint32_t l[3] = {s0, s1, 0};
    accum(2, &l[1], 1, h);

    // Subtract u*S
    negaccum(10, a, 3, l);

    // Add u * 2^256 to a.
    // 2^256 corresponds to the limb at index 8 (256 / 32 = 8).
    // So we add u to a[8].
    accum(2, a + 8, 1, h);
  }
};

template <bool optimized_mul = true>
using Fp256k1 = FpGeneric<4, optimized_mul, Fp256k1Reduce>;

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_P256K1_H_
