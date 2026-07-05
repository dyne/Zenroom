// Copyright 2026 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_BUILDER_H_
#define PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_BUILDER_H_

#include <stddef.h>

#include <cstdint>
#include <memory>
#include <unordered_map>
#include <vector>

#include "algebra/hash.h"
#include "sumcheck/equad.h"
#include "sumcheck/quad.h"
#include "util/panic.h"

// Helper functions for building quads.  They should be used only
// by tests and the compiler, but not by the prover and verifier.
namespace proofs {

// helper class for builting the kvec_ vector
template <class Field>
class KvecBuilder {
  using Elt = typename Field::Elt;
  using kvec_t = std::vector<Elt>;

  // Class that defines the hash function for Elt.
  class EltHash {
   public:
    const Field& f_;
    explicit EltHash(const Field& f) : f_(f) {}
    size_t operator()(const Elt& k) const { return elt_hash(k, f_); }
  };

 public:
  explicit KvecBuilder(const Field& f)
      : table_(10, EltHash(f)), kvec_(std::make_shared<kvec_t>()) {}

  size_t kstore(const Elt& k) {
    auto [it, inserted] = table_.try_emplace(k, 0);
    if (inserted) {
      it->second = kvec_->size();
      kvec_->push_back(k);
    }
    return it->second;
  }

  size_t kload(const Elt& k) const {
    if (auto search = table_.find(k); search != table_.end()) {
      return search->second;
    }
    check(false, "kload() failed");
    return 0;
  }

  std::shared_ptr<kvec_t> kvec() { return kvec_; }

 private:
  std::unordered_map<Elt, size_t, EltHash> table_;
  std::shared_ptr<kvec_t> kvec_;
};

// hasher for delta_corner
template <class Field>
struct delta_corner_hash {
  using delta_corner = typename Quad<Field>::delta_corner;
  static uint64_t hash_combine(uint64_t seed, uint64_t v) {
    return (seed * 0x100000001b3ull) ^ v;
  }
  uint64_t operator()(const delta_corner& d) const {
    uint64_t h = 0xcbf29ce484222325ull;
    h = hash_combine(h, static_cast<uint32_t>(d.dg));
    h = hash_combine(h, static_cast<uint32_t>(d.dh[0]));
    h = hash_combine(h, static_cast<uint32_t>(d.dh[1]));
    h = hash_combine(h, d.vi);
    return h;
  }
};

// helper class for building the delta_table_ vector
template <class Field>
class DeltaTableBuilder {
  using quad_corner_t = typename Quad<Field>::quad_corner_t;
  using delta_corner = typename Quad<Field>::delta_corner;
  using delta_table_t = typename Quad<Field>::delta_table_t;

 public:
  DeltaTableBuilder() : delta_table_(std::make_shared<delta_table_t>()) {}

  uint32_t dedup(quad_corner_t dg, quad_corner_t dh0, quad_corner_t dh1,
                 uint32_t vi) {
    delta_corner d{dg, {dh0, dh1}, vi};
    auto [it, inserted] = delta_map_.try_emplace(d, delta_table_->size());
    if (inserted) {
      delta_table_->push_back(d);
    }
    return it->second;
  }

  std::shared_ptr<delta_table_t> delta_table() { return delta_table_; }

 private:
  std::shared_ptr<delta_table_t> delta_table_;
  std::unordered_map<delta_corner, uint32_t, delta_corner_hash<Field>>
      delta_map_;
};

// ApproximateDeltaTableBuilder is like DeltaTableBuilder, but with a two-way
// set-associative cache instead of an exact hash table. We prefer quick lookup
// at the cost of missing some deduplications.
template <class Field>
class ApproximateDeltaTableBuilder {
  using quad_corner_t = typename Quad<Field>::quad_corner_t;
  using delta_corner = typename Quad<Field>::delta_corner;
  using delta_table_t = typename Quad<Field>::delta_table_t;

 public:
  explicit ApproximateDeltaTableBuilder(size_t cache_size)
      : delta_table_(std::make_shared<delta_table_t>()), cache_(cache_size) {}

  uint32_t dedup(quad_corner_t dg, quad_corner_t dh0, quad_corner_t dh1,
                 uint32_t vi) {
    delta_corner d{dg, {dh0, dh1}, vi};
    size_t h = delta_corner_hash<Field>{}(d);
    size_t idx = static_cast<size_t>(h % cache_.size());
    CacheEntry& ent = cache_[idx];
    if (ent.slots[0].valid && ent.slots[0].d == d) {
      return ent.slots[0].index;
    }
    if (ent.slots[1].valid && ent.slots[1].d == d) {
      // Maintain the LRU property that slot[0] is the most recently used.
      std::swap(ent.slots[0], ent.slots[1]);
      return ent.slots[0].index;
    }

    uint32_t index = delta_table_->size();
    delta_table_->push_back(d);
    // LRU eviction.
    ent.slots[1] = ent.slots[0];
    ent.slots[0] = {d, index, true};
    return index;
  }

  std::shared_ptr<delta_table_t> delta_table() { return delta_table_; }

 private:
  struct Slot {
    delta_corner d;
    uint32_t index;
    bool valid = false;
  };

  struct CacheEntry {
    Slot slots[2];
  };

  std::shared_ptr<delta_table_t> delta_table_;
  std::vector<CacheEntry> cache_;
};

template <class Field>
class QuadBuilder {
  using Elt = typename Field::Elt;
  using ecorner = typename EQuad<Field>::ecorner;
  using index_t = typename EQuad<Field>::index_t;

 public:
  // Convert an EQuad into a Quad by collecting all constants in the
  // EQuad.  A more refined approach would collect all constants
  // in all layers.
  static std::unique_ptr<Quad<Field>> compress(const EQuad<Field>* EQUAD,
                                               const Field& f) {
    KvecBuilder<Field> kb(f);
    // collect all constants
    for (index_t i = 0; i < EQUAD->n_; ++i) {
      (void)kb.kstore(EQUAD->ec_[i].v);
    }

    DeltaTableBuilder<Field> db;
    auto q =
        std::make_unique<Quad<Field>>(EQUAD->n_, kb.kvec(), db.delta_table());
    using QuadCorner = typename Quad<Field>::quad_corner_t;
    QuadCorner prev_g(0), prev_h0(0), prev_h1(0);
    for (index_t i = 0; i < EQUAD->n_; ++i) {
      const ecorner& eqi = EQUAD->ec_[i];
      q->assign(i,
                db.dedup(eqi.g - prev_g, eqi.h[0] - prev_h0, eqi.h[1] - prev_h1,
                         static_cast<uint32_t>(kb.kload(eqi.v))));
      prev_g = eqi.g;
      prev_h0 = eqi.h[0];
      prev_h1 = eqi.h[1];
    }
    return q;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_SUMCHECK_QUAD_BUILDER_H_
