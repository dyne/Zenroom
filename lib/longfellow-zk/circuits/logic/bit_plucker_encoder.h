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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_ENCODER_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_ENCODER_H_

#include <stddef.h>
#include <stdint.h>

#include <array>

#include "circuits/logic/bit_plucker_constants.h"

namespace proofs {
template <class Field, size_t LOGN>
class BitPluckerEncoder {
  const Field& f_;

  using Elt = typename Field::Elt;
  static constexpr size_t kN = size_t(1) << LOGN;
  static constexpr size_t kNv32Elts = (32u + LOGN - 1u) / LOGN;
  static constexpr size_t kNv128Elts = (128u + LOGN - 1u) / LOGN;
  static constexpr size_t kNv256Elts = (256u + LOGN - 1u) / LOGN;

 public:
  using packed_v32 = std::array<Elt, kNv32Elts>;
  using packed_v128 = std::array<Elt, kNv128Elts>;
  using packed_v256 = std::array<Elt, kNv256Elts>;

  explicit BitPluckerEncoder(const Field& F) : f_(F) {}

  Elt encode(size_t i) const { return bit_plucker_point<Field, kN>()(i, f_); }

  // Special case packer for uint32_t used in sha256.
  packed_v32 mkpacked_v32(uint32_t j) {
    packed_v32 r;
    for (size_t i = 0; i < r.size(); ++i) {
      r[i] = encode(j & (kN - 1));
      j >>= LOGN;
    }
    return r;
  }

  template <typename T>
  T pack(uint8_t bits[/* n bits */], size_t n) {
    T r;
    for (size_t i = 0; i < r.size(); ++i) {
      size_t v = 0;
      for (size_t j = 0; j < LOGN; ++j) {
        if (i * LOGN + j < n) {
          v += (bits[i * LOGN + j] & 0x1) << j;
        }
      }
      r[i] = encode(v);
    }
    return r;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_ENCODER_H_
