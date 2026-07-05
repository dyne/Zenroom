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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_EVALUATION_BACKEND_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_EVALUATION_BACKEND_H_

#include "util/panic.h"

namespace proofs {
// backend that evaluates values directly
template <class Field>
class EvaluationBackend {
  using Elt = typename Field::Elt;

 public:
  explicit EvaluationBackend(const Field& F,
                             bool panic_on_assertion_failure = true)
      : f_(F),
        panic_on_assertion_failure_(panic_on_assertion_failure),
        assertion_failed_(false) {}

  ~EvaluationBackend() {
    // Crash if assertion_failed_, which indicates that a test
    // has forgotten to read the value
    check(!assertion_failed_, "assertion_failed_ true in ~EvaluationBackend()");
  }

  // Reading ASSERTION_FAILED_ returns the current ASSERTION_FAILED_
  // state and resets the state.
  bool assertion_failed() const {
    bool b = assertion_failed_;
    assertion_failed_ = false;
    return b;
  }

  struct V {
    Elt e;
    V() = default;
    explicit V(const Elt& x) : e(x) {}
    Elt elt() const { return e; }

    bool operator==(const V& y) const { return e == y.e; }
    bool operator!=(const V& y) const { return e != y.e; }
  };

  V assert0(const V& a) const {
    if (a.e == f_.zero()) {
      return a;
    } else {
      if (panic_on_assertion_failure_) {
        check(false, "a != F.zero()");
      }
      assertion_failed_ = true;
    }
    return a;
  }

  V add(const V& a, const V& b) const { return V{f_.addf(a.e, b.e)}; }
  V sub(const V& a, const V& b) const { return V{f_.subf(a.e, b.e)}; }
  V mul(const V& a, const V& b) const { return V{f_.mulf(a.e, b.e)}; }
  V mul(const Elt& a, const V& b) const { return V{f_.mulf(a, b.e)}; }
  V mul(const Elt& a, const V& b, const V& c) const {
    return mul(a, mul(b, c));
  }
  V konst(const Elt& a) const { return V{a}; }

  V ax(const Elt& a, const V& x) const { return V{f_.mulf(a, x.e)}; }
  V axy(const Elt& a, const V& x, const V& y) const {
    return V{f_.mulf(a, f_.mulf(x.e, y.e))};
  }
  V axpy(const V& y, const Elt& a, const V& x) const {
    return V{f_.addf(y.e, f_.mulf(a, x.e))};
  }
  V apy(const V& y, const Elt& a) const { return V{f_.addf(y.e, a)}; }

 private:
  const Field& f_;
  bool panic_on_assertion_failure_;
  mutable bool assertion_failed_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_EVALUATION_BACKEND_H_
