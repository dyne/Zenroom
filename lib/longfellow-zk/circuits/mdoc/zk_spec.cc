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

#include <stdint.h>

#include <cstring>

#include "circuits/mdoc/mdoc_zk.h"

extern "C" {
// This is a hardcoded list of all the ZK specifications supported by this
// library. Every time a new breaking change is introduced in either the circuit
// format or its interpretation, a new version must be added here.
// It is possible to remove old versions, if we're sure that they are not used
// by either provers of verifiers in the wild.
//
// The format is:
// {
//   - system - The ZK system name and version ("longfellow-libzk-v*" for Google
//   library).
//   - circuit_hash - SHA265 hash of the output of generate_circuit() function,
//   the circuit in compressed format. It's converted to a hex string. Every
//   time the circuit changes, the hash must be manaully calculated and a new
//   ZKSpec added to this list.
//   - num_attributes. number of attributes the circuit supports,
//   - version. version of the ZK specification
// }

const ZkSpecStruct kZkSpecs[kNumZkSpecs] = {
    {"longfellow-libzk-v1",
     "2836f0df5b7c2c431be21411831f8b3d2b7694b025a9d56a25086276161f7a93", 1, 1},
    {"longfellow-libzk-v1",
     "40a24808f53f516b3e653ec898342c46acf3b4a98433013548e780d2ffb1b4d0", 2, 1},
    {"longfellow-libzk-v1",
     "0f5a3bfa24a1252544fda4602fea98fc69b6296b64d4c7e48f2420de2910bf55", 3, 1},
    {"longfellow-libzk-v1",
     "96b71d7173c0341860d7b1b8fbcceca3d55347ecca1c9617e7d6efbb6b5cf344", 4, 1},
};

const ZkSpecStruct *find_zk_spec(const char *system_name,
                                 const char *circuit_hash) {
  for (size_t i = 0; i < kNumZkSpecs; ++i) {
    const ZkSpecStruct &zk_spec = kZkSpecs[i];
    if (strcmp(zk_spec.system, system_name) == 0 &&
        strcmp(zk_spec.circuit_hash, circuit_hash) == 0) {
      return &zk_spec;
    }
  }
  return nullptr;
}

}  // extern "C"
