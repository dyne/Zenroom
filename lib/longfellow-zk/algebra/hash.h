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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_HASH_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_HASH_H_

#include <cstddef>
#include <cstdint>

#include "util/crc64.h"

namespace proofs {

// canonical hash of an Elt
template <class Field>
uint64_t elt_hash(const typename Field::Elt& k, const Field& F) {
  uint64_t crc = 0x1;
  uint8_t buf[Field::kBytes];
  F.to_bytes_field(buf, k);
  for (size_t l = 0; l < Field::kBytes; ++l) {
    crc = crc64::update(crc, buf[l], 8);
  }
  return crc;
}

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_HASH_H_
