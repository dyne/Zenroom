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

#include "pbsch_commitment.h"

#include <string.h>

#include "amcl.h"
#include "ecp_SECP256K1.h"

/* ---- Deterministic scalar multiplication (double-and-add) ---------------
 *
 * ECP_SECP256K1_mul internally uses BIG_256_28_randomnum for side-channel
 * randomization, making it non-deterministic. For Pedersen commitments
 * (which MUST be deterministic within a session), we implement a simple
 * double-and-add using the deterministic ECP_SECP256K1_dbl and _add.
 *
 * This is not constant-time and should not be used for secret-dependent
 * scalars in production. For Pedersen, the scalar is a message or derived
 * blinding value — not a secret key. */

static void ecp_mul_deterministic(ECP_SECP256K1 *P, BIG_256_28 e) {
    if (BIG_256_28_iszilch(e)) { ECP_SECP256K1_inf(P); return; }

    ECP_SECP256K1 R;
    ECP_SECP256K1_inf(&R);

    int nb = BIG_256_28_nbits(e);
    for (int i = nb - 1; i >= 0; --i) {
        ECP_SECP256K1_dbl(&R);
        if (BIG_256_28_bit(e, i)) {
            ECP_SECP256K1_add(&R, P);
        }
    }
    ECP_SECP256K1_copy(P, &R);
}

/* ---- Internal helpers -------------------------------------------------- */

/* Streaming SHA-256 for the iterative H-derivation loop. */
static void h_init(hash256 *h) { HASH256_init(h); }
static void h_update(hash256 *h, const uint8_t *data, size_t len) {
    for (size_t i = 0; i < len; ++i)
        HASH256_process(h, data[i]);
}
static void h_final(hash256 *h, uint8_t out[32]) {
    HASH256_hash(h, (char *)out);
}

static void h_u16_be(hash256 *h, uint16_t n) {
    uint8_t b[2] = {(uint8_t)(n >> 8), (uint8_t)(n & 0xff)};
    h_update(h, b, sizeof(b));
}

static void h_u32_be(hash256 *h, uint32_t n) {
    uint8_t b[4] = {
        (uint8_t)(n >> 24), (uint8_t)(n >> 16),
        (uint8_t)(n >> 8), (uint8_t)(n & 0xff)};
    h_update(h, b, sizeof(b));
}

/* ---- H generator ------------------------------------------------------- */

static uint8_t g_h_x[32];
static int g_h_ready = 0;

static int derive_h(ECP_SECP256K1 *H) {
    static const char kTag[] = "Zenroom/PBSch/PedersenH/v1";
    uint8_t digest[32];
    int iteration = 0;

    for (;;) {
        hash256 ctx;
        h_init(&ctx);
        h_update(&ctx, (const uint8_t *)kTag, strlen(kTag));
        if (iteration > 0) {
            uint8_t c = (uint8_t)(iteration & 0xFF);
            h_update(&ctx, &c, 1);
        }
        h_final(&ctx, digest);

        BIG_256_28 x;
        BIG_256_28_fromBytes(x, (char *)digest);
        BIG_256_28 p;
        BIG_256_28_rcopy(p, Modulus_SECP256K1);
        if (BIG_256_28_comp(x, p) >= 0) { iteration++; continue; }
        if (ECP_SECP256K1_setx(H, x, 0)) { ECP_SECP256K1_affine(H); return 0; }
        iteration++;
    }
}

static int scalar_is_canonical(const uint8_t scalar[32]) {
    BIG_256_28 value;
    BIG_256_28 order;
    BIG_256_28_fromBytes(value, (char *)scalar);
    BIG_256_28_copy(order, (chunk *)CURVE_Order_SECP256K1);
    return BIG_256_28_comp(value, order) < 0;
}

static int scalar_is_nonzero_canonical(const uint8_t scalar[32]) {
    BIG_256_28 value, zero, order;
    BIG_256_28_zero(zero);
    BIG_256_28_fromBytes(value, (char *)scalar);
    BIG_256_28_copy(order, (chunk *)CURVE_Order_SECP256K1);
    return BIG_256_28_comp(value, zero) != 0 &&
           BIG_256_28_comp(value, order) < 0;
}

