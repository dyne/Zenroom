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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_H_

#include <cstddef>

#include "algebra/fp_generic.h"
#include "algebra/sysdep.h"

namespace proofs {

/*
The FpReduce structure factors out the main routine for performing modular
reduction wrt to a Montgomery-represented field element in the FpGeneric
class. This struct contains a generic reduction step that always works,
but it can be specialized for certain primes to achieve better efficiency as
done with our 128- and 256- bit fields.
*/
struct FpReduce {
  template <class limb_t, class N>
  static inline void reduction_step(limb_t a[], limb_t mprime, const N& m) {
    constexpr size_t kLimbs = N::kLimbs;
    if (kLimbs == 1) {
      // The general case (below) represents the (kLimbs+1)-word product as
      // L+(H<<64), where in general L and H overlap, requiring
      // two additions.  For kLimbs==1, L and H do not overlap, and we can
      // interpret [L, H] as a single double-precision number.
      limb_t lh[2];
      limb_t r = mprime * a[0];
      mulhl(1, lh, lh + 1, r, m.limb_);
      accum(3, a, 2, lh);
    } else {
      limb_t l[kLimbs], h[kLimbs];
      limb_t r = mprime * a[0];
      mulhl(kLimbs, l, h, r, m.limb_);
      accum(kLimbs + 2, a, kLimbs, l);
      accum(kLimbs + 1, a + 1, kLimbs, h);
    }
  }
};

template <size_t W, bool optimized_mul = false>
using Fp = FpGeneric<W, optimized_mul, FpReduce>;
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP_H_
