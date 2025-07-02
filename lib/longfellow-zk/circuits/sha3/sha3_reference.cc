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

#include "circuits/sha3/sha3_reference.h"

#include <cstdint>
#include <cstdlib>

#include "circuits/sha3/sha3_round_constants.h"

namespace proofs {
static uint64_t rotl(uint64_t x, size_t b) {
  return (x << b) | (x >> (64 - b));
}

void Sha3Reference::keccak_f_1600_DEBUG_ONLY(uint64_t A[5][5]) {
  return keccak_f_1600(A);
}

void Sha3Reference::keccak_f_1600(uint64_t A[5][5]) {
  for (size_t round = 0; round < 24; ++round) {
    // FIPS 202 3.2.1, theta
    uint64_t C[5];
    for (size_t x = 0; x < 5; ++x) {
      C[x] = A[x][0] ^ A[x][1] ^ A[x][2] ^ A[x][3] ^ A[x][4];
    }

    for (size_t x = 0; x < 5; ++x) {
      uint64_t D_x = C[(x + 4) % 5] ^ rotl(C[(x + 1) % 5], 1);
      for (size_t y = 0; y < 5; ++y) {
        A[x][y] ^= D_x;
      }
    }

    // FIPS 202 3.2.2, rho
    {
      size_t x = 1, y = 0;
      for (size_t t = 0; t < 24; ++t) {
        A[x][y] = rotl(A[x][y], sha3_rotc[t]);
        size_t nx = y, ny = (2 * x + 3 * y) % 5;
        x = nx;
        y = ny;
      }
    }

    // FIPS 202 3.2.3, pi
    uint64_t A1[5][5];
    for (size_t x = 0; x < 5; ++x) {
      for (size_t y = 0; y < 5; ++y) {
        A1[x][y] = A[(x + 3 * y) % 5][x];
      }
    }

    // FIPS 202 3.2.4, chi
    for (size_t x = 0; x < 5; ++x) {
      for (size_t y = 0; y < 5; ++y) {
        A[x][y] = A1[x][y] ^ ((~A1[(x + 1) % 5][y]) & A1[(x + 2) % 5][y]);
      }
    }

    // FIPS 202 3.2.5, iota
    A[0][0] ^= sha3_rc[round];
  }
}

static uint64_t ru64le(const uint8_t* d) {
  uint64_t r = 0;
  for (size_t i = 8; i-- > 0;) {
    r = (r << 8) + (d[i] & 0xffu);
  }
  return r;
}

static void wu64le(uint8_t* d, uint64_t n) {
  for (size_t i = 0; i < 8; ++i) {
    d[i] = (n >> (8 * i)) & 0xffu;
  }
}

static void xorin(uint64_t A[5][5], const uint8_t* d, size_t n) {
  size_t x = 0, y = 0;
  while (n > 0) {
    A[x][y] ^= ru64le(d);
    ++x;
    if (x == 5) {
      ++y;
      x = 0;
    }
    d += sizeof(uint64_t);
    n -= sizeof(uint64_t);
  }
}

void Sha3Reference::update(const char* data, size_t n) {
  for (size_t i = 0; i < n; ++i) {
    buf_[wrptr_++] = data[i];
    if (wrptr_ == rate_) {
      xorin(a_, buf_, rate_);
      wrptr_ = 0;
      keccak_f_1600(a_);
    }
  }
}

void Sha3Reference::final(uint8_t digest[/*mdlen*/]) {
  buf_[wrptr_++] = 0x06;
  while (wrptr_ < rate_) {
    buf_[wrptr_++] = 0;
  }
  buf_[rate_ - 1] ^= 0x80;
  xorin(a_, buf_, rate_);
  wrptr_ = 0;
  keccak_f_1600(a_);

  size_t x = 0, y = 0;
  for (size_t i = 0; i < mdlen_; i += 8) {
    wu64le(&digest[i], a_[x][y]);
    ++x;
    if (x == 5) {
      ++y;
      x = 0;
    }
  }
}
}  // namespace proofs
