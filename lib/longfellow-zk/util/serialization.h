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

#ifndef PRIVACY_PROOFS_ZK_LIB_UTIL_SERIALIZATION_H_
#define PRIVACY_PROOFS_ZK_LIB_UTIL_SERIALIZATION_H_

#include <cstdint>

namespace proofs {

static inline void u64_to_le(uint8_t a[/*8*/], uint64_t x) {
  a[0] = x & 0xffu;
  a[1] = (x >> 8) & 0xffu;
  a[2] = (x >> 16) & 0xffu;
  a[3] = (x >> 24) & 0xffu;
  a[4] = (x >> 32) & 0xffu;
  a[5] = (x >> 40) & 0xffu;
  a[6] = (x >> 48) & 0xffu;
  a[7] = (x >> 56) & 0xffu;
}

static inline uint64_t u64_of_le(const uint8_t a[/*8*/]) {
  return ((uint64_t)a[7] << 56) | ((uint64_t)a[6] << 48) |
         ((uint64_t)a[5] << 40) | ((uint64_t)a[4] << 32) |
         ((uint64_t)a[3] << 24) | ((uint64_t)a[2] << 16) |
         ((uint64_t)a[1] << 8) | (uint64_t)a[0];
}

static inline void u32_to_le(uint8_t a[/*4*/], uint32_t x) {
  a[0] = x & 0xffu;
  a[1] = (x >> 8) & 0xffu;
  a[2] = (x >> 16) & 0xffu;
  a[3] = (x >> 24) & 0xffu;
}

static inline uint32_t u32_of_le(const uint8_t a[/*4*/]) {
  return ((uint32_t)a[3] << 24) | ((uint32_t)a[2] << 16) |
         ((uint32_t)a[1] << 8) | (uint32_t)a[0];
}

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_UTIL_SERIALIZATION_H_
