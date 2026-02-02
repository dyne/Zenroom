// Copyright (C) 2025-2026 Dyne.org foundation
// designed, written and maintained by Denis Roio <jaromil@dyne.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#ifndef LONGFELLOW_ZK_LUA_CUSTOM_BACKEND_H_
#define LONGFELLOW_ZK_LUA_CUSTOM_BACKEND_H_

#include <stdlib.h>

#include <cstddef>

#include "circuits/compiler/compiler.h"

namespace proofs {
// Custom backend that compiles a circuit that, when evaluated, computes Elt's
// This is a workaround for the missing wire_id method in QuadCircuit
template <class Field>
class CustomCompilerBackend {
  using QuadCircuitF = QuadCircuit<Field>;
  using Elt = typename Field::Elt;

 public:
  using V = size_t;

  explicit CustomCompilerBackend(QuadCircuitF* q) : q_(q) {}

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

  V input_wire() const { return q_->input_wire(); }
  void output_wire(size_t n, V wire_id) const { q_->output_wire(n, wire_id); }
  
  // Workaround: wire_id is just the wire index itself for CompilerBackend
  size_t wire_id(const V& a) const { return a; }

 private:
  QuadCircuitF* q_;
};
}  // namespace proofs

#endif  // LONGFELLOW_ZK_LUA_CUSTOM_BACKEND_H_