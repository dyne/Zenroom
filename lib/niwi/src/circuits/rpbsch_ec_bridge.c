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

#include "rpbsch_ec_bridge.h"

#include "amcl.h"
#include "ecp_SECP256K1.h"

#include <string.h>

/* ---- EC point addition: R = P + Q ---- */
int niwi_rpbsch_ec_add(const uint8_t x1[32], const uint8_t y1[32],
                        const uint8_t x2[32], const uint8_t y2[32],
                        uint8_t x_out[32], uint8_t y_out[32]) {
    BIG_256_28 px, py, qx, qy;
    BIG_256_28_fromBytes(px, (char *)x1);
    BIG_256_28_fromBytes(py, (char *)y1);
    BIG_256_28_fromBytes(qx, (char *)x2);
    BIG_256_28_fromBytes(qy, (char *)y2);

    /* Check p < prime */
    BIG_256_28 pmod;
    BIG_256_28_rcopy(pmod, Modulus_SECP256K1);
    if (BIG_256_28_comp(px, pmod) >= 0 || BIG_256_28_comp(qx, pmod) >= 0)
        return -1;

    ECP_SECP256K1 P, Q;
    if (!ECP_SECP256K1_set(&P, px, py)) return -1;
    if (!ECP_SECP256K1_set(&Q, qx, qy)) return -1;

    ECP_SECP256K1_add(&P, &Q);
    ECP_SECP256K1_affine(&P);

    BIG_256_28 rx, ry;
    ECP_SECP256K1_get(rx, ry, &P);
    BIG_256_28_toBytes((char *)x_out, rx);
    BIG_256_28_toBytes((char *)y_out, ry);
    return 0;
}

/* ---- EC scalar multiplication: R = k * P (deterministic) ---- */
int niwi_rpbsch_ec_mul(const uint8_t x[32], const uint8_t y[32],
                        const uint8_t scalar[32],
                        uint8_t x_out[32], uint8_t y_out[32]) {
    BIG_256_28 px, py, k;
    BIG_256_28_fromBytes(px, (char *)x);
    BIG_256_28_fromBytes(py, (char *)y);
    BIG_256_28_fromBytes(k,  (char *)scalar);

    /* Check x < prime */
    BIG_256_28 pmod;
    BIG_256_28_rcopy(pmod, Modulus_SECP256K1);
    if (BIG_256_28_comp(px, pmod) >= 0) return -1;

    ECP_SECP256K1 P;
    if (!ECP_SECP256K1_set(&P, px, py)) return -1;

    /* Deterministic double-and-add (same as pbsch_commitment.c) */
    if (BIG_256_28_iszilch(k)) { ECP_SECP256K1_inf(&P); return -1; }
    ECP_SECP256K1 R;
    ECP_SECP256K1_inf(&R);
    int nb = BIG_256_28_nbits(k);
    for (int i = nb - 1; i >= 0; --i) {
        ECP_SECP256K1_dbl(&R);
        if (BIG_256_28_bit(k, i)) ECP_SECP256K1_add(&R, &P);
    }
    ECP_SECP256K1_affine(&R);

    BIG_256_28 rx, ry;
    ECP_SECP256K1_get(rx, ry, &R);
    BIG_256_28_toBytes((char *)x_out, rx);
    BIG_256_28_toBytes((char *)y_out, ry);
    return 0;
}

/* ---- Decompress point with given parity ---- */
int niwi_rpbsch_decompress(const uint8_t x[32], uint8_t prefix,
                            uint8_t y_out[32]) {
    BIG_256_28 xb;
    BIG_256_28_fromBytes(xb, (char *)x);

    /* Check x < prime */
    BIG_256_28 pmod;
    BIG_256_28_rcopy(pmod, Modulus_SECP256K1);
    if (BIG_256_28_comp(xb, pmod) >= 0) return -1;

    int sign = (prefix == 0x03) ? 1 : 0;  /* 0=even(0x02), 1=odd(0x03) */
    ECP_SECP256K1 P;
    if (!ECP_SECP256K1_setx(&P, xb, sign)) return -1;
    ECP_SECP256K1_affine(&P);

    BIG_256_28 y;
    ECP_SECP256K1_get(xb, y, &P);
    BIG_256_28_toBytes((char *)y_out, y);
    return 0;
}