static int point_from_compressed(ECP_SECP256K1 *P,
                                 const uint8_t c[NIWI_PBSCH_CMP_SIZE]) {
    if (!P || !c || (c[0] != 0x02 && c[0] != 0x03)) return -1;
    BIG_256_28 x;
    BIG_256_28_fromBytes(x, (char *)(c + 1));
    return ECP_SECP256K1_setx(P, x, c[0] & 1) ? 0 : -1;
}

static void point_compressed(const ECP_SECP256K1 *P,
                             uint8_t out[NIWI_PBSCH_CMP_SIZE]) {
    BIG_256_28 x, y;
    ECP_SECP256K1 Q;
    ECP_SECP256K1_copy(&Q, (ECP_SECP256K1 *)P);
    ECP_SECP256K1_affine(&Q);
    ECP_SECP256K1_get(x, y, &Q);
    out[0] = (BIG_256_28_parity(y) == 1) ? 0x03 : 0x02;
    BIG_256_28_toBytes((char *)(out + 1), x);
}

static void scalar_to_bytes(const BIG_256_28 x, uint8_t out[32]) {
    BIG_256_28 t;
    BIG_256_28_copy(t, (chunk *)x);
    BIG_256_28_norm(t);
    BIG_256_28_toBytes((char *)out, t);
}

static void scalar_addmul(BIG_256_28 out, const BIG_256_28 a,
                          uint16_t ch, const BIG_256_28 m) {
    BIG_256_28 order, ch_big, prod;
    DBIG_256_28 dprod;
    BIG_256_28_copy(order, (chunk *)CURVE_Order_SECP256K1);
    BIG_256_28_zero(ch_big);
    BIG_256_28_inc(ch_big, ch);
    BIG_256_28_norm(ch_big);
    BIG_256_28_mul(dprod, ch_big, (chunk *)m);
    BIG_256_28_dmod(prod, dprod, order);
    BIG_256_28_add(out, (chunk *)a, prod);
    BIG_256_28_norm(out);
    BIG_256_28_mod(out, order);
}

static int derive_scalar(const uint8_t seed[32], uint32_t attempt,
                         uint16_t i, uint8_t which, BIG_256_28 out) {
    static const char tag[] = "Zenroom/PBSch/CMT3/native-nonce/v1";
    uint8_t digest[32];
    for (uint32_t counter = 0; counter < 65536; ++counter) {
        hash256 h;
        h_init(&h);
        h_update(&h, (const uint8_t *)tag, strlen(tag));
        h_update(&h, seed, 32);
        h_u32_be(&h, attempt);
        h_u16_be(&h, i);
        h_update(&h, &which, 1);
        h_u32_be(&h, counter);
        h_final(&h, digest);
        if (scalar_is_nonzero_canonical(digest)) {
            BIG_256_28_fromBytes(out, (char *)digest);
            return 0;
        }
    }
    return -1;
}

static uint16_t cmt3_hash_value(const uint8_t ck[32],
                                const uint8_t c[NIWI_PBSCH_CMP_SIZE],
                                const uint8_t all_A[10 * NIWI_PBSCH_CMP_SIZE],
                                uint16_t i, uint16_t ch,
                                const uint8_t z_m[32],
                                const uint8_t z_r[32]) {
    static const char domain[] = "Zenroom/PBSch/CMT3/Fischlin05/v1";
    uint8_t digest[32];
    hash256 h;
    h_init(&h);
    h_update(&h, (const uint8_t *)domain, strlen(domain));
    h_update(&h, ck, 32);
    h_update(&h, c, NIWI_PBSCH_CMP_SIZE);
    h_update(&h, all_A, 10 * NIWI_PBSCH_CMP_SIZE);
    h_u16_be(&h, i);
    h_u16_be(&h, ch);
    h_update(&h, z_m, 32);
    h_update(&h, z_r, 32);
    h_final(&h, digest);
    return (uint16_t)((((uint16_t)digest[0] << 8) | digest[1]) & 0x01ff);
}

uint16_t niwi_pbsch_cmt3_hash_value(
    const uint8_t ck[32], const uint8_t c[NIWI_PBSCH_CMP_SIZE],
    const uint8_t all_A[10 * NIWI_PBSCH_CMP_SIZE], uint16_t i,
    uint16_t ch, const uint8_t z_m[32], const uint8_t z_r[32]) {
    if (!ck || !c || !all_A || !z_m || !z_r) return 0xffff;
    return cmt3_hash_value(ck, c, all_A, i, ch, z_m, z_r);
}

