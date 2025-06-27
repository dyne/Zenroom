/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include "util/crypto.h"

#include <cstddef>
#include <cstdint>

// from zenroom
extern "C" {
#include <randombytes.h>
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
