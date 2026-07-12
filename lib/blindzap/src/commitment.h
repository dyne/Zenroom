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

#ifndef NIWI_COMMITMENT_H
#define NIWI_COMMITMENT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- KLP22 challenge-share commitment -------------------------------- */

/* Size of a KLP22 commitment (32 bytes, SHA-256 digest).
 * Will increase when Pedersen replaces this (49 bytes for ECP). */
#define NIWI_KLP22_COMMIT_SIZE 32

/* Size of KLP22 commitment randomness (32 bytes). */
#define NIWI_KLP22_RAND_SIZE 32

/* Size of the opening (message + randomness, 64 bytes). */
#define NIWI_KLP22_OPENING_SIZE 64

/* Commit to a message with fresh randomness.
 * commitment_out: 32-byte commitment digest
 * opening_out: 64-byte opening (message || randomness), needed for verify
 * Returns 0 on success, -1 on error. */
int niwi_klp22_commit(const uint8_t *message, size_t msg_len,
                       uint8_t commitment_out[NIWI_KLP22_COMMIT_SIZE],
                       uint8_t opening_out[NIWI_KLP22_OPENING_SIZE]);

/* Verify a KLP22 commitment opening.
 * commitment: 32-byte commitment to verify against
 * message: the original message
 * msg_len: length of the original message
 * opening: 64-byte opening (message[32] || randomness[32])
 * Returns 0 if valid, -1 if invalid. */
int niwi_klp22_verify(const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE],
                       const uint8_t *message, size_t msg_len,
                       const uint8_t opening[NIWI_KLP22_OPENING_SIZE]);

/* ---- Pass/NPRO leaf commitment --------------------------------------- */

/* Size of a leaf commitment digest (32 bytes). */
#define NIWI_LEAF_COMMIT_SIZE 32

/* Size of leaf commitment randomness (32 bytes). */
#define NIWI_LEAF_RAND_SIZE 32

/* Commit to leaf data as a domain-separated NPRO query.
 * This produces a single leaf digest that will be aggregated into a
 * Merkle tree (Merkle aggregation is part of the Ligero adaptation phase).
 *
 * leaf_data, leaf_len: the encoded leaf content
 * commitment_out: 32-byte leaf commitment digest
 * preimage_out: 64 bytes (leaf_data_padded[32] || randomness[32])
 * Returns 0 on success, -1 on error. */
int niwi_leaf_commit(const uint8_t *leaf_data, size_t leaf_len,
                      uint8_t commitment_out[NIWI_LEAF_COMMIT_SIZE],
                      uint8_t preimage_out[64]);

/* Verify a leaf commitment preimage.
 * commitment: the expected 32-byte commitment digest
 * leaf_data, leaf_len: the purported leaf content
 * preimage: 64 bytes (leaf_data_padded[32] || randomness[32])
 * Returns 0 if valid, -1 if invalid. */
int niwi_leaf_verify(const uint8_t commitment[NIWI_LEAF_COMMIT_SIZE],
                      const uint8_t *leaf_data, size_t leaf_len,
                      const uint8_t preimage[64]);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_COMMITMENT_H */
