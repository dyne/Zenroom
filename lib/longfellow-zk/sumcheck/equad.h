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

#ifndef PRIVACY_PROOFS_ZK_LIB_SUMCHECK_EQUAD_H_
#define PRIVACY_PROOFS_ZK_LIB_SUMCHECK_EQUAD_H_

#include <stddef.h>

#include <algorithm>
#include <cstdint>
#include <vector>

#include "algebra/compare.h"
#include "util/ceildiv.h"
#include "util/panic.h"
#define DEFINE_STRONG_INT_TYPE(a, b) using a = b

// ------------------------------------------------------------
// Expanded representation of the Quad
namespace proofs {
template <class Field>
class EQuad {
  using Elt = typename Field::Elt;

 public:
  // To save space when representing large circuits, quad_corner_t
  // is defined as uint32_t.  (Note that Elt probably imposes uint64_t
  // alignment, so struct corner has holes.)
  //
  // To make the narrowing explicit, define corner_t as a
  // Google-specific strong int.  Outside of Google, replace
  // this definition with a typedef.
  DEFINE_STRONG_INT_TYPE(quad_corner_t, uint32_t);

  struct ecorner {
    quad_corner_t g;     // "gate" variable
    quad_corner_t h[2];  // two "hand" variables
    Elt v;

    // equality of indices
    bool eqndx(const ecorner& y) const {
      return (g == y.g && h[0] == y.h[0] && h[1] == y.h[1]);
    }

    bool eq_hands(const ecorner& y) const {
      return (h[0] == y.h[0] && h[1] == y.h[1]);
    }

    void canonicalize() {
      quad_corner_t h0 = h[0], h1 = h[1];
      h[0] = std::min<quad_corner_t>(h0, h1);
      h[1] = std::max<quad_corner_t>(h0, h1);
    }
  };

  using index_t = size_t;
  index_t n_;
  std::vector<ecorner> ec_;

  explicit EQuad(index_t n) : n_(n), ec_(n) { check(n > 0, "EQuad n > 0"); }

  // no copies
  EQuad(const EQuad& y) = delete;
  EQuad(EQuad&& y) = delete;
  EQuad& operator=(const EQuad& y) = delete;
  EQuad& operator=(EQuad&& y) = delete;

  void canonicalize(const Field& F) {
    for (index_t i = 0; i < n_; ++i) {
      ec_[i].canonicalize();
    }
    // Sort only the first n_ elements, as n_ may have been reduced by
    // coalescing.
    std::sort(ec_.begin(), ec_.begin() + n_,
              [&F](const ecorner& x, const ecorner& y) {
                return compare_ecorner(x, y, F);
              });
    coalesce(F);
  }

 private:
  static bool compare_ecorner(const ecorner& x, const ecorner& y,
                              const Field& F) {
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

  void coalesce(const Field& F) {
    // Coalesce duplicates.
    // The (rd,wr)=(0,0) iteration executes the else{} branch and
    // continues with (1,1), so we start at (1,1) and avoid the
    // special case for wr-1 at wr=0.
    check(n_ > 0, "n_ > 0");
    index_t wr = 1;
    for (index_t rd = 1; rd < n_; ++rd) {
      if (ec_[rd].eqndx(ec_[wr - 1])) {
        F.add(ec_[wr - 1].v, ec_[rd].v);
      } else {
        ec_[wr] = ec_[rd];
        wr++;
      }
    }
    n_ = wr;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_SUMCHECK_EQUAD_H_
