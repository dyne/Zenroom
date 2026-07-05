// Copyright 2026 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_PROTO_CIRCUIT_IO_H_
#define PRIVACY_PROOFS_ZK_LIB_PROTO_CIRCUIT_IO_H_

#include <cstddef>
#include <cstdint>
#include <optional>

namespace proofs {

enum FieldID {
  NONE = 0,
  P256_ID = 1,
  P384_ID = 2,
  P521_ID = 3,
  GF2_128_ID = 4,
  GF2_16_ID = 5,
  FP128_ID = 6,
  FP64_ID = 7,
  GOLDI_ID = 8,
  FP64_2_ID = 9,
  SECP_ID = 10,
};

struct CircuitIO {
  // The reader and writer classes implement an optimization by which
  // internal indices for wire and gate labels and circuit size
  // statistics are stored in a configurable number of bytes
  // (kBytesPerSizeT) which we set to 3 instead of 8 to save space.
  // If this value is set to >4, there is a possibility of failure on
  // 32b platforms, which currently stops execution.  Thus, all
  // circuits must be tested on 32b platforms to ensure they are small
  // enough to work.
  static constexpr size_t kBytesPerSizeT = 3;

  static constexpr size_t kIdSize = 32;
  static constexpr size_t kMaxLayers = 10000;  // deep circuits are errors
  static constexpr uint64_t kMaxValue = (1ULL << (kBytesPerSizeT * 8)) - 1;

  // Multiplies arguments and checks for overflow.
  template <typename T>
  static std::optional<T> checked_mul(T a, T b) {
    T ab = a * b;
    if (a == 0 || ab / a == b) return ab;
    return std::nullopt;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_PROTO_CIRCUIT_IO_H_
