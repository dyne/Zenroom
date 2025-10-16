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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_NAT_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_NAT_H_

#include <array>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <optional>

#include "algebra/limb.h"
#include "algebra/static_string.h"
#include "algebra/sysdep.h"
#include "util/panic.h"

namespace proofs {

// return a^-1 mod 2^L where L is the number of bits in limb_t
template <class limb_t>
static limb_t inv_mod_b(limb_t a) {
  // Let v=1-a.  We have 1/a=1/(1-v)=1+v+v^2+..., or
  // 1/a=(1+v)(1+v^2)(1+v^4)... At some point v^(2^k) becomes 0 mod
  // 2^L because v is even.

  // A more complicated variant of this idea appears in Dumas,
  // J.G. "On Newton–Raphson Iteration for Multiplicative Inverses
  // Modulo Prime Powers", Algorithm 3, where they use v'=a-1
  // instead of v=1-a, and so the first term needs to be handled
  // separately as 2-a instead of 1+v, breaking the uniformity of
  // the algorithm.  The sign difference disappears after the first
  // squaring.
  check((a & 1) != 0, "even A in inv_mod_b()");

  limb_t v = 1u - a;
  limb_t u = 1u;
  while (v != 0) {
    u *= (1u + v);
    v *= v;
  }
  return u;
}

// This function should only be called on static input known at compile time.
unsigned digit(char c);

template <size_t W64>
class Nat : public Limb<W64> {
 public:
  using Super = Limb<W64>;
  using T = Nat<W64>;
  using limb_t = typename Super::limb_t;
  using Super::kLimbs;
  using Super::kU64;
  using Super::limb_;

  // Maximum length for an untrusted string, 2^64 ~ 20 decimal digits.
  static constexpr size_t kMaxStringLen = 20 * W64 + 1;

  Nat() = default;  // uninitialized
  explicit Nat(uint64_t x) : Super(x) {}

  explicit Nat(const std::array<uint64_t, kU64>& a) : Super(a) {}

  // Pre-condition: the caller of this function must check that the string
  // s is either a valid base-10 or base-16 representation of a natural number
  // that does not overflow the representation.
  // In our current implementation, this method is only used on static strings.
  explicit Nat(const StaticString& ss) : Super(0) {
    limb_t base = 10u;
    const char* s = ss.as_pointer;
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
      s += 2;
      base = 16u;
    }
    for (; *s; s++) {
      T d(digit(*s));
      bool ok = muls(limb_, base);
      check(ok, "overflow in nat(const char *s)");
      limb_t ah = add_limb(kLimbs, limb_, d.limb_);
      check(ah == 0, "overflow in nat(const char *s)");
    }
  }

  template <size_t LEN>
  explicit Nat(const char (&p)[LEN]) : Nat(StaticString(p)) {}

  // Interpret A[] as a little-endian nat
  static T of_bytes(const uint8_t a[/* kBytes */]) {
    T r;
    for (size_t i = 0; i < kLimbs; ++i) {
      a = Super::of_bytes(&r.limb_[i], a);
    }
    return r;
  }

  static std::optional<unsigned> safe_digit(char c, limb_t base) {
    c = tolower(c);
    if (c >= '0' && c <= '9') {
      return c - '0';
    } else if (base == 16u && c >= 'a' && c <= 'f') {
      return c - 'a' + 10;
    }
    return std::nullopt;
  }

  static std::optional<T> of_untrusted_string(const char* s) {
    T r(0);
    limb_t base = 10u;
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
      s += 2;
      base = 16u;
    }
    const char* p = s;
    for (size_t len = 0; len < kMaxStringLen && *p; ++len, ++p) {
      auto d = safe_digit(*p, base);
      if (!d.has_value()) {
        return std::nullopt;
      }
      T td(d.value());
      if (!muls(r.limb_, base)) {
        return std::nullopt;
      }
      limb_t ah = add_limb(kLimbs, r.limb_, td.limb_);
      if (ah != 0) {
        return std::nullopt;
      }
    }
    // If the loop terminates due to the length limit, then the string is not
    // a valid base-10 or base-16 representation of a natural number.
    if (*p) {
      return std::nullopt;
    }
    return r;
  }

  bool operator<(const T& y) const {
    T b = *this;
    limb_t bh = sub_limb(kLimbs, b.limb_, y.limb_);
    return (bh != 0);
  }

  T& add(const T& y) {
    (void)add_limb(kLimbs, limb_, y.limb_);
    return *this;
  }
  T& sub(const T& y) {
    (void)sub_limb(kLimbs, limb_, y.limb_);
    return *this;
  }

 private:
  // b *= a, returns false if overflow occurred.
  static bool muls(limb_t b[kLimbs], limb_t a) {
    limb_t h[kLimbs];
    mulhl(kLimbs, b, h, a, b);
    limb_t bh = addh(kLimbs, b, h);
    return bh == 0;
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_NAT_H_
