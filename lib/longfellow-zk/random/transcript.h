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

#ifndef PRIVACY_PROOFS_ZK_LIB_RANDOM_TRANSCRIPT_H_
#define PRIVACY_PROOFS_ZK_LIB_RANDOM_TRANSCRIPT_H_

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <memory>

#include "random/random.h"
#include "util/crypto.h"
#include "util/panic.h"
#include "util/serialization.h"

namespace proofs {

/*
FSPRF and Transcript together used implement the Fiat-Shamir transform.
*/
class FSPRF  {
 public:
  explicit FSPRF(const uint8_t key[kPRFKeySize])
      : prf_(key), nblock_(0), rdptr_(kPRFOutputSize) {}

  // Disable copy for good measure.
  explicit FSPRF(const FSPRF&) = delete;
  FSPRF& operator=(const FSPRF&) = delete;

  // Maximum number of blocks that can be generated using a 128-bit PRF.
  // The limit is 2^64, but 2^40 suffices for our application.
  constexpr static uint64_t kMaxBlocks = 0x10000000000;

  void bytes(uint8_t buf[/*n*/], size_t n) {
    while (n-- > 0) {
      if (rdptr_ == kPRFOutputSize) {
        refill();
      }
      *buf++ = saved_[rdptr_++];
    }
  }

 private:
  void refill() {
    check(nblock_ < kMaxBlocks, "too many blocks");
    uint8_t in[kPRFInputSize] = {};
    u64_to_le(in, nblock_++);
    prf_.Eval(saved_, in);
    rdptr_ = 0;
  }

  PRF prf_;
  uint64_t nblock_;
  size_t rdptr_;       // read pointer into saved[]
  uint8_t saved_[kPRFOutputSize];  // saved pseudo-random bytes
};

class Transcript : public RandomEngine {
  enum { TAG_BSTR = 0, TAG_FIELD_ELEM = 1, TAG_ARRAY = 2 };

 public:
  // A transcript must be explicitly initialized so that each instance of
  // the Random oracle is unique.
  Transcript(const uint8_t init[], size_t init_len, size_t version = 3)
      : sha_(), prf_(), version_(version) {
    write(init, init_len);
  }

  // Remove default copy and move implementations.
  Transcript(const Transcript&) = delete;
  Transcript& operator=(const Transcript&) = delete;

  // Explicit copy to avoid accidental passing by value.
  Transcript clone() { return Transcript(sha_, version_); }

  // Generate bytes by via the current FSPRF object.
  void bytes(uint8_t buf[/*n*/], size_t n) override {
    if (!prf_) {
      uint8_t key[kPRFKeySize];
      get(key);
      prf_ = std::make_unique<FSPRF>(key);
    }
    prf_->bytes(buf, n);
  }

  // snapshot the hash of the transcript so far
  void get(uint8_t key[/*kPRFKeySize*/]) {
    check(kPRFKeySize == kSHA256DigestSize, "prf key size != digest output");
    // fork the state because we will finalize it
    SHA256 tmp_hash;
    tmp_hash.CopyState(sha_);
    tmp_hash.DigestData(key);
  }

  // Typed write operations.  We tag byte-array(n), field-element, and
  // array-of-field-element(n).
  //
  // We make a few arbitrary choices that make no real difference.
  // All lengths are 64-bit.  We distinguish a field element from
  // an array of one field element, which is kind of arbitrary.

  // byte string
  void write(const uint8_t data[/*n*/], size_t n) {
    tag(TAG_BSTR);
    length(n);

    write_untyped(data, n);
  }

  // N zero bytes
  void write0(size_t n) {
    tag(TAG_BSTR);
    length(n);

    uint8_t data[32] = {};
    for (; n > 32; n -= 32) {
      write_untyped(data, 32);
    }
    write_untyped(data, n);
  }

  // one field element
  template <class Field>
  void write(const typename Field::Elt& e, const Field& F) {
    tag(TAG_FIELD_ELEM);

    write_untyped(e, F);
  }

  // array of field elements
  template <class Field>
  void write(const typename Field::Elt e[/*n*/], size_t ince, size_t n,
             const Field& F) {
    if (version_ > 3) {
      tag(TAG_ARRAY);
    } else {
      tag(1);  // in version 3, the TAG_ARRAY was 1.
    }
    length(n);

    for (size_t i = 0; i < n; ++i) {
      write_untyped(e[i * ince], F);
    }
  }

 private:
  explicit Transcript(const SHA256& sha, size_t version)
      : sha_(), version_(version) {
    sha_.CopyState(sha);
  }

  // Output a 1-byte tag
  void tag(size_t t) {
    uint8_t d = static_cast<uint8_t>(t);
    write_untyped(&d, 1);
  }

  // Output a 8-byte length.  We pass the length
  // as size_t, but we always write it as uint64_t
  void length(size_t x) {
    uint8_t a[8];
    u64_to_le(a, x);
    write_untyped(a, 8);
  }

  void write_untyped(const uint8_t data[/*n*/], size_t n) {
    // invalidate the PRF on any writes
    prf_.reset();
    sha_.Update(data, n);
  }

  template <class Field>
  void write_untyped(const typename Field::Elt& e, const Field& F) {
    uint8_t buf[Field::kBytes];
    F.to_bytes_field(buf, e);
    write_untyped(buf, sizeof(buf));
  }

  SHA256 sha_;
  std::unique_ptr<FSPRF> prf_;
  const size_t version_;  // version 4+ fixes the TAG_ARRAY typo.
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_RANDOM_TRANSCRIPT_H_
