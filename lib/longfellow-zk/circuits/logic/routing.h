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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_ROUTING_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_ROUTING_H_

#include <stddef.h>

#include <algorithm>
#include <vector>

#include "util/ceildiv.h"
#include "util/panic.h"

namespace proofs {
/*
The Routing class implements circuits that shift an array by a variable number
of positions. The following table can help pick parameters for a shift:

shift_bit[2][2][1]    depth: 2 wires: 6 in: 4 out:2 use:6 ovh:0 t:5 cse:0 notn:7
unshift_bit[2][2][1]  depth: 2 wires: 6 in: 4 out:2 use:6 ovh:0 t:5 cse:0 notn:7
shift_bit[4][4][1]    depth: 3 wires: 17 in: 7 out:4 use:15 ovh:2 t:23 cse:0
notn:27 unshift_bit[4][4][1]  depth: 3 wires: 17 in: 7 out:4 use:15 ovh:2 t:23
cse:0 notn:27 shift_bit[4][4][2]    depth: 3 wires: 19 in: 7 out:4 use:15 ovh:4
t:23 cse:2 notn:20 unshift_bit[4][4][2]  depth: 3 wires: 19 in: 7 out:4 use:15
ovh:4 t:23 cse:2 notn:20 shift_bit[8][8][1]    depth: 4 wires: 41 in: 12 out:8
use:36 ovh:5 t:70 cse:0 notn:83 unshift_bit[8][8][1]  depth: 4 wires: 41 in: 12
out:8 use:36 ovh:5 t:70 cse:0 notn:83 shift_bit[8][8][2]    depth: 4 wires: 44
in: 12 out:8 use:32 ovh:12 t:64 cse:2 notn:62 unshift_bit[8][8][2]  depth: 4
wires: 44 in: 12 out:8 use:32 ovh:12 t:67 cse:2 notn:68 shift_bit[16][16][1]
depth: 5 wires: 94 in: 21 out:16 use:85 ovh:9 t:186 cse:0 notn:227
unshift_bit[16][16][1]  depth: 5 wires: 94 in: 21 out:16 use:85 ovh:9 t:186
cse:0 notn:227 shift_bit[16][16][2]    depth: 4 wires: 82 in: 21 out:16 use:61
ovh:21 t:137 cse:4 notn:147 unshift_bit[16][16][2]  depth: 4 wires: 82 in: 21
out:16 use:61 ovh:21 t:137 cse:4 notn:147 shift_bit[16][16][4]    depth: 4
wires: 94 in: 21 out:16 use:61 ovh:33 t:203 cse:58 notn:255
unshift_bit[16][16][4]  depth: 4 wires: 94 in: 21 out:16 use:61 ovh:33 t:203
cse:58 notn:255 shift_bit[32][32][1]    depth: 6 wires: 212 in: 38 out:32
use:198 ovh:14 t:463 cse:0 notn:579 unshift_bit[32][32][1]  depth: 6 wires: 212
in: 38 out:32 use:198 ovh:14 t:463 cse:0 notn:579 shift_bit[32][32][2]    depth:
5 wires: 184 in: 38 out:32 use:142 ovh:42 t:351 cse:4 notn:405
unshift_bit[32][32][2]  depth: 5 wires: 184 in: 38 out:32 use:142 ovh:42 t:366
cse:4 notn:435 shift_bit[32][32][4]    depth: 5 wires: 193 in: 38 out:32 use:118
ovh:75 t:371 cse:13 notn:427 unshift_bit[32][32][4]  depth: 5 wires: 193 in: 38
out:32 use:118 ovh:75 t:413 cse:13 notn:511 shift_bit[64][64][1]    depth: 7
wires: 475 in: 71 out:64 use:455 ovh:20 t:1109 cse:0 notn:1411
unshift_bit[64][64][1]  depth: 7 wires: 475 in: 71 out:64 use:455 ovh:20 t:1109
cse:0 notn:1411 shift_bit[64][64][2]    depth: 5 wires: 353 in: 71 out:64
use:275 ovh:78 t:747 cse:6 notn:922 unshift_bit[64][64][2]  depth: 5 wires: 353
in: 71 out:64 use:275 ovh:78 t:747 cse:6 notn:922 shift_bit[64][64][4]    depth:
5 wires: 363 in: 71 out:64 use:223 ovh:140 t:954 cse:22 notn:1319
unshift_bit[64][64][4]  depth: 5 wires: 363 in: 71 out:64 use:223 ovh:140 t:954
cse:22 notn:1319 shift_bit[128][128][1]  depth: 8 wires: 1059 in: 136 out:128
use:1032 ovh:27 t:2588 cse:0 notn:3331 unshift_bit[128][128][1]  depth: 8 wires:
1059 in: 136 out:128 use:1032 ovh:27 t:2588 cse:0 notn:3331
shift_bit[128][128][2]    depth: 6 wires: 808 in: 136 out:128 use:660 ovh:148
t:1842 cse:6 notn:2332 unshift_bit[128][128][2]  depth: 6 wires: 808 in: 136
out:128 use:660 ovh:148 t:1905 cse:6 notn:2458 shift_bit[128][128][4]    depth:
5 wires: 695 in: 136 out:128 use:428 ovh:267 t:2406 cse:69 notn:3686
unshift_bit[128][128][4]  depth: 5 wires: 695 in: 136 out:128 use:428 ovh:267
t:2826 cse:69 notn:4526 shift_bit[256][256][1]    depth: 9 wires: 2348 in: 265
out:256 use:2313 ovh:35 t:5924 cse:0 notn:7683 unshift_bit[256][256][1]  depth:
9 wires: 2348 in: 265 out:256 use:2313 ovh:35 t:5924 cse:0 notn:7683
shift_bit[256][256][2]    depth: 6 wires: 1588 in: 265 out:256 use:1305 ovh:283
t:3905 cse:8 notn:5153 unshift_bit[256][256][2]  depth: 6 wires: 1588 in: 265
out:256 use:1305 ovh:283 t:3905 cse:8 notn:5153 shift_bit[256][256][4]    depth:
5 wires: 1355 in: 265 out:256 use:825 ovh:530 t:6750 cse:116 notn:11309
unshift_bit[256][256][4]  depth: 5 wires: 1355 in: 265 out:256 use:825 ovh:530
t:6750 cse:116 notn:11309 shift_bit[256][256][8]    depth: 5 wires: 1595 in: 265
out:256 use:825 ovh:770 t:33990 cse:2756 notn:65309 unshift_bit[256][256][8]
depth: 5 wires: 1595 in: 265 out:256 use:825 ovh:770 t:33990 cse:2756 notn:65309
shift_bit[512][512][1]    depth: 10 wires: 5174 in: 522 out:512 use:5130 ovh:44
t:13357 cse:0 notn:17411 unshift_bit[512][512][1]  depth: 10 wires: 5174 in: 522
out:512 use:5130 ovh:44 t:13357 cse:0 notn:17411 shift_bit[512][512][2] depth: 7
wires: 3644 in: 522 out:512 use:3098 ovh:546 t:9289 cse:8 notn:12323
unshift_bit[512][512][2]  depth: 7 wires: 3644 in: 522 out:512 use:3098 ovh:546
t:9544 cse:8 notn:12833 shift_bit[512][512][4]    depth: 6 wires: 3148 in: 522
out:512 use:2094 ovh:1054 t:11361 cse:33 notn:17462 unshift_bit[512][512][4]
depth: 6 wires: 3148 in: 522 out:512 use:2094 ovh:1054 t:11361 cse:33 notn:17462
shift_bit[512][512][8]    depth: 6 wires: 3194 in: 522 out:512 use:1618 ovh:1576
t:18192 cse:224 notn:31029 unshift_bit[512][512][8]  depth: 6 wires: 3194 in:
522 out:512 use:1618 ovh:1576 t:21912 cse:224 notn:38469
shift_bit[1024][1024][1]  depth: 11 wires: 11329 in: 1035 out:1024 use:11275
ovh:54 t:29751 cse:0 notn:38915 unshift_bit[1024][1024][1]  depth: 11 wires:
11329 in: 1035 out:1024 use:11275 ovh:54 t:29751 cse:0 notn:38915
shift_bit[1024][1024][2]    depth: 7 wires: 7243 in: 1035 out:1024 use:6175
ovh:1068 t:19547 cse:10 notn:26664 unshift_bit[1024][1024][2]  depth: 7 wires:
7243 in: 1035 out:1024 use:6175 ovh:1068 t:19547 cse:10 notn:26664
shift_bit[1024][1024][4]    depth: 6 wires: 6232 in: 1035 out:1024 use:4155
ovh:2077 t:26989 cse:80 notn:43573 unshift_bit[1024][1024][4]  depth: 6 wires:
6232 in: 1035 out:1024 use:4155 ovh:2077 t:30769 cse:80 notn:51133
shift_bit[1024][1024][8]    depth: 6 wires: 6296 in: 1035 out:1024 use:3179
ovh:3117 t:52409 cse:332 notn:94285 unshift_bit[1024][1024][8]  depth: 6 wires:
6296 in: 1035 out:1024 use:3179 ovh:3117 t:52409 cse:332 notn:94285
*/
template <class Logic>
class Routing {
 public:
  typedef typename Logic::BitW bitW;
  typedef typename Logic::EltW EltW;
  const Logic& l_;

