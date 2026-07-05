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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_ADDER_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_ADDER_H_

#include <stddef.h>

#include <cstdint>
#include <initializer_list>
#include <vector>

// Circuit element that maps bitvec<N> V to a field element E
// in such a way that:
//
// 1) addition can be performed efficiently, e.g. as field
//    addition or field multiplication
// 2) given and E that is the sum of K bitvecs, a simple circuit
//    asserts that E = A mod 2^N
namespace proofs {

template <class Logic, size_t N, bool kCharacteristicTwo>
class BitAdderAux;

// Use the additive group in fields with large characteristic
template <class Logic, size_t N>
class BitAdderAux<Logic, N, /*kCharacteristicTwo=*/false> {
 public:
  using Field = typename Logic::Field;
  using BitW = typename Logic::BitW;
  using EltW = typename Logic::EltW;
  using Elt = typename Field::Elt;
  using BV = typename Logic::template bitvec<N>;
  const Logic& l_;

  explicit BitAdderAux(const Logic& l) : l_(l) {}

  EltW as_field_element(const BV& v) const {
    constexpr uint64_t uno = 1;
    EltW r = l_.konst(l_.zero());
    for (size_t i = 0; i < N; ++i) {
      r = l_.axpy(r, l_.elt(uno << i), l_.eval(v[i]));
    }
    return r;
  }

  EltW add(const EltW& a, const EltW& b) const { return l_.add(a, b); }
  EltW add(const BV& a, const BV& b) const {
    return add(as_field_element(a), as_field_element(b));
  }
  EltW add(
      std::initializer_list<typename Logic::template bitvec_view<N>> a) const {
    return l_.add(0, a.size(), [&](size_t i) {
      return as_field_element(*(a.begin()[i].ptr));
    });
  }

  // assert that B = A + i*2^N for 0 <= i < k
  void assert_eqmod(const BV& a, const EltW& b, size_t k) const {
    constexpr uint64_t uno = 1;
    EltW z = l_.sub(b, as_field_element(a));
    EltW zz = l_.mul(
        0, k, [&](size_t i) { return l_.sub(z, l_.konst((uno << N) * i)); });
    l_.assert0(zz);
  }
};

// Use the multiplicative group in GF(2^k)
template <class Logic, size_t N>
class BitAdderAux<Logic, N, /*kCharacteristicTwo=*/true> {
 public:
  using Field = typename Logic::Field;
  using BitW = typename Logic::BitW;
  using EltW = typename Logic::EltW;
  using Elt = typename Field::Elt;
  using BV = typename Logic::template bitvec<N>;
  const Logic& l_;

  explicit BitAdderAux(const Logic& l) : l_(l) {
    // assume that X is a root of unity of order large enough.
    Elt alpha = l_.f_.x();

    for (size_t i = 0; i < N; ++i) {
      alpha_2_i_[i] = alpha;
      alpha = l_.mulf(alpha, alpha);
    }
    alpha_2_n_ = alpha;
  }

  EltW as_field_element(const BV& v) const {
    return l_.mul(0, N, [&](size_t i) {
      return l_.mux(v[i], l_.konst(alpha_2_i_[i]), l_.konst(l_.one()));
    });
  }

  EltW add(const EltW& a, const EltW& b) const { return l_.mul(a, b); }
  EltW add(const BV& a, const BV& b) const {
    return add(as_field_element(a), as_field_element(b));
  }
  EltW add(
      std::initializer_list<typename Logic::template bitvec_view<N>> a) const {
    return l_.mul(0, a.size(), [&](size_t i) {
      return as_field_element(*(a.begin()[i].ptr));
    });
  }

  // assert that B = A + alpha^(i*2^N) for 0 <= i < k
  void assert_eqmod(const BV& a, const EltW& b, size_t k) const {
    std::vector<Elt> p(k);
    p[0] = l_.f_.one();
    for (size_t i = 1; i < k; ++i) {
      p[i] = l_.f_.mulf(alpha_2_n_, p[i - 1]);
    }
    EltW aa = as_field_element(a);
    EltW prod = l_.mul(
        0, k, [&](size_t i) { return l_.sub(b, l_.mul(l_.konst(p[i]), aa)); });
    l_.assert0(prod);
  }

 private:
  Elt alpha_2_i_[N + 1];
  Elt alpha_2_n_;
};

template <class Logic, size_t N>
using BitAdder = BitAdderAux<Logic, N, Logic::Field::kCharacteristicTwo>;
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_ADDER_H_