static size_t cmt3_write_query_row(
    uint8_t *out, const uint8_t c[NIWI_PBSCH_CMP_SIZE],
    const uint8_t ck[32], const uint8_t all_A[10 * NIWI_PBSCH_CMP_SIZE],
    uint16_t i, uint16_t ch, const uint8_t z_m[32],
    const uint8_t z_r[32], uint16_t h, uint8_t selected) {
    size_t off = 0;
    memcpy(out + off, c, NIWI_PBSCH_CMP_SIZE); off += NIWI_PBSCH_CMP_SIZE;
    memcpy(out + off, ck, 32); off += 32;
    memcpy(out + off, all_A, 10 * NIWI_PBSCH_CMP_SIZE);
    off += 10 * NIWI_PBSCH_CMP_SIZE;
    out[off++] = (uint8_t)(i >> 8);
    out[off++] = (uint8_t)(i & 0xff);
    out[off++] = (uint8_t)(ch >> 8);
    out[off++] = (uint8_t)(ch & 0xff);
    memcpy(out + off, z_m, 32); off += 32;
    memcpy(out + off, z_r, 32); off += 32;
    out[off++] = (uint8_t)(h >> 8);
    out[off++] = (uint8_t)(h & 0xff);
    out[off++] = selected ? 1 : 0;
    return off;
}

static void cmt3_sigma_commit(const ECP_SECP256K1 *H, const BIG_256_28 a,
                              const BIG_256_28 b, ECP_SECP256K1 *A) {
    ECP_SECP256K1 G, bH;
    ECP_SECP256K1_generator(&G);
    ecp_mul_deterministic(&G, (chunk *)a);
    ECP_SECP256K1_copy(&bH, (ECP_SECP256K1 *)H);
    ecp_mul_deterministic(&bH, (chunk *)b);
    ECP_SECP256K1_add(&G, &bH);
    ECP_SECP256K1_affine(&G);
    ECP_SECP256K1_copy(A, &G);
}

int niwi_pbsch_pedersen_h(uint8_t h_x_out[32]) {
    if (g_h_ready) { memcpy(h_x_out, g_h_x, 32); return 0; }
    ECP_SECP256K1 H;

    /* H derivation uses ECP_SECP256K1_setx, not mul, so it is deterministic.
     * But the RNG save/restore is not needed here. */
    if (derive_h(&H) != 0) return -1;
    /* Manual compressed serialization */
    {
        BIG_256_28 x, y;
        ECP_SECP256K1_get(x, y, &H);
        if (BIG_256_28_parity(y) != 0) return -1;  /* must be even */
        BIG_256_28_toBytes((char *)g_h_x, x);
    }
    g_h_ready = 1;
    memcpy(h_x_out, g_h_x, 32);
    return 0;
}

/* ---- Pedersen primitives -----------------------------------------------
 *
 * PBSch Cmt profile: canonical binding Pedersen commitment over secp256k1.
 * The straight-line extractable CMT1 opening envelope is built in Lua so the
 * encoding remains readable; this native layer owns scalar validation and
 * deterministic curve arithmetic. Native RPBSch LZK0 verifies these openings,
 * but the profile is still not the paper-exact Cmt construction. */

int niwi_pbsch_pedersen_commit(const uint8_t msg[32], const uint8_t rho[32],
                               uint8_t c_out[NIWI_PBSCH_CMP_SIZE]) {
    ECP_SECP256K1 H, C;
    if (!msg || !rho || !c_out) return -1;
    if (!scalar_is_canonical(msg) || !scalar_is_canonical(rho)) return -1;
    if (niwi_pbsch_pedersen_h(g_h_x) < 0) return -1;

    /* get H from cached x via setx(0) */
    BIG_256_28 hx;
    BIG_256_28_fromBytes(hx, (char *)g_h_x);
    if (!ECP_SECP256K1_setx(&H, hx, 0)) return -1;
    ECP_SECP256K1_affine(&H);

    BIG_256_28 m_big, r_big;
    BIG_256_28_fromBytes(m_big, (char *)msg);
    BIG_256_28_fromBytes(r_big, (char *)rho);

    /* C = m·G */
    ECP_SECP256K1_generator(&C);
    ecp_mul_deterministic(&C, m_big);

    /* rH = r·H */
    ECP_SECP256K1 rH;
    ECP_SECP256K1_copy(&rH, &H);
    ecp_mul_deterministic(&rH, r_big);

    /* C += rH */
    ECP_SECP256K1_add(&C, &rH);
    ECP_SECP256K1_affine(&C);

    /* Manual compressed serialization (avoiding _toOctet issues).
     * BIP-340 convention: 0x02 for even y, 0x03 for odd y. */
    {
        BIG_256_28 x, y;
        ECP_SECP256K1_get(x, y, &C);
        c_out[0] = (BIG_256_28_parity(y) == 1) ? 0x03 : 0x02;
        BIG_256_28_toBytes((char *)(c_out + 1), x);
    }
    return 0;
}

