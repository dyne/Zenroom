// Copyright 2025-2026 Dyne.org foundation
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

// Compatibility shim: the dyne Longfellow tree split the old CircuitRep
// into CircuitReader + CircuitWriter.  This header restores the unified
// CircuitRep API that zk-circuit-lang expects.

#ifndef PRIVACY_PROOFS_ZK_LIB_PROTO_CIRCUIT_H_
#define PRIVACY_PROOFS_ZK_LIB_PROTO_CIRCUIT_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <vector>

#include "proto/circuit_io.h"
#include "proto/circuit_reader.h"
#include "proto/circuit_writer.h"

namespace proofs {

template <class Field>
class CircuitRep {
 public:
  explicit CircuitRep(const Field& f, FieldID field_id)
      : writer_(f, field_id), reader_(f, field_id) {}

  void to_bytes(const Circuit<Field>& sc_c, std::vector<uint8_t>& bytes) {
    writer_.to_bytes(sc_c, bytes);
  }

  std::unique_ptr<Circuit<Field>> from_bytes(ReadBuffer& buf,
                                             bool enforce_circuit_id) {
    return reader_.from_bytes(buf, enforce_circuit_id);
  }

 private:
  CircuitWriter<Field> writer_;
  CircuitReader<Field> reader_;
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_PROTO_CIRCUIT_H_
