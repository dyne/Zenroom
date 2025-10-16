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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_H_

#include <stddef.h>

#include <array>
#include <vector>

#include "algebra/interpolation.h"
#include "algebra/poly.h"
#include "circuits/logic/bit_plucker_constants.h"
#include "circuits/logic/polynomial.h"

namespace proofs {
/*

Many circuits we design require bit inputs in {0,1} when the field F takes 128+
bits to represent. Each input to a circuit is an element in F, and must either
be sent to the verifier or committed, and thus sending several single-bit
inputs represents an overhead.

A bit-plucker is a circuit component that maps a set
S \subset F of size 2^k into k wires, b_0, ..., b_k-1, that are each in {0,1}.
Thus, it can reduce the number of inputs that a predicate circuit requires, and
thus makes the proof smaller or more efficient to compute or verify.

The optimal bit-plucker for k bits depends on k.  For small k, the simplest
bit plucker is sufficient. In some cases, bit pluckers can exploit the field
structure.

[ RUN      ] BitPlucker.PluckSize
pluck[1]: depth:  3 wires: 6 in: 2 out:2 use:4 ovh:2 t:6 cse:0 notn:9
pluck[2]: depth:  4 wires: 14 in: 2 out:4 use:9 ovh:5 t:18 cse:5 notn:19
pluck[3]: depth:  5 wires: 25 in: 2 out:6 use:17 ovh:8 t:38 cse:23 notn:40
pluck[4]: depth:  6 wires: 40 in: 2 out:8 use:29 ovh:11 t:74 cse:73 notn:87
pluck[5]: depth:  7 wires: 61 in: 2 out:10 use:47 ovh:14 t:144 cse:199 notn:194
pluck[6]: depth:  8 wires: 92 in: 2 out:12 use:75 ovh:17 t:288 cse:501 notn:437
pluck[7]: depth:  9 wires: 141 in: 2 out:14 use:121 ovh:20 t:594 cse:1203 notn:984
pluck[8]: depth: 10 wires: 224 in: 2 out:16 use:201 ovh:23 t:1254 cse:2801 notn:2203

Our experiments also considered an O(N)-wires, O(N)-terms bit plucker.
To pluck a LOGN-bit quantity E, write E = N0*E1 + E0 where E0 is a
LOGN0-bit quantity and where E1 is a LOGN1-bit quantity, and where
LOGN0 = ceil(LOGN/2), LOGN1 = floor(LOGN/2).  This decomposition
can be computed by interpolating two Polynomials of length N.  Now
we are left with plucking two quantities E0, E1, which can be done
by any subquadratic-time plucker.

A similar idea for the LOGN -> N binary decoder is in Knuth 7.1.2
Exercise 39.  (A plucker is the moral transpose of the binary
decoder.)

However, this plucker was dominated by the smaller one for our use case, and
thus removed from the code here. It can be resurrected from experimental if
needed.

[ RUN      ] BitPlucker.LargePluckSize
large_pluck[2] depth: 5 wires: 15 in: 2 out:4 use:9 ovh:6 t:19 cse:9 notn:27
large_pluck[3] depth: 7 wires: 31 in: 2 out:5 use:20 ovh:11 t:43 cse:19 notn:50
large_pluck[4] depth: 8 wires: 46 in: 2 out:8 use:33 ovh:13 t:70 cse:33 notn:89
large_pluck[5] depth: 10 wires: 79 in: 2 out:8 use:60 ovh:19 t:128 cse:68 notn:164
large_pluck[6] depth: 11 wires: 119 in: 2 out:12 use:99 ovh:20 t:209 cse:119 notn:299
large_pluck[7] depth: 13 wires: 206 in: 2 out:11 use:179 ovh:27 t:381 cse:234 notn:567
large_pluck[8] depth: 14 wires: 344 in: 2 out:16 use:317 ovh:27 t:668 cse:413 notn:1065
large_pluck[9] depth: 16 wires: 631 in: 2 out:14 use:596 ovh:35 t:1260 cse:796 notn:2064
large_pluck[10] depth: 17 wires: 1157 in: 2 out:20 use:1123 ovh:34 t:2347 cse:1435 notn:3967
large_pluck[11] depth: 19 wires: 2224 in: 2 out:17 use:2181 ovh:43 t:4551 cse:2762 notn:7789
large_pluck[12] depth: 20 wires: 4294 in: 2 out:24 use:4253 ovh:41 t:8782 cse:5113 notn:15205

*/
template <class Logic, size_t LOGN>
class BitPlucker {
 public:
  static constexpr size_t kN = 1 << LOGN;
  static constexpr size_t kNv32Elts = (32u + LOGN - 1u) / LOGN;
  static constexpr size_t kNv256Elts = (256u + LOGN - 1u) / LOGN;
  static constexpr size_t kNv128Elts = (128u + LOGN - 1u) / LOGN;
  using Field = typename Logic::Field;
  using BitW = typename Logic::BitW;
  using EltW = typename Logic::EltW;
  using Elt = typename Field::Elt;
  using PolyN = Poly<kN, Field>;
  using InterpolationN = Interpolation<kN, Field>;
  using v32 = typename Logic::v32;
  using v256 = typename Logic::v256;
  using packed_v32 = std::array<EltW, kNv32Elts>;
  using packed_v128 = std::array<EltW, kNv128Elts>;
  using packed_v256 = std::array<EltW, kNv256Elts>;

