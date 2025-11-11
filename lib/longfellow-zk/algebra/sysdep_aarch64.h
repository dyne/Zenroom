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

static inline unsigned int adc(unsigned int *a, unsigned int b, unsigned int c) {
	unsigned int result;
	unsigned int carry_out;
	__asm__ volatile(
		"adds %w[result], %w[a_val], %w[b_val]\n\t"
		"adc %w[carry_out], %w[zero], %w[zero]"
		: [result] "=&r"(result),
		  [carry_out] "=&r"(carry_out)
		: [a_val] "r"(*a),
		  [b_val] "r"(b),
		  [zero] "r"(0U)
		: "cc");
	if (c) {
		__asm__ volatile(
			"adds %w[result], %w[result], #1\n\t"
			"adc %w[carry_out], %w[carry_out], %w[zero]"
			: [result] "+r"(result),
			  [carry_out] "+r"(carry_out)
			: [zero] "r"(0U)
			: "cc");
	}
	*a = result;
	return carry_out;
}
static inline unsigned long adc(unsigned long *a, unsigned long b, unsigned long c) {
	unsigned long result;
	unsigned long carry_out;
	__asm__ volatile(
		"adds %[result], %[a_val], %[b_val]\n\t"
		"adc %[carry_out], %[zero], %[zero]"
		: [result] "=&r"(result),
		  [carry_out] "=&r"(carry_out)
		: [a_val] "r"(*a),
		  [b_val] "r"(b),
		  [zero] "r"(0UL)
		: "cc");
	if (c) {
		__asm__ volatile(
			"adds %[result], %[result], #1\n\t"
			"adc %[carry_out], %[carry_out], %[zero]"
			: [result] "+r"(result),
			  [carry_out] "+r"(carry_out)
			: [zero] "r"(0UL)
			: "cc");
	}
	*a = result;
	return carry_out;
}
static inline unsigned long long adc(unsigned long long *a, unsigned long long b, unsigned long long c) {
	// Same as unsigned long on AArch64
	return adc((unsigned long *)a, (unsigned long)b, (unsigned long)c);
}

static inline unsigned int sbb(unsigned int *a, unsigned int b, unsigned int c) {
	unsigned int result;
	unsigned int borrow_out;
	__asm__ volatile(
		"subs %w[result], %w[a_val], %w[b_val]\n\t"
		"sbc %w[borrow_out], %w[zero], %w[zero]"
		: [result] "=&r"(result),
		  [borrow_out] "=&r"(borrow_out)
		: [a_val] "r"(*a),
		  [b_val] "r"(b),
		  [zero] "r"(0U)
		: "cc");
	if (c) {
		__asm__ volatile(
			"subs %w[result], %w[result], #1\n\t"
			"sbc %w[borrow_out], %w[borrow_out], %w[zero]"
			: [result] "+r"(result),
			  [borrow_out] "+r"(borrow_out)
			: [zero] "r"(0U)
			: "cc");
	}
	*a = result;
	return borrow_out;
}
static inline unsigned long sbb(unsigned long *a, unsigned long b, unsigned long c) {
	unsigned long result;
	unsigned long borrow_out;
	__asm__ volatile(
		"subs %[result], %[a_val], %[b_val]\n\t"
		"sbc %[borrow_out], %[zero], %[zero]"
		: [result] "=&r"(result),
		  [borrow_out] "=&r"(borrow_out)
		: [a_val] "r"(*a),
		  [b_val] "r"(b),
		  [zero] "r"(0UL)
		: "cc");
	if (c) {
		__asm__ volatile(
			"subs %[result], %[result], #1\n\t"
			"sbc %[borrow_out], %[borrow_out], %[zero]"
			: [result] "+r"(result),
			  [borrow_out] "+r"(borrow_out)
			: [zero] "r"(0UL)
			: "cc");
	}
	*a = result;
	return borrow_out;
}
static inline unsigned long long sbb(unsigned long long *a, unsigned long long b, unsigned long long c) {
	// Same as unsigned long on AArch64
	return sbb((unsigned long *)a, (unsigned long)b, (unsigned long)c);
}

static inline void mulq(uint64_t *l, uint64_t *h, uint64_t a, uint64_t b) {
	__uint128_t p = (__uint128_t)a * (__uint128_t)b;
	*l = (uint64_t)p;
	*h = (uint64_t)(p >> 64);
}
