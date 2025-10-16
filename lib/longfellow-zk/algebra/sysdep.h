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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_SYSDEP_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_SYSDEP_H_

#include <stddef.h>

#include <cstdint>

#include "util/panic.h"  // IWYU pragma: keep

#if defined(__x86_64__) || defined(__i386__)
// system-dependent basic arithmetic functions: add with carry
// and 64x64->128 bit multiplication
#include <x86intrin.h>  // IWYU pragma: keep
#endif

namespace proofs {

#if defined(__x86_64__)
static inline uint64_t adc(uint64_t* a, uint64_t b, uint64_t c) {
  // unsigned long long (not uint64_t) is *required* by the
  // _addcarry_u64() prototype.  uint64_t is unsigned long on
  // linux, and pointers to the two types are incompatible even
  // though the conversion is a no-op.
  unsigned long long out;
  c = _addcarry_u64(c, *a, b, &out);
  *a = out;
  return c;
}
static inline uint32_t adc(uint32_t* a, uint32_t b, uint32_t c) {
  return _addcarry_u32(c, *a, b, a);
}
static inline uint64_t sbb(uint64_t* a, uint64_t b, uint64_t c) {
  unsigned long long out;
  c = _subborrow_u64(c, *a, b, &out);
  *a = out;
  return c;
}
static inline uint32_t sbb(uint32_t* a, uint32_t b, uint32_t c) {
  return _subborrow_u32(c, *a, b, a);
}
static inline void mulq(uint64_t* l, uint64_t* h, uint64_t a, uint64_t b) {
  asm("mulx %2, %0, %1" : "=r"(*l), "=r"(*h) : "r"(b), "d"(a));
}
#elif defined(__i386__)
static inline uint32_t adc(uint32_t* a, uint32_t b, uint32_t c) {
  return _addcarry_u32(c, *a, b, a);
}
static inline uint32_t sbb(uint32_t* a, uint32_t b, uint32_t c) {
  return _subborrow_u32(c, *a, b, a);
}

// these two functions are supposed to be defined but are
// never called
static inline unsigned long long adc(unsigned long long* a,
                                     unsigned long long b,
                                     unsigned long long c) {
  check(false, "adcll() not defined");
  return 0;
}
static inline unsigned long long sbb(unsigned long long* a,
                                     unsigned long long b,
                                     unsigned long long c) {
  check(false, "sbbll() not defined");
  return 0;
}

#define SYSDEP_MULQ64_NOT_DEFINED
#elif defined(__clang__)
// The clang intrinsics use the builtin-types int, long, etc.
// Thus we define adc() and sbb() in terms of those types.
static inline unsigned long long adc(unsigned long long* a,
                                     unsigned long long b,
                                     unsigned long long c) {
  *a = __builtin_addcll(*a, b, c, &c);
  return c;
}
static inline unsigned long adc(unsigned long* a, unsigned long b,
                                unsigned long c) {
  *a = __builtin_addcl(*a, b, c, &c);
  return c;
}
static inline unsigned int adc(unsigned int* a, unsigned int b,
                               unsigned int c) {
  *a = __builtin_addc(*a, b, c, &c);
  return c;
}

static inline unsigned long long sbb(unsigned long long* a,
                                     unsigned long long b,
                                     unsigned long long c) {
  *a = __builtin_subcll(*a, b, c, &c);
  return c;
}
static inline unsigned long sbb(unsigned long* a, unsigned long b,
                                unsigned long c) {
  *a = __builtin_subcl(*a, b, c, &c);
  return c;
}
static inline unsigned int sbb(unsigned int* a, unsigned int b,
                               unsigned int c) {
  *a = __builtin_subc(*a, b, c, &c);
  return c;
}

#if defined(__SIZEOF_INT128__)
// It seems that __SIZEOF_INT128__ is defined if __uint128_t is.
static inline void mulq(uint64_t* l, uint64_t* h, uint64_t a, uint64_t b) {
  __uint128_t p = (__uint128_t)b * (__uint128_t)a;
  *l = p;
  *h = p >> 64;
}
#else  // defined(__SIZEOF_INT128__)
#define SYSDEP_MULQ64_NOT_DEFINED
#endif  // defined(__SIZEOF_INT128__)
#endif

static inline void mulq(uint32_t* l, uint32_t* h, uint32_t a, uint32_t b) {
  uint64_t p = (uint64_t)b * (uint64_t)a;
  *l = p;
  *h = p >> 32;
}

// Identity function whose only purpose is to confuse the compiler.
// We have no coherent theory of when and why this is useful, but
// here are a couple of cases where this hack makes a difference:
//
// * Passing the cmov() values through identity_limb() seems
//   to favor the generation of a conditional move instruction
//   as opposed to a conditional branch.
// * Clang and gcc match a+b+carry to generate the adcq instruction,
//   but a+0+carry becomes a+carry and the match fails.  So
//   we pretend that the zero is not a zero.
// * A similar issue arises in subtract with carry.
//
// This function is obviously a hack.  Works for me today but YMMV.
//
template <class limb_t>
static inline limb_t identity_limb(limb_t v) {
  asm("" : "+r"(v)::);
  return v;
}

template <class limb_t>
static inline limb_t zero_limb() {
  return identity_limb<limb_t>(0);
}

// a += b
template <class limb_t>
static inline void accum(size_t Wa, limb_t a[/*Wa*/], size_t Wb,
                         const limb_t b[/*Wb*/]) {
  limb_t c = 0;
  for (size_t i = 0; i < Wb; ++i) {
    c = adc(&a[i], b[i], c);
  }
  for (size_t i = Wb; i < Wa; ++i) {
    c = adc(&a[i], 0, c);
  }
}

// a -= b
template <class limb_t>
static inline void negaccum(size_t Wa, limb_t a[/*Wa*/], size_t Wb,
                            const limb_t b[/*Wb*/]) {
  limb_t c = 0;
  for (size_t i = 0; i < Wb; ++i) {
    c = sbb(&a[i], b[i], c);
  }
  for (size_t i = Wb; i < Wa; ++i) {
    c = sbb(&a[i], 0, c);
  }
}

// h::a += b
template <class limb_t>
static inline limb_t add_limb(size_t W, limb_t a[/*W*/],
                              const limb_t b[/*W*/]) {
  limb_t c = 0;
  for (size_t i = 0; i < W; ++i) {
    c = adc(&a[i], b[i], c);
  }
  limb_t h = zero_limb<limb_t>();
  c = adc(&h, 0, c);
  return h;
}

// h::a += b * 2^(bits per limb)
template <class limb_t>
static inline limb_t addh(size_t W, limb_t a[/*W*/], const limb_t b[/*W*/]) {
  limb_t c = 0;
  for (size_t i = 1; i < W; ++i) {
    c = adc(&a[i], b[i - 1], c);
  }
  limb_t h = zero_limb<limb_t>();
  c = adc(&h, b[W - 1], c);
  return h;
}

// h::a -= b
template <class limb_t>
static inline limb_t sub_limb(size_t W, limb_t a[/*W*/],
                              const limb_t b[/*W*/]) {
  limb_t c = 0;
  for (size_t i = 0; i < W; ++i) {
    c = sbb(&a[i], b[i], c);
  }
  limb_t h = zero_limb<limb_t>();
  c = sbb(&h, 0, c);
  return h;
}

// h:l = a*b
template <class limb_t>
static inline void mulhl(size_t W, limb_t l[/*W*/], limb_t h[/*W*/], limb_t a,
                         const limb_t b[/*W*/]) {
  for (size_t i = 0; i < W; ++i) {
    mulq(&l[i], &h[i], a, b[i]);
  }
}

// a = b
template <class limb_t>
static inline void mov(size_t W, limb_t a[/*W*/], const limb_t b[/*W*/]) {
  for (size_t i = 0; i < W; ++i) {
    a[i] = b[i];
  }
}

// It seems that using assembly code is the only way to
// force gcc and clang to use conditional moves.
#if defined(__x86_64__)
static inline void cmovnz(size_t W, uint64_t a[/*W*/], uint64_t nz,
                          const uint64_t b[/*W*/]) {
  if (W == 1) {
    asm("testq %[nz], %[nz]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        : [a0] "+r"(a[0])
        : [nz] "r"(nz), [b0] "r"(b[0]));
  } else if (W == 2) {
    asm("testq %[nz], %[nz]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        "cmovneq %[b1], %[a1]\n\t"
        : [a0] "+r"(a[0]), [a1] "+r"(a[1])
        : [nz] "r"(nz), [b0] "r"(b[0]), [b1] "r"(b[1]));
  } else if (W == 3) {
    asm("testq %[nz], %[nz]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        "cmovneq %[b1], %[a1]\n\t"
        "cmovneq %[b2], %[a2]\n\t"
        : [a0] "+r"(a[0]), [a1] "+r"(a[1]), [a2] "+r"(a[2])
        : [nz] "r"(nz), [b0] "r"(b[0]), [b1] "r"(b[1]), [b2] "r"(b[2]));
  } else if (W == 4) {
    asm("testq %[nz], %[nz]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        "cmovneq %[b1], %[a1]\n\t"
        "cmovneq %[b2], %[a2]\n\t"
        "cmovneq %[b3], %[a3]\n\t"
        : [a0] "+r"(a[0]), [a1] "+r"(a[1]), [a2] "+r"(a[2]), [a3] "+r"(a[3])
        : [nz] "r"(nz), [b0] "r"(b[0]), [b1] "r"(b[1]), [b2] "r"(b[2]),
          [b3] "r"(b[3]));
  } else {
    for (size_t i = 0; i < W; ++i) {
      a[i] = (nz != 0) ? b[i] : a[i];
    }
  }
}

static inline void cmovne(size_t W, uint64_t a[/*W*/], uint64_t x, uint64_t y,
                          const uint64_t b[/*W*/]) {
  if (W == 1) {
    asm("cmpq %[x], %[y]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        : [a0] "+r"(a[0])
        : [x] "r"(x), [y] "r"(y), [b0] "r"(b[0])
        : "cc");
  } else if (W == 2) {
    asm("cmpq %[x], %[y]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        "cmovneq %[b1], %[a1]\n\t"
        : [a0] "+r"(a[0]), [a1] "+r"(a[1])
        : [x] "r"(x), [y] "r"(y), [b0] "r"(b[0]), [b1] "r"(b[1])
        : "cc");
  } else if (W == 3) {
    asm("cmpq %[x], %[y]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        "cmovneq %[b1], %[a1]\n\t"
        "cmovneq %[b2], %[a2]\n\t"
        : [a0] "+r"(a[0]), [a1] "+r"(a[1]), [a2] "+r"(a[2])
        : [x] "r"(x), [y] "r"(y), [b0] "r"(b[0]), [b1] "r"(b[1]), [b2] "r"(b[2])
        : "cc");
  } else if (W == 4) {
    asm("cmpq %[x], %[y]\n\t"
        "cmovneq %[b0], %[a0]\n\t"
        "cmovneq %[b1], %[a1]\n\t"
        "cmovneq %[b2], %[a2]\n\t"
        "cmovneq %[b3], %[a3]\n\t"
        : [a0] "+r"(a[0]), [a1] "+r"(a[1]), [a2] "+r"(a[2]), [a3] "+r"(a[3])
        : [x] "r"(x), [y] "r"(y), [b0] "r"(b[0]), [b1] "r"(b[1]),
          [b2] "r"(b[2]), [b3] "r"(b[3])
        : "cc");
  } else {
    for (size_t i = 0; i < W; ++i) {
      a[i] = (x != y) ? b[i] : a[i];
    }
  }
}

static inline uint64_t addcmovc(uint64_t a, uint64_t b, uint64_t c) {
  asm("add %[b], %[a]\n\t"
      "cmovaeq %[c], %[a]\n\t"
      : [a] "+r"(a)
      : [b] "r"(b), [c] "r"(c)
      : "cc");
  return a;
}

static inline uint64_t sub_sysdep(uint64_t a, uint64_t y, uint64_t m) {
  uint64_t z = 0;
  asm("subq %[y], %[a]\n\t"
      "cmovbq %[m], %[z]\n\t"
      : [a] "+r"(a), [z] "+r"(z)
      : [y] "r"(y), [m] "r"(m)
      : "cc");
  return a + z;
}

#elif defined(__aarch64__)

static inline void cmovne(size_t W, uint64_t a[/*W*/], uint64_t x, uint64_t y,
                          const uint64_t b[/*W*/]) {
  if (W == 1) {
    asm("cmp %[x], %[y]\n\t"                //
        "csel %[a0], %[a0], %[b0], eq\n\t"  //
        : [a0] "+r"(a[0])                   //
        : [x] "r"(x), [y] "ri"(y),          //
          [b0] "r"(b[0])                    //
        : "cc");
  } else if (W == 2) {
    asm("cmp %[x], %[y]\n\t"                //
        "csel %[a0], %[a0], %[b0], eq\n\t"  //
        "csel %[a1], %[a1], %[b1], eq\n\t"  //
        : [a0] "+r"(a[0]),                  //
          [a1] "+r"(a[1])                   //
        : [x] "r"(x), [y] "ri"(y),          //
          [b0] "r"(b[0]),                   //
          [b1] "r"(b[1])                    //
        : "cc");
  } else if (W == 3) {
    asm("cmp %[x], %[y]\n\t"                //
        "csel %[a0], %[a0], %[b0], eq\n\t"  //
        "csel %[a1], %[a1], %[b1], eq\n\t"  //
        "csel %[a2], %[a2], %[b2], eq\n\t"  //
        : [a0] "+r"(a[0]),                  //
          [a1] "+r"(a[1]),                  //
          [a2] "+r"(a[2])                   //
        : [x] "r"(x), [y] "ri"(y),          //
          [b0] "r"(b[0]),                   //
          [b1] "r"(b[1]),                   //
          [b2] "r"(b[2])                    //
        : "cc");
  } else if (W == 4) {
    asm("cmp %[x], %[y]\n\t"                //
        "csel %[a0], %[a0], %[b0], eq\n\t"  //
        "csel %[a1], %[a1], %[b1], eq\n\t"  //
        "csel %[a2], %[a2], %[b2], eq\n\t"  //
        "csel %[a3], %[a3], %[b3], eq\n\t"  //
        : [a0] "+r"(a[0]),                  //
          [a1] "+r"(a[1]),                  //
          [a2] "+r"(a[2]),                  //
          [a3] "+r"(a[3])                   //
        : [x] "r"(x), [y] "ri"(y),          //
          [b0] "r"(b[0]),                   //
          [b1] "r"(b[1]),                   //
          [b2] "r"(b[2]),                   //
          [b3] "r"(b[3])                    //
        : "cc");
  } else {
    for (size_t i = 0; i < W; ++i) {
      a[i] = (x != y) ? b[i] : a[i];
    }
  }
}

// a = (nz != 0) ? b : a
static inline void cmovnz(size_t W, uint64_t a[/*W*/], uint64_t nz,
                          const uint64_t b[/*W*/]) {
  constexpr uint64_t z = 0;
  cmovne(W, a, nz, z, b);
}

static inline uint64_t addcmovc(uint64_t a, uint64_t b, uint64_t c) {
  asm("adds %[a], %[a], %[b]\n\t"
      "csel %[a], %[a], %[c], hs\n\t"
      : [a] "+r"(a)
      : [b] "r"(b), [c] "r"(c)
      : "cc");
  return a;
}

static inline uint64_t sub_sysdep(uint64_t a, uint64_t y, uint64_t m) {
  asm("subs %[a], %[a], %[y]\n\t"
      "csel %[m], %[m], xzr, lo"
      : [a] "+r"(a), [m] "+r"(m)
      : [y] "r"(y)
      : "cc");
  return a + m;
}

#else  // generic portable code

// a = (x != y) ? b : a
template <class limb_t>
static inline void cmovne(size_t W, limb_t a[/*W*/], limb_t x, limb_t y,
                          const limb_t b[/*W*/]) {
  for (size_t i = 0; i < W; ++i) {
    a[i] = (x != y) ? b[i] : a[i];
  }
}

// a = (nz != 0) ? b : a
template <class limb_t>
static inline void cmovnz(size_t W, limb_t a[/*W*/], limb_t nz,
                          const limb_t b[/*W*/]) {
  constexpr limb_t z = 0;
  cmovne(W, a, nz, z, b);
}

template <class limb_t>
static inline limb_t addcmovc(limb_t a, limb_t b, limb_t c) {
  limb_t t = a + b;
  return (a > t) ? t : c;
}

template <class limb_t>
static inline limb_t sub_sysdep(limb_t a, limb_t y, limb_t m) {
  limb_t t0 = a - y;
  return (y > a) ? (t0 + m) : t0;
}

#endif

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_SYSDEP_H_
