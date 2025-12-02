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

#ifndef PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_H_
#define PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_H_

#include <stddef.h>

#include <algorithm>
#include <cstdint>
#include <memory>
#include <vector>

#include "algebra/compare.h"
#include "algebra/poly.h"
#include "arrays/affine.h"
#include "arrays/eqs.h"
#include "util/ceildiv.h"
#include "util/panic.h"
#define DEFINE_STRONG_INT_TYPE(a, b) using a = b

// ------------------------------------------------------------
// Special-purpose sparse array for use with sumcheck
namespace proofs {
template <class Field>
class Quad {
  using Elt = typename Field::Elt;
  using T2 = Poly<2, Field>;

 public:
  // To save space when representing large circuits, quad_corner_t
  // is defined as uint32_t.  (Note that Elt probably imposes uint64_t
  // alignment, so struct corner has holes.)
  //
  // To make the narrowing explicit, define corner_t as a
  // Google-specific strong int.  Outside of Google, replace
  // this definition with a typedef.
  DEFINE_STRONG_INT_TYPE(quad_corner_t, uint32_t);

  struct corner {
    quad_corner_t g;     // "gate" variable
    quad_corner_t h[2];  // two "hand" variables
    Elt v;

    bool operator==(const corner& y) const {
      return g == y.g &&
             morton::eq(size_t(h[0]), size_t(h[1]), size_t(y.h[0]),
                        size_t(y.h[1])) &&
             v == y.v;
    }

    bool eqndx(const corner& y) const {
      return (g == y.g && h[0] == y.h[0] && h[1] == y.h[1]);
    }

    void canonicalize() {
      quad_corner_t h0 = h[0], h1 = h[1];
      h[0] = std::min<quad_corner_t>(h0, h1);
      h[1] = std::max<quad_corner_t>(h0, h1);
    }

    static bool compare(const corner& x, const corner& y, const Field& F) {
      if (morton::lt(size_t(x.h[0]), size_t(x.h[1]), size_t(y.h[0]),
                     size_t(y.h[1]))) {
        return true;
      } else if (morton::eq(size_t(x.h[0]), size_t(x.h[1]), size_t(y.h[0]),
                            size_t(y.h[1]))) {
        if (x.g < y.g) return true;
        if (x.g > y.g) return false;
        return elt_less_than(x.v, y.v, F);
      } else {
        return false;
      }
    }
  };

  using index_t = size_t;
  index_t n_;
  std::vector<corner> c_;

  bool operator==(const Quad& y) const {
    return n_ == y.n_ &&
           std::equal(c_.begin(), c_.end(), y.c_.begin(), y.c_.end());
  }

  explicit Quad(index_t n) : n_(n), c_(n) {}

  // no copies, but see clone() below
  Quad(const Quad& y) = delete;
  Quad(const Quad&& y) = delete;
  Quad operator=(const Quad& y) = delete;

  std::unique_ptr<Quad> clone() const {
    auto s = std::make_unique<Quad>(n_);
    for (index_t i = 0; i < n_; ++i) {
      s->c_[i] = c_[i];
    }
    return s;
  }

  void bind_h(const Elt& r, size_t hand, const Field& F) {
    index_t rd = 0, wr = 0;
    while (rd < n_) {
      corner cc;
      cc.g = quad_corner_t(0);
      cc.h[hand] = c_[rd].h[hand] >> 1;
      cc.h[1 - hand] = c_[rd].h[1 - hand];

      size_t rd1 = rd + 1;
      if (rd1 < n_ &&                                         //
          c_[rd].h[1 - hand] == c_[rd1].h[1 - hand] &&        //
          (c_[rd].h[hand] >> 1) == (c_[rd1].h[hand] >> 1) &&  //
          c_[rd1].h[hand] == c_[rd].h[hand] + quad_corner_t(1)) {
        // we have two corners.
        cc.v = affine_interpolation(r, c_[rd].v, c_[rd1].v, F);
        rd += 2;
      } else {
        // we have one corner and the other one is zero.
        if ((c_[rd].h[hand] & quad_corner_t(1)) == quad_corner_t(0)) {
          cc.v = affine_interpolation_nz_z(r, c_[rd].v, F);
        } else {
          cc.v = affine_interpolation_z_nz(r, c_[rd].v, F);
        }
        rd = rd1;
      }

      c_[wr++] = cc;
    }

    // shrink the array
    n_ = wr;
  }

  // Set zero coefficients to BETA, then bind to both
  // G0 and G1 and take the linear combination bind(G0) + alpha*bind(G1)
  void bind_g(size_t logv, const Elt* G0, const Elt* G1, const Elt& alpha,
              const Elt& beta, const Field& F) {
    size_t nv = size_t(1) << logv;
    auto dot = Eqs<Field>::raw_eq2(logv, nv, G0, G1, alpha, F);
    for (index_t i = 0; i < n_; ++i) {
      if (c_[i].v == F.zero()) {
        c_[i].v = beta;
      }
      F.mul(c_[i].v, dot[corner_t(c_[i].g)]);
      c_[i].g = quad_corner_t(0);
    }

    // coalesce any duplicates that we may have created
    coalesce(F);
  }

  // Optimized combined bind_g + bind_h, nondestructive
  Elt bind_gh_all(
      // G bindings
      size_t logv, const Elt G0[/*logv*/], const Elt G1[/*logv*/],
      const Elt& alpha, const Elt& beta,
      // H bindings
      size_t logw, const Elt H0[/*logw*/], const Elt H1[/*logw*/],
      // field
      const Field& F) const {
    size_t nv = size_t(1) << logv;
    auto eqg = Eqs<Field>::raw_eq2(logv, nv, G0, G1, alpha, F);

    size_t nw = size_t(1) << logw;
    Eqs<Field> eqh0(logw, nw, H0, F);
    Eqs<Field> eqh1(logw, nw, H1, F);

    Elt s{};

    for (index_t i = 0; i < n_; ++i) {
      Elt q(c_[i].v);
      if (q == F.zero()) {
        q = beta;
      }
      F.mul(q, eqg[corner_t(c_[i].g)]);
      F.mul(q, eqh0.at(corner_t(c_[i].h[0])));
      F.mul(q, eqh1.at(corner_t(c_[i].h[1])));
      F.add(s, q);
    }
    return s;
  }

  Elt scalar() {
    check(n_ == 1, "n_ == 1");
    check(c_[0].g == quad_corner_t(0), "c_[0].g == 0");
    check(c_[0].h[0] == quad_corner_t(0), "c_[0].h[0] == 0");
    check(c_[0].h[1] == quad_corner_t(0), "c_[0].h[1] == 0");
    return c_[0].v;
  }

  void canonicalize(const Field& F) {
    for (index_t i = 0; i < n_; ++i) {
      c_[i].canonicalize();
    }
    std::sort(c_.begin(), c_.end(), [&F](const corner& x, const corner& y) {
      return corner::compare(x, y, F);
    });
    coalesce(F);
  }

 private:
  void coalesce(const Field& F) {
    // Coalesce duplicates.
    // The (rd,wr)=(0,0) iteration executes the else{} branch and
    // continues with (1,1), so we start at (1,1) and avoid the
    // special case for wr-1 at wr=0.
    index_t wr = 1;
    for (index_t rd = 1; rd < n_; ++rd) {
      if (c_[rd].eqndx(c_[wr - 1])) {
        F.add(c_[wr - 1].v, c_[rd].v);
      } else {
        c_[wr] = c_[rd];
        wr++;
      }
    }
    n_ = wr;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_H_
