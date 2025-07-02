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

#ifndef PRIVACY_PROOFS_ZK_LIB_UTIL_PANIC_H_
#define PRIVACY_PROOFS_ZK_LIB_UTIL_PANIC_H_

#if defined(__ABSL__)
#include "third_party/absl/log/check.h"
#else
#include <cstdio>
#include <cstdlib>
#endif

namespace proofs {

inline void check(bool truth, const char* why) {
#if defined(__ABSL__)
  CHECK(truth) << why;
#else
  if (!truth) {
    fprintf(stderr, "%s", why);
    abort();
  }
#endif
}

};  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_UTIL_PANIC_H_
