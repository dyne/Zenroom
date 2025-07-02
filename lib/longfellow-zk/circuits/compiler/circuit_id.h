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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_CIRCUIT_ID_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_CIRCUIT_ID_H_

#include <stddef.h>

#include <cstdint>

#include "circuits/compiler/circuit_id.h"
#include "sumcheck/circuit.h"
#include "util/crypto.h"

namespace proofs {

// This method produces a unique name for a circuit. It does not match
// the serialization method for the circuit.
template <class Field>
void circuit_id(uint8_t id[/*32*/], const Circuit<Field>& c, const Field& F) {
  const uint64_t CHAR2 = 0x2;
  const uint64_t ODD = 0x1;
  SHA256 sha;
  uint8_t tmp[Field::kBytes];
  if (F.kCharacteristicTwo) {
    // Characteristic two fields are uniquely determined by their length
    // in our codebase.
    sha.Update8(CHAR2);  // Indicates binary field.
    sha.Update8(F.kBits);
  } else {
    // Prime fields are determined by -1.
    sha.Update8(ODD);  // Indicates odd prime field.
    F.to_bytes_field(tmp, F.mone());
    sha.Update(tmp, sizeof(tmp));
  }
  sha.Update8(c.nv);
  sha.Update8(c.logv);
  sha.Update8(c.nc);
  sha.Update8(c.logc);
  sha.Update8(c.nl);
  sha.Update8(c.ninputs);
  sha.Update8(c.npub_in);
  sha.Update8(c.subfield_boundary);
  for (const auto& layer : c.l) {
    sha.Update8(layer.nw);
    sha.Update8(layer.logw);
    sha.Update8(layer.quad->n_);
    for (size_t i = 0; i < layer.quad->n_; ++i) {
      sha.Update8(static_cast<uint64_t>(layer.quad->c_[i].g));
      sha.Update8(static_cast<uint64_t>(layer.quad->c_[i].h[0]));
      sha.Update8(static_cast<uint64_t>(layer.quad->c_[i].h[1]));
      F.to_bytes_field(tmp, layer.quad->c_[i].v);
      sha.Update(tmp, sizeof(tmp));
    }
  }
  sha.DigestData(id);
}

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_CIRCUIT_ID_H_