  explicit Routing(const Logic& l) : l_(l) {}

  // Set B[i] = A[i + amount], for 0 <= i < k.  Note that A and B
  // are in general of different size.
  template <class T>
  void shift(size_t logn, const bitW amount[/*logn*/], size_t k, T B[/*k*/],
             size_t n, const T A[/*n*/], const T& defaultA,
             size_t unroll) const {
    std::vector<T> tmp(n);
    for (size_t i = 0; i < n; ++i) {
      tmp[i] = A[i];
    }

    // Now shift TMP in-place.

    // Counting backwards from logn produces a smaller circuit if one
    // only cares about a contiguous subset of outputs.  E.g. if one
    // wants the first k outputs the number of wires is O(n log k).
    size_t l = logn;

    // This funny logic in terms of (target_nrounds, consumed)
    // attempts to equalize the number of bits consumed per round.
    // E.g., if logn = 11 and unroll = 7, a naive consumed = unroll
    // would yield 11 = 7 + 4.  Instead, we set target_nrounds = 2,
    // and consumed is 6 in the first round and 5 in the second round.
    size_t target_nrounds = ceildiv(logn, unroll);

    while (target_nrounds > 0) {
      size_t consumed = ceildiv(l, target_nrounds);
      --target_nrounds;

      l -= consumed;
      size_t shift = size_t(1) << l;
      shift_step(consumed, &amount[l], n, k, tmp.data(), shift, defaultA);
    }

    check(l == 0, "l==0");

    for (size_t i = 0; i < k; ++i) {
      if (i < n) {
        B[i] = tmp[i];
      } else {
        B[i] = defaultA;
      }
    }
  }

