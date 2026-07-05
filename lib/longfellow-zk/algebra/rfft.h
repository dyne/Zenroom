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

  // The machinery in this file only works if omega^{n/4} == (0, 1)
  // (== C.i()) as opposed to the conjugate (0, -1).  There is nothing
  // wrong with C.conj(C.i()), but we hardcode the positive sign
  // in all the radix-4 butterflies.
  static void validate_I(const CElt& ii, const FieldExt& C) {
    check(ii == C.i(), "wrong sign for i(), need the conjugate root");
  }

  // We hardcode w8.re == w8.im for 8th-roots of unity.
  // This always holds if p mod 8 == 7, in which case the
  // 8-th root is the usual +/- (1+i)/sqrt(2), assuming w8^2 = I
  // (as opposed to -I).
  static void validate_w8(const CElt& w8) {
    check(w8.re == w8.im, "wrong 8-th root of unity");
  }

  // ------------------------------------------------------------
  // Main algorithm starts here.
  //
  // The overall algorithm is a radix-4 Cooley-Tukey FFT.  Generally
  // speaking, Cooley-Tukey decomposes a problem of size N into R
  // subproblems of size N/R and N/R subproblems of size R, where R is
  // called the "radix".  For quadratic field extensions, R=4 is
  // better than R=2 because one can hardcode a size-4 FFT requiring
  // no multiplications, as multiplying by the fourth root of unity I
  // is free.  This is true as long as I^2 = -1, which we assume.
  //
  // The main complexity of the code is due to the fact that the input
  // is in the base field of the quadratic extension (henceforth we
  // say that the input is "real").  Under this assumption, the output
  // C is in the extension field ("complex"), but it is conjugate
  // symmetric C[n-i] = conj(C[j]), so it has only n degrees of
  // freedom and not 2n.  Note that C[0] is real and, for even n,
  // C[n/2] is also real.
  //
  // One neat way to store a conjugate-symmetric array C[] into a real
  // array A[] is to say that A[j] = real(C[j]) for 2*j<=n, and A[j] =
  // imag(C[j]) otherwise.  See H. Sorensen, D. Jones, M. Heideman,
  // and C. Burrus: "Real-valued fast Fourier transform algorithms"
  // IEEE Transactions on Acoustics, Speech, and Signal Processing,
  // Volume: 35, Issue: 6, June 1987.  This idea is closely related to
  // the storage layout in the Fast Discrete Hartley Transform.
  // Following the terminology of the GNU Scientific Library, later
  // also adopted by FFTW, we call this format the "half-complex"
  // storage.  Even though the implementation in file works only for N
  // = 2^k, the half-complex format works for all N.  For even n, a
  // half-complex array contains n/2+1 real elements and n/2-1
  // imaginary elements.  This asymmetry requires special handling of
  // the two excess real elements.
  //
  // Because the real input and the half-complex output have different
  // types, we need to distinguish the real->half-complex transform
  // from the half-complex->real transform.  We now focus on the
  // real->half-complex transform, with the understanding that the
  // half-complex->real is the same process run backwards.
  //
  // Letting n = 2^k, each radix-4 step reduces k by 2.  If k is odd,
  // we must perform a radix-2 step somewhere, one can execute the
  // radix-2 step at an arbitrary butterfly level in the algorithm.
  // We choose to place the radix-2 step in the first butterfly level,
  // which has no twiddle factors.  To this end, r2hcI_2() implements
  // a real->half-complex FFT of size 2, and r2hcI_4() implements a
  // real->half-complex FFT of size 4.
  //
  // The remaining radix-4 butterflies are implemented in hc2hcf_4(),
  // which is an ordinary decimation-in-time Cooley-Tukey butterfly
  // hardcoding the fourth root of unity I (as opposed to -I).
  // (Decimation-in-time means that the butterfly applies the twiddle
  // factors first and then it applies the transform.)
  //
  // However, because of the two excess real elements in a
  // half-complex array, hc2hcf_4() alone is not sufficient.  The
  // first butterfly of each level always has real inputs and no
  // twiddle factors, and it can therefore be covered by r2hcI_4().
  // The last bufferfly of each level also has real inputs with
  // twiddle factors w_8^j, where w_8 is an eighth root of unity.
  // This is occasionally called a type-II Fourier transform, by
  // analogy with the so-called type-II Discrete Cosine Transform.
  // r2hcII_4() hardcodes this latter case.
  //
  // For the complex FFT, both the decimation-in-time and
  // decimation-in-frequency variants are possible.  For
  // real->half-complex, it seems like decimation-in-time is the only
  // possibility.
  // ------------------------------------------------------------
  static void r2hcI_2(RElt* A, size_t s, const Field& R) {
    RElt t = A[s];
    A[s] = A[0];
    R.add(A[0], t);
    R.sub(A[s], t);
  }

  static void r2hcI_4(RElt* A, size_t s, const Field& R) {
    RElt x0 = A[0];
    RElt x1 = A[s];
    RElt z0 = R.addf(x0, x1);
    RElt x2 = A[2 * s];
    RElt x3 = A[3 * s];
    RElt z1 = R.addf(x2, x3);
    A[0] = R.addf(z0, z1);
    A[2 * s] = R.subf(z0, z1);
    A[s] = R.subf(x0, x1);
    A[3 * s] = R.subf(x3, x2);
  }

  // j = m/2 butterfly in the main loop, where w8^2 = I
  static void r2hcII_4(RElt* A, size_t s, const CElt& w8, const Field& R) {
    RElt x2 = A[2 * s];
    RElt x3 = A[3 * s];
    RElt z0 = R.addf(x2, x3);
    RElt z1 = R.subf(x2, x3);
    R.mul(z0, w8.im);
    R.mul(z1, w8.re);
    RElt x0 = A[0];
    RElt x1 = A[s];
    A[0] = R.addf(x0, z1);
    A[s] = R.subf(x0, z1);
    A[2 * s] = R.subf(x1, z0);
    A[3 * s] = R.addf(x1, z0);
    R.neg(A[3 * s]);
  }

  static void hc2hcf_4(RElt* Ar, RElt* Ai, size_t s, const CElt& tw1,
                       const CElt& tw2, const CElt& tw3, const Field& R) {
    cmulj(&Ar[s], &Ai[s], tw2.re, tw2.im, R);
    RElt y0r = R.addf(Ar[0], Ar[s]);
    RElt y0i = R.addf(Ai[0], Ai[s]);
    RElt y1r = R.subf(Ar[0], Ar[s]);
    RElt y1i = R.subf(Ai[0], Ai[s]);
    cmulj(&Ar[2 * s], &Ai[2 * s], tw1.re, tw1.im, R);
    cmulj(&Ar[3 * s], &Ai[3 * s], tw3.re, tw3.im, R);
    RElt y2r = R.addf(Ar[3 * s], Ar[2 * s]);
    RElt y3r = R.subf(Ar[3 * s], Ar[2 * s]);
    RElt y2i = R.addf(Ai[2 * s], Ai[3 * s]);
    RElt y3i = R.subf(Ai[2 * s], Ai[3 * s]);
    Ar[0] = R.addf(y0r, y2r);
    Ai[s] = R.subf(y0r, y2r);
    Ar[s] = R.addf(y1r, y3i);
    Ai[0] = R.subf(y1r, y3i);
    Ai[3 * s] = R.addf(y2i, y0i);
    Ar[2 * s] = R.subf(y2i, y0i);
    Ai[2 * s] = R.addf(y3r, y1i);
    Ar[3 * s] = R.subf(y3r, y1i);
  }

  //------------------------------------------------------------
  // Backward butterflies.
  //
  // "Backward" means sign +1 in the exponent of the twiddle
  // factors.
  //
  // hc2rI_{2,4}: half-complex->real backward transform.
  //
  // hc2rIII_4: half-complex->real backward transform with w_8^j
  // twiddle factors.  This is sometimes called a type-III FFT with
  // the understanding that the inverse of a type-II FFT is a
  // type-III.  The terminology is what it is.
  //
  // hc2hcb_4(): the main complex->complex backward butterfly.  The
  // backward algorithm is decimation-in-frequency, which means that
  // the twiddle factors are applied at the end of the butterfly.
  // ------------------------------------------------------------
  static void hc2rI_2(RElt* A, size_t s, const Field& R) {
    RElt t = A[s];
    A[s] = A[0];
    R.add(A[0], t);
    R.sub(A[s], t);
  }

  static void hc2rI_4(RElt* A, size_t s, const Field& R) {
    RElt y0 = R.addf(A[0], A[2 * s]);
    RElt y1 = R.subf(A[0], A[2 * s]);
    RElt y2 = R.addf(A[s], A[s]);
    RElt y3 = R.addf(A[3 * s], A[3 * s]);
    A[0] = R.addf(y0, y2);
    A[s] = R.subf(y0, y2);
    A[2 * s] = R.subf(y1, y3);
    A[3 * s] = R.addf(y1, y3);
  }

  static void hc2rIII_4(RElt* A, size_t s, const CElt& w8, const Field& R) {
    RElt x0 = R.addf(A[0], A[0]);
    RElt x1 = R.addf(A[s], A[s]);
    RElt x2 = R.addf(A[2 * s], A[2 * s]);
    RElt x3 = R.addf(A[3 * s], A[3 * s]);
    A[0] = R.addf(x0, x1);
    A[s] = R.subf(x2, x3);
    RElt z0 = R.subf(x0, x1);
    R.mul(z0, w8.re);
    RElt z1 = R.addf(x3, x2);
    R.mul(z1, w8.im);
    A[2 * s] = R.subf(z0, z1);
    A[3 * s] = R.addf(z0, z1);
    R.neg(A[3 * s]);
  }

  static void hc2hcb_4(RElt* Ar, RElt* Ai, size_t s, const CElt& tw1,
                       const CElt& tw2, const CElt& tw3, const Field& R) {
    RElt z0 = R.addf(Ar[0], Ai[s]);
    RElt z1 = R.subf(Ar[0], Ai[s]);
    RElt z2 = R.addf(Ar[s], Ai[0]);
    RElt z3 = R.subf(Ar[s], Ai[0]);
    RElt z4 = R.addf(Ai[3 * s], Ar[2 * s]);
    RElt z5 = R.subf(Ai[3 * s], Ar[2 * s]);
    RElt z6 = R.addf(Ai[2 * s], Ar[3 * s]);
    RElt z7 = R.subf(Ai[2 * s], Ar[3 * s]);
    Ar[0] = R.addf(z0, z2);
    Ai[0] = R.addf(z5, z7);
    Ar[s] = R.subf(z0, z2);
    Ai[s] = R.subf(z5, z7);
    cmul(&Ar[s], &Ai[s], tw2.re, tw2.im, R);
    Ar[2 * s] = R.subf(z1, z6);
    Ai[2 * s] = R.addf(z4, z3);
    cmul(&Ar[2 * s], &Ai[2 * s], tw1.re, tw1.im, R);
    Ar[3 * s] = R.addf(z1, z6);
    Ai[3 * s] = R.subf(z4, z3);
    cmul(&Ar[3 * s], &Ai[3 * s], tw3.re, tw3.im, R);
  }

 public:
  // Forward real to half-complex in-place transform.
  // N (the length of A) must be a power of 2
  static void r2hc(RElt A[/*n*/], size_t n, const CElt& omega,
                   uint64_t omega_order, const FieldExt& C) {
    const Field& R = C.base_field();
    validate_root(omega, C);

    if (n == 2) {
      r2hcI_2(A, 1, R);
    } else if (n >= 4) {
      CElt omega_n = Twiddle<FieldExt>::reroot(omega, omega_order, n, C);
      Twiddle<FieldExt> roots(n, omega_n, C);
      validate_I(roots.w_[n / 4], C);
      if (n >= 8) {
        validate_w8(roots.w_[n / 8]);
      }
      Permutations<RElt>::bitrev(A, n);

      size_t m = n;
      while (m > 4) {
        m /= 4;
      }

      if (m == 2) {
        for (size_t k = 0; k < n; k += 2) {
          r2hcI_2(&A[k], 1, R);
        }
      } else {
        // m == 4
        for (size_t k = 0; k < n; k += 4) {
          r2hcI_4(&A[k], 1, R);
        }
      }

      for (; m < n; m = 4 * m) {
        size_t ws = n / (4 * m);
        for (size_t k = 0; k < n; k += 4 * m) {
          size_t j;
          r2hcI_4(&A[k], m, R);  // j==0

          for (j = 1; j + j < m; ++j) {
            hc2hcf_4(&A[k + j], &A[k + m - j], m, roots.w_[j * ws],
                     roots.w_[2 * j * ws], roots.w_[3 * j * ws], R);
          }

          r2hcII_4(&A[k + j], m, roots.w_[j * ws], R);  // j==m/2
        }
      }
    }
  }

  // Backward half-complex to real in-place transform.
  static void hc2r(RElt A[/*n*/], size_t n, const CElt& omega,
                   uint64_t omega_order, const FieldExt& C) {
    const Field& R = C.base_field();
    validate_root(omega, C);

    if (n == 2) {
      hc2rI_2(A, 1, R);
    } else if (n >= 4) {
      CElt omega_n = Twiddle<FieldExt>::reroot(omega, omega_order, n, C);
      Twiddle<FieldExt> roots(n, omega_n, C);
      validate_I(roots.w_[n / 4], C);
      if (n >= 8) {
        validate_w8(roots.w_[n / 8]);
      }

      size_t m = n;

      while (m > 4) {
        m /= 4;
        size_t ws = n / (4 * m);
        for (size_t k = 0; k < n; k += 4 * m) {
          size_t j;
          hc2rI_4(&A[k], m, R);  // j==0

          for (j = 1; j + j < m; ++j) {
            hc2hcb_4(&A[k + j], &A[k + m - j], m, roots.w_[j * ws],
                     roots.w_[2 * j * ws], roots.w_[3 * j * ws], R);
          }

          hc2rIII_4(&A[k + j], m, roots.w_[j * ws], R);  // j==m/2
        }
      }

      if (m == 2) {
        for (size_t k = 0; k < n; k += 2) {
          hc2rI_2(&A[k], 1, R);
        }
      } else {
        // m == 4
        for (size_t k = 0; k < n; k += 4) {
          hc2rI_4(&A[k], 1, R);
        }
      }

      Permutations<RElt>::bitrev(A, n);
    }
  }

  // X *= B
  static void cmul(RElt* xr, RElt* xi, const RElt& br, const RElt& bi,
                   const Field& R) {
    // Karatsuba 3 mul + 5 add
    RElt p0 = R.mulf(*xr, br);
    RElt p1 = R.mulf(*xi, bi);
    RElt a01 = R.addf(*xr, *xi);
    RElt b01 = R.addf(br, bi);
    *xr = R.subf(p0, p1);
    R.mul(a01, b01);
    R.sub(a01, p0);
    R.sub(a01, p1);
    *xi = a01;
  }

  // *X *= conj(B)
  static void cmulj(RElt* xr, RElt* xi, const RElt& br, const RElt& bi,
                    const Field& R) {
    // Karatsuba 3 mul + 5 add
    RElt p0 = R.mulf(*xr, br);
    RElt p1 = R.mulf(*xi, bi);
    RElt a01 = R.addf(*xr, *xi);
    RElt b01 = R.subf(br, bi);
    *xr = R.addf(p0, p1);
    R.mul(a01, b01);
    R.sub(a01, p0);
    R.add(a01, p1);
    *xi = a01;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_RFFT_H_
