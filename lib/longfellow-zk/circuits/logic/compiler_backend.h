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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_COMPILER_BACKEND_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_COMPILER_BACKEND_H_

#include <stdlib.h>

#include <cstddef>

#include "circuits/compiler/compiler.h"

namespace proofs {
// backend that compiles a circuit that, when evaluated, computes Elt's
template <class Field>
class CompilerBackend {
  using QuadCircuitF = QuadCircuit<Field>;
  using Elt = typename Field::Elt;

 public:
  using V = size_t;

  explicit CompilerBackend(QuadCircuitF* q) : q_(q) {}

  V assert0(const V& a) const { return q_->assert0(a); }
  V add(const V& a, const V& b) const { return q_->add(a, b); }
  V sub(const V& a, const V& b) const {
    auto mb = mul(konst(q_->f_.mone()), b);
    return add(a, mb);
  }
  V mul(const V& a, const V& b) const { return q_->mul(a, b); }
  V mul(const Elt& a, const V& b) const { return q_->mul(a, b); }
  V mul(const Elt& a, const V& b, const V& c) const { return q_->mul(a, b, c); }
  V konst(const Elt& a) const { return q_->konst(a); }

  V ax(const Elt& a, const V& x) const { return q_->mul(a, x); }
  V axy(const Elt& a, const V& x, const V& y) const { return q_->mul(a, x, y); }
  V axpy(const V& y, const Elt& a, const V& x) const {
    return q_->axpy(y, a, x);
  }
  V apy(const V& y, const Elt& a) const { return q_->apy(y, a); }

  V input() const { return q_->input(); }
  void output(size_t n, V wire_id) const { q_->output(n, wire_id); }
  size_t wire_id(const V& a) const { return q_->wire_id(a); }

 private:
  QuadCircuitF* q_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_COMPILER_BACKEND_H_
