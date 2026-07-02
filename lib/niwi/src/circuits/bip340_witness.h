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

#ifndef NIWI_CIRCUITS_BIP340_WITNESS_H
#define NIWI_CIRCUITS_BIP340_WITNESS_H

#include <cstddef>
#include <cstdint>
#include <cstring>

#include "algebra/nat.h"
#include "arrays/dense.h"

#include "bip340_witness_bridge.h"
#include "circuits/sha/flatsha256_witness.h"

namespace niwi {

/* Native BIP-340 witness generator.
 *
 * Produces:
 *   - Scalar-mul witness for s·G + e_neg·P + c·R = O
 *     where e_neg = n - e,  c = n - 1  (both positive scalars < n)
 *   - SHA-256 tagged_hash witness (future, to be wired inside the circuit)
 */

template <class EC, class ScalarField>
class Bip340Witness {
  using Field = typename EC::Field;
  using Elt   = typename Field::Elt;
  using Nat   = typename Field::N;
  using Point = typename EC::ECPoint;

  static constexpr size_t kBits = EC::kBits;

 public:
  Elt rx_, ry_, s_inv_, pk_inv_;
  Elt pre_[8];
  Elt bi_[kBits];
  Elt int_x_[kBits - 1], int_y_[kBits - 1], int_z_[kBits - 1];
  Elt e_challenge_;
  Elt e_neg_;        /* n - e */
  Elt c_val_;        /* n - 1, used for bit-table witness generation */

  /* Bit decompositions for range/parity checks */
  Elt s_bits_[kBits], e_bits_[kBits], e_neg_bits_[kBits];
  Elt pk_x_bits_[kBits], R_x_bits_[kBits];
  Elt ry_lsb_[8], py_lsb_[8];
  Elt msg_bits_[256];     /* message bits for circuit SHA input */

  Bip340Witness(const Field& F, const EC& ec, const ScalarField& Fn)
      : f_(F), ec_(ec), fn_(Fn) {}

  bool compute(const uint8_t pk_bytes[32],
               const uint8_t R_bytes[32],
               const uint8_t s_bytes[32],
               const uint8_t msg[32]) {
    const Elt one = f_.one();

    auto elt_from_be32 = [&](const uint8_t be[32]) -> Elt {
        uint8_t le[32];
        for (size_t i = 0; i < 32; ++i) le[i] = be[31 - i];
        return f_.to_montgomery(Nat::of_bytes(le));
    };

    Elt pk_x  = elt_from_be32(pk_bytes);
    Elt rx    = elt_from_be32(R_bytes);

    uint8_t y_buf[32];
    if (niwi_bip340_lift_x(pk_bytes, y_buf) != 0) return false;
    Elt pk_y = elt_from_be32(y_buf);

    if (niwi_bip340_lift_x(R_bytes, y_buf) != 0) return false;
    rx_ = rx; ry_ = elt_from_be32(y_buf);

    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) le[i] = s_bytes[31 - i];
    Nat s_nat = Nat::of_bytes(le);

    /* Compute e_challenge = SHA-256 tagged hash output (native).
     * Wire the SHA witness for later in-circuit integration. */
    build_sha(R_bytes, pk_bytes, msg);
    {
        uint8_t hash_out[32];
        for (size_t i = 0; i < 8; ++i) {
            hash_out[4*i]   = (sha_h1[2][i] >> 24) & 0xFF;
            hash_out[4*i+1] = (sha_h1[2][i] >> 16) & 0xFF;
            hash_out[4*i+2] = (sha_h1[2][i] >> 8)  & 0xFF;
            hash_out[4*i+3] = sha_h1[2][i] & 0xFF;
        }
        e_challenge_ = elt_from_be32(hash_out);
    }

    (void)msg; /* SHA witness stored; used when circuit integration is ready */

    /* Compute e_neg = n - e  and  c = n - 1  (mod n).
     * Both are positive scalars < n. The circuit uses their actual bits. */
    {
        auto n_val = fn_.of_string(
            "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");
        auto e_n   = fn_.to_montgomery(f_.from_montgomery(e_challenge_));

        auto e_neg_n = fn_.subf(n_val, e_n);      /* n - e in scalar field */
        auto c_n     = fn_.subf(n_val, fn_.one()); /* n - 1 in scalar field */

        e_neg_ = f_.to_montgomery(fn_.from_montgomery(e_neg_n));
        c_val_ = f_.to_montgomery(fn_.from_montgomery(c_n));
    }

