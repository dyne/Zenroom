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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA_FLATSHA256_CIRCUIT_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA_FLATSHA256_CIRCUIT_H_

#include <stddef.h>

#include <cstdint>
#include <vector>

#include "circuits/compiler/compiler.h"
#include "circuits/logic/bit_adder.h"
#include "circuits/sha/sha256_constants.h"

namespace proofs {
// FlatSHA256Circuit
//
// Implements SHA256 hash function as an arithmetic circuit over the field F.
// The circuit is flattened, meaning that the SHA round function has been
// repeated in parallel instead of sequentially. As a result, the prover must
// provide the intermediate round values as witnesses.
//
// This package does not have any external dependencies on a SHA256 library.
//
// There are two versions of this function, one with standard bit inputs, and
// another with packed bit inputs. The later reduces the number of inputs at
// the cost of increasing the depth and number of wires. For example, the
// following shows the difference with pack parameter 2.
//
// FlatSHA256_Circuit.assert_transform_block
//  depth: 7 wires: 38029 in: 6657 out:128 use:30897 ovh:7132 t:166468 cse:9703
//  notn:113744
//
// FlatSHA256_Circuit.assert_transform_block_packed
//  depth: 9 wires: 65735 in: 3585 out:128 use:55486 ovh:10249 t:214653
//  cse:28135 notn:151504
//
//
template <class Logic, class BitPlucker>
class FlatSHA256Circuit {
 public:
  using v8 = typename Logic::v8;
  using v256 = typename Logic::v256;
  using v32 = typename Logic::v32;
  using EltW = typename Logic::EltW;
  using Field = typename Logic::Field;
  using packed_v32 = typename BitPlucker::packed_v32;

  const Logic& l_;
  BitPlucker bp_; /* public, so caller can encode input */

  struct BlockWitness {
    packed_v32 outw[48];
    packed_v32 oute[64];
    packed_v32 outa[64];
    packed_v32 h1[8];

    static packed_v32 packed_input(QuadCircuit<typename Logic::Field>& Q) {
      packed_v32 r;
      for (size_t i = 0; i < r.size(); ++i) {
        r[i] = Q.input();
      }
      return r;
    }

    void input(QuadCircuit<typename Logic::Field>& Q) {
      for (size_t k = 0; k < 48; ++k) {
        outw[k] = packed_input(Q);
      }
      for (size_t k = 0; k < 64; ++k) {
        oute[k] = packed_input(Q);
        outa[k] = packed_input(Q);
      }
      for (size_t k = 0; k < 8; ++k) {
        h1[k] = packed_input(Q);
      }
    }
  };

  explicit FlatSHA256Circuit(const Logic& l) : l_(l), bp_(l_) {}

  static packed_v32 packed_input(QuadCircuit<Field>& Q) {
    packed_v32 r;
    for (size_t i = 0; i < r.size(); ++i) {
      r[i] = Q.input();
    }
    return r;
  }

  void assert_transform_block(const v32 in[16], const v32 H0[8],
                              const v32 outw[48], const v32 oute[64],
                              const v32 outa[64], const v32 H1[8]) const {
    const Logic& L = l_;  // shorthand
    BitAdder<Logic, 32> BA(L);

    std::vector<v32> w(64);
    for (size_t i = 0; i < 16; ++i) {
      w[i] = in[i];
    }

    for (size_t i = 16; i < 64; ++i) {
      auto sw2 = sigma1(w[i - 2]);
      auto sw15 = sigma0(w[i - 15]);
      std::vector<v32> terms = {sw2, w[i - 7], sw15, w[i - 16]};
      w[i] = outw[i - 16];
      BA.assert_eqmod(w[i], BA.add(terms), 4);
    }

    v32 a = H0[0];
    v32 b = H0[1];
    v32 c = H0[2];
    v32 d = H0[3];
    v32 e = H0[4];
    v32 f = H0[5];
    v32 g = H0[6];
    v32 h = H0[7];

    for (size_t t = 0; t < 64; ++t) {
      auto s1e = Sigma1(e);
      auto ch = L.vCh(&e, &f, g);
      auto rt = L.vbit32(kSha256Round[t]);
      std::vector<v32> t1_terms = {h, s1e, ch, rt, w[t]};
      EltW t1 = BA.add(t1_terms);
      EltW sigma0 = BA.as_field_element(Sigma0(a));
      EltW vmaj = BA.as_field_element(L.vMaj(&a, &b, c));
      EltW t2 = BA.add(&sigma0, vmaj);

      h = g;
      g = f;
      f = e;
      e = oute[t];
      EltW ed = BA.as_field_element(d);
      BA.assert_eqmod(e, BA.add(&t1, ed), 6);
      d = c;
      c = b;
      b = a;
      a = outa[t];
      BA.assert_eqmod(a, BA.add(&t1, t2), 7);
    }

    BA.assert_eqmod(H1[0], BA.add(H0[0], a), 2);
    BA.assert_eqmod(H1[1], BA.add(H0[1], b), 2);
    BA.assert_eqmod(H1[2], BA.add(H0[2], c), 2);
    BA.assert_eqmod(H1[3], BA.add(H0[3], d), 2);
    BA.assert_eqmod(H1[4], BA.add(H0[4], e), 2);
    BA.assert_eqmod(H1[5], BA.add(H0[5], f), 2);
    BA.assert_eqmod(H1[6], BA.add(H0[6], g), 2);
    BA.assert_eqmod(H1[7], BA.add(H0[7], h), 2);
  }

