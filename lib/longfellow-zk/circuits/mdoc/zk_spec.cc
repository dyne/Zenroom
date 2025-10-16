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
//   time the circuit changes, the hash must be manually calculated and a new
//   ZKSpec added to this list.
//   - num_attributes. number of attributes the circuit supports,
//   - version. version of the ZK specification
//.  - block_enc_hash. block_enc parameter for the ZK proof of the hash
//     component. Version 3 uses the legacy-computed value, v4 uses optimized
//     values.
//   - block_enc_sig. block_enc parameter for the ZK proof of the signature
//     component.
// }

const ZkSpecStruct kZkSpecs[kNumZkSpecs] = {
    // Circuits produced on 2025-08-21
    {"longfellow-libzk-v1",
     "f88a39e561ec0be02bb3dfe38fb609ad154e98decbbe632887d850fc612fea6f", 1, 5,
     4096, 2945},
    {"longfellow-libzk-v1",
     "f51b7248b364462854d306326abded169854697d752d3bb6d9a9446ff7605ddb", 2, 5,
     4025, 2945},
    {"longfellow-libzk-v1",
     "c27195e03e22c9ab4efe9e1dabd2c33aa8b2429cc4e86410c6f12542d3c5e0a1", 3, 5,
     4121, 2945},
    {"longfellow-libzk-v1",
     "fa5fadfb2a916d3b71144e9b412eff78f71fd6a6d4607eac10de66b195868b7a", 4, 5,
     4283, 2945},

    // Circuits produced on 2025-07-22.
    {"longfellow-libzk-v1",
     "89288b9aa69d2120d211618fcca8345deb4f85d2e710c220cc9c059bbee4c91f", 1, 4,
     4096, 4096},
    {"longfellow-libzk-v1",
     "d260f7ef1bc82a25ad174d61a9611ba4a6e0c8f2f8520d2b6ea1549c79abcd55", 2, 4,
     4096, 4096},
    {"longfellow-libzk-v1",
     "77aa19bdb547b68a30deb37b94d3a506222a455806afcddda88d591493e9a689", 3, 4,
     4096, 4096},
    {"longfellow-libzk-v1",
     "31bc7c86c71871dad73619e7da7c5a379221602a3f28ea991b05da1ef656d13c", 4, 4,
     4096, 4096},

    // Circuits produced on 2025-06-13
    {"longfellow-libzk-v1",
     "bd3168ea0a9096b4f7b9b61d1c210dac1b7126a9ec40b8bc770d4d485efce4e9", 1, 3,
     4096, 4096},
    {"longfellow-libzk-v1",
     "40b2b68088f1d4c93a42edf01330fed8cac471cdae2b192b198b4d4fc41c9083", 2, 3,
     4096, 4096},
    {"longfellow-libzk-v1",
     "99a5da3739df68c87c7a380cc904bb275dbd4f1b916c3d297ba9d15ee86dd585", 3, 3,
     4096, 4096},
    {"longfellow-libzk-v1",
     "5249dac202b61e03361a2857867297ee7b1d96a8a4c477d15a4560bde29f704f", 4, 3,
     4096, 4096},
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
