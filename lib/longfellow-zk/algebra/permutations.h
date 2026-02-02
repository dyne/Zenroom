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

  /* X[i] = X[(i+shift) mod N] */
  /* We now use the notation X{N} to denote that X consists of N
     elements.  We have X = [A{SHIFT} B{N-SHIFT}].  We want
     X' = [B A] = rev[rev(A) rev(B)], where rev(A) reverses
     array A in-place.
  */
  static void rotate(Elt* x, size_t n, size_t shift) {
    if (shift > 0) {
      reverse(x, 0, shift);
      reverse(x, shift, n);
      reverse(x, 0, n);
    }
  }

  static void unrotate(Elt* x, size_t n, size_t shift) {
    if (shift > 0) {
      reverse(x, 0, n);
      reverse(x, shift, n);
      reverse(x, 0, shift);
    }
  }

 private:
  static void bitrev_increment(size_t* j, size_t bit) {
    do {
      bit >>= 1;
      *j ^= bit;
    } while (!(*j & bit));
  }

  // reverse x[i,j)
  static void reverse(Elt* x, size_t i, size_t j) {
    while (i + 1 < j) {
      --j;
      std::swap(x[i], x[j]);
      i++;
    }
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_PERMUTATIONS_H_
