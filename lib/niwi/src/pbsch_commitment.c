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
static void sha256_stream_init(hash256 *h) { HASH256_init(h); }
static void sha256_stream_update(hash256 *h, const uint8_t *data, size_t len) {
    for (size_t i = 0; i < len; ++i)
        HASH256_process(h, data[i]);
}
static void sha256_stream_final(hash256 *h, uint8_t out[32]) {
    HASH256_hash(h, (char *)out);
}

/* Derive the independent Pedersen generator H.
 * H = lift_x(SHA-256("Zenroom/PBSch/PedersenH/v1" || iteration)).
 * Uses iterative hashing if the x-coordinate fails lift_x. */
static int derive_pedersen_h(ECP_SECP256K1 *H) {
    static const char kTag[] = "Zenroom/PBSch/PedersenH/v1";
    uint8_t digest[32];
    int iteration = 0;

    for (;;) {
        hash256 ctx;
        sha256_stream_init(&ctx);
        sha256_stream_update(&ctx, (const uint8_t *)kTag, strlen(kTag));
        if (iteration > 0) {
            uint8_t c = (uint8_t)(iteration & 0xFF);
            sha256_stream_update(&ctx, &c, 1);
        }
        sha256_stream_final(&ctx, digest);

        /* BIP-340-style lift_x: setx(s=0) gives y with LSB == 0 (even). */
        BIG_256_28 x;
        BIG_256_28_fromBytes(x, (char *)digest);
        /* x < p check */
        BIG_256_28 p;
        BIG_256_28_rcopy(p, Modulus_SECP256K1);
        if (BIG_256_28_comp(x, p) >= 0) {
            iteration++;
            continue;
        }
        if (ECP_SECP256K1_setx(H, x, 0)) {
            ECP_SECP256K1_affine(H);
            return 0;
        }
        /* No point on curve for this x, try next. */
        iteration++;
    }
}

/* Pedersen commitment: C = m·G + r·H.
 * result must be a fresh ECP point; it is initialized as m·G then r·H is
 * added in-place. */
static int pedersen_commit(ECP_SECP256K1 *result, ECP_SECP256K1 *H_gen,
                           const uint8_t m[32], const uint8_t r[32]) {
    BIG_256_28 m_big, r_big;
    BIG_256_28_fromBytes(m_big, (char *)m);
    BIG_256_28_fromBytes(r_big, (char *)r);

    /* result = m·G */
    ECP_SECP256K1_generator(result);
    ECP_SECP256K1_mul(result, m_big);

    /* rH = r·H */
    ECP_SECP256K1 rH;
    ECP_SECP256K1_copy(&rH, H_gen);
    ECP_SECP256K1_mul(&rH, r_big);

    /* result += rH */
    ECP_SECP256K1_add(result, &rH);
    return 0;
}

/* Serialize a point to compressed form (0x02/0x03 || x). */
static int point_to_cmp(uint8_t out[33], ECP_SECP256K1 *P) {
    uint8_t buf[65];
    octet o = {33, 65, buf};
    ECP_SECP256K1_toOctet(&o, P, 1);  /* 1 = compressed */
    if (buf[0] != 0x02 && buf[0] != 0x03) return -1;
    memcpy(out, buf, 33);
    return 0;
}

/* Deserialize compressed point back to ECP. */
static int cmp_to_point(ECP_SECP256K1 *P, const uint8_t cmp[33]) {
    octet o = {33, 33, (char *)cmp};
    return ECP_SECP256K1_fromOctet(P, &o);
}

/* ---- H generator ------------------------------------------------------- */

static uint8_t g_pedersen_h_x[32];
static int g_pedersen_h_ready = 0;

static int ensure_pedersen_h(void) {
    if (g_pedersen_h_ready) return 0;
    ECP_SECP256K1 H;
    if (derive_pedersen_h(&H) != 0) return -1;
    /* Extract the x-coordinate for caching. */
    uint8_t buf[65];
    octet o = {33, 65, buf};
    ECP_SECP256K1_toOctet(&o, &H, 1);
    if (buf[0] != 0x02) return -1;  /* must be even-y */
    memcpy(g_pedersen_h_x, buf + 1, 32);
    g_pedersen_h_ready = 1;
    return 0;
}

const uint8_t *niwi_pbsch_pedersen_h_x(void) {
    if (ensure_pedersen_h() != 0) return NULL;
    return g_pedersen_h_x;
}

/* Re-derive the H point from its cached x-coordinate. */
static int load_h_gen(ECP_SECP256K1 *H) {
    if (ensure_pedersen_h() != 0) return -1;
    /* Use setx(s=0) to re-derive the even-y point from x. */
    BIG_256_28 x;
    BIG_256_28_fromBytes(x, (char *)g_pedersen_h_x);
    if (!ECP_SECP256K1_setx(H, x, 0)) return -1;
    ECP_SECP256K1_affine(H);
    return 0;
}

/* ---- Public API -------------------------------------------------------- */

int niwi_pbsch_cmt_commit(const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                          uint8_t c_out[NIWI_PBSCH_C_CMP_SIZE]) {
    ECP_SECP256K1 H_gen, C_pt;
    if (load_h_gen(&H_gen) != 0) return -1;
    if (pedersen_commit(&C_pt, &H_gen, msg, rho) != 0) return -1;
    if (point_to_cmp(c_out, &C_pt) != 0) return -1;
    return 0;
}

int niwi_pbsch_cmt_verify(const uint8_t c[NIWI_PBSCH_C_CMP_SIZE],
                          const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE]) {
    uint8_t recomputed[33];
    if (niwi_pbsch_cmt_commit(msg, rho, recomputed) != 0) return -1;
    return (memcmp(c, recomputed, 33) == 0) ? 0 : -1;
}

int niwi_pbsch_cmt_s_commit(const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                            uint8_t s_out[NIWI_PBSCH_S_CMP_SIZE]) {
    /* Bind the tuple to a single scalar via SHA-256. */
    uint8_t tuple[224];
    memcpy(tuple, sig0, 64);
    memcpy(tuple + 64, sig1, 64);
    memcpy(tuple + 128, nu_u, 32);
    memcpy(tuple + 160, nu_u_prime, 32);
    memcpy(tuple + 192, nu_s, 32);

    uint8_t msg[32];
    sha256(msg, tuple, 224);

    ECP_SECP256K1 H_gen, S_pt;
    if (load_h_gen(&H_gen) != 0) return -1;
    if (pedersen_commit(&S_pt, &H_gen, msg, rho) != 0) return -1;
    if (point_to_cmp(s_out, &S_pt) != 0) return -1;
    return 0;
}

int niwi_pbsch_cmt_s_verify(const uint8_t s[NIWI_PBSCH_S_CMP_SIZE],
                            const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE]) {
    uint8_t recomputed[33];
    if (niwi_pbsch_cmt_s_commit(sig0, sig1, nu_u, nu_u_prime, nu_s, rho,
                                 recomputed) != 0)
        return -1;
    return (memcmp(s, recomputed, 33) == 0) ? 0 : -1;
}
