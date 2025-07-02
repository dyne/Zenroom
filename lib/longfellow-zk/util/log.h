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

#ifndef PRIVACY_PROOFS_ZK_LIB_UTIL_LOG_H_
#define PRIVACY_PROOFS_ZK_LIB_UTIL_LOG_H_

// Simple, self-contained logger for this library.

namespace proofs {

enum LogLevel {
  ERROR = 1,
  WARNING = 10,
  INFO = 100,
};

void set_log_level(enum LogLevel l);

void log(enum LogLevel l, const char* format, ...);
};  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_UTIL_LOG_H_
