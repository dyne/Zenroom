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

/* Milagro ECP/SECP and SHA-256 */
#include "amcl.h"
#include "ecp_SECP256K1.h"

/* ---- Internal helpers -------------------------------------------------- */

/* One-shot SHA-256 via Milagro's HASH256 API. */
static void sha256(uint8_t out[32], const uint8_t *data, size_t len) {
    hash256 sha;
    HASH256_init(&sha);
    for (size_t i = 0; i < len; ++i) {
        HASH256_process(&sha, data[i]);
    }
    HASH256_hash(&sha, out);
}

/* Streaming SHA-256 for iterative hashing (Pedersen H derivation). */
static void sha256_stream_init(hash256 *h) { HASH256_init(h); }
static void sha256_stream_update(hash256 *h, const uint8_t *data, size_t len) {
    for (size_t i = 0; i < len; ++i) HASH256_process(h, data[i]);
}
static void sha256_stream_final(hash256 *h, uint8_t out[32]) {
    HASH256_hash(h, (char *)out);
}

/* Derive the independent Pedersen generator H.
 * H = lift_x(SHA-256("Zenroom/PBSch/PedersenH/v1")).
 * Uses iterative hashing if lift_x fails. */
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

        /* Try to lift x to a point with even y */
        octet xo = {32, 32, digest};
        if (ECP_SECP256K1_fromOctet(H, &xo) == 0) {
            iteration++;
            continue;
        }

        /* Check even y (BIP-340 convention) */
        uint8_t buf[65];
        octet yo = {33, 65, buf};
        ECP_SECP256K1_toOctet(&yo, (ECP_SECP256K1 *)H, 0);
        if (buf[0] == 0x02) return 0;  /* Success: even y */

        /* Negate to make y even */
        ECP_SECP256K1_neg(H);
        return 0;
    }
}

/* Pedersen commitment C = m*G + r*H. */
static int pedersen_commit(ECP_SECP256K1 *result, ECP_SECP256K1 *H_gen,
                           const uint8_t m[32], const uint8_t r[32]) {
    BIG_256_28 m_big, r_big;
    BIG_256_28_fromBytesLen(m_big, (char *)m, 32);
    BIG_256_28_fromBytesLen(r_big, (char *)r, 32);

    ECP_SECP256K1 mG, rH;
    ECP_SECP256K1_generator(&mG);
    ECP_SECP256K1_mul(&mG, m_big);
    ECP_SECP256K1_copy(&rH, H_gen);
    ECP_SECP256K1_mul(&rH, r_big);
    ECP_SECP256K1_add(result, &mG);
    ECP_SECP256K1_add(result, &rH);
    return 0;
}

/* Serialize point to x-only with parity byte. */
static int point_to_x_only(uint8_t x_out[32], uint8_t *parity_out,
                           ECP_SECP256K1 *P) {
    uint8_t buf[65];
    octet o = {33, 65, buf};
    ECP_SECP256K1_toOctet(&o, P, 0);
    if (buf[0] != 0x02 && buf[0] != 0x03) return -1;
    *parity_out = buf[0];
    memcpy(x_out, buf + 1, 32);
    return 0;
}

/* Opening proof: pi = SHA-256("PBSch/Cmt/v1" || C_x[32] || parity || tuple). */
static int compute_opening_proof(uint8_t pi_out[32],
                                  const uint8_t c_x[32], uint8_t c_parity,
                                  const uint8_t *tuple_data, size_t tuple_len) {
    uint8_t buf[1024];
    static const char kDomain[] = "PBSch/Cmt/v1";
    size_t domain_len = strlen(kDomain);

    if (domain_len + 32 + 1 + tuple_len > sizeof(buf)) return -1;
    size_t off = 0;
    memcpy(buf + off, kDomain, domain_len); off += domain_len;
    memcpy(buf + off, c_x, 32); off += 32;
    buf[off++] = c_parity;
    memcpy(buf + off, tuple_data, tuple_len); off += tuple_len;

    sha256(pi_out, buf, off);
    return 0;
}

/* ---- H generator ------------------------------------------------------- */

