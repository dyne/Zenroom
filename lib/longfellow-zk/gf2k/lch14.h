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

#ifndef PRIVACY_PROOFS_ZK_LIB_GF2K_LCH14_H_
#define PRIVACY_PROOFS_ZK_LIB_GF2K_LCH14_H_

#include <stdio.h>

#include <vector>

#include "util/panic.h"

// The algorithm from [LCH14] following [DP24, Algorithm 2]
//
// [LCH14] Sian-Jheng Lin, Wei-Ho Chung, and Yunghsiang S. Han: Novel
// Polynomial Basis and Its Application to Reed-Solomon Erasure Codes,
// https://arxiv.org/pdf/1404.3458

// [DP24] Benjamin E. Diamond and Jim Posen, Polylogarithmic Proofs
// for Multilinears over Binary Towers, https://eprint.iacr.org/2024/504

namespace proofs {

template <class Field>
class LCH14 {
  using Elt = typename Field::Elt;

  // only works in binary fields
  static_assert(Field::kCharacteristicTwo);

 public:
  static constexpr size_t kSubFieldBits = Field::kSubFieldBits;

  explicit LCH14(const Field &F) : f_(F) {
    // Compute W_i(\beta_j) for all i, j.

    // We store the unnormalized W_[i][j] = W_i(\beta_j)
    // in the same memory as the normalized \hat{W}_i(\beta_j), since
    // the unnormalized values are not needed after normalization.

    // In an attempt to improve clarity, we syntactically distinguish
    // the unnormalized array W from the normalized array w_hat_,
    // but one must be mindful that the two names alias to the
    // same memory locations.
    auto W = w_hat_;

    // Base case: W_0(X) = X
    for (size_t j = 0; j < kSubFieldBits; ++j) {
      W[0][j] = f_.beta(j);
    }

    // Inductive case: W_{i+1}(X) = W_i(X)(W_i(X)+W_i(\beta_i))
    for (size_t i = 0; i + 1 < kSubFieldBits; ++i) {
      for (size_t j = 0; j < kSubFieldBits; ++j) {
        W[i + 1][j] = f_.mulf(W[i][j], f_.addf(W[i][j], W[i][i]));
      }
    }

    // normalized \hat{W}_i(\beta j)
    for (size_t i = 0; i < kSubFieldBits; ++i) {
      Elt scale = f_.invertf(W[i][i]);
      for (size_t j = 0; j < kSubFieldBits; ++j) {
        w_hat_[i][j] = f_.mulf(scale, W[i][j]);
      }
    }
  }

  // Computation of a single twiddle factor.
  // Implicit in [LCH14, III.E], explicit in [DP24, Algorithm 2].
  Elt twiddle(size_t i, size_t u) const {
    Elt t = f_.zero();
    for (size_t k = 0; u != 0; ++k, u >>= 1) {
      if (u & 1) {
        f_.add(t, w_hat_[i][k]);
      }
    }
    return t;
  }

  // linear-time computation of all twiddles at the same time
  void twiddles(size_t i, size_t l, size_t coset, Elt tw[]) const {
    tw[0] = twiddle(i, coset);
    for (size_t k = 0; (i + 1) + k < l; ++k) {
      Elt shift = w_hat_[i][(i + 1) + k];
      for (size_t u = 0; u < (k1 << k); ++u) {
        tw[u + (k1 << k)] = f_.addf(tw[u], shift);
      }
    }
  }

  size_t ntwiddles(size_t l) const { return k1 << (l - 1); }

  // Notation from [DP24, Algorithm 2], except that we hardcode R=0
  // and add the coset parameter.
  void FFT(size_t l, size_t coset, Elt B[/* n = (1 << l) */]) const {
    check(l <= kSubFieldBits, "l <= kSubFieldBits");

    if (l > 0) {
      // space for twiddle factors
      std::vector<Elt> tw(ntwiddles(l));

      for (size_t i = l; i-- > 0;) {
        size_t s = k1 << i;
        twiddles(i, l, coset, &tw[0]);
        for (size_t u = 0; (u << (i + 1)) < (k1 << l); ++u) {
          Elt twu = tw[u];
          for (size_t v = 0; v < s; ++v) {
            butterfly_fwd(B, (u << (i + 1)) + v, s, twu);
          }
        }
      }
    }
  }

