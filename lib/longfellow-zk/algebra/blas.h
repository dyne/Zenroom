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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_BLAS_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_BLAS_H_

// basic linear algebra subroutines
#include <stddef.h>

namespace proofs {
template <class Field>
class Blas {
 public:
  using Elt = typename Field::Elt;

  // SUM_{i} x[i * incx].y[i * incy]
  static Elt dot(size_t n, const Elt x[/*n:incx*/], size_t incx,
                 const Elt y[/*n:incy*/], size_t incy, const Field& F) {
    Elt r = F.zero();
    for (size_t i = 0; i < n; i++) {
      F.add(r, F.mulf(x[i * incx], y[i * incy]));
    }
    return r;
  }

  // SUM_{i} x[i * incx], or the dot product x^T * 1
  static Elt dot1(size_t n, const Elt x[/*n:incx*/], size_t incx,
                  const Field& F) {
    Elt r = F.zero();
    for (size_t i = 0; i < n; ++i) {
      F.add(r, x[i * incx]);
    }
    return r;
  }

  // y = a*y
  static void scale(size_t n, Elt y[/*k:incy*/], size_t incy, const Elt a,
                    const Field& F) {
    for (size_t i = 0; i < n; i++) {
      F.mul(y[i * incy], a);
    }
  }

  // y = a*x + y.
  static void axpy(size_t n, Elt y[/*k:incy*/], size_t incy, const Elt a,
                   const Elt x[/*k:incx*/], size_t incx, const Field& F) {
    for (size_t i = 0; i < n; i++) {
      F.add(y[i * incy], F.mulf(x[i * incx], a));
    }
  }

  // nonstandard axpy() where A[] is itself an array
  static void vaxpy(size_t n, Elt y[/*k:incy*/], size_t incy,
                    const Elt a[/*k:inca*/], size_t inca,
                    const Elt x[/*k:incx*/], size_t incx, const Field& F) {
    for (size_t i = 0; i < n; i++) {
      F.add(y[i * incy], F.mulf(x[i * incx], a[i * inca]));
    }
  }

  // y[i] -= a[i] * x[i]
  static void vymax(size_t n, Elt y[/*k:incy*/], size_t incy,
                    const Elt a[/*k:inca*/], size_t inca,
                    const Elt x[/*k:incx*/], size_t incx, const Field& F) {
    for (size_t i = 0; i < n; i++) {
      F.sub(y[i * incy], F.mulf(x[i * incx], a[i * inca]));
    }
  }

  static bool equal(size_t n, const Elt x[/*n:incx*/], size_t incx,
                    const Elt y[/*n:incy*/], size_t incy, const Field& F) {
    for (size_t i = 0; i < n; i++) {
      if (x[i * incx] != y[i * incy]) return false;
    }
    return true;
  }

  static bool equal0(size_t n, const Elt x[/*n:incx*/], size_t incx,
                     const Field& F) {
    for (size_t i = 0; i < n; i++) {
      if (x[i * incx] != F.zero()) return false;
    }
    return true;
  }

  static void copy(size_t n, Elt dst[/*n:incx*/], size_t incd,
                   const Elt src[/*n:incy*/], size_t incs) {
    for (size_t i = 0; i < n; i++) {
      dst[i * incd] = src[i * incs];
    }
  }

  // DST[i] = SRC[IDX[i]].  DST and SRC must not overlap.
  static void gather(size_t n, Elt dst[/*n*/], const Elt src[],
                     const size_t idx[/*n*/]) {
    for (size_t i = 0; i < n; i++) {
      dst[i] = src[idx[i]];
    }
  }

  static void clear(size_t n, Elt dst[/*n:incx*/], size_t incd,
                    const Field& F) {
    for (size_t i = 0; i < n; i++) {
      dst[i * incd] = F.zero();
    }
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_BLAS_H_