int niwi_pbsch_pedersen_verify(const uint8_t c[NIWI_PBSCH_CMP_SIZE],
                               const uint8_t msg[32], const uint8_t rho[32]) {
    if (!c || !msg || !rho) return -1;
    uint8_t recomputed[33];
    if (niwi_pbsch_pedersen_commit(msg, rho, recomputed) != 0) return -1;
    return (memcmp(c, recomputed, 33) == 0) ? 0 : -1;
}

int niwi_pbsch_cmt3_prove_seeded(
    const uint8_t c[NIWI_PBSCH_CMP_SIZE], const uint8_t msg[32],
    const uint8_t rho[32], const uint8_t seed[32],
    uint8_t proof_out[NIWI_PBSCH_CMT3_PROOF_SIZE]) {
    enum { R = 10, T = 12, S_BOUND = 10 };
    if (!c || !msg || !rho || !seed || !proof_out) return -1;
    if (!scalar_is_canonical(msg) || !scalar_is_canonical(rho)) return -1;
    if (niwi_pbsch_pedersen_verify_lf(c, msg, rho) != 0) return -1;

    uint8_t ck[32];
    if (niwi_pbsch_pedersen_h(ck) != 0) return -1;

    ECP_SECP256K1 H;
    BIG_256_28 hx, m_big, r_big;
    BIG_256_28_fromBytes(hx, (char *)ck);
    if (!ECP_SECP256K1_setx(&H, hx, 0)) return -1;
    ECP_SECP256K1_affine(&H);
    BIG_256_28_fromBytes(m_big, (char *)msg);
    BIG_256_28_fromBytes(r_big, (char *)rho);

    for (uint32_t attempt = 0; attempt < 1024; ++attempt) {
        BIG_256_28 a[R], b[R];
        ECP_SECP256K1 A[R];
        uint8_t all_A[R * NIWI_PBSCH_CMP_SIZE];
        uint16_t selected_ch[R];
        uint8_t selected_z_m[R][32];
        uint8_t selected_z_r[R][32];
        uint32_t threshold_sum = 0;

        for (uint16_t i = 0; i < R; ++i) {
            if (derive_scalar(seed, attempt, i + 1, 'a', a[i]) != 0 ||
                derive_scalar(seed, attempt, i + 1, 'b', b[i]) != 0) {
                return -1;
            }
            cmt3_sigma_commit(&H, a[i], b[i], &A[i]);
            point_compressed(&A[i], all_A + i * NIWI_PBSCH_CMP_SIZE);
        }

        for (uint16_t i = 0; i < R; ++i) {
            uint16_t best_ch = 0;
            uint16_t best_hash = 0xffff;
            uint8_t best_z_m[32], best_z_r[32];

            for (uint16_t ch = 0; ch < (1u << T); ++ch) {
                BIG_256_28 z_m_big, z_r_big;
                uint8_t z_m[32], z_r[32];
                uint16_t h;

                scalar_addmul(z_m_big, a[i], ch, m_big);
                scalar_addmul(z_r_big, b[i], ch, r_big);
                scalar_to_bytes(z_m_big, z_m);
                scalar_to_bytes(z_r_big, z_r);
                h = cmt3_hash_value(ck, c, all_A, i + 1, ch, z_m, z_r);
                if (h < best_hash) {
                    best_hash = h;
                    best_ch = ch;
                    memcpy(best_z_m, z_m, 32);
                    memcpy(best_z_r, z_r, 32);
                }
                if (h == 0) break;
            }

            selected_ch[i] = best_ch;
            memcpy(selected_z_m[i], best_z_m, 32);
            memcpy(selected_z_r[i], best_z_r, 32);
            threshold_sum += best_hash;
            if (threshold_sum > S_BOUND) break;
        }

        if (threshold_sum <= S_BOUND) {
            size_t off = 0;
            memcpy(proof_out + off, "CMT3", 4); off += 4;
            proof_out[off++] = 0x01;
            memcpy(proof_out + off, ck, 32); off += 32;
            memcpy(proof_out + off, all_A, sizeof(all_A)); off += sizeof(all_A);
            for (uint16_t i = 0; i < R; ++i) {
                proof_out[off++] = (uint8_t)(selected_ch[i] >> 8);
                proof_out[off++] = (uint8_t)(selected_ch[i] & 0xff);
            }
            for (uint16_t i = 0; i < R; ++i) {
                memcpy(proof_out + off, selected_z_m[i], 32); off += 32;
            }
            for (uint16_t i = 0; i < R; ++i) {
                memcpy(proof_out + off, selected_z_r[i], 32); off += 32;
            }
            return off == NIWI_PBSCH_CMT3_PROOF_SIZE ? 0 : -1;
        }
    }

    return -1;
}