    /* ---- Bit decompositions for range checks and parity ---- */

    /* Helper: decompose a Nat into Elt bits */
    auto nat_to_bits = [&](const Nat& n, Elt* out) {
      for (size_t i = 0; i < kBits; ++i)
        out[i] = f_.of_scalar(n.bit(i) ? 1 : 0);
    };
    /* Helper: decompose an Elt (in Montgomery form) into Elt bits */
    auto elt_to_bits = [&](const Elt& e, Elt* out) {
      Nat n = f_.from_montgomery(e);
      nat_to_bits(n, out);
    };
    /* Helper: low 8 bits of an Elt */
    auto low8 = [&](const Elt& e, Elt* out) {
      Nat n = f_.from_montgomery(e);
      for (size_t i = 0; i < 8; ++i)
        out[i] = f_.of_scalar(n.bit(i) ? 1 : 0);
    };

    nat_to_bits(s_nat, s_bits_);
    elt_to_bits(e_challenge_, e_bits_);
    elt_to_bits(e_neg_, e_neg_bits_);
    elt_to_bits(pk_x, pk_x_bits_);
    elt_to_bits(rx, R_x_bits_);
    low8(ry_, ry_lsb_);
    low8(pk_y, py_lsb_);

    /* Message bits: 32 bytes = 256 field elements (0 or 1) */
    for (size_t i = 0; i < 32; ++i)
      for (size_t b = 0; b < 8; ++b)
        msg_bits_[i * 8 + b] = f_.of_scalar((msg[i] >> (7 - b)) & 1);

    return build_scalar_mul(pk_x, pk_y, rx_, ry_, e_neg_, c_val_, s_nat);
  }
    filler.push_back(rx_);
    filler.push_back(ry_);
    filler.push_back(s_inv_);
    filler.push_back(pk_inv_);
    for (size_t i = 0; i < 8; ++i) filler.push_back(pre_[i]);
    for (size_t i = 0; i < kBits; ++i) {
        filler.push_back(bi_[i]);
        if (i < kBits - 1) {
            filler.push_back(int_x_[i]);
            filler.push_back(int_y_[i]);
            filler.push_back(int_z_[i]);
        }
    }
    filler.push_back(e_challenge_);
    filler.push_back(e_neg_);
    /* Bit decompositions for range checks */
    for (size_t i = 0; i < kBits; ++i) filler.push_back(s_bits_[i]);
    for (size_t i = 0; i < kBits; ++i) filler.push_back(e_bits_[i]);
    for (size_t i = 0; i < kBits; ++i) filler.push_back(e_neg_bits_[i]);
    for (size_t i = 0; i < kBits; ++i) filler.push_back(pk_x_bits_[i]);
    for (size_t i = 0; i < kBits; ++i) filler.push_back(R_x_bits_[i]);
    /* Parity LSB bits */
    for (size_t i = 0; i < 8; ++i) filler.push_back(ry_lsb_[i]);
    for (size_t i = 0; i < 8; ++i) filler.push_back(py_lsb_[i]);

    /* SHA-256 witnesses: 3 blocks, packed_v32 encoding (7 field elements per uint32_t word) */
    {
      auto pack32 = [&](uint32_t val) {
        for (size_t g = 0; g < 6; ++g) {
          uint32_t bits = (val >> (5 * g)) & 0x1F;
          filler.push_back(f_.subf(f_.of_scalar(2 * bits), f_.of_scalar(31)));
        }
        uint32_t bits = (val >> 30) & 0x3;
        filler.push_back(f_.subf(f_.of_scalar(2 * bits), f_.of_scalar(3)));
      };
      for (size_t b = 0; b < 3; ++b) {
        for (size_t i = 0; i < 48; ++i) pack32(sha_outw[b][i]);
        for (size_t i = 0; i < 64; ++i) pack32(sha_oute[b][i]);
        for (size_t i = 0; i < 64; ++i) pack32(sha_outa[b][i]);
        for (size_t i = 0; i < 8;  ++i) pack32(sha_h1[b][i]);
      }
    }

