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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_MEMCMP_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_MEMCMP_H_

#include <stddef.h>

#include <vector>

namespace proofs {
// This class implements the an equivalent of memcmp for arrays of
// v8.  The logic comparison operators do all the work, and the only
// problem is to arrange bits in the correct order for comparison.
// In more detail, these methods compare the bit strings represented by
// the array of v8 inputs (recall a v8 is 8 wires each containing a {0,1} value
// in the Field).
template <class Logic>
class Memcmp {
 public:
  using BitW = typename Logic::BitW;
  using v8 = typename Logic::v8;
  const Logic& l_;

  explicit Memcmp(const Logic& l) : l_(l) {}

  // A < B
  BitW lt(size_t n, const v8 A[/*n*/], const v8 B[/*n*/]) const {
    std::vector<BitW> a(8 * n);
    std::vector<BitW> b(8 * n);
    arrange(n, a.data(), A);
    arrange(n, b.data(), B);
    return l_.lt(8 * n, a.data(), b.data());
  }

  // A <= B
  BitW leq(size_t n, const v8 A[/*n*/], const v8 B[/*n*/]) const {
    std::vector<BitW> a(8 * n);
    std::vector<BitW> b(8 * n);
    arrange(n, a.data(), A);
    arrange(n, b.data(), B);
    return l_.leq(8 * n, a.data(), b.data());
  }

 private:
  void arrange(size_t n, BitW bits[/* 8 * n */], const v8 bytes[/*n*/]) const {
    // from LSB to MSB:
    for (size_t i = n; i-- > 0;) {
      for (size_t j = 0; j < 8; ++j) {
        *bits++ = bytes[i][j];
      }
    }
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_MEMCMP_H_
