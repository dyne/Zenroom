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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_COMPARE_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_COMPARE_H_

#include <cstddef>
#include <cstdint>

namespace proofs {

// canonical a < b operation, defined as lexicographic comparison of
// the Elt's serialization
template <class Field>
bool elt_less_than(const typename Field::Elt& a, const typename Field::Elt& b,
                   const Field& F) {
  uint8_t ua[Field::kBytes], ub[Field::kBytes];
  F.to_bytes_field(ua, a);
  F.to_bytes_field(ub, b);
  for (size_t j = 0; j < Field::kBytes; ++j) {
    if (ua[j] < ub[j]) return true;
    if (ua[j] > ub[j]) return false;
  }
  return false;  // equal
}

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_COMPARE_H_
