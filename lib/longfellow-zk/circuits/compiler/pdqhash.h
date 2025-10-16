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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_PDQHASH_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_PDQHASH_H_

#include <stddef.h>
#include <stdint.h>

#include <functional>
#include <vector>

#define DEFINE_STRONG_INT_TYPE(a, b) using a = b

namespace proofs {

// Old-school, quick and dirty hash table specialized for
// uint64_t key, value_t value.  Support multiple keys
// ("multimap").
//
// This is supposed to solve the same problem as the C++
// unordered_multimap, except that the unordered_multimap
// stores key/value as a linked list and leaves the malloc()
// arena so fragmented that malloc_coalesce() takes several
// hundred ms to reconstruct the heap.
class PdqHash {
 public:
  // value of NIL denotes empty slot
  using value_t = uint32_t;
  static const constexpr value_t kNil = ~static_cast<value_t>(0);

  // Store the key as uint32_t to save space.  This is ok because
  // "key" is not really a key.  Instead, find() invokes pred() which
  // compares against the full key (stored outside this class).
  DEFINE_STRONG_INT_TYPE(stored_key_t, uint32_t);

  static stored_key_t narrow(uint64_t k) { return stored_key_t(k + (k >> 32)); }

  struct kv {
    stored_key_t k;
    value_t v;

    kv() : k(stored_key_t(0)), v(kNil) {}
  };

  PdqHash() : bits_(10), sz_(0), table_(capacity()) {}

  void insert(uint64_t k64, value_t v) {
    if (2 * sz_ > capacity()) {
      rehash();
    }
    insert0(narrow(k64), v);
  }

  size_t find(uint64_t k64, const std::function<bool(value_t)> &pred) {
    stored_key_t k = narrow(k64);
    size_t mask = (size_t(1) << bits_) - 1;
    size_t dh = dhash(k);
    for (size_t h = hash(k);; h += dh) {
      const kv *p = &table_[h & mask];
      if (p->v == kNil) {
        // not found
        return kNil;
      }
      if (p->k == k && pred(p->v)) {
        // found
        return p->v;
      }
    }
  }

 private:
  void insert0(stored_key_t k, value_t v) {
    size_t mask = (size_t(1) << bits_) - 1;
    size_t dh = dhash(k);
    for (size_t h = hash(k);; h += dh) {
      kv *p = &table_[h & mask];
      if (p->v == kNil) {
        p->k = k;
        p->v = v;
        ++sz_;
        return;
      }
    }
  }

  // Adhoc hash function suffices for this application.
  uint64_t hash(uint64_t k) {
    return k + 3 * (k >> bits_) + 7 * (k >> (2 * bits_));
  }
  uint64_t hash(stored_key_t nk) { return hash(static_cast<uint64_t>(nk)); }
  uint64_t dhash(stored_key_t nk) {
    // If gcd(dhash, capacity()) == 1, the insert loop does not have a short
    // cycle.
    return 2 * hash(hash(nk)) + 1;
  }
  void rehash() {
    ++bits_;
    std::vector<kv> table1(capacity());
    table_.swap(table1);
    for (const auto &p : table1) {
      if (p.v != kNil) {
        insert0(p.k, p.v);
      }
    }
  }

  size_t capacity() { return size_t(1) << bits_; }

  size_t bits_;
  size_t sz_;
  std::vector<kv> table_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_PDQHASH_H_
