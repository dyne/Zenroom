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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP2_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP2_H_

#include <stddef.h>

#include <cstdint>
#include <optional>

#include "util/panic.h"

namespace proofs {
// Fields of the form a+sqrt(r)*b where a, b \in Fp and
// r is a quadratic nonresidue in Fp.  The special "complex"
// case r = -1 allows for a faster implementation of multiplication.
//
// With slight abuse of terminology, we call "a" the "real" part and
// "b" the "imaginary" part, and we call the sqrt(r) "i" even when
// r != -1.
template <class Field, bool nonresidue_is_mone = true>
class Fp2 {
 public:
  using Scalar = typename Field::Elt;
  using BaseField = Field;
  using TypeTag = typename Field::TypeTag;

  // size of the serialization into bytes
  static constexpr size_t kBytes = 2 * Field::kBytes;
  static constexpr size_t kBits = 2 * Field::kBits;
  static constexpr size_t kSubFieldBytes = Field::kBytes;
  static constexpr bool kCharacteristicTwo = false;
  const Field& f_;

  struct Elt {
    Scalar re, im;
    bool operator==(const Elt& y) const { return re == y.re && im == y.im; }
    bool operator!=(const Elt& y) const { return !operator==(y); }
  };

  explicit Fp2(const Field& F, const Scalar& nonresidue)
      : f_(F), nonresidue_(nonresidue) {
    if (nonresidue_is_mone) {
      check(nonresidue == F.mone(), "nonresidue == F.mone()");
    } else {
      check(nonresidue != F.mone(), "nonresidue != F.mone()");
    }

    i_ = Elt{f_.zero(), f_.one()};
    for (uint64_t i = 0; i < sizeof(k_) / sizeof(k_[0]); ++i) {
      k_[i] = of_scalar(i);
    }
    khalf_ = Elt{f_.half(), f_.zero()};
    kmone_ = Elt{f_.mone(), f_.zero()};
  }
  explicit Fp2(const Field& F) : Fp2(F, F.mone()) {}

  Fp2(const Fp2&) = delete;
  Fp2& operator=(const Fp2&) = delete;

  const Field& base_field() const { return f_; }

  Scalar real(const Elt& e) const { return e.re; }
  bool is_real(const Elt& e) const { return e.im == f_.zero(); }

  void add(Elt& a, const Elt& y) const {
    f_.add(a.re, y.re);
    f_.add(a.im, y.im);
  }
  void sub(Elt& a, const Elt& y) const {
    f_.sub(a.re, y.re);
    f_.sub(a.im, y.im);
  }
  void mul(Elt& a, const Elt& y) const {
    auto p0 = f_.mulf(a.re, y.re);
    auto p1 = f_.mulf(a.im, y.im);
    auto a01 = f_.addf(a.re, a.im);
    auto y01 = f_.addf(y.re, y.im);
    if (nonresidue_is_mone) {
      a.re = f_.subf(p0, p1);
    } else {
      a.re = f_.addf(p0, f_.mulf(p1, nonresidue_));
    }
    f_.mul(a01, y01);
    f_.sub(a01, p0);
    f_.sub(a01, p1);
    a.im = a01;
  }
  void mul(Elt& a, const Scalar& y) const {
    f_.mul(a.re, y);
    f_.mul(a.im, y);
  }
  void neg(Elt& x) const {
    Elt y(k_[0]);
    sub(y, x);
    x = y;
  }
  void conj(Elt& x) const { f_.neg(x.im); }
  void invert(Elt& x) const {
    Scalar denom;
    if (nonresidue_is_mone) {
      denom = f_.addf(f_.mulf(x.re, x.re), f_.mulf(x.im, x.im));
    } else {
      denom = f_.subf(f_.mulf(x.re, x.re),
                      f_.mulf(nonresidue_, f_.mulf(x.im, x.im)));
    }
    f_.invert(denom);
    conj(x);
    mul(x, denom);
  }

  // functional interface
  Elt addf(Elt a, const Elt& y) const {
    add(a, y);
    return a;
  }
  Elt subf(Elt a, const Elt& y) const {
    sub(a, y);
    return a;
  }
  Elt mulf(Elt a, const Elt& y) const {
    mul(a, y);
    return a;
  }
  Elt mulf(Elt a, const Scalar& y) const {
    mul(a, y);
    return a;
  }
  Elt negf(Elt a) const {
    neg(a);
    return a;
  }
  Elt invertf(Elt a) const {
    invert(a);
    return a;
  }
  Elt conjf(Elt a) const {
    conj(a);
    return a;
  }

  Elt of_scalar(uint64_t a) const { return of_scalar_field(a); }
  Elt of_scalar(const Scalar& e) const { return of_scalar_field(e); }

  Elt of_scalar_field(const Scalar& e) const { return Elt{e, f_.zero()}; }
  Elt of_scalar_field(uint64_t a) const {
    return Elt{f_.of_scalar(a), f_.zero()};
  }
  Elt of_scalar_field(uint64_t ar, uint64_t ai) const {
    return Elt{f_.of_scalar(ar), f_.of_scalar(ai)};
  }

  template <size_t N>
  Elt of_string(const char (&s)[N]) const {
    return Elt{f_.of_string(s), f_.zero()};
  }

  template <size_t NR, size_t NI>
  Elt of_string(const char (&sr)[NR], const char (&si)[NI]) const {
    return Elt{f_.of_string(sr), f_.of_string(si)};
  }

  std::optional<Elt> of_bytes_field(const uint8_t ab[/* kBytes */]) const {
    if (auto re = f_.of_bytes_field(ab)) {
      if (auto im = f_.of_bytes_field(ab + Field::kBytes)) {
        return Elt{re.value(), im.value()};
      }
    }
    return std::nullopt;
  }

  void to_bytes_field(uint8_t ab[/* kBytes */], const Elt& x) const {
    f_.to_bytes_field(ab, x.re);
    f_.to_bytes_field(ab + Field::kBytes, x.im);
  }

  bool in_subfield(const Elt& e) const { return is_real(e); }

  std::optional<Elt> of_bytes_subfield(
      const uint8_t ab[/* kSubFieldBytes */]) const {
    if (auto re = f_.of_bytes_subfield(ab)) {
      return of_scalar(re.value());
    }
    return std::nullopt;
  }

  void to_bytes_subfield(uint8_t ab[/* kSubFieldBytes */], const Elt& x) const {
    check(in_subfield(x), "x not in subfield");
    f_.to_bytes_subfield(ab, x.re);
  }

  const Elt& zero() const { return k_[0]; }
  const Elt& one() const { return k_[1]; }
  const Elt& two() const { return k_[2]; }
  const Elt& half() const { return khalf_; }
  const Elt& mone() const { return kmone_; }
  const Elt& i() const { return i_; }
  Elt poly_evaluation_point(size_t i) const {
    return of_scalar(f_.poly_evaluation_point(i));
  }
  Elt newton_denominator(size_t k, size_t i) const {
    return of_scalar(f_.newton_denominator(k, i));
  }

 private:
  Scalar nonresidue_;
  Elt k_[3];  // small constants
  Elt i_;     // i^2 = -1
  Elt khalf_;
  Elt kmone_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_FP2_H_
