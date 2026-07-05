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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_COUNTER_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_COUNTER_H_

#include <stddef.h>

#include <cstdint>

// Embedding of small unsigned integers into an additive group of
// unspecified size, but assumed to be able to encode 16 bits or so.
// For prime fields inject the integer mod p, and for
// binary fields use the multiplicative group.
namespace proofs {

template <class Logic, bool kCharacteristicTwo>
class CounterAux;

// Use the additive group in fields with large characteristic
template <class Logic_>
class CounterAux<Logic_, /*kCharacteristicTwo=*/false> {
 public:
  using Logic = Logic_;
  using Field = typename Logic::Field;
  using EltW = typename Logic::EltW;
  using BitW = typename Logic::BitW;
  using CElt = typename Field::CElt;

  // Even though everything is ultimately represented
  // as EltW, keeps the types distinct to avoid
  // confusion.

  struct CEltW {
    EltW e;
  };

  explicit CounterAux(const Logic& l) : l_(l) {}

  const Logic& logic() const { return l_; }

  // Convert a counter into *some* field element such that the counter is
  // nonzero (as a counter) iff the field element is nonzero.
  EltW znz_indicator(const CEltW& celt) const { return celt.e; }

  CEltW mone() const { return CEltW{l_.konst(l_.mone())}; }
  CEltW as_counter(uint64_t n) const { return CEltW{l_.konst(n)}; }
  CEltW as_counter(const CElt& x) const { return CEltW{l_.konst(x.e)}; }

  CEltW as_counter(const BitW& b) const { return CEltW{l_.eval(b)}; }

  template <size_t N>
  CEltW as_counter(const typename Logic::template bitvec<N>& v) const {
    // counters have the same representation as scalars
    return CEltW{l_.as_scalar(v)};
  }

  CEltW add(const CEltW& a, const CEltW& b) const {
    return CEltW{l_.add(a.e, b.e)};
  }

  // a ? b : 0
  CEltW ite0(const BitW& a, const CEltW& b) const {
    return CEltW{l_.mul(l_.eval(a), b.e)};
  }

  // a ? b : c
  CEltW mux(const BitW& a, const CEltW& b, const CEltW& c) const {
    return add(c, ite0(a, sub(b, c)));
  }
  void assert0(const CEltW& a) const { l_.assert0(a.e); }
  void assert_eq(const CEltW& a, const CEltW& b) const {
    l_.assert_eq(a.e, b.e);
  }

  CEltW input() const { return CEltW{l_.eltw_input()}; }

 private:
  const Logic& l_;

  // used only internally, do not export since we don't
  // want to invert in the multiplicative group
  CEltW sub(const CEltW& a, const CEltW& b) const {
    return CEltW{l_.sub(a.e, b.e)};
  }
};

// use the multiplicative group in characteristic 2
template <class Logic_>
class CounterAux<Logic_, /*kCharacteristicTwo=*/true> {
 public:
  using Logic = Logic_;
  using Field = typename Logic::Field;
  using EltW = typename Logic::EltW;
  using BitW = typename Logic::BitW;
  using CElt = typename Field::CElt;

  struct CEltW {
    EltW e;
  };

  explicit CounterAux(const Logic& l) : l_(l) {}

  const Logic& logic() const { return l_; }

  // Convert a counter into *some* field element such that the counter is
  // nonzero (as a counter) iff the field element is nonzero.
  EltW znz_indicator(const CEltW& celt) const {
    return l_.sub(celt.e, l_.konst(l_.one()));
  }

  CEltW mone() const { return CEltW{l_.konst(l_.f_.invg())}; }
  CEltW as_counter(uint64_t n) const {
    return CEltW{l_.konst(l_.f_.as_counter(n).e)};
  }
  CEltW as_counter(const CElt& x) const { return CEltW{l_.konst(x.e)}; }

  CEltW as_counter(const BitW& b) const {
    CEltW iftrue = CEltW{l_.konst(l_.f_.g())};
    return ite0(b, iftrue);
  }

  template <size_t N>
  CEltW as_counter(const typename Logic::template bitvec<N>& v) const {
    // do the multiplication in Logic since we don't have
    // a range addition in Counter
    return CEltW{l_.mul(0, N, [&](size_t i) {
      return l_.mux(v[i], l_.konst(l_.f_.counter_beta(i)), l_.konst(l_.one()));
    })};
  }

  CEltW add(const CEltW& a, const CEltW& b) const {
    return CEltW{l_.mul(a.e, b.e)};
  }

  // a ? b : 0
  CEltW ite0(const BitW& a, const CEltW& b) const {
    return CEltW{l_.mux(a, b.e, l_.konst(l_.one()))};
  }

  // a ? b : c
  CEltW mux(const BitW& a, const CEltW& b, const CEltW& c) const {
    return CEltW{l_.mux(a, b.e, c.e)};
  }
  void assert0(const CEltW& a) const { l_.assert_eq(a.e, l_.konst(l_.one())); }
  void assert_eq(const CEltW& a, const CEltW& b) const {
    l_.assert_eq(a.e, b.e);
  }

  CEltW input() const { return CEltW{l_.eltw_input()}; }

 private:
  const Logic& l_;
};

template <class Logic>
using Counter = CounterAux<Logic, Logic::Field::kCharacteristicTwo>;
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_COUNTER_H_
