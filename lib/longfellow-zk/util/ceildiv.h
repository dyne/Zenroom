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

#ifndef PRIVACY_PROOFS_ZK_LIB_UTIL_CEILDIV_H_
#define PRIVACY_PROOFS_ZK_LIB_UTIL_CEILDIV_H_

// This package holds basic math utility functions.

#include <cstddef>
#include <cstdint>

namespace proofs {

// ceil(a/b)
template <class T>
T ceildiv(T a, T b) {
  return (a + (b - 1)) / b;
}

inline size_t lg(size_t n) {
  size_t lgk = 0, k = 1;
  while (k < n) {
    k *= 2;
    lgk += 1;
  }
  return lgk;
}

// Morton-order operations
namespace morton {
// extract even bits (pack)
inline uint64_t even(uint64_t x) {
  x &= 0x5555555555555555ull;
  x |= (x >> 1);
  x &= 0x3333333333333333ull;
  x |= (x >> 2);
  x &= 0x0F0F0F0F0F0F0F0Full;
  x |= (x >> 4);
  x &= 0x00FF00FF00FF00FFull;
  x |= (x >> 8);
  x &= 0x0000FFFF0000FFFFull;
  x |= (x >> 16);
  x &= 0x00000000FFFFFFFFull;
  return x;
}

// inverse of even (unpack)
inline uint64_t uneven(uint64_t x) {
  x &= 0x00000000FFFFFFFFull;
  x |= (x << 16);
  x &= 0x0000FFFF0000FFFFull;
  x |= (x << 8);
  x &= 0x00FF00FF00FF00FFull;
  x |= (x << 4);
  x &= 0x0F0F0F0F0F0F0F0Full;
  x |= (x << 2);
  x &= 0x3333333333333333ull;
  x |= (x << 1);
  x &= 0x5555555555555555ull;
  return x;
}

// Given two integers X and Y represented
// as (even, odd) bits (X0, X1) and
// (Y0, Y1), set (X0, X1) to the even/odd
// representation of X+Y
template <class T>
static void add(T *x0, T *x1, T y0, T y1) {
  // Given two arrays X[i] and Y[i] of bits, the goal
  // is to build an adder.  One way to build an adder
  // is to switch to the generate/propagate representation
  //   G[i] = X[i] & Y[i]
  //   P[i] = X[i] ^ Y[i]
  // where G[i] means "position i generates a carry" and P[i] means
  // "position i propagates the carry coming from position i-1".
  //
  // Generate/propagate can be extended to pairs of positions
  // via the equations
  //
  //   G = G[i+1] ^ (G[i] ^ P[i+1])
  //   P = P[i+1] & P[i].                       (1)
  //
  // (This is all well-known adder stuff that has been known since
  // at least the '50s).
  //
  // Our strategy is thus: convert the addends into G/P representation;
  // combine the [2i] and [2i+1] positions via Equation (1), and
  // use the C "+" operation to propagate the carry over one array.
  //
  // The fun part is, how do you use the C adder to propagate G.
  // The standard form of the adder is:
  //
  //   (G, P) = (X & Y, X ^ Y)
  //   G' = propagate G in any convenient way
  //   (X + Y) = RESULT = P ^ G'
  //
  // and thus we can extract the propagated G' as G' = (X + Y) ^ X ^ Y.
  //
  // The other fun part is, given G and P, how do you go back to X and
  // Y that can be fed to the C adder?  The transformation (X, Y) -> (G, P)
  // is not injective, but any inverse will work.  We choose
  //
  //   X = G
  //   Y = P ^ G

  // Convert inputs into (G, P) form.
  T g0 = *x0 & y0, g1 = *x1 & y1;
  T p0 = *x0 ^ y0, p1 = *x1 ^ y1;

  // Combine the two (G, P) inputs.
  T g = g1 ^ (g0 & p1);
  T p = p0 & p1;

  // Convert back into (X, Y) = (G, P ^ G) and compute
  // GPRIME = (X + Y) ^ X ^ Y, which simplifies to (X + Y) ^ P
  // because X = G and Y = P ^ G.
  // Here we lose the carry of the addition, making it impossible
  // to output a global carry.
  T gprime = (g + (p ^ g)) ^ p;

  // XOR the propagated carries back into P
  *x0 = gprime ^ p0;
  *x1 = g0 ^ (gprime & p0) ^ p1;
}

// a-b via ~(~a + b)
template <class T>
static void sub(T *x0, T *x1, T y0, T y1) {
  *x0 = ~*x0;
  *x1 = ~*x1;
  add(x0, x1, y0, y1);
  *x0 = ~*x0;
  *x1 = ~*x1;
}

// a < b via (a - b) < 0.  Since we don't have
// the output carry of the subtraction, we pretend that
// the result is signed.
template <class T>
static bool lt(T x0, T x1, T y0, T y1) {
  sub(&x0, &x1, y0, y1);
  return (x1 >> (8 * sizeof(T) - 1)) == 1;
}

template <class T>
static bool eq(T x0, T x1, T y0, T y1) {
  return x0 == y0 && x1 == y1;
}

}  // namespace morton
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_UTIL_CEILDIV_H_
