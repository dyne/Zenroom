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

#ifndef PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_H_
#define PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_H_

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <memory>
#include <vector>

#include "arrays/affine.h"
#include "arrays/eqs.h"
#include "sumcheck/equad.h"
#include "sumcheck/hquad.h"
#include "util/panic.h"

// ------------------------------------------------------------
// Representation of the QUAD array used in sumcheck.
//
// The main concern is to save memory.  To this end,
// we have three representations of the quad.
//
// The fully expanded representation EQuad (in equad.h)
// comprises the indices and the coefficient value.  EQuad
// is the only representation that can be canonicalized.
//
// The "ordinary" representation Quad (this file) contains (g, h)
// indices but it stores the coefficient as an index into an array of
// constants, where the index is 32 bits and the constant is a large
// field element.
//
// In addition, HQuad represents a QUAD after the g index has
// been bound.  Since g = 0 it does not need to be stored.
// A special method Quad::bind_g produces a compact HQuad in
// one step.
//
// The compiler works on EQuad and converts to Quad when done.
// Circuit evaluation works on Quad and materializes EQuad
// lazily.  Sumcheck starts with Quad, binds g into an HQuad,
// and finishes binding h on HQuad.
namespace proofs {
template <class Field>
class Quad {
  using Elt = typename Field::Elt;
  using Accum = typename Field::Accum;
  using kvec_t = std::vector<Elt>;
  using ecorner = typename EQuad<Field>::ecorner;
  using hcorner = typename HQuad<Field>::hcorner;
  using vcorner = typename HQuad<Field>::vcorner;

 public:
  using quad_corner_t = typename EQuad<Field>::quad_corner_t;
  using index_t = typename EQuad<Field>::index_t;

  struct delta_corner {
    quad_corner_t dg;
    quad_corner_t dh[2];
    uint32_t vi;

    bool operator==(const delta_corner& o) const {
      return dg == o.dg && dh[0] == o.dh[0] && dh[1] == o.dh[1] && vi == o.vi;
    }
  };

  using delta_table_t = std::vector<delta_corner>;

  explicit Quad(index_t n, std::shared_ptr<kvec_t> kvec,
                std::shared_ptr<delta_table_t> delta_table)
      : n_(n),
        vc_(n),
        delta_table_(std::move(delta_table)),
        kvec_(std::move(kvec)) {
    check(n > 0, "Quad n > 0");
  }

  // no copies
  Quad(const Quad& y) = delete;
  Quad(Quad&& y) = delete;
  Quad& operator=(const Quad& y) = delete;
  Quad& operator=(Quad&& y) = delete;

  index_t size() const { return n_; }

  void assign(index_t i, uint32_t di) { vc_[i] = di; }

  class const_iterator {
   public:
    using iterator_category = std::forward_iterator_tag;
    using value_type = ecorner;
    using difference_type = std::ptrdiff_t;
    using pointer = void;  // operator* returns by value
    using reference = ecorner;

    const_iterator(const Quad* q, index_t i)
        : q_(q), i_(i), prev_g_(0), prev_h0_(0), prev_h1_(0) {}

    ecorner operator*() const {
      const auto& d = (*q_->delta_table_)[q_->vc_[i_]];
      return ecorner{prev_g_ + d.dg,
                     {prev_h0_ + d.dh[0], prev_h1_ + d.dh[1]},
                     (*q_->kvec_)[d.vi]};
    }
    const_iterator& operator++() {
      const auto& d = (*q_->delta_table_)[q_->vc_[i_]];
      prev_g_ += d.dg;
      prev_h0_ += d.dh[0];
      prev_h1_ += d.dh[1];
      ++i_;
      return *this;
    }
    const_iterator operator++(int) {
      const_iterator tmp = *this;
      ++(*this);
      return tmp;
    }
    bool operator==(const const_iterator& other) const {
      return i_ == other.i_;
    }
    bool operator!=(const const_iterator& other) const {
      return i_ != other.i_;
    }

   private:
    const Quad* q_;
    index_t i_;
    quad_corner_t prev_g_;
    quad_corner_t prev_h0_;
    quad_corner_t prev_h1_;
  };

  const_iterator begin() const { return const_iterator(this, 0); }
  const_iterator end() const { return const_iterator(this, n_); }

  // Equivalent to expand()->bind_g(...).

  // Allocate an hquad of minimal size and
  // g-bind it in place.
  std::unique_ptr<HQuad<Field>> bind_g(size_t logv, const Elt* G0,
                                       const Elt* G1, const Elt& alpha,
                                       const Elt& beta, const Field& F) const {
    check(n_ > 0, "n_ > 0");
    index_t final_size = 1;
    auto it = begin();
    auto prev_ec = *it;
    for (++it; it != end(); ++it) {
      if (!(*it).eq_hands(prev_ec)) {
        final_size++;
      }
      prev_ec = *it;
    }

    auto s = std::make_unique<HQuad<Field>>(final_size);

    const size_t nv = size_t(1) << logv;
    auto dot = Eqs<Field>::raw_eq2(logv, nv, G0, G1, alpha, F);

    index_t wr = 0;
    for (const auto& ec : *this) {
      hcorner hc{{ec.h[0], ec.h[1]}};
      vcorner vc{prep_v(ec.v, dot[corner_t(ec.g)], beta, F)};
      if (wr > 0 && hc.eq_hands(s->hc_[wr - 1])) {
        F.add(s->vc_[wr - 1].v, vc.v);
      } else {
        s->hc_[wr] = hc;
        s->vc_[wr] = vc;
        ++wr;
      }
    }

    return s;
  }

  // Optimized combined bind_g + bind_h, nondestructive, avoiding expansion
  Elt bind_gh_all(
      // G bindings
      size_t logv, const Elt G0[/*logv*/], const Elt G1[/*logv*/],
      const Elt& alpha, const Elt& beta,
      // H bindings
      size_t logw, const Elt H0[/*logw*/], const Elt H1[/*logw*/],
      // field
      const Field& F) const {
    const size_t nv = size_t(1) << logv;
    auto eqg = Eqs<Field>::raw_eq2(logv, nv, G0, G1, alpha, F);

    const size_t nw = size_t(1) << logw;
    Eqs<Field> eqh0(logw, nw, H0, F);
    Eqs<Field> eqh1(logw, nw, H1, F);

    Accum s{};
    for (const auto& ec : *this) {
      Elt q = prep_v(ec.v, eqg[corner_t(ec.g)], beta, F);
      F.mul(q, eqh0.at(corner_t(ec.h[0])));
      F.mac(s, q, eqh1.at(corner_t(ec.h[1])));
    }
    return F.reduce(s);
  }

 private:
  static Elt prep_v(const Elt& v, const Elt& dot, const Elt& beta,
                    const Field& F) {
    if (v == F.zero()) {
      return F.mulf(beta, dot);
    } else {
      return F.mulf(v, dot);
    }
  }

  index_t n_;
  std::vector<uint32_t> vc_;
  std::shared_ptr<delta_table_t> delta_table_;
  std::shared_ptr<kvec_t> kvec_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_H_
