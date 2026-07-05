/*
 * Copyright (C) 2025 Dyne.org foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "util/crypto.h"

#include <cstddef>
#include <cstdint>

extern "C" {
#include <util/randombytes.h>
}

#include "util/panic.h"

namespace proofs {

void rand_bytes(uint8_t out[/*n*/], size_t n) {
  int ret = randombytes(out, n);
  check(ret == 0, "randombytes failed");
}

void hex_to_str(char out[/* 2*n + 1*/], const uint8_t in[/*n*/], size_t n) {
  for (size_t i = 0; i < n; ++i) {
    out[2 * i] = "0123456789abcdef"[in[i] >> 4];
    out[2 * i + 1] = "0123456789abcdef"[in[i] & 0xf];
  }
  out[2 * n] = '\0';
}


}  // namespace proofs