  void IFFT(size_t l, size_t coset, Elt B[/* n = (1 << l) */]) const {
    check(l <= kSubFieldBits, "l <= kSubFieldBits");

    if (l > 0) {
      // space for twiddle factors
      std::vector<Elt> tw(ntwiddles(l));

      for (size_t i = 0; i < l; ++i) {
        size_t s = k1 << i;
        twiddles(i, l, coset, &tw[0]);
        for (size_t u = 0; (u << (i + 1)) < (k1 << l); ++u) {
          Elt twu = tw[u];
          for (size_t v = 0; v < s; ++v) {
            butterfly_bwd(B, (u << (i + 1)) + v, s, twu);
          }
        }
      }
    }
  }

  void BidirectionalFFT(size_t l, size_t k, Elt B[/* n = (1 << l) */]) const {
    check(l <= kSubFieldBits, "l <= kSubFieldBits");
    bidir_recur(/*i=*/l, /*coset=*/0, k, B);
  }

  // debug access to w_hat_
  Elt WHat_DEBUG(size_t i, size_t j) const { return w_hat_[i][j]; }

 private:
  // avoid writing static_cast<size_t>(1) all the time.
  static constexpr size_t k1 = 1;

  const Field &f_;

  // precomputed [i][j] -> \hat{W}(\beta_j)
  Elt w_hat_[kSubFieldBits][kSubFieldBits];

  // The algorithm described in Joris van der Hoeven, "The Truncated
  // Fourier Transform and Applications".  This implementation is
  // based on the pseudo-code from the followup paper "Notes on the
  // Truncated Fourier Transform", also by Joris van der Hoeven.
  //
  // Van der Hoeven considers the classic multiplicative FFT;
  // here we port the algorithm to the [LCH14] adaptive FFT.

  // Here we call the algorithm the "Bidirectional FFT", because
  // the algorithm takes a set of points in the "time" domain
  // and the complementary set of points in the "frequency" domain,
  // and it flips time and frequency, so the algorithm can be
  // used to compute the forward and backward transforms, as well
  // as combinations of the two.
  //
  // The literature on the truncated Fourier transforms assumes that
  // the complementary set of points are implicitly set to zero, and
  // the main problem is how to avoid storing the zeroes.  Our main
  // problem is not time or space efficiency, but polynomial
  // interpolation.  Given k evaluations of a polynomial of degree <k,
  // compute the other evaluations up to n=2^l.  So we care about both
  // the unknown nonzero coefficients and the unknown n-k evaluations.
  void bidir_recur(size_t i, size_t coset, size_t k,
                   Elt B[/* n = (1 << i) */]) const {
    if (i-- > 0) {
      size_t s = k1 << i;
      Elt twu = twiddle(i, coset);

      if (k < s) {
        for (size_t uv = k; uv < s; ++uv) {
          butterfly_fwd(B, uv, s, twu);
        }

        bidir_recur(i, coset, k, B);

        for (size_t uv = 0; uv < k; ++uv) {
          butterfly_diag(B, uv, s, twu);
        }

        FFT(i, coset + s, B + s);
      } else /* k >= s */ {
        IFFT(i, coset, B);

        for (size_t uv = k - s; uv < s; ++uv) {
          butterfly_diag(B, uv, s, twu);
        }

        bidir_recur(i, coset + s, k - s, B + s);

        for (size_t uv = 0; uv < k - s; ++uv) {
          butterfly_bwd(B, uv, s, twu);
        }
      }
    }
  }

  inline void butterfly_fwd(Elt B[], size_t uv, size_t s,
                            const Elt &twu) const {
    f_.add(B[uv], f_.mulf(twu, B[uv + s]));
    f_.add(B[uv + s], B[uv]);
  }

  inline void butterfly_bwd(Elt B[], size_t uv, size_t s,
                            const Elt &twu) const {
    f_.sub(B[uv + s], B[uv]);
    f_.sub(B[uv], f_.mulf(twu, B[uv + s]));
  }

  // forward at [uv + s], backward at [uv]
  inline void butterfly_diag(Elt B[], size_t uv, size_t s,
                             const Elt &twu) const {
    Elt b1 = B[uv + s];
    f_.add(B[uv + s], B[uv]);
    f_.sub(B[uv], f_.mulf(twu, b1));
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_GF2K_LCH14_H_
