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

#ifndef PRIVACY_PROOFS_ZK_LIB_UTIL_CRC64_H_
#define PRIVACY_PROOFS_ZK_LIB_UTIL_CRC64_H_

/*
This package defines 3 basic methods for computing a simple 64-bit CRC.
It is used for checksum and comparison of datastructures that are internal
to this library.
*/

#include <stdlib.h>

#include <cstdint>

namespace proofs {
namespace crc64 {
static inline uint64_t shlu64(uint64_t x, size_t n) {
  return (n >= 64) ? 0u : (x << n);
}
static inline uint64_t shru64(uint64_t x, size_t n) {
  return (n >= 64) ? 0u : (x >> n);
}
static inline uint64_t update(uint64_t crc, uint64_t u, size_t n = 64) {
  crc ^= u;
  uint64_t l = shlu64(crc, 127u - n) ^ shlu64(crc, 125u - n) ^
               shlu64(crc, 124u - n) ^ shlu64(crc, 64u - n);
  return shru64(crc, n) ^ l ^ (l >> 1) ^ (l >> 3) ^ (l >> 4);
}
}  // namespace crc64
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_UTIL_CRC64_H_