int niwi_pbsch_cmt3_prove_seeded_observed(
    const uint8_t c[NIWI_PBSCH_CMP_SIZE], const uint8_t msg[32],
    const uint8_t rho[32], const uint8_t seed[32],
    uint8_t proof_out[NIWI_PBSCH_CMT3_PROOF_SIZE],
    uint8_t queries_out[NIWI_PBSCH_CMT3_QUERY_MAX_SIZE],
    size_t *queries_len) {
    enum { R = 10, T = 12, S_BOUND = 10 };
    if (!queries_len) return -1;
    *queries_len = 0;
    if (!c || !msg || !rho || !seed || !proof_out || !queries_out) return -1;
    if (!scalar_is_canonical(msg) || !scalar_is_canonical(rho)) return -1;
    if (niwi_pbsch_pedersen_verify_lf(c, msg, rho) != 0) return -1;

    uint8_t ck[32];
    if (niwi_pbsch_pedersen_h(ck) != 0) return -1;

    ECP_SECP256K1 H;
    BIG_256_28 hx, m_big, r_big;
    BIG_256_28_fromBytes(hx, (char *)ck);
    if (!ECP_SECP256K1_setx(&H, hx, 0)) return -1;
    ECP_SECP256K1_affine(&H);
    BIG_256_28_fromBytes(m_big, (char *)msg);
    BIG_256_28_fromBytes(r_big, (char *)rho);

    for (uint32_t attempt = 0; attempt < 1024; ++attempt) {
        BIG_256_28 a[R], b[R];
        ECP_SECP256K1 A[R];
        uint8_t all_A[R * NIWI_PBSCH_CMP_SIZE];
        uint16_t selected_ch[R], selected_hash[R];
        uint16_t alt_ch[R], alt_hash[R];
        uint8_t selected_z_m[R][32], selected_z_r[R][32];
        uint8_t alt_z_m[R][32], alt_z_r[R][32];
        uint8_t has_alt[R];
        uint32_t threshold_sum = 0;

        memset(has_alt, 0, sizeof(has_alt));
        for (uint16_t i = 0; i < R; ++i) {
            if (derive_scalar(seed, attempt, i + 1, 'a', a[i]) != 0 ||
                derive_scalar(seed, attempt, i + 1, 'b', b[i]) != 0) {
                return -1;
            }
            cmt3_sigma_commit(&H, a[i], b[i], &A[i]);
            point_compressed(&A[i], all_A + i * NIWI_PBSCH_CMP_SIZE);
        }

        for (uint16_t i = 0; i < R; ++i) {
            uint16_t best_ch = 0;
            uint16_t best_hash = 0xffff;
            uint8_t best_z_m[32], best_z_r[32];
            int has_best = 0;

            for (uint16_t ch = 0; ch < (1u << T); ++ch) {
                BIG_256_28 z_m_big, z_r_big;
                uint8_t z_m[32], z_r[32];
                uint16_t h;

                scalar_addmul(z_m_big, a[i], ch, m_big);
                scalar_addmul(z_r_big, b[i], ch, r_big);
                scalar_to_bytes(z_m_big, z_m);
                scalar_to_bytes(z_r_big, z_r);
                h = cmt3_hash_value(ck, c, all_A, i + 1, ch, z_m, z_r);
                if (!has_best || h < best_hash) {
                    if (has_best && !has_alt[i]) {
                        alt_ch[i] = best_ch;
                        alt_hash[i] = best_hash;
                        memcpy(alt_z_m[i], best_z_m, 32);
                        memcpy(alt_z_r[i], best_z_r, 32);
                        has_alt[i] = 1;
                    }
                    best_ch = ch;
                    best_hash = h;
                    memcpy(best_z_m, z_m, 32);
                    memcpy(best_z_r, z_r, 32);
                    has_best = 1;
                } else if (!has_alt[i]) {
                    alt_ch[i] = ch;
                    alt_hash[i] = h;
                    memcpy(alt_z_m[i], z_m, 32);
                    memcpy(alt_z_r[i], z_r, 32);
                    has_alt[i] = 1;
                }
                if (best_hash == 0 && has_alt[i]) break;
            }

            selected_ch[i] = best_ch;
            selected_hash[i] = best_hash;
            memcpy(selected_z_m[i], best_z_m, 32);
            memcpy(selected_z_r[i], best_z_r, 32);
            threshold_sum += best_hash;
            if (threshold_sum > S_BOUND) break;
        }

        if (threshold_sum <= S_BOUND) {
            size_t off = 0;
            memcpy(proof_out + off, "CMT3", 4); off += 4;
            proof_out[off++] = 0x01;
            memcpy(proof_out + off, ck, 32); off += 32;
            memcpy(proof_out + off, all_A, sizeof(all_A)); off += sizeof(all_A);
            for (uint16_t i = 0; i < R; ++i) {
                proof_out[off++] = (uint8_t)(selected_ch[i] >> 8);
                proof_out[off++] = (uint8_t)(selected_ch[i] & 0xff);
            }
            for (uint16_t i = 0; i < R; ++i) {
                memcpy(proof_out + off, selected_z_m[i], 32); off += 32;
            }
            for (uint16_t i = 0; i < R; ++i) {
                memcpy(proof_out + off, selected_z_r[i], 32); off += 32;
            }
            if (off != NIWI_PBSCH_CMT3_PROOF_SIZE) return -1;

            size_t qoff = 0;
            uint16_t rows = 0;
            memcpy(queries_out + qoff, "CQ3Q", 4); qoff += 4;
            qoff += 2;
            for (uint16_t i = 0; i < R; ++i) {
                qoff += cmt3_write_query_row(
                    queries_out + qoff, c, ck, all_A, i + 1, selected_ch[i],
                    selected_z_m[i], selected_z_r[i], selected_hash[i], 1);
                rows++;
                if (has_alt[i]) {
                    qoff += cmt3_write_query_row(
                        queries_out + qoff, c, ck, all_A, i + 1, alt_ch[i],
                        alt_z_m[i], alt_z_r[i], alt_hash[i], 0);
                    rows++;
                }
            }
            queries_out[4] = (uint8_t)(rows >> 8);
            queries_out[5] = (uint8_t)(rows & 0xff);
            *queries_len = qoff;
            return 0;
        }
    }

    return -1;
}

