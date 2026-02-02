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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_WITNESS_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_WITNESS_H_

#include <cstddef>
#include <cstdint>

#include "arrays/dense.h"
#include "circuits/logic/bit_plucker_encoder.h"
#include "gf2k/gf2_128.h"

namespace proofs {

template <class Field>
class MacWitness {
  using f_128 = GF2_128<>;
  using gf2k = f_128::Elt;
  using packer = BitPluckerEncoder<Field, 2>;
  using packed_v128 = typename packer::packed_v128;
  using packed_v256 = typename packer::packed_v256;

 public:
  explicit MacWitness(const Field& F, const f_128& GF) : f_(F), gf_(GF) {}

  void fill_witness(DenseFiller<Field>& fill) const {
    packer bp(f_);
    uint8_t tmp[f_128::kBits];
    for (size_t i = 0; i < 2; ++i) {
      for (size_t j = 0; j < f_128::kBits; ++j) {
        tmp[j] = ap_[i][j];
      }
      fill.push_back(bp.template pack<packed_v128>(tmp, f_128::kBits));
    }

    for (size_t i = 0; i < 2; ++i) {
      for (size_t j = 0; j < f_128::kBits; ++j) {
        tmp[j] = x_[i][j];
      }
      fill.push_back(bp.template pack<packed_v128>(tmp, 128));
    }
  }

  // Computes a mac witness on a 32-byte message x.
  // This code assumes that a gf element is at least 16 bytes.
  void compute_witness(const gf2k a_p[/*2*/], const uint8_t x[/*32*/]) {
    for (size_t i = 0; i < 2; ++i) {
      x_[i] = gf_.of_bytes_field(&x[i * 16]).value();
      ap_[i] = a_p[i];
    }
  }

 private:
  gf2k ap_[2], x_[2];
  const Field& f_;
  const f_128& gf_;
};

class MacGF2Witness {
  using f_128 = GF2_128<>;
  using gf2k = f_128::Elt;

 public:
  void fill_witness(DenseFiller<f_128>& fill) const {
    fill.push_back(ap_[0]);
    fill.push_back(ap_[1]);
  }

  // Computes a mac witness on a 32-byte message x.
  void compute_witness(const gf2k a_p[/*2*/]) {
    for (size_t i = 0; i < 2; ++i) {
      ap_[i] = a_p[i];
    }
  }

 private:
  gf2k ap_[2];
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_WITNESS_H_
