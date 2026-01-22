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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_TWIDDLE_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_TWIDDLE_H_

#include <stddef.h>
#include <stdint.h>

#include <vector>

// Twiddle factors for FFT
namespace proofs {

template <class Field>
class Twiddle {
  using Elt = typename Field::Elt;

 public:
  size_t order_;
  // powers of omega_n
  std::vector<Elt> w_;

  explicit Twiddle(size_t n, const Elt& omega_n, const Field& F)
      : order_(n), w_(n / 2) {
    auto w = F.one();
    for (size_t i = 0; 2 * i < n; ++i) {
      w_[i] = w;
      F.mul(w, omega_n);
    }
  }

  // given a n-th root of unity omega_n, return a r-th root of unity
  // for r <= n
  static Elt reroot(const Elt& omega_n, uint64_t n, uint64_t r,
                    const Field& F) {
    Elt omega_r = omega_n;
    while (r < n) {
      F.mul(omega_r, omega_r);
      r += r;
    }
    return omega_r;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_TWIDDLE_H_