static uint32_t read_u32_be(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | (uint32_t)p[3];
}

int niwi_pbsch_cmt3_verify(const uint8_t c[NIWI_PBSCH_CMP_SIZE],
                           const uint8_t proof[NIWI_PBSCH_CMT3_PROOF_SIZE]) {
    enum { R = 10, T = 12, S_BOUND = 10 };
    if (!c || !proof) return -1;
    if (point_from_compressed(&(ECP_SECP256K1){0}, c) != 0) return -1;
    if (memcmp(proof, "CMT3", 4) != 0 || proof[4] != 0x01) return -1;

    const uint8_t *ck = proof + 5;
    uint8_t expected_ck[32];
    if (niwi_pbsch_pedersen_h(expected_ck) != 0 ||
        memcmp(ck, expected_ck, 32) != 0) {
        return -1;
    }

    const uint8_t *all_A = proof + 37;
    const uint8_t *ch_bytes = all_A + R * NIWI_PBSCH_CMP_SIZE;
    const uint8_t *z_m = ch_bytes + 2 * R;
    const uint8_t *z_r = z_m + 32 * R;
    ECP_SECP256K1 C, H;
    BIG_256_28 hx;
    uint32_t threshold_sum = 0;

    if (point_from_compressed(&C, c) != 0) return -1;
    BIG_256_28_fromBytes(hx, (char *)ck);
    if (!ECP_SECP256K1_setx(&H, hx, 0)) return -1;
    ECP_SECP256K1_affine(&H);

    for (uint16_t i = 0; i < R; ++i) {
        const uint8_t *A_bytes = all_A + i * NIWI_PBSCH_CMP_SIZE;
        const uint8_t *zi_m = z_m + i * 32;
        const uint8_t *zi_r = z_r + i * 32;
        uint16_t ch = (uint16_t)(((uint16_t)ch_bytes[2 * i] << 8) |
                                 ch_bytes[2 * i + 1]);
        ECP_SECP256K1 A, lhs, rhs, zH;
        BIG_256_28 zm_big, zr_big, ch_big;
        uint16_t h;

        if (ch >= (1u << T) ||
            !scalar_is_canonical(zi_m) || !scalar_is_canonical(zi_r) ||
            point_from_compressed(&A, A_bytes) != 0) {
            return -1;
        }

        BIG_256_28_fromBytes(zm_big, (char *)zi_m);
        BIG_256_28_fromBytes(zr_big, (char *)zi_r);
        ECP_SECP256K1_generator(&lhs);
        ecp_mul_deterministic(&lhs, zm_big);
        ECP_SECP256K1_copy(&zH, &H);
        ecp_mul_deterministic(&zH, zr_big);
        ECP_SECP256K1_add(&lhs, &zH);
        ECP_SECP256K1_affine(&lhs);

        BIG_256_28_zero(ch_big);
        BIG_256_28_inc(ch_big, ch);
        BIG_256_28_norm(ch_big);
        ECP_SECP256K1_copy(&rhs, &C);
        ecp_mul_deterministic(&rhs, ch_big);
        ECP_SECP256K1_add(&rhs, &A);
        ECP_SECP256K1_affine(&rhs);
        if (!ECP_SECP256K1_equals(&lhs, &rhs)) return -1;

        h = cmt3_hash_value(ck, c, all_A, i + 1, ch, zi_m, zi_r);
        threshold_sum += h;
        if (threshold_sum > S_BOUND) return -1;
    }

    return 0;
}

