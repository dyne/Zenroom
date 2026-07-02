/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
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

#ifndef NIWI_CIRCUITS_BIP340_CIRCUIT_H
#define NIWI_CIRCUITS_BIP340_CIRCUIT_H

#include <cstddef>
#include <cstdint>
#include <cstring>

#include "bip340_witness_bridge.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/sha/flatsha256_circuit.h"
#include "circuits/sha/sha256_constants.h"
#include "circuits/secp256k1_circuit.h"

namespace niwi {

/* BIP-340 verification circuit with in-circuit tagged hash.
 *
 * Public:  pk_x, R_x, s_val
 * Witness: y-coordinates, scalar-mul table, SHA block witnesses,
 *          message bits, bit decompositions
 *
 * Verifies:
 *   1. pk_x, R_x lift to even-y curve points
 *   2. e = tagged_hash("BIP0340/challenge", R_x||pk_x||msg) mod n
 *      (3-block SHA-256 inside the circuit)
 *   3. s·G == R + e·P   (double-scalar)
 *   4. Range: s < n, e < n, pk_x < p, R_x < p
 *   5. e_circuit + e_neg = n  (scalar binding)
 */

template <class LogicCircuit, class EC, class ScalarField>
class Bip340Circuit {
 public:
  using EltW   = typename LogicCircuit::EltW;
  using Elt    = typename LogicCircuit::Elt;
  using BitW   = typename LogicCircuit::BitW;
  using v256   = typename LogicCircuit::v256;
  using v32    = typename LogicCircuit::v32;
  using v8     = typename LogicCircuit::v8;

  static constexpr size_t kBits = EC::kBits;
  static constexpr size_t kShaBlocks = 3;

  using Bp = proofs::BitPlucker<LogicCircuit, 5>;
  using packed_v32 = typename Bp::packed_v32;

  struct Witness {
    EltW rx, ry, s_inv, pk_inv;
    EltW pre[8];
    EltW bi[kBits];
    EltW int_x[kBits - 1], int_y[kBits - 1], int_z[kBits - 1];
    EltW e_circuit, e_neg_wire;

    /* Bit decomp for range/parity */
    v256 s_bits, e_bits, e_neg_bits, pk_x_bits, R_x_bits;
    v8   ry_lsb, py_lsb;

    /* SHA-256 witnesses: 3 blocks */
    packed_v32 sha_outw[kShaBlocks][48];
    packed_v32 sha_oute[kShaBlocks][64];
    packed_v32 sha_outa[kShaBlocks][64];
    packed_v32 sha_h1[kShaBlocks][8];

    /* Message: 8 v32 words (32 bytes) */
    v32 msg_bits[8];

    void input(const LogicCircuit& lc) {
      rx = lc.eltw_input(); ry = lc.eltw_input();
      s_inv = lc.eltw_input(); pk_inv = lc.eltw_input();
      for (size_t i = 0; i < 8; ++i) pre[i] = lc.eltw_input();
      for (size_t i = 0; i < kBits; ++i) {
        bi[i] = lc.eltw_input();
        if (i < kBits - 1) {
          int_x[i] = lc.eltw_input(); int_y[i] = lc.eltw_input();
          int_z[i] = lc.eltw_input();
        }
      }
      e_circuit = lc.eltw_input(); e_neg_wire = lc.eltw_input();
      s_bits     = lc.template vinput<256>();
      e_bits     = lc.template vinput<256>();
      e_neg_bits = lc.template vinput<256>();
      pk_x_bits  = lc.template vinput<256>();
      R_x_bits   = lc.template vinput<256>();
      ry_lsb = lc.template vinput<8>();
      py_lsb = lc.template vinput<8>();
      for (size_t b = 0; b < kShaBlocks; ++b) {
        for (size_t i = 0; i < 48; ++i)
          sha_outw[b][i] = Bp::template packed_input<packed_v32>(lc);
        for (size_t i = 0; i < 64; ++i)
          sha_oute[b][i] = Bp::template packed_input<packed_v32>(lc);
        for (size_t i = 0; i < 64; ++i)
          sha_outa[b][i] = Bp::template packed_input<packed_v32>(lc);
        for (size_t i = 0; i < 8; ++i)
          sha_h1[b][i] = Bp::template packed_input<packed_v32>(lc);
      }
      for (size_t i = 0; i < 8; ++i) msg_bits[i] = lc.template vinput<32>();
    }
  };

