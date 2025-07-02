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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_RFFT_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_RFFT_H_

#include <stddef.h>
#include <stdint.h>

#include "algebra/permutations.h"
#include "algebra/twiddle.h"
#include "util/panic.h"

namespace proofs {

// Real FFT and its inverse.
//
// The FFT F[j] of a real input R[k] is complex and
// conjugate-symmetric: F[j] = conj(F[n - j]).
//
// Following the FFTW conventions, to avoid doubling the
// storage, we store F[j] as a "half-complex" array HC[j] of elements
// in the base field.
//
//   HC[j] = (2j <= n) ? real(F[j]) : imag(F[n - j])
//
// Thus we have two kinds of transforms: R2HC (real to
// half-complex) and HC2R (half-complex to real).
//
// Again following the FFTW conventions, we say that
// the R2HC transform is "forward" (minus sign in the exponent)
// and the HC2R sign is "backward" (plus sign in the exponent).
// See fft.h for a definition of forward and backward.

template <class FieldExt>
class RFFT {
  using Field = typename FieldExt::BaseField;
  using RElt = typename Field::Elt;
  using CElt = typename FieldExt::Elt;

  // The machinery in this file only works if the root is
  // on the unit circle, because we multiply by the conjugate
  // instead of by the inverse.
  static void validate_root(const CElt& omega, const FieldExt& C) {
    check(C.mulf(omega, C.conjf(omega)) == C.one(),
          "root of unity not on the unit circle");
  }

  static void r2hcI(RElt* A, size_t s, const Field& R) {
    RElt t = A[s];
    A[s] = A[0];
    R.add(A[0], t);
    R.sub(A[s], t);
  }
  static void r2hcII(RElt* A, size_t s, const CElt& tw, const Field& R) {
    R.mul(A[s], R.negf(tw.im));
  }

  static void hc2hcf(RElt* Ar, RElt* Ai, size_t s, const CElt& tw,
                     const Field& R) {
    RElt xr, xi;
    cmulj(&xr, &xi, Ar[s], Ai[s], tw.re, tw.im, R);
    RElt ar0 = Ar[0];
    RElt ai0 = Ai[0];
    Ar[0] = R.addf(ar0, xr);
    Ai[0] = R.subf(ar0, xr);
    Ar[s] = R.subf(xi, ai0);
    Ai[s] = R.addf(xi, ai0);
  }

  static void hc2rI(RElt* A, size_t s, const Field& R) {
    RElt t = A[s];
    A[s] = A[0];
    R.add(A[0], t);
    R.sub(A[s], t);
  }

  static void hc2rIII(RElt* A, size_t s, const CElt& tw, const Field& R) {
    R.add(A[0], A[0]);
    R.add(A[s], A[s]);
    R.mul(A[s], R.negf(tw.im));
  }

  static void hc2hcb(RElt* Ar, RElt* Ai, size_t s, const CElt& tw,
                     const Field& R) {
    RElt ar0 = Ar[0];
    RElt ai0 = Ai[0];
    RElt ar1 = Ar[s];
    RElt ai1 = Ai[s];
    Ar[0] = R.addf(ar0, ai0);
    Ai[0] = R.subf(ai1, ar1);
    RElt xr = R.subf(ar0, ai0);
    RElt xi = R.addf(ai1, ar1);
    cmul(&Ar[s], &Ai[s], xr, xi, tw.re, tw.im, R);
  }

 public:
  // Forward real to half-complex in-place transform.
  // N (the length of A) must be a power of 2
  static void r2hc(RElt A[/*n*/], size_t n, const CElt& omega_m, uint64_t m,
                   const FieldExt& C) {
    validate_root(omega_m, C);

    if (n <= 1) {
      return;
    }

    const Field& R = C.base_field();
    CElt omega_n = Twiddle<FieldExt>::reroot(omega_m, m, n, C);
    Twiddle<FieldExt> roots(n, omega_n, C);

    Permutations<RElt>::bitrev(A, n);

    // m=1 iteration
    for (size_t k = 0; k < n; k += 2) {
      r2hcI(&A[k], 1, R);
    }

    // m>1 iterations
    for (size_t m = 2; m < n; m = 2 * m) {
      size_t ws = n / (2 * m);
      for (size_t k = 0; k < n; k += 2 * m) {
        size_t j;
        r2hcI(&A[k], m, R);  // j==0

        for (j = 1; j + j < m; ++j) {
          hc2hcf(&A[k + j], &A[k + m - j], m, roots.w_[j * ws], R);
        }

        r2hcII(&A[k + j], m, roots.w_[j * ws], R);  // j==m/2
      }
    }
  }

  // Backward half-complex to real in-place transform.
  static void hc2r(RElt A[/*n*/], size_t n, const CElt& omega_m, uint64_t m,
                   const FieldExt& C) {
    validate_root(omega_m, C);

    if (n <= 1) {
      return;
    }

    const Field& R = C.base_field();
    CElt omega_n = Twiddle<FieldExt>::reroot(omega_m, m, n, C);
    Twiddle<FieldExt> roots(n, omega_n, C);

    // m>1 iterations
    for (size_t m = n; (m /= 2) >= 2;) {
      size_t ws = n / (2 * m);
      for (size_t k = 0; k < n; k += 2 * m) {
        size_t j;
        hc2rI(&A[k], m, R);  // j==0

        for (j = 1; j + j < m; ++j) {
          hc2hcb(&A[k + j], &A[k + m - j], m, roots.w_[j * ws], R);
        }

        hc2rIII(&A[k + j], m, roots.w_[j * ws], R);  // j==m/2
      }
    }

    // m=1 iteration
    for (size_t k = 0; k < n; k += 2) {
      hc2rI(&A[k], 1, R);
    }

    Permutations<RElt>::bitrev(A, n);
  }

  // X = A * B
  static void cmul(RElt* xr, RElt* xi, const RElt& ar, const RElt& ai,
                   const RElt& br, const RElt& bi, const Field& R) {
    // Karatsuba 3 mul + 5 add
    auto p0 = R.mulf(ar, br);
    auto p1 = R.mulf(ai, bi);
    auto a01 = R.addf(ar, ai);
    auto b01 = R.addf(br, bi);
    *xr = R.subf(p0, p1);
    R.mul(a01, b01);
    R.sub(a01, p0);
    R.sub(a01, p1);
    *xi = a01;
  }

  // X = A * conj(B)
  static void cmulj(RElt* xr, RElt* xi, const RElt& ar, const RElt& ai,
                    const RElt& br, const RElt& bi, const Field& R) {
    // Karatsuba 3 mul + 5 add
    auto p0 = R.mulf(ar, br);
    auto p1 = R.mulf(ai, bi);
    auto a01 = R.addf(ar, ai);
    auto b01 = R.subf(br, bi);
    *xr = R.addf(p0, p1);
    R.mul(a01, b01);
    R.sub(a01, p0);
    R.add(a01, p1);
    *xi = a01;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_RFFT_H_
