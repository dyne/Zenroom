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

#ifndef NIWI_CIRCUITS_RPBSCH_EC_BRIDGE_H
#define NIWI_CIRCUITS_RPBSCH_EC_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* EC point addition: (x_out, y_out) = (x1, y1) + (x2, y2) on secp256k1.
 * Returns 0 on success, -1 if points are invalid. */
int niwi_rpbsch_ec_add(const uint8_t x1[32], const uint8_t y1[32],
                        const uint8_t x2[32], const uint8_t y2[32],
                        uint8_t x_out[32], uint8_t y_out[32]);

/* EC scalar multiplication: (x_out, y_out) = scalar * (x, y), deterministic.
 * Returns 0 on success, -1 if point is invalid or scalar=0. */
int niwi_rpbsch_ec_mul(const uint8_t x[32], const uint8_t y[32],
                        const uint8_t scalar[32],
                        uint8_t x_out[32], uint8_t y_out[32]);

/* Decompress x-only with given prefix byte (0x02=even, 0x03=odd).
 * Returns y_out such that (x, y_out) is on the curve with matching parity.
 * Returns 0 on success, -1 if x >= p or no point exists. */
int niwi_rpbsch_decompress(const uint8_t x[32], uint8_t prefix,
                            uint8_t y_out[32]);

#ifdef __cplusplus
}
#endif

#endif  /* NIWI_CIRCUITS_RPBSCH_EC_BRIDGE_H */
