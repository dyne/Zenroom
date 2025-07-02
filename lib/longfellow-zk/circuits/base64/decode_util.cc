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

#include "circuits/base64/decode_util.h"

#include <stdint.h>

#include <cstddef>
#include <string>
#include <vector>

namespace proofs {

bool base64_decode_url(std::string inp, std::vector<uint8_t>& out) {
  std::string valid =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

  for (size_t i = 0; i < inp.size(); i += 4) {
    uint8_t quad[4] = {0}; /* a quad of 6 bits */
    for (size_t j = 0; j < 4 && i + j < inp.size(); ++j) {
      size_t ind = valid.find(inp[i + j]);
      if (ind == std::string::npos) {
        return false;
      }
      quad[j] = (uint8_t)ind;
    }
    uint8_t res[3] = {0};
    res[0] = quad[0] << 2 | quad[1] >> 4;
    res[1] = quad[1] << 4 | quad[2] >> 2;
    res[2] = quad[2] << 6 | quad[3];
    out.insert(out.end(), res, res + 3);
  }
  return true;
}

}  // namespace proofs
