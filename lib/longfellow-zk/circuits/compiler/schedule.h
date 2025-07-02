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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_SCHEDULE_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_SCHEDULE_H_

#include <stddef.h>
#include <stdint.h>

#include <algorithm>
#include <memory>
#include <vector>

#include "algebra/compare.h"
#include "arrays/affine.h"
#include "circuits/compiler/node.h"
#include "sumcheck/circuit.h"
#include "sumcheck/quad.h"
#include "util/ceildiv.h"
#include "util/panic.h"

namespace proofs {
template <class Field>
class Scheduler {
  using Elt = typename Field::Elt;
  using nodeinfo = NodeInfoF<Field>;
  using node = NodeF<Field>;
  using size_t_for_storage = term::size_t_for_storage;
  using quad_corner_t = typename Quad<Field>::quad_corner_t;

  const Field& f_;
  const std::vector<node>& nodes_;

 public:
  size_t nwires_;
  size_t nquad_terms_;
  size_t nwires_overhead_;

  Scheduler(const std::vector<node>& nodes, const Field& f)
      : f_(f),
        nodes_(nodes),
        nwires_(0),
        nquad_terms_(0),
        nwires_overhead_(0) {}

  std::unique_ptr<Circuit<Field>> mkcircuit(const std::vector<Elt>& constants,
                                            size_t depth_ub, size_t nc) {
    std::unique_ptr<Circuit<Field>> c = std::make_unique<Circuit<Field>>();

    // number of layers and copies
    c->nl = depth_ub - 1;  // depth 0 = input nodes, not a "layer"
    c->nc = nc;
    c->logc = lg(nc);

    auto lnodes = order_by_layer(constants, depth_ub);

    // TODO [matteof 2025-03-12] ASSIGN_WIRE_IDS() renames LNODES in
    // order to sort it and assign LNODES[].DESIRED_WIRE ID.  Then it
    // throws away the renamed LNODES.  Then FILL_LAYERS() renames
    // LNODES again in order to produce the final quad.  It would be
    // better to produce the quad directly in ASSIGN_WIRE_IDS().  Punt
    // for now, this is just a performance optimization of the
    // compiler anyway.
    //
    assign_wire_ids(lnodes);
    fill_layers(c.get(), depth_ub, lnodes);

    return c;
  }

 private:
  // per-layer representation of nodes and terms
  struct lterm {
    Elt k;
    quad_corner_t lop0, lop1;
  };
  struct lnode {
    quad_corner_t desired_wire_id;

    // Copy wires are forced to be distinct from wires in the
    // original dag, in order to avoid ambiguity in renaming.
    //
    // Copy wires are always of the form 1*op, which doesn't
    // normally appear in the dag because the algebraic simplifier
    // reduces it to op.  However, one can in theory create such
    // a node by judicious use of linear().  Rather than
    // trying to figure out which circuits one is not allowed
    // to write, it seems simpler to just handle this case
    // uniformly.
    bool is_copy_wire;

    std::vector<lterm> lterms;

    lnode(quad_corner_t desired_wire_id, bool is_copy_wire,
          const std::vector<lterm>& lterms)
        : desired_wire_id(desired_wire_id),
          is_copy_wire(is_copy_wire),
          lterms(lterms) {}
  };

  quad_corner_t lop_of_op_at_depth(
      const std::vector<std::vector<quad_corner_t>>& lop, size_t op,
      size_t d) const {
    const node& n = nodes_.at(op);
    return lop.at(op).at(d - n.info.depth);
  }

