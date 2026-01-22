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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_UTILITY_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_UTILITY_H_

#include <stddef.h>

#include <cstdint>

namespace proofs {
template <class Field>
class AlgebraUtil {
 public:
  using Elt = typename Field::Elt;

  // a[i*da] = inverse(b[i*db]), via Montgomery batch inversion
  static void batch_invert(size_t n, Elt a[/*n with stride da*/], size_t da,
                           const Elt b[/*n with stride db*/], size_t db,
                           const Field& F) {
    Elt p = F.one();

    // a[i] \gets \prod_{j<i] b[j]
    for (size_t i = 0; i < n; ++i) {
      Elt bi = b[i * db];
      a[i * da] = p;
      F.mul(p, bi);
    }

    // now p = \prod_{j<n] b[j]
    F.invert(p);

    for (size_t i = n; i-- > 0;) {
      F.mul(a[i * da], p);
      F.mul(p, b[i * db]);
    }
  }

  // a[i] = 1/i, with a[0]=0
  static void batch_inverse_arithmetic(size_t n, Elt a[/*n*/], const Field& F) {
    a[0] = F.zero();
    // this is essentially batch_inverse with b[i]=bi

    Elt p = F.one();
    Elt bi = F.zero();

    for (size_t i = 1; i < n; ++i) {
      F.add(bi, F.one());
      a[i] = p;
      F.mul(p, bi);
    }

    // now p = \prod_{j<n] b[j]
    F.invert(p);

    for (size_t i = n; i-- > 0;) {
      F.mul(a[i], p);
      F.mul(p, bi);
      F.sub(bi, F.one());
    }
  }

  static Elt factorial(uint64_t n, const Field& F) {
    auto p = F.one();
    auto fi = F.one();
    for (uint64_t i = 1; i <= n; ++i) {
      F.mul(p, fi);
      F.add(fi, F.one());
    }
    return p;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_UTILITY_H_
