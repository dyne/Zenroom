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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_REFERENCE_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_REFERENCE_H_

#include <cstddef>
#include <cstdint>
#include <vector>

#include "arrays/dense.h"
#include "random/random.h"
#include "util/panic.h"

namespace proofs {

template <class GF>
class MACReference {
  using gf2k = typename GF::Elt;

 public:
  void sample(gf2k ap[], size_t n, RandomEngine* rng) {
    check(n > 0, "n must be positive");
    std::vector<uint8_t> buf(n * GF::kBytes);
    rng->bytes(buf.data(), n * GF::kBytes);
    for (size_t i = 0; i < n; ++i) {
      ap[i] = gf_.of_bytes_field(&buf[i * GF::kBytes]).value();
    }
  }

  // Computes the mac of a 32-byte message.
  void compute(gf2k mac[/*2*/], const gf2k& av, const gf2k ap[/*2*/],
               uint8_t msg[/*32*/]) const {
    uint8_t tmp[GF::kBytes] = {0};
    for (size_t i = 0; i < 2; ++i) {
      memcpy(tmp, &msg[i * GF::kBytes], GF::kBytes);
      gf2k m = gf_.of_bytes_field(tmp).value();
      mac[i] = gf_.mulf(gf_.addf(av, ap[i]), m);
    }
  }

  void to_bytes(gf2k mac[/*2*/], uint8_t buf[/* 32 */]) {
    gf_.to_bytes(mac[0], buf);
    gf_.to_bytes(mac[1], buf + GF::kBytes);
  }

 private:
  GF gf_;
};

template <typename GF, typename Field>
void fill_gf2k(const typename GF::Elt& m, DenseFiller<Field>& df,
               const Field& f) {
  for (size_t i = 0; i < GF::kBits; ++i) {
    df.push_back(m[i] ? f.one() : f.zero());
  }
}

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_REFERENCE_H_