  // Convert the DAG of nodes into a layered dag of lnodes.
  std::vector<std::vector<lnode>> order_by_layer(
      const std::vector<Elt>& constants, size_t depth_ub) {
    // The source DAG is indexed by NODES_[OP].
    // The destination dag uses a two-dimensional indexing
    // scheme LNODES[D][LOP], where D is the depth.

    // A single value NODES_[OP] may be replicated multiple times in
    // LNODES.  The mapping is maintained in array LOPS such that
    // LOPS[OP][D - D0] contains the LOP index of node OP at depth D.
    // D0 is the depth at which NODES_[OP] is first computed, and
    // there is no point in storing LOPS[OP] for D < D0.

    std::vector<std::vector<lnode>> lnodes(depth_ub);
    std::vector<std::vector<quad_corner_t>> lops(nodes_.size());

    nwires_overhead_ = 0;

    for (size_t op = 0; op < nodes_.size(); ++op) {
      const auto& n = nodes_[op];
      const nodeinfo& nfo = n.info;
      if (nfo.is_needed && !n.zero()) {
        size_t d = nfo.depth;

        // Allocate the LOP at depth D
        quad_corner_t lop = quad_corner_t(lnodes.at(d).size());
        lops.at(op).push_back(lop);

        // create a LOPS entry for depth D
        /*scope*/ {
          std::vector<lterm> lterms;
          for (const auto& t : n.terms) {
            lterm lt = {
                .k = constants.at(t.ki),
                .lop0 = lop_of_op_at_depth(lops, t.op0, d - 1),
                .lop1 = lop_of_op_at_depth(lops, t.op1, d - 1),
            };
            lterms.push_back(lt);
          }
          lnodes.at(d).push_back(lnode(nfo.desired_wire_id(d, depth_ub),
                                       /*is_copy_wire=*/false, lterms));
        }

        // create copy wires
        for (size_t d = nfo.depth + 1; d < nfo.max_needed_depth; ++d) {
          quad_corner_t lop_dm1 = lop;

          // allocate the LOP at depth D
          lop = quad_corner_t(lnodes.at(d).size());
          lops.at(op).push_back(lop);

          std::vector<lterm> lterms;

          // Insert a multiplication by one of the layer
          // at the previous layer.
          lterm lt = {
              .k = f_.one(),
              .lop0 = quad_corner_t(0),
              .lop1 = lop_dm1,
          };
          lterms.push_back(lt);
          lnodes.at(d).push_back(lnode(nfo.desired_wire_id(d, depth_ub),
                                       /*is_copy_wire=*/true, lterms));
          ++nwires_overhead_;
        }  // for copy wires
      }  // if needed
    }  // for OP

    return lnodes;
  }

  //------------------------------------------------------------
  // canonical assignment of wire ids
  //------------------------------------------------------------
  //
  // The canonicalization order is a matter of convention.
  // We make some arbitrary choices that appear to interact
  // better with ZSTD compression.  The label [ARBITRARY CHOICE]
  // denotes all places in the code where this occurs.
  //
  class renamed_lterm {
   public:
    Elt k_;
    quad_corner_t rlop0_, rlop1_;

    // [ARBITRARY CHOICE] Consistent with corner::canonicalize() in
    // sumcheck/quad.h
    renamed_lterm(const Elt& k, quad_corner_t rlop0, quad_corner_t rlop1)
        : k_(k),
          rlop0_(std::min<quad_corner_t>(rlop0, rlop1)),
          rlop1_(std::max<quad_corner_t>(rlop0, rlop1)) {}

    bool operator==(const renamed_lterm& y) const {
      return rlop0_ == y.rlop0_ && rlop1_ == y.rlop1_ && k_ == y.k_;
    }

    // canonical order
    static bool compare(const renamed_lterm& a, const renamed_lterm& b,
                        const Field& F) {
      if (a.rlop0_ < b.rlop0_) return true;
      if (a.rlop0_ > b.rlop0_) return false;
      if (a.rlop1_ < b.rlop1_) return true;
      if (a.rlop1_ > b.rlop1_) return false;
      return elt_less_than(a.k_, b.k_, F);
    }
  };

  class renamed_lnode {
   public:
    quad_corner_t desired_wire_id_;
    quad_corner_t original_wire_index_;
    bool is_copy_wire_;
    std::vector<renamed_lterm> rlterms_;