int niwi_rpbsch_parse_full_statement(const uint8_t *buf, size_t len,
                                     niwi_rpbsch_statement_t *out) {
    size_t off = 0;

    if (!buf || !out || len != NIWI_RPBSCH_FULL_STATEMENT_SIZE) return -1;
    if (memcmp(buf, "RPB2", 4) != 0) return -1;
    off = 4;

    if (read_u32_be(buf + off) != NIWI_RPBSCH_CORE_STATEMENT_SIZE) return -1;
    off += 4;
    memcpy(out->core, buf + off, NIWI_RPBSCH_CORE_STATEMENT_SIZE);
    memcpy(out->C, buf + off + 128, NIWI_PBSCH_CMP_SIZE);
    memcpy(out->S, buf + off + 225, NIWI_PBSCH_CMP_SIZE);
    off += NIWI_RPBSCH_CORE_STATEMENT_SIZE;

    if (read_u32_be(buf + off) != NIWI_PBSCH_CMT3_PROOF_SIZE) return -1;
    off += 4;
    memcpy(out->C_proof, buf + off, NIWI_PBSCH_CMT3_PROOF_SIZE);
    off += NIWI_PBSCH_CMT3_PROOF_SIZE;

    if (read_u32_be(buf + off) != NIWI_PBSCH_CMT3_PROOF_SIZE) return -1;
    off += 4;
    memcpy(out->S_proof, buf + off, NIWI_PBSCH_CMT3_PROOF_SIZE);
    off += NIWI_PBSCH_CMT3_PROOF_SIZE;

    return off == len ? 0 : -1;
}

int niwi_rpbsch_validate_full_statement(const uint8_t *buf, size_t len,
                                        niwi_rpbsch_statement_t *out) {
    niwi_rpbsch_statement_t parsed;
    niwi_rpbsch_statement_t *dst = out ? out : &parsed;

    /* Lua repeats these checks for API-facing defense in depth. Keep native
     * parsing and proof binding here as the authoritative protocol boundary. */
    if (niwi_rpbsch_parse_full_statement(buf, len, dst) != 0) return -1;
    if (niwi_pbsch_cmt3_verify(dst->C, dst->C_proof) != 0) return -1;
    if (niwi_pbsch_cmt3_verify(dst->S, dst->S_proof) != 0) return -1;
    return 0;
}
