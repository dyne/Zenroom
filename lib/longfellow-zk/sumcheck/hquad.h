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

#ifndef PRIVACY_PROOFS_ZK_LIB_SUMCHECK_HQUAD_H_
#define PRIVACY_PROOFS_ZK_LIB_SUMCHECK_HQUAD_H_

#include <stddef.h>

#include <vector>

#include "arrays/affine.h"
#include "sumcheck/equad.h"
#include "util/panic.h"

// ------------------------------------------------------------
// Representation of the quad after bind_g, in which case g = 0
// and we don't need to store it.
namespace proofs {
template <class Field>
class HQuad {
  using Elt = typename Field::Elt;

 public:
  using quad_corner_t = typename EQuad<Field>::quad_corner_t;
  using index_t = typename EQuad<Field>::index_t;

  // Ideally we would write
  //
  //  struct hcorner {
  //    quad_corner_t h[2];
  //    Elt v;
  //  };
  //
  // However, Elt may be 128-bit aligned, causing holes in the struct.
  // Thus we store an array of H and an array of V.

  struct hcorner {
    quad_corner_t h[2];  // two "hand" variables

    bool eq_hands(const hcorner& y) const {
      return (h[0] == y.h[0] && h[1] == y.h[1]);
    }
  };
  struct vcorner {
    Elt v;
  };

  index_t n_;
  std::vector<hcorner> hc_;
  std::vector<vcorner> vc_;

  explicit HQuad(index_t n) : n_(n), hc_(n), vc_(n) {}

  // no copies
  HQuad(const HQuad& y) = delete;
  HQuad(HQuad&& y) = delete;
  HQuad& operator=(const HQuad& y) = delete;
  HQuad& operator=(HQuad&& y) = delete;

  // We explicitly compile two specialized versions of bind_h, one for
  // each hand, to avoid the silly index computation based on hand.
  void bind_h(const Elt& r, size_t hand, const Field& F) {
    if (hand == 0) {
      bind_h<0>(r, F);
    } else {
      bind_h<1>(r, F);
    }
  }

  Elt scalar() const {
    check(n_ == 1, "n_ == 1");
    check(hc_[0].h[0] == quad_corner_t(0), "hc_[0].h[0] == 0");
    check(hc_[0].h[1] == quad_corner_t(0), "hc_[0].h[1] == 0");
    return vc_[0].v;
  }

 private:
  template <size_t hand>
  void bind_h(const Elt& r, const Field& F) {
    index_t rd = 0, wr = 0;
    while (rd < n_) {
      hcorner hcc;
      vcorner vcc;
      hcc.h[hand] = hc_[rd].h[hand] >> 1;
      hcc.h[1 - hand] = hc_[rd].h[1 - hand];

      size_t rd1 = rd + 1;
      if (rd1 < n_ &&                                           //
          hc_[rd].h[1 - hand] == hc_[rd1].h[1 - hand] &&        //
          (hc_[rd].h[hand] >> 1) == (hc_[rd1].h[hand] >> 1) &&  //
          hc_[rd1].h[hand] == hc_[rd].h[hand] + quad_corner_t(1)) {
        // we have two corners.
        vcc.v = affine_interpolation(r, vc_[rd].v, vc_[rd1].v, F);
        rd += 2;
      } else {
        // we have one corner and the other one is zero.
        if ((hc_[rd].h[hand] & quad_corner_t(1)) == quad_corner_t(0)) {
          vcc.v = affine_interpolation_nz_z(r, vc_[rd].v, F);
        } else {
          vcc.v = affine_interpolation_z_nz(r, vc_[rd].v, F);
        }
        rd = rd1;
      }

      hc_[wr] = hcc;
      vc_[wr] = vcc;
      ++wr;
    }

    // shrink the array
    n_ = wr;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_SUMCHECK_HQUAD_H_