  // Set A[i + amount] = B[i], for 0 <= i < k.  Note that A and B
  // are in general of different size.
  template <class T>
  void unshift(size_t logn, const bitW amount[/*logn*/], size_t n, T A[/*n*/],
               size_t k, const T B[/*k*/], const T& defaultB,
               size_t unroll) const {
    // we don't need TMP since we can operate on A directly
    for (size_t i = 0; i < n; ++i) {
      if (i < k) {
        A[i] = B[i];
      } else {
        A[i] = defaultB;
      }
    }

    size_t l = 0;
    size_t target_nrounds = ceildiv(logn, unroll);
    while (target_nrounds > 0) {
      size_t consumed = ceildiv((logn - l), target_nrounds);
      --target_nrounds;

      size_t shift = size_t(1) << l;
      unshift_step(consumed, &amount[l], n, k, A, shift, defaultB);

      l += consumed;
    }
    proofs::check(l == logn, "l==logn");
  }

  template <class T, size_t LOGN>
  void shift(const typename Logic::template bitvec<LOGN>& amount, size_t k,
             T B[/*k*/], size_t n, const T A[/*n*/], const T& defaultA,
             size_t unroll) const {
    shift(LOGN, &amount[0], k, B, n, A, defaultA, unroll);
  }

  template <class T, size_t LOGN>
  void unshift(const typename Logic::template bitvec<LOGN>& amount, size_t n,
               T A[/*n*/], size_t k, const T B[/*k*/], const T& defaultB,
               size_t unroll) const {
    unshift(LOGN, &amount[0], n, A, k, B, defaultB, unroll);
  }

 private:
  template <class T>
  void shift_step(size_t logc, const bitW amount[/*logc*/], size_t n, size_t k,
                  T tmp[/*n*/], size_t shift, const T& defaultA) const {
    const Logic& L = l_;  // shorthand
    size_t c = size_t(1) << logc;

    // cache the common subexpression amount_is[i]
    std::vector<bitW> amount_is(c);
    std::vector<bitW> ibits(logc);
    for (size_t i = 0; i < c; ++i) {
      L.bits(logc, ibits.data(), i);
      amount_is[i] = L.eq(logc, ibits.data(), amount);
    }

    really_shift(c, amount_is.data(), n, k, tmp, shift, defaultA);
  }

