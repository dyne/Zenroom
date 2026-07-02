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
 * Precomputes:
 *   - SHA-256 tagged_hash witness (3 blocks)
 *   - Double-scalar multiplication witness table for s·G == R + e·P
 */

template <class EC>
class Bip340Witness {
  using Field = typename EC::Field;
  using Elt   = typename Field::Elt;
  using Nat   = typename Field::N;
  using Point = typename EC::ECPoint;

 public:
  static constexpr size_t kBits = EC::kBits;

  /* Witness layout (matching circuit input order):
   *   rx, ry, s_inv, pk_inv
   *   pre[8]
   *   bi[kBits], int_x[kBits-1], int_y[kBits-1], int_z[kBits-1]
   *   e
   */
  Elt rx_, ry_, s_inv_, pk_inv_;
  Elt pre_[8];
  Elt bi_[kBits];
  Elt int_x_[kBits - 1];
  Elt int_y_[kBits - 1];
  Elt int_z_[kBits - 1];
  Elt e_challenge_;

  /* SHA-256 witness: padded input and block witness data for 3 blocks. */
  uint8_t  sha_padded[192];
  uint32_t sha_outw[3][48];
  uint32_t sha_oute[3][64];
  uint32_t sha_outa[3][64];
  uint32_t sha_h1[3][8];
  uint8_t  sha_num_blocks;

  Bip340Witness(const Field& F, const EC& ec) : f_(F), ec_(ec) {}

  bool compute(const uint8_t pk_bytes[32],
               const uint8_t R_bytes[32],
               const uint8_t s_bytes[32],
               const uint8_t msg[32]) {

    /* ---- Lift both x-only points ---- */
    const Elt one = f_.one();
    Elt pk_y, ry;

    auto elt_from_be32 = [&](const uint8_t be[32]) -> Elt {
        uint8_t le[32];
        for (size_t i = 0; i < 32; ++i) le[i] = be[31 - i];
        Nat n = Nat::of_bytes(le);
        return f_.to_montgomery(n);
    };

    Elt pk_x = elt_from_be32(pk_bytes);
    rx_ = elt_from_be32(R_bytes);

    uint8_t y_buf[32];
    if (niwi_bip340_lift_x(pk_bytes, y_buf) != 0) return false;
    pk_y = elt_from_be32(y_buf);

    if (niwi_bip340_lift_x(R_bytes, y_buf) != 0) return false;
    ry_ = elt_from_be32(y_buf);

    /* ---- Parse s scalar ---- */
    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) le[i] = s_bytes[31 - i];
    Nat s_nat = Nat::of_bytes(le);

    /* ---- Build SHA-256 tagged hash witness ---- */
    build_sha(R_bytes, pk_bytes, msg);

    /* Extract e from final block H1 output */
    uint8_t hash_out[32];
    for (size_t i = 0; i < 8; ++i) {
        hash_out[4*i]   = (sha_h1[2][i] >> 24) & 0xFF;
        hash_out[4*i+1] = (sha_h1[2][i] >> 16) & 0xFF;
        hash_out[4*i+2] = (sha_h1[2][i] >> 8)  & 0xFF;
        hash_out[4*i+3] = sha_h1[2][i] & 0xFF;
    }
    e_challenge_ = elt_from_be32(hash_out);

    /* ---- Build scalar-mul witness ---- */
    return build_scalar_mul(pk_x, pk_y, rx_, ry_, e_challenge_, s_nat);
  }

  void fill_witness(proofs::DenseFiller<Field>& filler) const {
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
  }

 private:
  const Field& f_;
  const EC& ec_;

  void build_sha(const uint8_t R_b[32], const uint8_t pk_b[32],
                 const uint8_t m[32]) {
    /* sha_tag = SHA-256("BIP0340/challenge") */
    uint8_t sha_tag[32];
    niwi_bip340_sha256((const uint8_t *)"BIP0340/challenge", 18, sha_tag);

    /* tagged hash preimage: sha_tag || sha_tag || R || pk || m = 160B */
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
                         const Elt e, const Nat& s_nat) {
    const Elt one = f_.one();

    Point G(ec_.gx_, ec_.gy_, one);
    Point P(pk_x, pk_y, one);
    Point R(rx, ry, one);

    /* Precompute table: GP, GR, PR, GPR (affine) */
    Point GP  = ec_.addEf(G, P);  ec_.normalize(GP);
    Point GR  = ec_.addEf(G, R);  ec_.normalize(GR);
    Point PR  = ec_.addEf(P, R);  ec_.normalize(PR);
    Point GPR = ec_.addEf(GP, R); ec_.normalize(GPR);

    pre_[0] = GP.x;   pre_[1] = GP.y;
    pre_[2] = GR.x;   pre_[3] = GR.y;
    pre_[4] = PR.x;   pre_[5] = PR.y;
    pre_[6] = GPR.x;  pre_[7] = GPR.y;

    /* Nonzero witnesses */
    Elt s_f = f_.to_montgomery(s_nat);
    s_inv_ = s_f; f_.invert(s_inv_);
    pk_inv_ = pk_x; f_.invert(pk_inv_);

    /* Bit decompositions */
    uint8_t s_b[kBits], e_b[kBits];
    {
        auto e_n = f_.from_montgomery(e);
        for (size_t i = 0; i < kBits; ++i) {
            s_b[i] = s_nat.bit(i) ? 1 : 0;
            e_b[i] = e_n.bit(i)   ? 1 : 0;
        }
    }

    /* Trace intermediate points */
    Elt ax = f_.zero(), ay = one, az = f_.zero();

    for (size_t i = 0; i < kBits; ++i) {
        size_t rev_i = kBits - 1 - i;
        /* Positive table skeleton: s*G + e*P + R = O.
         * Final BIP-340 needs n-e and n-1 scalar witnesses. */
        uint8_t bi = s_b[rev_i] + 2 * e_b[rev_i] + 4 * 1;
        bi_[i] = f_.of_scalar(2 * bi - 7);

        Point mux;
        switch (bi) {
            case 0: mux = ec_.zero(); break;
            case 1: mux = G;   break;
            case 2: mux = P;   break;
            case 3: mux = GP;  break;
            case 4: mux = R;   break;
            case 5: mux = GR;  break;
            case 6: mux = PR;  break;
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
