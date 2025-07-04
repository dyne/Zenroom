/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025 Dyne.org foundation
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
  static inline gf2_128_elt_t gf2_128_mul(gf2_128_elt_t x, gf2_128_elt_t y) {
    const v128_t poly = wasm_i64x2_splat(0x87);
    // split into 32-bit halves for 32x32->64 multiplication
    v128_t x_lo = wasm_u32x4_shr(x, 0);    // x0_lo, x1_lo, x2_lo, x3_lo
    v128_t x_hi = wasm_u32x4_shr(x, 32);   // x0_hi, x1_hi, x2_hi, x3_hi
    v128_t y_lo = wasm_u32x4_shr(y, 0);    // y0_lo, y1_lo, y2_lo, y3_lo
    v128_t y_hi = wasm_u32x4_shr(y, 32);   // y0_hi, y1_hi, y2_hi, y3_hi
    // compute partial products (32x32->64)
    v128_t t0 = wasm_i64x2_mul(x_lo, y_lo);
    v128_t t1a = wasm_i64x2_mul(x_lo, y_hi);
    v128_t t1b = wasm_i64x2_mul(x_hi, y_lo);
    v128_t t2 = wasm_i64x2_mul(x_hi, y_hi);
    // combine middle terms (t1a + t1b)
    v128_t t1 = wasm_v128_xor(t1a, t1b);
    // reduction modulo x^128 + x^7 + x^2 + x + 1 (0x87)
    v128_t shifted = wasm_i64x2_shl(t1, 32);
    v128_t reduced = wasm_i64x2_shr(t1, 63);  // Mask for reduction
    reduced = wasm_v128_and(reduced, poly);
    return wasm_v128_xor(t0, wasm_v128_xor(shifted, reduced));
  }
}  // namespace proofs
