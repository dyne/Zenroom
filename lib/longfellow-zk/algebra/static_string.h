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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_STATIC_STRING_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_STATIC_STRING_H_

#include <cstddef>

// utility class to wrap pointers to compile-time
// constant strings
struct StaticString {
  template <size_t N>
  explicit StaticString(const char (&s)[N]) : as_pointer(s) {}

  const char* as_pointer;
};

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_STATIC_STRING_H_