static uint8_t g_pedersen_h_x[32];
static int g_pedersen_h_ready = 0;

static int ensure_pedersen_h(void) {
    if (g_pedersen_h_ready) return 0;
    ECP_SECP256K1 H;
    if (derive_pedersen_h(&H) != 0) return -1;
    uint8_t parity;
    if (point_to_x_only(g_pedersen_h_x, &parity, &H) != 0) return -1;
    g_pedersen_h_ready = 1;
    return 0;
}

const uint8_t *niwi_pbsch_pedersen_h_x(void) {
    if (ensure_pedersen_h() != 0) return NULL;
    return g_pedersen_h_x;
}

/* ---- Public API -------------------------------------------------------- */

int niwi_pbsch_cmt_commit(const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t alpha[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t beta[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                          uint8_t c_out[NIWI_PBSCH_C_SIZE]) {
    if (ensure_pedersen_h() != 0) return -1;

    ECP_SECP256K1 H_gen, C_pt;
    octet h_xo = {32, 32, g_pedersen_h_x};
    if (!ECP_SECP256K1_fromOctet(&H_gen, &h_xo)) return -1;

    /* Pedersen: C = m*G + r*H where r = SHA-256(alpha || beta) */
    uint8_t r[32], combined[64];
    memcpy(combined, alpha, 32);
    memcpy(combined + 32, beta, 32);
    sha256(r, combined, 64);

    if (pedersen_commit(&C_pt, &H_gen, msg, r) != 0) return -1;

    uint8_t c_x[32], c_parity;
    if (point_to_x_only(c_x, &c_parity, &C_pt) != 0) return -1;

    /* Opening proof */
    uint8_t tuple[128];
    memcpy(tuple, msg, 32);
    memcpy(tuple + 32, alpha, 32);
    memcpy(tuple + 64, beta, 32);
    memcpy(tuple + 96, rho, 32);

    memcpy(c_out, c_x, 32);
    c_out[32] = c_parity;
    if (compute_opening_proof(c_out + 33, c_x, c_parity, tuple, 128) != 0)
        return -1;
    return 0;
}

int niwi_pbsch_cmt_verify(const uint8_t c[NIWI_PBSCH_C_SIZE],
                          const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t alpha[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t beta[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE]) {
    uint8_t recomputed[65];
    if (niwi_pbsch_cmt_commit(msg, alpha, beta, rho, recomputed) != 0)
        return -1;
    return (memcmp(c, recomputed, 65) == 0) ? 0 : -1;
}

int niwi_pbsch_cmt_s_commit(const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                            uint8_t s_out[NIWI_PBSCH_S_SIZE]) {
    if (ensure_pedersen_h() != 0) return -1;

    uint8_t tuple[224];
    memcpy(tuple, sig0, 64);
    memcpy(tuple + 64, sig1, 64);
    memcpy(tuple + 128, nu_u, 32);
    memcpy(tuple + 160, nu_u_prime, 32);
    memcpy(tuple + 192, nu_s, 32);

    uint8_t r[32];
    sha256(r, tuple, 224);

    ECP_SECP256K1 H_gen, S_pt;
    octet h_xo = {32, 32, g_pedersen_h_x};
    if (!ECP_SECP256K1_fromOctet(&H_gen, &h_xo)) return -1;

    if (pedersen_commit(&S_pt, &H_gen, r, r) != 0) return -1;

    uint8_t s_x[32], s_parity;
    if (point_to_x_only(s_x, &s_parity, &S_pt) != 0) return -1;

    memcpy(s_out, s_x, 32);
    s_out[32] = s_parity;
    if (compute_opening_proof(s_out + 33, s_x, s_parity, tuple, 224) != 0)
        return -1;
    return 0;
}

int niwi_pbsch_cmt_s_verify(const uint8_t s[NIWI_PBSCH_S_SIZE],
                            const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE]) {
    uint8_t recomputed[65];
    if (niwi_pbsch_cmt_s_commit(sig0, sig1, nu_u, nu_u_prime, nu_s, rho,
                                 recomputed) != 0) return -1;
    return (memcmp(s, recomputed, 65) == 0) ? 0 : -1;
}
