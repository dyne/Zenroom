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

#include "util/log.h"

#include <stdarg.h>
#include <stdio.h>

// The logic of these #ifdefs implements the following:
//   1. If we are building for Android, use the android logging library.
//   2. If we are building for google3, use the absl logging library.
//   3. Otherwise, use the std::chrono and fprintf(stderr) for logging.

#if defined(__ANDROID__)
#include <android/log.h>
#endif

#if defined(__ABSL__)
#include "third_party/absl/log/log.h"
#else
// The point of using std::chrono is to avoid the dependency on absl::time.
#include <chrono>
#endif

namespace proofs {

// This implementation maintains its own error thresholds in order to
// support future migration away from absl or android logging libraries.
static enum LogLevel _LOG_LEVEL = INFO;

#if !defined(__ABSL__)
static auto _last = std::chrono::steady_clock::now();
const char* level_str(enum LogLevel l) {
  switch (l) {
    case ERROR:
      return "ERROR";
    case WARNING:
      return "WARNING";
    case INFO:
      return "INFO";
    default:
      return "[Unknown]";
  }
}
#endif

void set_log_level(enum LogLevel l) { _LOG_LEVEL = l; }

void log(enum LogLevel l, const char* format, ...) {
  va_list args;
  va_start(args, format);
  char tmp[1024];
  vsnprintf(tmp, sizeof(tmp), format, args);
  va_end(args);

#if defined(__ANDROID__)
  if (l <= _LOG_LEVEL) {
    switch (l) {
      case ERROR:
        __android_log_print(ANDROID_LOG_ERROR, "proofs", "%s", tmp);
        break;
      case WARNING:
        __android_log_print(ANDROID_LOG_WARN, "proofs", "%s", tmp);
        break;
      case INFO:
        __android_log_print(ANDROID_LOG_INFO, "proofs", "%s", tmp);
        break;
    }
  }
#elif defined(__ABSL__)
  if (l <= _LOG_LEVEL) {
    switch (l) {
      case LogLevel::ERROR:
        LOG(ERROR) << tmp;
        break;
      case LogLevel::WARNING:
        LOG(WARNING) << tmp;
        break;
      case LogLevel::INFO:
        LOG(INFO) << tmp;
        break;
    }
  }
#else
  using microseconds = std::chrono::microseconds;
  using milliseconds = std::chrono::milliseconds;
  if (l <= _LOG_LEVEL) {
    auto nt = std::chrono::steady_clock::now();
    auto mus = std::chrono::duration_cast<microseconds>(nt - _last).count();
    auto ms = std::chrono::duration_cast<milliseconds>(nt - _last).count();
    mus -= ms * 1000;
    _last = nt;
    fprintf(stderr, "[%s][+%5llu.%.3llu ms] %s\n", level_str(_LOG_LEVEL),
            static_cast<long long>(ms), static_cast<long long>(mus), tmp);
  }
#endif
}

}  // namespace proofs
