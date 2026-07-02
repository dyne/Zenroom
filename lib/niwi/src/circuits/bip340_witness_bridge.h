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

#ifndef NIWI_CIRCUITS_BIP340_WITNESS_BRIDGE_H
#define NIWI_CIRCUITS_BIP340_WITNESS_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Lift an x-only coordinate to an even-y secp256k1 point.
 * x[32]   — input x-coordinate (big-endian)
 * y_out[32] — output y-coordinate (big-endian, even)
 * Returns 0 on success, -1 if x >= p or not a valid even-y point. */
int niwi_bip340_lift_x(const uint8_t x[32], uint8_t y_out[32]);

/* One-shot SHA-256 (used for tagged_hash preimage). */
void niwi_bip340_sha256(const uint8_t *data, size_t len, uint8_t out[32]);

#ifdef __cplusplus
}
#endif

#endif  /* NIWI_CIRCUITS_BIP340_WITNESS_BRIDGE_H */
