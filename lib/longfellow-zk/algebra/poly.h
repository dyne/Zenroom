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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_POLY_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_POLY_H_

#include <cstddef>

namespace proofs {

// This file defines templates for fixed-size N-tuples of field elements that
// can be interpreted as polynomial coefficients and/or values and/or Newton
// expansion. These polynomials handle the main operations of the sumcheck
// protocol.

// The Poly template represents a full polynomial stored as N evaluation points.
// It supports interpolation at an arbitrary point in the Field.
template <size_t N, class Field>
class Poly {
 public:
  static const size_t kN = N;
  using Elt = typename Field::Elt;
  using T = Poly;

  // the N-tuple itself
  Elt t_[N];

  Elt& operator[](size_t i) { return t_[i]; }
  const Elt& operator[](size_t i) const { return t_[i]; }

  T& add(const T& y, const Field& F) {
    for (size_t i = 0; i < N; ++i) {
      F.add(t_[i], y[i]);
    }
    return *this;
  }
  T& sub(const T& y, const Field& F) {
    for (size_t i = 0; i < N; ++i) {
      F.sub(t_[i], y[i]);
    }
    return *this;
  }
  T& mul(const T& y, const Field& F) {
    for (size_t i = 0; i < N; ++i) {
      F.mul(t_[i], y[i]);
    }
    return *this;
  }
  T& mul_scalar(const Elt& y, const Field& F) {
    for (size_t i = 0; i < N; ++i) {
      F.mul(t_[i], y);
    }
    return *this;
  }

  static T extend(const Poly<2, Field>& f, const Field& F) {
    T g;
    g[0] = f[0];
    g[1] = f[1];
    Elt df = F.subf(f[1], f[0]);

    if (Field::kCharacteristicTwo) {
      // Assume poly_evaluation_point[0] = 0, poly_evaluation_point[1] = 1,
      // and the rest are arbitrary.
      for (size_t i = 2; i < N; ++i) {
        g[i] = F.addf(g[0], F.mulf(F.poly_evaluation_point(i), df));
      }
    } else {
      // Assume that poly_evaluation_point[] form an arithmetic
      // progression.
      for (size_t i = 2; i < N; ++i) {
        g[i] = F.addf(g[i - 1], df);
      }
    }

    return g;
  }

  // convert Lagrange basis -> Newton forward differences for the
  // special case of evaluation points 0, 1, 2, ..., N-1.
  // See interpolation.h for the general case of interpolation.
  void newton_of_lagrange(const Field& F) {
    for (size_t i = 1; i < N; i++) {
      for (size_t k = N; k-- > i;) {
        F.sub(t_[k], t_[k - 1]);
        F.mul(t_[k], F.newton_denominator(k, i));
      }
    }
  }

  // Evaluate f(x) for a polynomial in the Newton forward-difference
  // basis.
  Elt eval_newton(const Elt& x, const Field& F) const {
    // Newton interpolation formula
    Elt e = t_[N - 1];
    for (size_t i = N - 1; i-- > 0;) {
      F.mul(e, F.subf(x, F.poly_evaluation_point(i)));
      F.add(e, t_[i]);
    }

    return e;
  }

  Elt eval_lagrange(const Elt& x, const Field& F) const {
    T tmp(*this);  // do not clobber *this
    tmp.newton_of_lagrange(F);
    return tmp.eval_newton(x, F);
  }

  // Evaluate f(r) given a polynomial in the standard basis
  // f(x)=t_[i]*x^i.
  Elt eval_monomial(const Elt& x, const Field& F) const {
    // Horner's algorithm
    Elt e = t_[N - 1];
    for (size_t i = N - 1; i-- > 0;) {
      F.mul(e, x);
      F.add(e, t_[i]);
    }
    return e;
  }

  // Interpolation via explicit dot product.
  //
  // The combination P.newton_of_lagrange().eval_newton(..., R, ...)
  // evaluates P at R given the Lagrange basis [P(0), P(1), ..., P(N-1)].
  //
  // On the contrary, this class computes a V(R) such that P(R) =
  // dot(V(R), [P(0), P(1), ..., P(N-1)]) and the caller computes the
  // inner product, either explicitly or via an inner-product
  // argument.  The construction is pure linear algebra: express the
  // Lagrange basis P = [P(0), P(1), ..., P(N-1)]^T as I * P where I
  // is the identity matrix, and interpolate the rows of I
  // via newton_of_lagrange().eval_newton().  Since newton_of_lagrange()
  // is O(N^2) and eval_newton() is O(N), pre-compute the eval_newton()
  // of all rows.
  class dot_interpolation {
    // identity_[k] contains the Newton basis of the polynomial P(x) such
    // that P(k) = 1 and P(i) = 0 for i != k and 0 <= i < N.
    T identity_[N];

   public:
    explicit dot_interpolation(const Field& F) {
      for (size_t k = 0; k < N; ++k) {
        for (size_t i = 0; i < N; ++i) {
          identity_[k][i] = (i == k) ? F.one() : F.zero();
        }
        identity_[k].newton_of_lagrange(F);
      }
    }

    // return V such that P(r) = V^T [P(0), P(1), ..., P(N-1)]
    T coef(const Elt& x, const Field& F) const {
      T c;
      for (size_t k = 0; k < N; ++k) {
        c[k] = identity_[k].eval_newton(x, F);
      }
      return c;
    }
  };
};

// In SumcheckPoly, the p(1) is not computed in the add, sub, mul, mul_scalar
// methods because it is implied by context. This optimization is used in the
// inner-loop of the sumcheck prover. A convenience method is provided to
// convert to a Poly object for use outside the inner-loop.
template <size_t N, class Field>
class SumcheckPoly {
 public:
  static const size_t kN = N;
  using Elt = typename Field::Elt;
  using T = SumcheckPoly;

  // the N-tuple itself
  Elt t_[N];

  SumcheckPoly() = default;

  explicit SumcheckPoly(const Poly<N, Field>& p) {
    for (size_t i = 0; i < N; ++i) {
      t_[i] = p[i];
    }
  }

  Elt& operator[](size_t i) { return t_[i]; }
  const Elt& operator[](size_t i) const { return t_[i]; }

  T& add(const T& y, const Field& F) {
    F.add(t_[0], y[0]);
    for (size_t i = 2; i < N; ++i) {
      F.add(t_[i], y[i]);
    }
    return *this;
  }
  T& sub(const T& y, const Field& F) {
    F.sub(t_[0], y[0]);
    for (size_t i = 2; i < N; ++i) {
      F.sub(t_[i], y[i]);
    }
    return *this;
  }
  T& mul(const T& y, const Field& F) {
    F.mul(t_[0], y[0]);
    for (size_t i = 2; i < N; ++i) {
      F.mul(t_[i], y[i]);
    }
    return *this;
  }
  T& mul_scalar(const Elt& y, const Field& F) {
    F.mul(t_[0], y);
    for (size_t i = 2; i < N; ++i) {
      F.mul(t_[i], y);
    }
    return *this;
  }

  // Convert to a Poly object by providing the p(1) explicitly.
  Poly<N, Field> to_poly(const Elt& p1) const {
    Poly<N, Field> p;
    for (size_t i = 0; i < N; ++i) {
      p[i] = t_[i];
    }
    p[1] = p1;
    return p;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_POLY_H_
