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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_NODE_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_NODE_H_

#include <stddef.h>
#include <stdint.h>

#include <algorithm>
#include <vector>

#include "sumcheck/quad.h"
#include "util/crc64.h"
#include "util/panic.h"

namespace proofs {

struct term {
  // size_t surrogate for storing things like depth and
  // pointers to nodes, since we only really need 32 bits.
  using size_t_for_storage = uint32_t;

  size_t_for_storage ki;  // index of the constant term into constants_[]
  size_t_for_storage op0, op1;

  term() = default;

  // canonicalized by op0 <= op1
  explicit term(size_t ki, size_t op0, size_t op1)
      : ki(ki),
        op0(std::min<size_t>(op0, op1)),
        op1(std::max<size_t>(op0, op1)) {
    // Terms with k=0 are not supposed to occur, since
    // we represent a zero node as an empty list of terms.
    // We represent Elt(0) as index ki=0 in the table of constants.
    proofs::check(ki != 0, "ki != 0");
  }

  // special hack for assert0
  struct assert0_type_hack {};  // so that we don't call this constructor
                                // accidentally
  explicit term(size_t op, assert0_type_hack& hack)
      : ki(/*kstore(f.zero())=*/0), op0(0), op1(op) {}

  bool ltndx(const term& y) const {
    if (op1 < y.op1) return true;
    if (op1 > y.op1) return false;
    return op0 < y.op0;
  }
  bool eqndx(const term& y) const { return (op1 == y.op1 && op0 == y.op0); }

  // term is a constant
  bool constant() const { return op0 == 0 && op1 == 0; }

  // linear term k * (1 * op1)
  bool linearp() const { return op0 == 0; }

  bool operator==(const term& y) const {
    return ki == y.ki && op0 == y.op0 && op1 == y.op1;
  }
};

template <class Field>
struct NodeInfoF {
  using quad_corner_t = typename Quad<Field>::quad_corner_t;
  using size_t_for_storage = term::size_t_for_storage;

  static const constexpr quad_corner_t kWireIdUndefined = quad_corner_t(-1);

  size_t_for_storage depth;
  quad_corner_t desired_wire_id_for_input;
  quad_corner_t desired_wire_id_for_output;
  size_t_for_storage max_needed_depth;
  bool is_needed;
  bool is_output;
  bool is_input;
  bool is_assert0;

  NodeInfoF()
      : depth(0),
        desired_wire_id_for_input(kWireIdUndefined),
        desired_wire_id_for_output(kWireIdUndefined),
        max_needed_depth(0),
        is_needed(false),
        is_output(false),
        is_input(false),
        is_assert0(false) {}

  // we use the desired wire id only at the appropriate depth,
  // and not e.g. for copy wires.
  quad_corner_t desired_wire_id(size_t depth0, size_t depth_ub) const {
    if (is_input && depth0 == 0) {
      return desired_wire_id_for_input;
    }
    if (is_output && depth0 + 1 == depth_ub) {
      return desired_wire_id_for_output;
    }
    return kWireIdUndefined;
  }
};

template <class Field>
struct NodeF {
  using nodeinfo = NodeInfoF<Field>;
  using quad_corner_t = typename Quad<Field>::quad_corner_t;

  std::vector<term> terms;
  nodeinfo info;

  NodeF() = delete;
  explicit NodeF(quad_corner_t id) : terms() {
    info.is_input = true;
    info.desired_wire_id_for_input = id;
  }

  explicit NodeF(size_t ki, size_t op0, size_t op1) : terms() {
    if (ki != 0) {
      terms.push_back(term(ki, op0, op1));
    }
  }

  explicit NodeF(const std::vector<term>& terms) : terms(terms) {}

  bool zero() const { return !info.is_input && terms.empty(); }
  bool constant() const { return terms.size() == 1 && terms[0].constant(); }
  bool linearp() const { return terms.size() == 1 && terms[0].linearp(); }

  bool operator==(const NodeF& y) const {
    if (info.is_input != y.info.is_input) return false;
    if (info.desired_wire_id_for_input != y.info.desired_wire_id_for_input)
      return false;
    if (info.is_output != y.info.is_output) return false;
    if (info.desired_wire_id_for_output != y.info.desired_wire_id_for_output)
      return false;
    if (info.is_input != y.info.is_input) return false;
    if (terms.size() != y.terms.size()) return false;
    size_t l = terms.size();
    for (size_t i = 0; i < l; ++i) {
      if (!(terms[i] == y.terms[i])) return false;
    }
    return true;
  }
  uint64_t hash() const {
    uint64_t crc = 0x1;
    crc = crc64::update(crc,
                        static_cast<uint64_t>(info.desired_wire_id_for_input));
    crc = crc64::update(crc,
                        static_cast<uint64_t>(info.desired_wire_id_for_output));
    crc = crc64::update(crc, info.is_input);
    crc = crc64::update(crc, info.is_output);
    size_t l = terms.size();
    crc = crc64::update(crc, l);
    for (size_t i = 0; i < l; ++i) {
      crc = crc64::update(crc, terms[i].ki);
      crc = crc64::update(crc, terms[i].op0);
      crc = crc64::update(crc, terms[i].op1);
    }
    return crc;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_NODE_H_
