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

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static void print_hex(const uint8_t *data, size_t len) {
    for (size_t i = 0; i < len; i++) printf("%02x", data[i]);
}

/* ---- KLP22 commitment tests ------------------------------------------ */

static void test_klp22_commit_verify(void) {
    const uint8_t msg[] = {0xAA, 0xBB, 0xCC};
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    int rc = niwi_klp22_commit(msg, 3, commitment, opening);
    assert(rc == 0);

    /* Verify with correct message and opening */
    rc = niwi_klp22_verify(commitment, msg, 3, opening);
    assert(rc == 0);

    printf("  PASS test_klp22_commit_verify\n");
}

static void test_klp22_wrong_message(void) {
    const uint8_t msg[] = {0x01, 0x02, 0x03};
    const uint8_t wrong[] = {0x01, 0x02, 0x04};
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    niwi_klp22_commit(msg, 3, commitment, opening);

    /* Verify with wrong message should fail */
    int rc = niwi_klp22_verify(commitment, wrong, 3, opening);
    assert(rc != 0);

    printf("  PASS test_klp22_wrong_message\n");
}

static void test_klp22_wrong_commitment(void) {
    const uint8_t msg[] = {0xDE, 0xAD};
    uint8_t commitment1[NIWI_KLP22_COMMIT_SIZE];
    uint8_t commitment2[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    niwi_klp22_commit(msg, 2, commitment1, opening);
    niwi_klp22_commit(msg, 2, commitment2, opening);

    /* Two calls with same msg produce different commitments (fresh randomness) */
    assert(memcmp(commitment1, commitment2, NIWI_KLP22_COMMIT_SIZE) != 0);

    printf("  PASS test_klp22_wrong_commitment (different randomness)\n");
}

static void test_klp22_tampered_opening(void) {
    const uint8_t msg[] = {0x42};
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    niwi_klp22_commit(msg, 1, commitment, opening);

    /* Flip a byte in randomness */
    opening[33] ^= 0xFF;
    int rc = niwi_klp22_verify(commitment, msg, 1, opening);
    assert(rc != 0);

    printf("  PASS test_klp22_tampered_opening\n");
}

static void test_klp22_empty_message(void) {
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    int rc = niwi_klp22_commit(NULL, 0, commitment, opening);
    /* Should fail on NULL message */
    assert(rc != 0);

    /* Empty but non-NULL */
    rc = niwi_klp22_commit((const uint8_t *)"", 0, commitment, opening);
    assert(rc == 0);
    rc = niwi_klp22_verify(commitment, (const uint8_t *)"", 0, opening);
    assert(rc == 0);

    printf("  PASS test_klp22_empty_message\n");
}

/* ---- Leaf commitment tests ------------------------------------------- */

static void test_leaf_commit_verify(void) {
    const uint8_t data[] = {0x10, 0x20, 0x30, 0x40};
    uint8_t commitment[NIWI_LEAF_COMMIT_SIZE];
    uint8_t preimage[64];

    int rc = niwi_leaf_commit(data, 4, commitment, preimage);
    assert(rc == 0);

    rc = niwi_leaf_verify(commitment, data, 4, preimage);
    assert(rc == 0);

    printf("  PASS test_leaf_commit_verify\n");
}

static void test_leaf_wrong_data(void) {
    const uint8_t data[] = {0x10, 0x20, 0x30, 0x40};
    const uint8_t wrong[] = {0x10, 0x20, 0x30, 0x41};
    uint8_t commitment[NIWI_LEAF_COMMIT_SIZE];
    uint8_t preimage[64];

    niwi_leaf_commit(data, 4, commitment, preimage);

    int rc = niwi_leaf_verify(commitment, wrong, 4, preimage);
    assert(rc != 0);

    printf("  PASS test_leaf_wrong_data\n");
}

static void test_leaf_tampered_preimage(void) {
    const uint8_t data[] = {0xFF};
    uint8_t commitment[NIWI_LEAF_COMMIT_SIZE];
    uint8_t preimage[64];

    niwi_leaf_commit(data, 1, commitment, preimage);

    /* Tamper randomness */
    preimage[33] ^= 0x01;
    int rc = niwi_leaf_verify(commitment, data, 1, preimage);
    assert(rc != 0);

    printf("  PASS test_leaf_tampered_preimage\n");
}

/* ---- Main ------------------------------------------------------------- */

int main(void) {
    printf("lib/niwi commitment tests:\n");
    test_klp22_commit_verify();
    test_klp22_wrong_message();
    test_klp22_wrong_commitment();
    test_klp22_tampered_opening();
    test_klp22_empty_message();
    test_leaf_commit_verify();
    test_leaf_wrong_data();
    test_leaf_tampered_preimage();
    printf("All commitment tests passed.\n");
    return 0;
}
