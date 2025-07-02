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

#include "circuits/sha/flatsha256_witness.h"

#include <stddef.h>
#include <stdint.h>

#include "circuits/sha/sha256_constants.h"
#include "util/ceildiv.h"
#include "util/panic.h"

namespace proofs {

static inline uint32_t shr(uint32_t x, size_t b) { return (x >> b); }

static inline uint32_t rotr(uint32_t x, size_t b) {
  return (x >> b) | (x << (32 - b));
}

static inline uint32_t Ch(uint32_t x, uint32_t y, uint32_t z) {
  return (x & y) ^ (~x & z);
}

static inline uint32_t Maj(uint32_t x, uint32_t y, uint32_t z) {
  return (x & y) ^ (x & z) ^ (y & z);
}

// See FIPS 180-4, section 4.1.2.  Use the confusing Sigma/sigma terminology
// from that document.
static inline uint32_t Sigma0(uint32_t x) {
  return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
}

static inline uint32_t Sigma1(uint32_t x) {
  return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
}

static inline uint32_t sigma0(uint32_t x) {
  return rotr(x, 7) ^ rotr(x, 18) ^ shr(x, 3);
}

static inline uint32_t sigma1(uint32_t x) {
  return rotr(x, 17) ^ rotr(x, 19) ^ shr(x, 10);
}

uint32_t SHA256_ru32be(const uint8_t *d) {
  uint32_t r = 0;
  for (size_t i = 0; i < 4; ++i) {
    r = (r << 8) + (d[i] & 0xffu);
  }
  return r;
}

void SHA256_wu64be(uint8_t *d, uint64_t n) {
  for (size_t i = 0; i < 8; ++i) {
    d[7 - i] = (n >> (8 * i)) & 0xffu;
  }
}

void FlatSHA256Witness::transform_and_witness_block(
    const uint32_t in[16], const uint32_t H0[8], uint32_t outw[48],
    uint32_t oute[64], uint32_t outa[64], uint32_t H1[8]) {
  uint32_t w[64];
  for (size_t i = 0; i < 16; ++i) {
    w[i] = in[i];
  }

  for (size_t i = 16; i < 64; ++i) {
    outw[i - 16] = w[i] =
        sigma1(w[i - 2]) + w[i - 7] + sigma0(w[i - 15]) + w[i - 16];
  }

  uint32_t a = H0[0];
  uint32_t b = H0[1];
  uint32_t c = H0[2];
  uint32_t d = H0[3];
  uint32_t e = H0[4];
  uint32_t f = H0[5];
  uint32_t g = H0[6];
  uint32_t h = H0[7];

  for (size_t t = 0; t < 64; ++t) {
    uint32_t t1 = h + Sigma1(e) + Ch(e, f, g) + kSha256Round[t] + w[t];
    uint32_t t2 = Sigma0(a) + Maj(a, b, c);
    h = g;
    g = f;
    f = e;
    oute[t] = e = d + t1;
    d = c;
    c = b;
    b = a;
    outa[t] = a = t1 + t2;
  }

  H1[0] = H0[0] + a;
  H1[1] = H0[1] + b;
  H1[2] = H0[2] + c;
  H1[3] = H0[3] + d;
  H1[4] = H0[4] + e;
  H1[5] = H0[5] + f;
  H1[6] = H0[6] + g;
  H1[7] = H0[7] + h;
}

static const uint32_t initial_h0[8] = {0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u,
                                       0xa54ff53au, 0x510e527fu, 0x9b05688cu,
                                       0x1f83d9abu, 0x5be0cd19u};

void FlatSHA256Witness::transform_and_witness_message(
    size_t n, const uint8_t msg[/*n*/], size_t max, uint8_t &numb,
    uint8_t in[/* 64*max */], BlockWitness bw[/*max*/]) {
  // Compute the exact number of blocks needed for hashing.
  numb = ceildiv<size_t>(n + 9, 64);

  size_t ii = 0;
  for (size_t i = 0; i < n; ++i, ++ii) {
    in[ii] = msg[i];
  }
  in[ii++] = 0x80;
  if ((ii % 64) == 0 || (ii % 64) > 56) {
    while (ii % 64) {
      in[ii++] = 0;
    }
  }
  while ((ii % 64) < 56) {
    in[ii++] = 0;
  }
  SHA256_wu64be(&in[ii], n * 8);
  ii += 8;
  check(ii % 64 == 0, "Invalid padding");

  // Pad to end.
  while (ii < 64 * max) {
    in[ii++] = 0;
  }

  // Compute all of the intermediate hashes and witnesses.
  uint32_t data[16];
  const uint32_t *H = initial_h0;
  for (size_t bl = 0; bl < max; bl++) {
    for (size_t i = 0; i < 16; ++i) {
      data[i] = SHA256_ru32be(&in[bl * 64 + i * 4]);
    }

    transform_and_witness_block(data, H, bw[bl].outw, bw[bl].oute, bw[bl].outa,
                                bw[bl].h1);
    H = bw[bl].h1;
  }
}

}  // namespace proofs
