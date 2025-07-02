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

#ifndef PRIVACY_PROOFS_ZK_LIB_ARRAYS_AFFINE_H_
#define PRIVACY_PROOFS_ZK_LIB_ARRAYS_AFFINE_H_

#include <stddef.h>

namespace proofs {

using corner_t = size_t;

// return r * f0 + (1-r) * f1 = f0 + r * (f1 - f0)
template <typename Field>
typename Field::Elt affine_interpolation(const typename Field::Elt& r,
                                         typename Field::Elt f0,
                                         typename Field::Elt f1,
                                         const Field& F) {
  F.sub(f1, f0);
  F.mul(f1, r);
  F.add(f0, f1);
  return f0;
}

// special case f0 = 0
template <typename Field>
typename Field::Elt affine_interpolation_z_nz(const typename Field::Elt& r,
                                              typename Field::Elt f1,
                                              const Field& F) {
  F.mul(f1, r);
  return f1;
}

// special case f1 = 0
template <typename Field>
typename Field::Elt affine_interpolation_nz_z(const typename Field::Elt& r,
                                              typename Field::Elt f0,
                                              const Field& F) {
  F.sub(f0, F.mulf(f0, r));
  return f0;
}

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ARRAYS_AFFINE_H_
