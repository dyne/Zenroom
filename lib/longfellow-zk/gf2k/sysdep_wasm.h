/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025-2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <cstdint>
#include <wasm_simd128.h>
namespace proofs {
using gf2_128_elt_t = v128_t;
// trivial identity operations to provide the same function signatures
static inline std::array<uint64_t, 2> uint64x2_of_gf2_128(gf2_128_elt_t x) {
  std::array<uint64_t, 2> result;
  wasm_v128_store(result.data(), x);
  return result;
}
static inline gf2_128_elt_t gf2_128_of_uint64x2(const std::array<uint64_t, 2>& x) {
  return wasm_v128_load(x.data());
}
static inline gf2_128_elt_t gf2_128_add(gf2_128_elt_t x, gf2_128_elt_t y) {
  return wasm_v128_xor(x, y);
}

// Carryless multiplication of two 64-bit integers
// Helper function for 64x64->128 carryless multiply
static inline void clmul64(uint64_t a, uint64_t b, uint64_t* hi, uint64_t* lo) {
  *lo = 0;
  *hi = 0;
  for (int i = 0; i < 64; ++i) {
    if ((b >> i) & 1) {
      *lo ^= a << i;
      if (i > 0) *hi ^= a >> (64 - i);
    }
  }
}

// Reduction modulo x^128 + x^7 + x^2 + x + 1
static inline v128_t reduce(uint64_t r3, uint64_t r2, uint64_t r1, uint64_t r0) {
  const uint64_t POLY = 0x87;

  // First, compute the multiplication of the high 128 bits by POLY.
  // C_H * POLY = (r3*x^64 + r2) * POLY
  // This is equivalent to (r3*POLY)*x^64 + (r2*POLY)

  uint64_t p1, p0;
  clmul64(r2, POLY, &p1, &p0); // p = r2 * POLY

  uint64_t q1, q0;
  clmul64(r3, POLY, &q1, &q0); // q = r3 * POLY

  // The full product C_H * POLY is q*x^64 + p.
  // q*x^64 = (q1*x^64 + q0)*x^64 = q1*x^128 + q0*x^64
  // modulo P(x), this is: q1*POLY + q0*x^64

  // Combine the terms: C_H*POLY = q1*POLY + (q0+p1)*x^64 + p0
  uint64_t m_hi = q0 ^ p1;
  uint64_t m_lo = p0;

  // Now, XOR this with the low 128 bits (r1, r0).
  uint64_t res_hi = r1 ^ m_hi;
  uint64_t res_lo = r0 ^ m_lo;

  // Finally, XOR the remainder from the q1*x^128 term.
  // q1 comes from clmul64(r3, POLY), where r3 is 64-bit and POLY is 8-bit.
  // The product is at most 71 bits, so q1 has at most 7 non-zero bits.
  // clmul64(q1, POLY) will produce a result less than 15 bits, so t1 will be 0.
  uint64_t t1, t0;
  clmul64(q1, POLY, &t1, &t0);

  res_hi ^= t1;
  res_lo ^= t0;

  // The result (res_hi, res_lo) is now fully reduced.
  return wasm_i64x2_make(res_lo, res_hi);
}

// GF(2^128) multiplication
static inline v128_t gf2_128_mul(v128_t a, v128_t b) {
  uint64_t a0 = wasm_i64x2_extract_lane(a, 0);
  uint64_t a1 = wasm_i64x2_extract_lane(a, 1);
  uint64_t b0 = wasm_i64x2_extract_lane(b, 0);
  uint64_t b1 = wasm_i64x2_extract_lane(b, 1);

  uint64_t z0_hi, z0_lo;
  uint64_t z1_hi, z1_lo;
  uint64_t z2_hi, z2_lo;
  uint64_t z3_hi, z3_lo;

  clmul64(a0, b0, &z0_hi, &z0_lo);
  clmul64(a0, b1, &z1_hi, &z1_lo);
  clmul64(a1, b0, &z2_hi, &z2_lo);
  clmul64(a1, b1, &z3_hi, &z3_lo);

  // Combine results
  uint64_t r0 = z0_lo;
  uint64_t r1 = z0_hi ^ z1_lo ^ z2_lo;
  uint64_t r2 = z1_hi ^ z2_hi ^ z3_lo;
  uint64_t r3 = z3_hi;

  return reduce(r3, r2, r1, r0);
}

}  // namespace proofs