    renamed_lnode(quad_corner_t desired_wire_id,
                  quad_corner_t original_wire_index, bool is_copy_wire,
                  const std::vector<renamed_lterm>& rlterms)
        : desired_wire_id_(desired_wire_id),
          original_wire_index_(original_wire_index),
          is_copy_wire_(is_copy_wire),
          rlterms_(rlterms) {}

    bool operator==(const renamed_lnode& y) const {
      if (is_copy_wire_ != y.is_copy_wire_) return false;
      if (rlterms_.size() != y.rlterms_.size()) return false;
      size_t l = rlterms_.size();
      for (size_t i = 0; i < l; ++i) {
        if (!(rlterms_[i] == y.rlterms_[i])) return false;
      }
      return true;
    }

    // canonical order
    static bool compare(const renamed_lnode& ra, const renamed_lnode& rb,
                        const Field& F) {
      // Defined before undefined.  This choice is mandated by the
      // fact that the range of defined wire id's starts at 0.
      if (ra.desired_wire_id_ != nodeinfo::kWireIdUndefined) {
        if (rb.desired_wire_id_ != nodeinfo::kWireIdUndefined) {
          return ra.desired_wire_id_ < rb.desired_wire_id_;
        } else {
          return true;
        }
      } else {
        if (rb.desired_wire_id_ != nodeinfo::kWireIdUndefined) {
          return false;
        }
        // else both undefined
      }

      // [ARBITRARY CHOICE] Lexicographic order on the reverse of the
      // terms array.  This seems to compress much better than
      // the normal lexicographic order.
      for (size_t ia = ra.rlterms_.size(), ib = rb.rlterms_.size();
           ia-- > 0 && ib-- > 0;) {
        const renamed_lterm& rlta = ra.rlterms_[ia];
        const renamed_lterm& rltb = rb.rlterms_[ib];
        if (renamed_lterm::compare(rlta, rltb, F)) return true;
        if (renamed_lterm::compare(rltb, rlta, F)) return false;
      }

      // [ARBITRARY CHOICE] If the common suffixes are the same, the
      // shorter terms come first.
      if (ra.rlterms_.size() < rb.rlterms_.size()) return true;
      if (ra.rlterms_.size() > rb.rlterms_.size()) return false;

      // Nodes that were in the original dag come first.
      if (!ra.is_copy_wire_ && rb.is_copy_wire_) return true;
      if (!rb.is_copy_wire_ && ra.is_copy_wire_) return false;

      // equal, i.e., not less-than
      return false;
    }
  };

  template <class T>
  bool uniq(const std::vector<T>& sorted) {
    for (size_t i = 0; i + 1 < sorted.size(); ++i) {
      if (sorted[i] == sorted[i + 1]) return false;
    }
    return true;
  }