  const Logic& l_;
  std::vector<PolyN> plucker_;

  explicit BitPlucker(const Logic& l) : l_(l), plucker_(LOGN) {
    // evaluation points
    PolyN X;
    for (size_t i = 0; i < kN; ++i) {
      X[i] = bit_plucker_point<Field, kN>()(i, l_.f_);
    }
    for (size_t k = 0; k < LOGN; ++k) {
      PolyN Y;
      for (size_t i = 0; i < kN; ++i) {
        Y[i] = l_.f_.of_scalar((i >> k) & 1);
      }
      plucker_[k] = InterpolationN::monomial_of_lagrange(Y, X, l_.f_);
    }
  }

  typename Logic::template bitvec<LOGN> pluck(const EltW& e) const {
    typename Logic::template bitvec<LOGN> r;
    const Logic& L = l_;  // shorthand
    const Polynomial<Logic> P(L);

    for (size_t k = 0; k < LOGN; ++k) {
      EltW v = P.eval(plucker_[k], e);
      L.assert_is_bit(v);
      r[k] = BitW(v, l_.f_);
    }

    return r;
  }

  v32 unpack_v32(const packed_v32& v) const {
    v32 r;
    for (size_t i = 0; i < v.size(); ++i) {
      auto b = pluck(v[i]);
      for (size_t j = 0; j < LOGN; ++j) {
        if (LOGN * i + j < 32) {
          r[LOGN * i + j] = b[j];
        }
      }
    }
    return r;
  }


  template <typename T, typename PackedT>
  T unpack(const PackedT& v) const {
    T r;
    for (size_t i = 0; i < v.size(); ++i) {
      auto b = pluck(v[i]);
      for (size_t j = 0; j < LOGN; ++j) {
        if (LOGN * i + j < r.size()) {
          r[LOGN * i + j] = b[j];
        }
      }
    }
    return r;
  }
};

/*
On input Elt ind, and Elt arr[], returns arr[ind].
This muxer is useful when the same array needs to be muxed multiple times
with different indices.  It differs from the above classes in that it
precomputes the coefficient array, which can depend on EltW inputs.

The template parameter N indicates the size of the array.
The template parameter PP defines the set of points used for the interpolation.
This value defaults to N, which defines the set of points
    { -N-1, -N-3, -N-5, ..., N-3, N-1}
but in some cases, one may want to explicitly specify the set of points.
*/
template <class Logic, size_t N, size_t PP = N>
class EltMuxer {
  static constexpr size_t kN = N;
  static constexpr size_t kPP = PP;

 public:
  using Field = typename Logic::Field;
  using EltW = typename Logic::EltW;
  using PolyN = Poly<kN, Field>;
  using InterpolationN = Interpolation<kN, Field>;

  EltMuxer(const Logic& l, const EltW arr[/* kN */]) : l_(l), coeff_(kN) {
    for (size_t i = 0; i < kN; ++i) {
      coeff_[i] = l_.konst(0);
    }
    for (size_t i = 0; i < kN; ++i) {
      PolyN basis_i = even_lagrange_basis(i);
      for (size_t j = 0; j < kN; ++j) {
        auto bi = l_.konst(basis_i[j]);
        auto barr_i = l_.mul(&bi, arr[i]);
        coeff_[j] = l_.add(&coeff_[j], barr_i);
      }
    }
  }

  EltW mux(const EltW& ind) const {
    const Polynomial<Logic> P(l_);

    std::array<EltW, kN> xi;
    P.powers_of_x(kN, xi.data(), ind);

    // dot product with coefficients
    EltW r = l_.konst(0);
    for (size_t i = 0; i < kN; ++i) {
      auto cxi = l_.mul(&coeff_[i], xi[i]);
      r = l_.add(&r, cxi);
    }
    return r;
  }

 private:
  const Logic& l_;
  std::vector<EltW> coeff_;

  PolyN even_lagrange_basis(size_t k) {
    PolyN X, Y;
    for (size_t i = 0; i < kN; ++i) {
      X[i] = bit_plucker_point<Field, PP>()(i, l_.f_);
      Y[i] = l_.f_.of_scalar((i == k));
    }
    return InterpolationN::monomial_of_lagrange(Y, X, l_.f_);
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_BIT_PLUCKER_H_
