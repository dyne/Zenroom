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

#ifndef PRIVACY_PROOFS_ZK_LIB_RANDOM_RANDOM_H_
#define PRIVACY_PROOFS_ZK_LIB_RANDOM_RANDOM_H_

#include <cstdint>
#include <cstdlib>
#include <optional>
#include <utility>
#include <vector>

#include "util/panic.h"

namespace proofs {

// Our protocols require random coins; this interface provides both prover
// and verifier components with those coins. Re-implementing this interface
// allows easily supporting the Fiat-Shamir transform, or for sampling using
// a system provided RNG such as openssl.
class RandomEngine {
 public:
  virtual ~RandomEngine() = default;
  virtual void bytes(uint8_t* buf, size_t n) = 0;  // pure virtual

  // Sample a random field element.
  // TODO [matteof 2025-02-07] Per RFC, we must mask off the high
  // bits, but this requires changes to the field interface.
  // Punt for now since the mask is all ones anyway.
  template <class Field>
  typename Field::Elt elt(const Field& F) {
    // Expected constant time.
    uint8_t buf[Field::kBytes];
    for (;;) {
      bytes(buf, sizeof(buf));
      if (std::optional<typename Field::Elt> maybe = F.of_bytes_field(buf)) {
        return maybe.value();
      }
    }
  }

  template <class Field>
  typename Field::Elt subfield_elt(const Field& F) {
    // Expected constant time.
    uint8_t buf[Field::kSubFieldBytes];
    for (;;) {
      bytes(buf, sizeof(buf));
      if (std::optional<typename Field::Elt> maybe = F.of_bytes_subfield(buf)) {
        return maybe.value();
      }
    }
  }

  // Convenience method to sample an array of random field elements.
  template <class Field>
  void elt(typename Field::Elt e[/*n*/], size_t n, const Field& F) {
    for (size_t i = 0; i < n; ++i) e[i] = elt(F);
  }

  // the minimal bitmask such that (n & mask) == n
  size_t mask(size_t n) {
    size_t mask = 0;
    while ((n & mask) != n) {
      mask <<= 1;
      mask |= 1u;
    }
    return mask;
  }

  // random size_t < n
  size_t nat(size_t n) {
    check(n > 0, "nat(0)");

    // compute the minimum number of random bytes needed
    size_t l = 0;
    size_t nn = n;
    while (nn != 0) {
      nn >>= 8;
      ++l;
    }
    check(l <= sizeof(size_t), "l <= sizeof(size_t)");

    size_t msk = mask(n);
    size_t r;
    uint8_t buf[sizeof(size_t)];

    // rejection sampling
    do {
      // consume L random bytes
      bytes(buf, l);

      // little-endian read
      r = 0;
      for (size_t i = l; i-- > 0;) {
        r = (r << 8) | buf[i];
      }

      // mask off high bits
      r &= msk;
    } while (r >= n);

    return r;
  }

  // Choose K distinct random naturals in [0..N).
  // Textbook algorithm requiring O(N) space
  void choose(size_t res[/*k*/], size_t n, size_t k) {
    check(n >= k, "n >= k");

    std::vector<size_t> A(n);
    for (size_t i = 0; i < n; ++i) {
      A[i] = i;
    }
    for (size_t i = 0; i < k; ++i) {
      size_t j = i + nat(n - i);
      std::swap(A[i], A[j]);
      res[i] = A[i];
    }
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_RANDOM_RANDOM_H_