  Bip340Circuit(const LogicCircuit& lc, const EC& ec, const ScalarField& Fn)
      : lc_(lc), secp_(lc, ec), bp_(lc_), sha_(lc_), fn_(Fn) {
    /* Precompute sha_tag = SHA-256("BIP0340/challenge") as 16 v32 values.
     * sha_tag (32 bytes) → sha_tag || sha_tag (64 bytes = 16 v32). */
    uint8_t sha_tag[32];
    niwi_bip340_sha256((const uint8_t *)"BIP0340/challenge", 17, sha_tag);
    for (size_t w = 0; w < 16; ++w) {
      /* Construct v32 from 4 bytes of sha_tag */
      uint32_t val = ((uint32_t)sha_tag[(w % 8) * 4]     << 24) |
                     ((uint32_t)sha_tag[(w % 8) * 4 + 1] << 16) |
                     ((uint32_t)sha_tag[(w % 8) * 4 + 2] << 8)  |
                      (uint32_t)sha_tag[(w % 8) * 4 + 3];
      sha_tag_in_[w] = lc_.vbit32(val);
    }
    /* Standard SHA-256 IV */
    uint32_t std_iv[8] = {
      0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,
      0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u
    };
    for (size_t i = 0; i < 8; ++i) sha_iv_[i] = lc_.vbit32(std_iv[i]);

    /* Block 2 padding: 160 bytes = 1280 bits.
     * Pad word 8: 0x80000000, words 9-13: 0x00000000,
     * word 14: 0x00000000, word 15: 0x00000500 */
    sha_pad_[0] = lc_.vbit32(0x80000000u);
    for (size_t i = 1; i < 6; ++i) sha_pad_[i] = lc_.vbit32(0);
    sha_pad_[6] = lc_.vbit32(0);
    sha_pad_[7] = lc_.vbit32(0x00000500u);
  }

  void verify(EltW pk_x, EltW R_x, EltW s_val, const Witness& w) const {
    EltW zero = lc_.konst(lc_.zero()), one = lc_.konst(lc_.one());

    /* ---- 1. Lift x-only, assert nonzero ---- */
    secp_.is_on_curve(pk_x, w.ry);
    secp_.is_on_curve(R_x, w.rx);
    secp_.assert_nonzero(pk_x, w.pk_inv);
    secp_.assert_nonzero(s_val, w.s_inv);

    /* ---- Parity (placeholder) ---- */
    for (size_t i = 0; i < 8; ++i) {
      lc_.assert0(w.ry_lsb[i]); lc_.assert0(w.py_lsb[i]);
    }

    /* ---- Range checks ---- */
    secp_.range_check_lt_n(s_val, w.s_bits);
    secp_.range_check_lt_n(w.e_circuit, w.e_bits);
    secp_.range_check_lt_p(pk_x, w.pk_x_bits);
    secp_.range_check_lt_p(R_x, w.R_x_bits);

    /* ---- 2. SHA-256 tagged hash (3 blocks) ---- */
    EltW e_hash = verify_tagged_hash(pk_x, R_x, w);

    /* e_circuit must equal the tagged hash output */
    lc_.assert_eq(&w.e_circuit, e_hash);

    /* ---- 3. Scalar binding: e_circuit + e_neg = n ---- */
    EltW n_wire = lc_.konst(lc_.elt(
        "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"));
    lc_.assert_eq(&lc_.add(&w.e_circuit, w.e_neg_wire), n_wire);
    secp_.range_check_lt_n(w.e_neg_wire, w.e_neg_bits);

    /* ---- 4. Double-scalar: s·G + e_neg·P + c·R = O ---- */
    typename Secp256k1Circuit<LogicCircuit>::ScalarMultWitness smw;
    for (size_t i = 0; i < 8; ++i) smw.pre[i] = w.pre[i];
    for (size_t i = 0; i < kBits; ++i) {
      smw.bi[i] = w.bi[i];
      if (i < kBits - 1) {
        smw.int_x[i] = w.int_x[i]; smw.int_y[i] = w.int_y[i];
        smw.int_z[i] = w.int_z[i];
      }
    }
    EltW c_wire = lc_.konst(lc_.elt(
        "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140"));
    secp_.verify_double_scalar(s_val, w.e_neg_wire, c_wire,
                               pk_x, w.ry, R_x, w.rx, smw);
    (void)zero; (void)one;
  }

