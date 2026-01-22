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

static inline unsigned int adc(unsigned int *a, unsigned int b,
							   unsigned int c) {
	unsigned int result;
	unsigned int carry_out;
	__asm__ volatile(
		"adds %[result], %[a_val], %[b_val]\n\t"
		"adc %[carry_out], %[zero], %[zero]"
		: [result] "=&r"(result),
		  [carry_out] "=&r"(carry_out)
		: [a_val] "r"(*a),
		  [b_val] "r"(b),
		  [zero] "r"(0U)
		: "cc");
	if (c) {
		__asm__ volatile(
			"adds %[result], %[result], #1\n\t"
			"adc %[carry_out], %[carry_out], %[zero]"
			: [result] "+r"(result),
			  [carry_out] "+r"(carry_out)
			: [zero] "r"(0U)
			: "cc");
	}
	*a = result;
	return carry_out;
}
static inline unsigned long adc(unsigned long *a, unsigned long b,
								unsigned long c) {
	return adc((unsigned int *)a, (unsigned int)b, (unsigned int)c);
}
static inline unsigned long long adc(unsigned long long *a,
									 unsigned long long b,
									 unsigned long long c) {
	unsigned int *a_ptr = (unsigned int *)a;
	unsigned int *b_ptr = (unsigned int *)&b;
	unsigned int carry = (unsigned int)c;
	unsigned int lo_carry = adc(&a_ptr[0], b_ptr[0], carry);
	unsigned int hi_carry = adc(&a_ptr[1], b_ptr[1], lo_carry);
	return hi_carry;
}

static inline unsigned int sbb(unsigned int *a, unsigned int b,
							   unsigned int c) {
	unsigned int result;
	unsigned int borrow_out;
	__asm__ volatile(
		"subs %[result], %[a_val], %[b_val]\n\t"
		"sbc %[borrow_out], %[zero], %[zero]"
		: [result] "=&r"(result),
		  [borrow_out] "=&r"(borrow_out)
		: [a_val] "r"(*a),
		  [b_val] "r"(b),
		  [zero] "r"(0U)
		: "cc");
	if (c) {
		__asm__ volatile(
			"subs %[result], %[result], #1\n\t"
			"sbc %[borrow_out], %[borrow_out], %[zero]"
			: [result] "+r"(result),
			  [borrow_out] "+r"(borrow_out)
			: [zero] "r"(0U)
			: "cc");
	}
	*a = result;
	return borrow_out;
}
static inline unsigned long sbb(unsigned long *a, unsigned long b,
								unsigned long c) {
	return sbb((unsigned int *)a, (unsigned int)b, (unsigned int)c);
}
static inline unsigned long long sbb(unsigned long long *a,
									 unsigned long long b,
									 unsigned long long c) {
	unsigned int *a_ptr = (unsigned int *)a;
	unsigned int *b_ptr = (unsigned int *)&b;
	unsigned int borrow = (unsigned int)c;
	unsigned int lo_borrow = sbb(&a_ptr[0], b_ptr[0], borrow);
	unsigned int hi_borrow = sbb(&a_ptr[1], b_ptr[1], lo_borrow);
	return hi_borrow;
}
