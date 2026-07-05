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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FFT_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FFT_H_

#include <stddef.h>
#include <stdint.h>

#include <algorithm>

#include "algebra/permutations.h"
#include "algebra/twiddle.h"

namespace proofs {
/*
Fast Fourier Transform (FFT).

We use FFTPACK/FFTW/MATLAB conventions where the FFT
has a negative sign in the exponent.  For root of unity
W, input ("time") T and output ("frequency") F, the
"forward" FFT computes

    F[k] = SUM_{j} T[j] W^{-jk}

and the "backward" fft computes

    T[j] = SUM_{k} F[k] W^{jk}

A forward transform followed by a backward transform
multiplies the array by N.

Matlab and engineers call the forward transform the FFT.
Mathematicians tend to call the backward transform the FFT.
*/
template <class Field>
class FFT {
  using Elt = typename Field::Elt;
  static constexpr size_t kBasecase = 16384;

  static void butterfly(Elt* A, size_t s, const Field& F) {
    Elt t = A[s];
    A[s] = A[0];
    F.add(A[0], t);
    F.sub(A[s], t);
  }

  static void butterflytw(Elt* A, size_t s, const Elt& twiddle,
                          const Field& F) {
    Elt t = A[s];
    F.mul(t, twiddle);
    A[s] = A[0];
    F.add(A[0], t);
    F.sub(A[s], t);
  }

  // Iterative backward FFT.
  // N (the length of A) must be a power of 2
  static void basecase(Elt A[/*n*/], size_t n, const Twiddle<Field>& roots,
                       const Field& F) {
    Permutations<Elt>::bitrev(A, n);

    // m=1 iteration
    for (size_t k = 0; k < n; k += 2) {
      butterfly(&A[k], 1, F);
    }

    // m>1 iterations
    for (size_t m = 2; m < n; m = 2 * m) {
      size_t ws = roots.order_ / (2 * m);
      for (size_t k = 0; k < n; k += 2 * m) {
        butterfly(&A[k], m, F);  // j==0
        for (size_t j = 1; j < m; ++j) {
          butterflytw(&A[k + j], m, roots.w_[j * ws], F);
        }
      }
    }
  }

  /* Factor N = R * S * R such that

     1) S <= FFT_BASECASE (not needed for correctness, but good for
        sanity)

     2) S <= R (needed because we transpose SxS submatrices of a SxR matrix)

  */
  static void choose_radix(size_t* r, size_t* s, size_t n) {
    // maintain the invariant N = R * S * R
    *s = n;
    *r = 1;

    while (*s > kBasecase || *s > *r) {
      *s >>= 2;
      *r <<= 1;
    }

    /* Now we have satisfied the spec of this function.  However,
       if we can choose S=1, R<=FFT_BASECASE, do so, because
       this choice leads to one call to BY_TWIDDLE() instead of two. */
    size_t s1 = *s, r1 = *r;
    while (r1 < kBasecase && s1 >= 4) {
      s1 >>= 2;
      r1 <<= 1;
    }

    if (s1 == 1) {
      *r = r1;
      *s = s1;
    }
  }

  // Recursive cache-oblivious backward FFT.
  static void recur(Elt* A, size_t n, const Elt& omega_n,
                    const Twiddle<Field>& roots, const Field& F) {
    if (n <= kBasecase) {
      basecase(A, n, roots, F);
    } else {
      size_t r, s;
      choose_radix(&r, &s, n);

      size_t m = r * s;
      Elt omega_m = Twiddle<Field>::reroot(omega_n, n, m, F);
      Elt omega_r = Twiddle<Field>::reroot(omega_m, m, r, F);

      for (size_t k = 0; k < s; ++k) {
        Permutations<Elt>::transpose(&A[k * r], m, r);
        for (size_t j = 0; j < r; ++j) {
          recur(&A[k * r + j * m], r, omega_r, roots, F);
        }
      }

      if (s > 1) {
        Elt omega_s = Twiddle<Field>::reroot(omega_r, r, s, F);
        for (size_t i = 0; i < r; ++i) {
          radix_step(&A[i * m], s, r / s, omega_m, omega_s, roots, F);
        }
      }

      radix_step(A, r, s, omega_n, omega_r, roots, F);
    }
  }

  static void radix_step(Elt* A, size_t r, size_t s, const Elt& omega_n,
                         const Elt& omega_r, const Twiddle<Field>& roots,
                         const Field& F) {
    size_t m = r * s;

    by_twiddle(A, m, r, omega_n, F);
    for (size_t k = 0; k < s; ++k) {
      Permutations<Elt>::transpose(&A[k * r], m, r);
      for (size_t j = 0; j < r; ++j) {
        recur(&A[k * r + j * m], r, omega_r, roots, F);
      }
      Permutations<Elt>::transpose(&A[k * r], m, r);
    }
  }

  static void by_twiddle(Elt* A, size_t m, size_t r, const Elt& omega_n,
                         const Field& F) {
    Elt wi1 = omega_n;
    for (size_t i = 1; i < r; ++i) {
      Elt wij = wi1;
      for (size_t j = 1; j < m; ++j) {
        F.mul(A[m * i + j], wij);
        F.mul(wij, wi1);
      }
      F.mul(wi1, omega_n);
    }
  }

 public:
  // omega_j is a j-th root of unity
  static void fftb(Elt A[/*n*/], size_t n, const Elt& omega_j, uint64_t j,
                   const Field& F) {
    if (n > 1) {
      Elt omega_n = Twiddle<Field>::reroot(omega_j, j, n, F);
      size_t b = std::min(n, kBasecase);
      Elt omega_b = Twiddle<Field>::reroot(omega_n, n, b, F);

      Twiddle<Field> roots(b, omega_b, F);
      recur(A, n, omega_n, roots, F);
    }
  }

  // forward transform
  static void fftf(Elt A[/*n*/], size_t n, const Elt& omega,
                   uint64_t omega_order, const Field& F) {
    fftb(A, n, F.invertf(omega), omega_order, F);
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FFT_H_