  // Packed API.
  // H0 not packed, all others packed
  void assert_transform_block(const v32 in[16], const v32 H0[8],
                              const packed_v32 poutw[48],
                              const packed_v32 poute[64],
                              const packed_v32 pouta[64],
                              const packed_v32 pH1[8]) const {
    std::vector<v32> H1(8);
    std::vector<v32> outw(48);
    std::vector<v32> oute(64), outa(64);
    for (size_t i = 0; i < 8; ++i) {
      H1[i] = bp_.unpack_v32(pH1[i]);
    }
    for (size_t i = 0; i < 48; ++i) {
      outw[i] = bp_.unpack_v32(poutw[i]);
    }
    for (size_t i = 0; i < 64; ++i) {
      oute[i] = bp_.unpack_v32(poute[i]);
      outa[i] = bp_.unpack_v32(pouta[i]);
    }
    assert_transform_block(in, H0, outw.data(), oute.data(), outa.data(),
                           H1.data());
  }

  // all packed
  void assert_transform_block(const v32 in[16], const packed_v32 pH0[8],
                              const packed_v32 poutw[48],
                              const packed_v32 poute[64],
                              const packed_v32 pouta[64],
                              const packed_v32 pH1[8]) const {
    std::vector<v32> H0(8);
    for (size_t i = 0; i < 8; ++i) {
      H0[i] = bp_.unpack_v32(pH0[i]);
    }
    assert_transform_block(in, H0.data(), poutw, poute, pouta, pH1);
  }

  /* This method checks that the block witness corresponds to the iterated
     computation of the sha block transform on the input.
  */
  void assert_message(size_t max, const v8& nb, const v8 in[/* 64*max */],
                      const BlockWitness bw[/*max*/]) const {
    const Logic& L = l_;  // shorthand
    const packed_v32* H = nullptr;
    std::vector<v32> tmp(16);

    for (size_t b = 0; b < max; ++b) {
      const v8* inb = &in[64 * b];
      for (size_t i = 0; i < 16; ++i) {
        // big-endian mapping of v8[4] into v32.  The first
        // argument of vappend() is the LSB, and thus +3 is
        // the LSB and +0 is the MSB, hence big-endian.
        tmp[i] = L.vappend(L.vappend(inb[4 * i + 3], inb[4 * i + 2]),
                           L.vappend(inb[4 * i + 1], inb[4 * i + 0]));
      }
      if (b == 0) {
        v32 H0[8];
        initial_context(H0);
        assert_transform_block(tmp.data(), H0, bw[b].outw, bw[b].oute,
                               bw[b].outa, bw[b].h1);
      } else {
        assert_transform_block(tmp.data(), H, bw[b].outw, bw[b].oute,
                               bw[b].outa, bw[b].h1);
      }
      H = bw[b].h1;
    }
  }

