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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA3_SHA3_ROUND_CONSTANTS_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA3_SHA3_ROUND_CONSTANTS_H_

#include <cstdint>
#include <cstdlib>

namespace proofs {
extern const uint64_t sha3_rc[24];
extern const size_t sha3_rotc[24];
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA3_SHA3_ROUND_CONSTANTS_H_
