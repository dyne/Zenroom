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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FFT_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FFT_H_

#include <stddef.h>
#include <stdint.h>

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

 public:
  // Backward FFT.
  // N (the length of A) must be a power of 2
  static void fftb(Elt A[/*n*/], size_t n, const Elt& omega_m, uint64_t m,
                   const Field& F) {
    if (n <= 1) {
      return;
    }

    Elt omega_n = Twiddle<Field>::reroot(omega_m, m, n, F);
    Twiddle<Field> roots(n, omega_n, F);

    Permutations<Elt>::bitrev(A, n);

    // m=1 iteration
    for (size_t k = 0; k < n; k += 2) {
      butterfly(&A[k], 1, F);
    }

    // m>1 iterations
    for (size_t m = 2; m < n; m = 2 * m) {
      size_t ws = n / (2 * m);
      for (size_t k = 0; k < n; k += 2 * m) {
        butterfly(&A[k], m, F);  // j==0
        for (size_t j = 1; j < m; ++j) {
          butterflytw(&A[k + j], m, roots.w_[j * ws], F);
        }
      }
    }
  }

  // forward transform
  static void fftf(Elt A[/*n*/], size_t n, const Elt& omega_m, uint64_t m,
                   const Field& F) {
    fftb(A, n, F.invertf(omega_m), m, F);
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FFT_H_
