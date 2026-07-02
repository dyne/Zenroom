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

#include "bip340_witness_bridge.h"

#include "amcl.h"
#include "ecp_SECP256K1.h"

#include <string.h>

/* Lift an x-only (32-byte) buffer to an even-y secp256k1 point.
 * On success: *y_out is the 32-byte big-endian y-coordinate,
 * *x_out is the canonical 32-byte x-coordinate (same as input).
 * Returns 0 on success, -1 if x >= p or (x, y) is not a valid even-y point. */
int niwi_bip340_lift_x(const uint8_t x[32], uint8_t y_out[32]) {
    BIG_256_28 x_mil;
    BIG_256_28_fromBytes(x_mil, (char *)x);

    /* Check x < p */
    BIG_256_28 p;
    BIG_256_28_rcopy(p, Modulus_SECP256K1);
    if (BIG_256_28_comp(x_mil, p) >= 0) return -1;

    /* Try to lift */
    ECP_SECP256K1 P;
    if (!ECP_SECP256K1_setx(&P, x_mil, 0)) return -1;
    ECP_SECP256K1_affine(&P);

    BIG_256_28 y_mil, x_check;
    ECP_SECP256K1_get(x_check, y_mil, &P);

    /* Require even y */
    if (BIG_256_28_parity(y_mil) != 0) return -1;

    BIG_256_28_toBytes((char *)y_out, y_mil);
    return 0;
}

/* SHA-256 of a single buffer, output 32 bytes. */
void niwi_bip340_sha256(const uint8_t *data, size_t len, uint8_t out[32]) {
    hash256 sha;
    HASH256_init(&sha);
    for (size_t i = 0; i < len; ++i)
        HASH256_process(&sha, data[i]);
    HASH256_hash(&sha, (char *)out);
}
