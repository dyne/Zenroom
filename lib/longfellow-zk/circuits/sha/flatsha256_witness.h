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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA_FLATSHA256_WITNESS_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA_FLATSHA256_WITNESS_H_

#include <stddef.h>
#include <stdint.h>

namespace proofs {

uint32_t SHA256_ru32be(const uint8_t *d);

class FlatSHA256Witness {
 public:
  struct BlockWitness {
    uint32_t outw[48];
    uint32_t oute[64];
    uint32_t outa[64];
    uint32_t h1[8];
  };

  static void transform_and_witness_block(const uint32_t in[16],
                                          const uint32_t H0[8],
                                          uint32_t outw[48], uint32_t oute[64],
                                          uint32_t outa[64], uint32_t H1[8]);

  static void transform_and_witness_message(size_t n, const uint8_t msg[/*n*/],
                                            size_t max, uint8_t &numb,
                                            uint8_t in[/* 64*max */],
                                            BlockWitness bw[/*max*/]);
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA_FLATSHA256_WITNESS_H_
