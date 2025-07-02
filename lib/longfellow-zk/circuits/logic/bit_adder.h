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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_ADDER_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_ADDER_H_

#include <stddef.h>

#include <cstdint>
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
    const Logic& L = l_;  // shorthand
    constexpr uint64_t uno = 1;
    EltW r = L.konst(L.zero());
    for (size_t i = 0; i < N; ++i) {
      auto vi = L.eval(v[i]);
      r = L.axpy(&r, L.elt(uno << i), vi);
    }
    return r;
  }

  EltW add(const EltW* a, const EltW& b) const { return l_.add(a, b); }
  EltW add(const BV& a, const BV& b) const {
    auto a_fe = as_field_element(a);
    auto b_fe = as_field_element(b);
    return add(&a_fe, b_fe);
  }
  EltW add(const std::vector<BV>& a) const {
    return l_.add(0, a.size(),
                  [&](size_t i) { return as_field_element(a[i]); });
  }

  // assert that B = A + i*2^N for 0 <= i < k
  void assert_eqmod(const BV& a, const EltW& b, size_t k) const {
    const Logic& L = l_;  // shorthand
    constexpr uint64_t uno = 1;
    EltW z = L.sub(&b, as_field_element(a));
    EltW zz = L.mul(0, k, [&](size_t i) {
      return L.sub(&z, L.konst((uno << N) * i));
    });
    L.assert0(zz);
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
    const Logic& L = l_;     // shorthand
    const Field& F = l_.f_;  // shorthand

    // assume that X is a root of unity of order large enough.
    Elt alpha = F.x();

    for (size_t i = 0; i < N; ++i) {
      alpha_2_i_[i] = alpha;
      alpha = L.mulf(alpha, alpha);
    }
    alpha_2_N_ = alpha;
  }

  EltW as_field_element(const BV& v) const {
    const Logic& L = l_;  // shorthand
    return L.mul(0, N, [&](size_t i) {
      auto a2i = L.konst(alpha_2_i_[i]);
      return L.mux(&v[i], &a2i, L.konst(L.one()));
    });
  }

  EltW add(const EltW* a, const EltW& b) const { return l_.mul(a, b); }
  EltW add(const BV& a, const BV& b) const {
    auto a_fe = as_field_element(a);
    auto b_fe = as_field_element(b);
    return add(&a_fe, b_fe);
  }
  EltW add(const std::vector<BV>& a) const {
    return l_.mul(0, a.size(),
                  [&](size_t i) { return as_field_element(a[i]); });
  }

  // assert that B = A + alpha^(i*2^N) for 0 <= i < k
  void assert_eqmod(const BV& a, const EltW& b, size_t k) const {
    const Logic& L = l_;     // shorthand
    const Field& F = l_.f_;  // shorthand

    std::vector<Elt> p(k);
    p[0] = F.one();
    for (size_t i = 1; i < k; ++i) {
      p[i] = F.mulf(alpha_2_N_, p[i - 1]);
    }
    EltW aa = as_field_element(a);
    EltW prod = L.mul(0, k, [&](size_t i) {
      auto pi = L.konst(p[i]);
      return L.sub(&b, L.mul(&pi, aa));
    });
    L.assert0(prod);
  }

 private:
  Elt alpha_2_i_[N + 1];
  Elt alpha_2_N_;
};

template <class Logic, size_t N>
using BitAdder = BitAdderAux<Logic, N, Logic::Field::kCharacteristicTwo>;
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_ADDER_H_
