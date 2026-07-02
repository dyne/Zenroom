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

/* One-shot SHA-256. */
static void sha256(uint8_t out[32], const uint8_t *data, size_t len) {
    hash256 sha;
    HASH256_init(&sha);
    for (size_t i = 0; i < len; ++i)
        HASH256_process(&sha, data[i]);
    HASH256_hash(&sha, out);
}

/* Streaming SHA-256 for the iterative H-derivation loop. */
static void h_init(hash256 *h) { HASH256_init(h); }
static void h_update(hash256 *h, const uint8_t *data, size_t len) {
    for (size_t i = 0; i < len; ++i)
        HASH256_process(h, data[i]);
}
static void h_final(hash256 *h, uint8_t out[32]) {
    HASH256_hash(h, (char *)out);
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

/* ---- Pedersen primitives ----------------------------------------------- */

int niwi_pbsch_pedersen_commit(const uint8_t msg[32], const uint8_t rho[32],
                               uint8_t c_out[NIWI_PBSCH_CMP_SIZE]) {
    ECP_SECP256K1 H, C;
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
    uint8_t recomputed[33];
    if (niwi_pbsch_pedersen_commit(msg, rho, recomputed) != 0) return -1;
    return (memcmp(c, recomputed, 33) == 0) ? 0 : -1;
}
