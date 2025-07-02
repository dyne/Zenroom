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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_POLYNOMIAL_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_POLYNOMIAL_H_

#include <stddef.h>

#include <array>

#include "algebra/poly.h"
#include "util/ceildiv.h"

namespace proofs {
template <class Logic>
class Polynomial {
 public:
  using Field = typename Logic::Field;
  using BitW = typename Logic::BitW;
  using EltW = typename Logic::EltW;
  const Logic& l_;

  explicit Polynomial(const Logic& l) : l_(l) {}

  void powers_of_x(size_t n, EltW xi[/*n*/], const EltW& x) const {
    const Logic& L = l_;  // shorthand

    if (n > 0) {
      xi[0] = L.konst(1);
      if (n > 1) {
        xi[1] = x;
        // invariant: xi[i] = x**i for i < k.
        // Extend inductively to k = n.
        for (size_t k = 2; k < n; ++k) {
          xi[k] = L.mul(&xi[k - k / 2], xi[k / 2]);
        }
      }
    }
  }

  // Evaluation via dot product with coefficients
  template <size_t N>
  EltW eval(const Poly<N, Field>& coef, const EltW& x) const {
    const Logic& L = l_;  // shorthand

    std::array<EltW, N> xi;
    powers_of_x(N, xi.data(), x);

    // dot product with coefficients
    EltW r = L.konst(0);
    for (size_t i = 0; i < N; ++i) {
      auto cxi = L.mul(coef[i], xi[i]);
      r = L.add(&r, cxi);
    }
    return r;
  }

  // Evaluation via parallel Horner's rule
  template <size_t N>
  EltW eval_horner(const Poly<N, Field>& coef, EltW x) const {
    const Logic& L = l_;  // shorthand

    std::array<EltW, N> c;
    for (size_t i = 0; i < N; ++i) {
      c[i] = L.konst(coef[i]);
    }

    for (size_t n = N; n > 1; n = ceildiv<size_t>(n, 2)) {
      for (size_t i = 0; 2 * i < n; ++i) {
        c[i] = c[2 * i];
        if (2 * i + 1 < n) {
          auto cxi = L.mul(&x, c[2 * i + 1]);
          c[i] = L.add(&c[i], cxi);
        }
      }
      x = L.mul(&x, x);
    }
    return c[0];
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_POLYNOMIAL_H_
