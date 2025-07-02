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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BASE64_DECODE_UTIL_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BASE64_DECODE_UTIL_H_

#include <stdint.h>

#include <string>
#include <vector>

namespace proofs {

bool base64_decode_url(std::string inp, std::vector<uint8_t>& out);

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_BASE64_DECODE_UTIL_H_