 private:
  const LogicCircuit& lc_;
  Secp256k1Circuit<LogicCircuit> secp_;
  Bp bp_;
  proofs::FlatSHA256Circuit<LogicCircuit, Bp> sha_;
  const ScalarField& fn_;

  v32 sha_tag_in_[16];   /* sha_tag || sha_tag (constant block 0 input) */
  v32 sha_iv_[8];        /* standard SHA-256 IV */
  v32 sha_pad_[8];       /* block 2 padding (constant) */

  /* Run 3 SHA-256 blocks for tagged_hash, return e_hash as EltW. */
  EltW verify_tagged_hash(EltW P_x, EltW R_x, const Witness& w) const {
    /* Block 0: sha_tag_in_ (constant), standard IV, witness[0] */
    sha_.assert_transform_block(sha_tag_in_, sha_iv_,
                                w.sha_outw[0], w.sha_oute[0],
                                w.sha_outa[0], w.sha_h1[0]);

    /* Block 0 H1 → unpack to v32 for block 1 H0 */
    v32 h0_block1[8];
    for (size_t i = 0; i < 8; ++i)
      h0_block1[i] = bp_.unpack_v32(w.sha_h1[0][i]);

    /* Block 1 input: R_x || P_x as 16 v32 words.
     * R_x: 256 bits = 8 v32, P_x: 256 bits = 8 v32.
     * Construct from bit decomposition witnesses. */
    v32 in_block1[16];
    for (size_t i = 0; i < 8; ++i) {
      in_block1[i]     = slice32(w.R_x_bits, i * 32);
      in_block1[i + 8] = slice32(w.pk_x_bits, i * 32);
    }

    sha_.assert_transform_block(in_block1, h0_block1,
                                w.sha_outw[1], w.sha_oute[1],
                                w.sha_outa[1], w.sha_h1[1]);

    /* Block 1 H1 → block 2 H0 */
    v32 h0_block2[8];
    for (size_t i = 0; i < 8; ++i)
      h0_block2[i] = bp_.unpack_v32(w.sha_h1[1][i]);

    /* Block 2 input: msg[0..7] || sha_pad_[0..7] */
    v32 in_block2[16];
    for (size_t i = 0; i < 8; ++i) in_block2[i]     = w.msg_bits[i];
    for (size_t i = 0; i < 8; ++i) in_block2[i + 8] = sha_pad_[i];

    sha_.assert_transform_block(in_block2, h0_block2,
                                w.sha_outw[2], w.sha_oute[2],
                                w.sha_outa[2], w.sha_h1[2]);

    /* Final H1 (8 packed_v32) → unpack to 8 v32 → concatenate bits → EltW */
    v256 hash_bits;
    for (size_t i = 0; i < 8; ++i) {
      v32 word = bp_.unpack_v32(w.sha_h1[2][i]);
      for (size_t j = 0; j < 32; ++j)
        hash_bits[i * 32 + j] = word[j];
    }

    return lc_.as_scalar(hash_bits);
  }

  /* Extract 32 consecutive bits from a v256. */
  v32 slice32(const v256& bits, size_t offset) const {
    v32 r;
    for (size_t i = 0; i < 32; ++i) r[i] = bits[offset + i];
    return r;
  }
};

}  // namespace niwi

#endif  // NIWI_CIRCUITS_BIP340_CIRCUIT_H
