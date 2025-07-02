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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_INTERPOLATION_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_INTERPOLATION_H_

#include <cstddef>

#include "algebra/poly.h"

namespace proofs {
// General-purpose polynomial interpolation routines,
// which operate on arbitrary points at the cost of
// computing inverses in the field.
// These static functions are grouped into a class due
// to the common template arguments.
template <size_t N, class Field>
class Interpolation {
 public:
  static const size_t kN = N;
  using Elt = typename Field::Elt;
  using PolyN = Poly<N, Field>;

  // Throughout, X are the evaluation points.

  // Lagrange basis to Newton
  static void newton_of_lagrange_inplace(PolyN &A, const PolyN &X,
                                         const Field &F) {
    // Cache one element E and its inverse.  In the common
    // case where the points X are in an arithmetic sequence,
    // this cache avoids the computation of most inverses.
    Elt e = F.one(), inve = F.one();

    for (size_t i = 1; i < N; i++) {
      for (size_t k = N; k-- > i;) {
        Elt dx = F.subf(X[k], X[k - i]);
        if (dx != e) {
          e = dx;
          inve = F.invertf(dx);
        }
        A[k] = F.mulf(F.subf(A[k], A[k - 1]), inve);
      }
    }
  }

  static PolyN newton_of_lagrange(const PolyN &L, const PolyN &X,
                                  const Field &F) {
    PolyN A = L;
    newton_of_lagrange_inplace(A, X, F);
    return A;
  }

  // evaluation in Newton basis
  static Elt eval_newton(PolyN &Newton, const PolyN &X, const Elt &x,
                         const Field &F) {
    Elt e{};

    for (size_t i = N; i-- > 0;) {
      e = F.addf(Newton[i], F.mulf(e, F.subf(x, X[i])));
    }
    return e;
  }

  // Newton basis to monomial basis (i.e., coefficients)
  static void monomial_of_newton_inplace(PolyN &A, const PolyN &X,
                                         const Field &F) {
    for (size_t i = N; i-- > 0;) {
      for (size_t k = i + 1; k < N; ++k) {
        A[k - 1] = F.subf(A[k - 1], F.mulf(A[k], X[i]));
      }
    }
  }

  static PolyN monomial_of_newton(const PolyN &Newton, const PolyN &X,
                                  const Field &F) {
    PolyN A = Newton;
    monomial_of_newton_inplace(A, X, F);
    return A;
  }

  // evaluation in the monomial basis
  static Elt eval_monomial(PolyN &M, const Elt &x, const Field &F) {
    Elt e{};

    for (size_t i = N; i-- > 0;) {
      e = F.addf(M[i], F.mulf(e, x));
    }
    return e;
  }

  static void monomial_of_lagrange_inplace(PolyN &A, const PolyN &X,
                                           const Field &F) {
    newton_of_lagrange_inplace(A, X, F);
    monomial_of_newton_inplace(A, X, F);
  }

  static PolyN monomial_of_lagrange(const PolyN &L, const PolyN &X,
                                    const Field &F) {
    PolyN A = L;
    monomial_of_lagrange_inplace(A, X, F);
    return A;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_INTERPOLATION_H_