    /* Message as 8 v32 = 256 field elements (one per bit) */
    for (size_t i = 0; i < 8; ++i)
      for (size_t j = 0; j < 32; ++j)
        filler.push_back(msg_bits_[i * 32 + j]);
  }

  /* SHA-256 witness data (for circuit integration) */
  uint8_t  sha_padded[192];
  uint32_t sha_outw[3][48], sha_oute[3][64], sha_outa[3][64], sha_h1[3][8];
  uint8_t  sha_num_blocks;
  uint8_t  sha_num_blocks;

 private:
  const Field& f_;
  const EC& ec_;
  const ScalarField& fn_;

  void build_sha(const uint8_t R_b[32], const uint8_t pk_b[32],
                 const uint8_t m[32]) {
    uint8_t sha_tag[32];
    niwi_bip340_sha256((const uint8_t *)"BIP0340/challenge", 18, sha_tag);

    uint8_t pre[160];
    memcpy(pre, sha_tag, 32);
    memcpy(pre + 32, sha_tag, 32);
    memcpy(pre + 64, R_b, 32);
    memcpy(pre + 96, pk_b, 32);
    memcpy(pre + 128, m, 32);

    proofs::FlatSHA256Witness::BlockWitness bw[3];
    uint8_t in[192];
    proofs::FlatSHA256Witness::transform_and_witness_message(
        160, pre, 3, sha_num_blocks, in, bw);
    memcpy(sha_padded, in, 192);
    for (size_t b = 0; b < 3; ++b) {
        memcpy(sha_outw[b], bw[b].outw, 48 * 4);
        memcpy(sha_oute[b], bw[b].oute, 64 * 4);
        memcpy(sha_outa[b], bw[b].outa, 64 * 4);
        memcpy(sha_h1[b],   bw[b].h1,   8 * 4);
    }
  }

  bool build_scalar_mul(const Elt pk_x, const Elt pk_y,
                         const Elt rx, const Elt ry,
                         const Elt e_neg, const Elt c_val,
                         const Nat& s_nat) {
    const Elt one = f_.one();

    Point G(ec_.gx_, ec_.gy_, one);
    Point P(pk_x, pk_y, one);
    Point R(rx, ry, one);

    Point GP  = ec_.addEf(G, P);  ec_.normalize(GP);
    Point GR  = ec_.addEf(G, R);  ec_.normalize(GR);
    Point PR  = ec_.addEf(P, R);  ec_.normalize(PR);
    Point GPR = ec_.addEf(GP, R); ec_.normalize(GPR);

    pre_[0] = GP.x;   pre_[1] = GP.y;
    pre_[2] = GR.x;   pre_[3] = GR.y;
    pre_[4] = PR.x;   pre_[5] = PR.y;
    pre_[6] = GPR.x;  pre_[7] = GPR.y;

    Elt s_f = f_.to_montgomery(s_nat);
    s_inv_ = s_f; f_.invert(s_inv_);
    pk_inv_ = pk_x; f_.invert(pk_inv_);

    /* Bit decompositions of s, e_neg, c (all positive scalars) */
    uint8_t bs[kBits], be[kBits], bc[kBits];
    {
        auto e_n = f_.from_montgomery(e_neg);
        auto c_n = f_.from_montgomery(c_val);
        for (size_t i = 0; i < kBits; ++i) {
            bs[i] = s_nat.bit(i) ? 1 : 0;
            be[i] = e_n.bit(i)   ? 1 : 0;
            bc[i] = c_n.bit(i)   ? 1 : 0;
        }
    }

    Elt ax = f_.zero(), ay = one, az = f_.zero();
    for (size_t i = 0; i < kBits; ++i) {
        size_t rev = kBits - 1 - i;
        uint8_t bi = bs[rev] + 2 * be[rev] + 4 * bc[rev];
        bi_[i] = f_.of_scalar(bi);  /* raw 0..7, not centered */

        Point mux;
        switch (bi) {
            case 0: mux = ec_.zero(); break;
            case 1: mux = G;  break;
            case 2: mux = P;  break;
            case 3: mux = GP; break;
            case 4: mux = R;  break;
            case 5: mux = GR; break;
            case 6: mux = PR; break;
            case 7: mux = GPR; break;
            default: return false;
        }

        if (i > 0) ec_.doubleE(ax, ay, az, ax, ay, az);
        ec_.addE(ax, ay, az, ax, ay, az, mux.x, mux.y, mux.z);

        if (i < kBits - 1) {
            int_x_[i] = ax; int_y_[i] = ay; int_z_[i] = az;
        }
    }
    return ax == f_.zero() && az == f_.zero();
  }
};

}  // namespace niwi

#endif  // NIWI_CIRCUITS_BIP340_WITNESS_H
