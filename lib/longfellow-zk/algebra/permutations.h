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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_PERMUTATIONS_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_PERMUTATIONS_H_

#include <stddef.h>

#include <utility>

namespace proofs {

template <class Elt>
class Permutations {
 public:
  static void bitrev(Elt A[/*n*/], size_t n) {
    size_t revi = 0;
    for (size_t i = 0; i < n - 1; ++i) {
      if (i < revi) {
        std::swap(A[i], A[revi]);
      }

      bitrev_increment(&revi, n);
    }
  }

 private:
  static void bitrev_increment(size_t* j, size_t bit) {
    do {
      bit >>= 1;
      *j ^= bit;
    } while (!(*j & bit));
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_PERMUTATIONS_H_