  template <class T>
  void unshift_step(size_t logc, const bitW amount[/*logc*/], size_t n,
                    size_t k, T A[/*n*/], size_t shift,
                    const T& defaultB) const {
    const Logic& L = l_;  // shorthand
    size_t c = size_t(1) << logc;

    // cache the common subexpression amount_is[i]
    std::vector<bitW> amount_is(c);
    std::vector<bitW> ibits(logc);
    for (size_t i = 0; i < c; ++i) {
      L.bits(logc, ibits.data(), i);
      amount_is[i] = L.eq(logc, ibits.data(), amount);
    }

    really_unshift(c, amount_is.data(), n, k, A, shift, defaultB);
  }

  void really_shift(size_t c, const bitW amount_is[/*c*/], size_t n, size_t k,
                    EltW tmp[/*n*/], size_t shift, const EltW& defaultA) const {
    const Logic& L = l_;  // shorthand
    for (size_t i = 0; i < n && i < k + shift; ++i) {
      auto f = [&](size_t j) {
        if (i + j * shift < n) {
          return L.lmul(&amount_is[j], tmp[i + j * shift]);
        } else {
          return L.lmul(&amount_is[j], defaultA);
        }
      };

      tmp[i] = L.add(0, c, f);
    }
  }

  void really_unshift(size_t c, const bitW amount_is[/*c*/], size_t n, size_t k,
                      EltW A[/*n*/], size_t shift, const EltW& defaultB) const {
    const Logic& L = l_;  // shorthand
    for (size_t i = std::min(n, k + c * shift); i-- > 0;) {
      auto f = [&](size_t j) {
        if (i >= j * shift) {
          return L.lmul(&amount_is[j], A[i - j * shift]);
        } else {
          return L.lmul(&amount_is[j], defaultB);
        }
      };

      A[i] = L.add(0, c, f);
    }
  }

  void really_shift(size_t c, const bitW amount_is[/*c*/], size_t n, size_t k,
                    bitW tmp[/*n*/], size_t shift, const bitW& defaultA) const {
    const Logic& L = l_;  // shorthand
    for (size_t i = 0; i < n && i < k + shift; ++i) {
      bitW r = L.bit(0);
      for (size_t j = 0; j < c; ++j) {
        if (i + j * shift < n) {
          r = L.lor_exclusive(&r, L.land(&amount_is[j], tmp[i + j * shift]));
        } else {
          r = L.lor_exclusive(&r, L.land(&amount_is[j], defaultA));
        }
      }
      tmp[i] = r;
    }
  }

  void really_unshift(size_t c, const bitW amount_is[/*c*/], size_t n, size_t k,
                      bitW A[/*n*/], size_t shift, const bitW& defaultB) const {
    const Logic& L = l_;  // shorthand
    for (size_t i = std::min(n, k + c * shift); i-- > 0;) {
      bitW r = L.bit(0);
      for (size_t j = 0; j < c; ++j) {
        if (i >= j * shift) {
          r = L.lor_exclusive(&r, L.land(&amount_is[j], A[i - j * shift]));
        } else {
          r = L.lor_exclusive(&r, L.land(&amount_is[j], defaultB));
        }
      }
      A[i] = r;
    }
  }

  template <size_t W>
  void really_shift(size_t c, const bitW amount_is[/*c*/], size_t n, size_t k,
                    typename Logic::template bitvec<W> tmp[/*n*/], size_t shift,
                    const typename Logic::template bitvec<W>& defaultA) const {
    const Logic& L = l_;  // shorthand
    for (size_t i = 0; i < n && i < k + shift; ++i) {
      for (size_t w = 0; w < W; ++w) {
        bitW r = L.bit(0);
        for (size_t j = 0; j < c; ++j) {
          if (i + j * shift < n) {
            r = L.lor_exclusive(&r,
                                L.land(&amount_is[j], tmp[i + j * shift][w]));
          } else {
            r = L.lor_exclusive(&r, L.land(&amount_is[j], defaultA[w]));
          }
        }
        tmp[i][w] = r;
      }
    }
  }

  template <size_t W>
  void really_unshift(
      size_t c, const bitW amount_is[/*c*/], size_t n, size_t k,
      typename Logic::template bitvec<W> A[/*n*/], size_t shift,
      const typename Logic::template bitvec<W>& defaultB) const {
    const Logic& L = l_;  // shorthand
    for (size_t i = std::min(n, k + c * shift); i-- > 0;) {
      for (size_t w = 0; w < W; ++w) {
        bitW r = L.bit(0);
        for (size_t j = 0; j < c; ++j) {
          if (i >= j * shift) {
            r = L.lor_exclusive(&r, L.land(&amount_is[j], A[i - j * shift][w]));
          } else {
            r = L.lor_exclusive(&r, L.land(&amount_is[j], defaultB[w]));
          }
        }
        A[i][w] = r;
      }
    }
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_LOGIC_ROUTING_H_
