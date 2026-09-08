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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_RNG_ADAPTER_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_RNG_ADAPTER_H_

#include <cstddef>
#include <cstdint>
#include <cstring>

#include "longfellow-zk/circuits/mdoc/mdoc_zk.h"
#include "longfellow-zk/random/random.h"

namespace proofs {

// Internal boundary adapter. It is header-visible so its fixture-free native
// test can cover callback lifetime and failure closure independently of mdoc.
class CallbackRandomEngine final : public RandomEngine {
 public:
  CallbackRandomEngine(MdocRandomCallback callback, void* context)
      : callback_(callback), context_(context) {}

  void bytes(uint8_t* out, size_t length) override {
    if (callback_ == nullptr || callback_(context_, out, length) != 0) {
      failed_ = true;
      std::memset(out, 0, length);
    }
  }

  bool failed() const { return failed_; }

 private:
  MdocRandomCallback callback_;
  void* context_;
  bool failed_ = false;
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_RNG_ADAPTER_H_
