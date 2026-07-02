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

#include "commitment.h"
#include "hash.h"

#include <string.h>

#include <stdlib.h> /* for rand() in scaffold randomness — NOT SECURE */

/*
 * Scaffold randomness: use a simple PRNG from rand().
 * WARNING: rand() is not cryptographically secure. This is for test
 * scaffolding only. Production must use system CSPRNG.
 */
#include <time.h>

static int scaffold_initialized = 0;
static void ensure_scaffold_seeded(void) {
    if (!scaffold_initialized) {
        srand((unsigned)time(NULL));
        scaffold_initialized = 1;
    }
}

static void scaffold_random(uint8_t *buf, size_t len) {
    ensure_scaffold_seeded();
    for (size_t i = 0; i < len; i++)
        buf[i] = (uint8_t)(rand() & 0xff);
}

/* ---- KLP22 challenge-share commitment -------------------------------- */

int niwi_klp22_commit(const uint8_t *message, size_t msg_len,
                       uint8_t commitment_out[NIWI_KLP22_COMMIT_SIZE],
                       uint8_t opening_out[NIWI_KLP22_OPENING_SIZE]) {
    if (!message || !commitment_out || !opening_out) return -1;
    if (msg_len > 32) return -1; /* pad if needed */

    /* Generate scaffold randomness. */
    uint8_t randomness[NIWI_KLP22_RAND_SIZE];
    scaffold_random(randomness, NIWI_KLP22_RAND_SIZE);

    /* Build opening: message (padded to 32 bytes) || randomness (32 bytes) */
    memset(opening_out, 0, NIWI_KLP22_OPENING_SIZE);
    if (msg_len > 0)
        memcpy(opening_out, message, msg_len);
    memcpy(opening_out + 32, randomness, NIWI_KLP22_RAND_SIZE);

    /* Commitment = NIWI_TAG_KCS("NK04") || domain-tagged hash of opening.
     *
     * For the scaffold: commit = SHA-256("NK04" || opening).
     * This is computationally hiding (a distinguisher can brute-force the
     * message space if it's small) but acceptable for test scaffolding.
     */
    niwi_hash_one_shot(NIWI_TAG_KCS, opening_out, NIWI_KLP22_OPENING_SIZE,
                       commitment_out);

    return 0;
}

int niwi_klp22_verify(const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE],
                       const uint8_t *message, size_t msg_len,
                       const uint8_t opening[NIWI_KLP22_OPENING_SIZE]) {
    if (!commitment || !message || !opening) return -1;
    if (msg_len > 32) return -1;

    /* Reconstruct the expected opening: message padded + randomness. */
    uint8_t expected_opening[NIWI_KLP22_OPENING_SIZE];
    memset(expected_opening, 0, NIWI_KLP22_OPENING_SIZE);
    if (msg_len > 0)
        memcpy(expected_opening, message, msg_len);
    memcpy(expected_opening + 32, opening + 32, NIWI_KLP22_RAND_SIZE);

    /* Must match the stored opening exactly. */
    if (memcmp(expected_opening, opening, NIWI_KLP22_OPENING_SIZE) != 0)
        return -1;

    /* Verify the commitment. */
    uint8_t recomputed[NIWI_KLP22_COMMIT_SIZE];
    niwi_hash_one_shot(NIWI_TAG_KCS, opening, NIWI_KLP22_OPENING_SIZE,
                       recomputed);

    if (memcmp(commitment, recomputed, NIWI_KLP22_COMMIT_SIZE) != 0)
        return -1;

    return 0;
}

/* ---- Pass/NPRO leaf commitment --------------------------------------- */

int niwi_leaf_commit(const uint8_t *leaf_data, size_t leaf_len,
                      uint8_t commitment_out[NIWI_LEAF_COMMIT_SIZE],
                      uint8_t preimage_out[64]) {
    if (!leaf_data || !commitment_out || !preimage_out) return -1;
    if (leaf_len > 64) return -1;

    /* Build preimage: padded leaf data (32 bytes) || randomness (32 bytes) */
    memset(preimage_out, 0, 64);
    if (leaf_len > 0) {
        size_t copy = leaf_len < 32 ? leaf_len : 32;
        memcpy(preimage_out, leaf_data, copy);
    }
    scaffold_random(preimage_out + 32, NIWI_LEAF_RAND_SIZE);

    /* Leaf commitment = domain-tagged hash. */
    niwi_hash_one_shot(NIWI_TAG_LEAF, preimage_out, 64, commitment_out);

    return 0;
}

int niwi_leaf_verify(const uint8_t commitment[NIWI_LEAF_COMMIT_SIZE],
                      const uint8_t *leaf_data, size_t leaf_len,
                      const uint8_t preimage[64]) {
    if (!commitment || !leaf_data || !preimage) return -1;
    if (leaf_len > 64) return -1;

    /* Verify preimage matches expected padded layout. */
    uint8_t expected[64];
    memset(expected, 0, 64);
    if (leaf_len > 0) {
        size_t copy = leaf_len < 32 ? leaf_len : 32;
        memcpy(expected, leaf_data, copy);
    }
    memcpy(expected + 32, preimage + 32, 32);

    if (memcmp(expected, preimage, 64) != 0)
        return -1;

    /* Verify the commitment. */
    uint8_t recomputed[NIWI_LEAF_COMMIT_SIZE];
    niwi_hash_one_shot(NIWI_TAG_LEAF, preimage, 64, recomputed);

    if (memcmp(commitment, recomputed, NIWI_LEAF_COMMIT_SIZE) != 0)
        return -1;

    return 0;
}