  /* This method checks that the block witness corresponds to the iterated
     computation of the sha block transform on the prefix || input.
  */
  void assert_message_with_prefix(size_t max, const v8& nb,
                                  const v8 in[/* < 64*max */],
                                  const uint8_t prefix[/* len */], size_t len,
                                  const BlockWitness bw[/*max*/]) const {
    const Logic& L = l_;  // shorthand
    std::vector<v32> tmp(16);

    std::vector<v8> bbuf(64 * max);
    for (size_t i = 0; i < len; ++i) {
      L.bits(8, bbuf[i].data(), prefix[i]);
    }
    for (size_t i = 0; i + len < 64 * max; ++i) {
      bbuf[i + len] = in[i];
    }

    assert_message(max, nb, bbuf.data(), bw);
  }

  /* This method checks if H(in) == target. The method requires that in[]
  contains exactly nb*64 bytes and has been padded according to the SHA256
  specification.
  */
  void assert_message_hash(size_t max, const v8& nb, const v8 in[/* 64*max */],
                           const v256& target,
                           const BlockWitness bw[/*max*/]) const {
    assert_message(max, nb, in, bw);
    assert_hash(max, target, nb, bw);
  }

  // This method checks if H(prefix || in) == target.
  // Since the prefix is hardcoded, the compiler can propagate constants
  // and produce smaller circuits. As above, the method requires that in[]
  // contains exactly nb*64 bytes and has been padded according to the SHA256
  // specification. To use this method, compute the block_witness for the
  // entire message as usual.
  void assert_message_hash_with_prefix(size_t max, const v8& nb,
                                       const v8 in[/* 64*max */],
                                       const uint8_t prefix[/* len */],
                                       size_t len, const v256& target,
                                       const BlockWitness bw[/*max*/]) const {
    assert_message_with_prefix(max, nb, in, prefix, len, bw);
    assert_hash(max, target, nb, bw);
  }

  // Verifies that the nb_th element of the block witness is equal to e.
  // The block witness keeps track of the intermediate output of each
  // block transform.  Therefore, this method can be used to verify that the
  // prover knows a preimage that hashes to the desired e.
  void assert_hash(size_t max, const v256& e, const v8& nb,
                   const BlockWitness bw[/*max*/]) const {
    packed_v32 x[8];
    for (size_t b = 0; b < max; ++b) {
      auto bt = l_.veq(nb, b + 1); /* b is zero-indexed */
      auto ebt = l_.eval(bt);
      for (size_t i = 0; i < 8; ++i) {
        for (size_t k = 0; k < bp_.kNv32Elts; ++k) {
          if (b == 0) {
            x[i][k] = l_.mul(&ebt, bw[b].h1[i][k]);
          } else {
            auto maybe_sha = l_.mul(&ebt, bw[b].h1[i][k]);
            x[i][k] = l_.add(&x[i][k], maybe_sha);
          }
        }
      }
    }

    // Unpack the hash into a v256 in reverse byte-order.
    v256 mm;
    for (size_t j = 0; j < 8; ++j) {
      auto hj = bp_.unpack_v32(x[j]);
      for (size_t k = 0; k < 32; ++k) {
        mm[((7 - j) * 32 + k)] = hj[k];
      }
    }
    l_.vassert_eq(&mm, e);
  }

 private:
  void initial_context(v32 H[8]) const {
    static const uint64_t initial[8] = {0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u,
                                        0xa54ff53au, 0x510e527fu, 0x9b05688cu,
                                        0x1f83d9abu, 0x5be0cd19u};
    for (size_t i = 0; i < 8; i++) {
      H[i] = l_.template vbit<32>(initial[i]);
    }
  }

  v32 Sigma0(const v32& x) const {
    auto x2 = l_.vrotr(x, 2);
    auto x13 = l_.vrotr(x, 13);
    return l_.vxor3(&x2, &x13, l_.vrotr(x, 22));
  }

  v32 Sigma1(const v32& x) const {
    auto x6 = l_.vrotr(x, 6);
    auto x11 = l_.vrotr(x, 11);
    return l_.vxor3(&x6, &x11, l_.vrotr(x, 25));
  }

  v32 sigma0(const v32& x) const {
    auto x7 = l_.vrotr(x, 7);
    auto x18 = l_.vrotr(x, 18);
    return l_.vxor3(&x7, &x18, l_.vshr(x, 3));
  }

  v32 sigma1(const v32& x) const {
    auto x17 = l_.vrotr(x, 17);
    auto x19 = l_.vrotr(x, 19);
    return l_.vxor3(&x17, &x19, l_.vshr(x, 10));
  }
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_SHA_FLATSHA256_CIRCUIT_H_
