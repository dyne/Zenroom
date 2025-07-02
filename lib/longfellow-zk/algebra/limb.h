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

#ifndef PRIVACY_PROOFS_ZK_LIB_ALGEBRA_LIMB_H_
#define PRIVACY_PROOFS_ZK_LIB_ALGEBRA_LIMB_H_

#include <array>
#include <cstddef>
#include <cstdint>

#include "util/serialization.h"

namespace proofs {

// Base class for representing bignum or bigpoly as arrays of
// machine-dependent "limbs".  The serialization is in this
// class; arithmetic is in subclasses.

template <size_t W64>
class Limb {
 public:
  using T = Limb<W64>;

#if __WORDSIZE == 64
  using limb_t = uint64_t;
#else
  using limb_t = uint32_t;
#endif

  // sizes in bytes, bits, limbs, uint64_t
  static constexpr size_t kBytes = 8 * W64;
  static constexpr size_t kBits = 64 * W64;
  static constexpr size_t kLimbs = kBytes / sizeof(limb_t);
  static constexpr size_t kU64 = W64;
  static constexpr size_t kBitsPerLimb = 8 * sizeof(limb_t);

  // no rounding allowed
  static_assert(kLimbs * sizeof(limb_t) == kBytes);

  limb_t limb_[kLimbs];

  Limb() = default;  // uninitialized
  explicit Limb(uint64_t x) : limb_{} { assign(limb_, 1, &x); }

  explicit Limb(const std::array<uint64_t, kU64>& a) : limb_{} {
    assign(limb_, kU64, &a[0]);
  }

  std::array<uint64_t, kU64> u64() const {
    std::array<uint64_t, kU64> a;
    unassign(limb_, kU64, &a[0]);
    return a;
  }

  void to_bytes(uint8_t a[/* kBytes */]) const {
    for (size_t i = 0; i < kLimbs; ++i) {
      a = to_bytes(&limb_[i], a);
    }
  }

  bool operator==(const T& other) const {
    for (size_t i = 0; i < kLimbs; ++i) {
      if (limb_[i] != other.limb_[i]) {
        return false;
      }
    }
    return true;
  }
  bool operator!=(const T& other) const { return !(operator==(other)); }

  // Shift right by z.  Return the bits that fall off
  // the edge.
  limb_t shiftr(size_t z) {
    limb_t c = 0;
    for (size_t i = kLimbs; i-- > 0;) {
      limb_t d = limb_[i];
      limb_[i] = c | (d >> z);
      c = d << (kBitsPerLimb - z);
    }
    return c;
  }

  // Returns the pos-th bit in the representation of this nat.
  limb_t bit(size_t pos) const {
    size_t ind = pos / kBitsPerLimb;
    if (ind < kLimbs) {
      size_t off = pos % kBitsPerLimb;
      return (limb_[ind] >> off) & 0x1u;
    }
    return 0;
  }

 protected:
  static void assign(uint64_t d[], size_t ns, const uint64_t s[/*ns*/]) {
    for (size_t i = 0; i < ns; ++i) {
      d[i] = s[i];
    }
  }

  static void assign(uint32_t d[], size_t ns, const uint64_t s[/*ns*/]) {
    for (size_t i = 0; i < ns; ++i) {
      d[2 * i] = static_cast<uint32_t>(s[i]);
      d[2 * i + 1] = static_cast<uint32_t>(s[i] >> 32);
    }
  }

  static void unassign(const uint64_t d[], size_t ns, uint64_t s[/*ns*/]) {
    for (size_t i = 0; i < ns; ++i) {
      s[i] = d[i];
    }
  }

  static void unassign(const uint32_t d[], size_t ns, uint64_t s[/*ns*/]) {
    for (size_t i = 0; i < ns; ++i) {
      s[i] = d[2 * i] | (static_cast<uint64_t>(d[2 * i + 1]) << 32);
    }
  }

  static const uint8_t* of_bytes(uint64_t* r, const uint8_t* a) {
    *r = u64_of_le(a);
    return a + 8;
  }
  static const uint8_t* of_bytes(uint32_t* r, const uint8_t* a) {
    *r = u32_of_le(a);
    return a + 4;
  }

  static uint8_t* to_bytes(const uint64_t* r, uint8_t* a) {
    u64_to_le(a, *r);
    return a + 8;
  }
  static uint8_t* to_bytes(const uint32_t* r, uint8_t* a) {
    u32_to_le(a, *r);
    return a + 4;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ALGEBRA_LIMB_H_