  void assign_wire_ids(std::vector<std::vector<lnode>>& lnodes) {
    // all inputs are expected to be defined already
    assert_all_desired_wire_id_defined(lnodes.at(0));

    for (size_t d = 1; d < lnodes.size(); ++d) {
      const std::vector<lnode>& lnodes_at_dm1 = lnodes.at(d - 1);
      const std::vector<lnode>& lnodes_at_d = lnodes.at(d);

      // Create a renamed clone of LNODES_AT_D, in which all
      // the LOP's are mapped to their desired wire id's
      // at the previous layer.  We use different types
      // to avoid any possibility of confusion.
      std::vector<renamed_lnode> renamed_at_d;

      quad_corner_t original_wire_index(0);
      for (const lnode& ln : lnodes_at_d) {
        std::vector<renamed_lterm> rlterms;

        // rename all terms
        rlterms.reserve(ln.lterms.size());
        for (const lterm& lt : ln.lterms) {
          rlterms.push_back(renamed_lterm(
              lt.k,
              lnodes_at_dm1.at(static_cast<size_t>(lt.lop0)).desired_wire_id,
              lnodes_at_dm1.at(static_cast<size_t>(lt.lop1)).desired_wire_id));
        }

        // canonicalize the terms order
        std::sort(rlterms.begin(), rlterms.end(),
                  [&](const renamed_lterm& a, const renamed_lterm& b) {
                    return renamed_lterm::compare(a, b, f_);
                  });

        // Terms must be unique, otherwise the canonicalization is
        // ill-defined.  Uniqueness is guaranteed by the algebraic
        // simplifier, but assert it for good measure.
        check(uniq(rlterms), "rlterms not unique");

        renamed_at_d.push_back(renamed_lnode(
            ln.desired_wire_id, original_wire_index, ln.is_copy_wire, rlterms));
        ++original_wire_index;
      }

      check(renamed_at_d.size() == lnodes_at_d.size(),
            "renamed_at_d.size() == lnodes_at_d.size()");

      std::sort(renamed_at_d.begin(), renamed_at_d.end(),
                [&](const renamed_lnode& a, const renamed_lnode& b) {
                  return renamed_lnode::compare(a, b, f_);
                });

      // Nodes must be unique, otherwise the canonicalization is
      // ill-defined.
      check(uniq(renamed_at_d), "renamed_at_d not unique");

      quad_corner_t wid(0);
      std::vector<lnode>& wlnodes_at_d = lnodes.at(d);

      for (const renamed_lnode& ln : renamed_at_d) {
        lnode& lnpi =
            wlnodes_at_d.at(static_cast<size_t>(ln.original_wire_index_));
        if (lnpi.desired_wire_id != nodeinfo::kWireIdUndefined) {
          // We must have computed the same wire id
          check(wid == lnpi.desired_wire_id, "wid == lnpi.desired_wire_id");
        } else {
          lnpi.desired_wire_id = wid;
        }
        wid++;
      }
    }
  }

  void assert_all_desired_wire_id_defined(const std::vector<lnode>& layer) {
    for (const auto& ln : layer) {
      check(ln.desired_wire_id != nodeinfo::kWireIdUndefined,
            "ln.desired_wire_id != kWireIdUndefined");
    }
  }

  void fill_layers(Circuit<Field>* c, size_t depth_ub,
                   const std::vector<std::vector<lnode>>& lnodes) {
    check(depth_ub == lnodes.size(), "depth_ub == lnodes.size()");

    corner_t nv = corner_t(lnodes.at(depth_ub - 1).size());

    nwires_ = nv;
    c->nv = nv;
    c->logv = lg(nv);

    // d-- > 1 (not 0) because depth 0 denotes input nodes, not a layer.
    // Sumcheck counts layers starting from the output, hence the loop
    // counts downwards.
    for (size_t d = depth_ub; d-- > 1;) {
      corner_t nw =
          corner_t(lnodes.at(d - 1).size());  // inputs[d] == outputs[d-1]
      nwires_ += nw;
      c->l.push_back(
          Layer<Field>{.nw = nw,
                       .logw = lg(nw),
                       .quad = mkquad(lnodes.at(d), lnodes.at(d - 1))});
    }
  }

  std::unique_ptr<const Quad<Field>> mkquad(
      const std::vector<lnode>& lnodes0,  // wires at this layer
      const std::vector<lnode>& lnodes1   // wires at the previous layer
  ) {
    size_t nterms0 = 0;
    for (const auto& ln0 : lnodes0) {
      nterms0 += ln0.lterms.size();
    }
    nquad_terms_ += nterms0;

    auto S = std::make_unique<Quad<Field>>(nterms0);
    size_t i = 0;
    for (const auto& ln0 : lnodes0) {
      for (const auto& lt : ln0.lterms) {
        S->c_[i++] = typename Quad<Field>::corner{
            .g = ln0.desired_wire_id,
            .h = {lnodes1.at(static_cast<size_t>(lt.lop0)).desired_wire_id,
                  lnodes1.at(static_cast<size_t>(lt.lop1)).desired_wire_id},
            .v = lt.k};
      }
    }
    S->canonicalize(f_);
    return S;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_SCHEDULE_H_
