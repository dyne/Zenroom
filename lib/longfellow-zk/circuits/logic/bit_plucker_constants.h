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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_CONSTANTS_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_CONSTANTS_H_

#include <stddef.h>
#include <stdint.h>

namespace proofs {
// bit-plucker code common to both compiler-time and
// wire-fill time
template <class Field, size_t N>
struct bit_plucker_point {
  using Elt = typename Field::Elt;

  // packing of bits compatible with even_lagrange_basis():
  Elt operator()(uint64_t bits, const Field& F) const {
    return F.subf(F.of_scalar(2 * bits), F.of_scalar(N - 1));
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_CONSTANTS_H_
