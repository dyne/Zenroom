/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "src/challenge_schedule.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static void fill(uint8_t out[32], uint8_t base) {
    for (size_t i = 0; i < 32; i++) out[i] = (uint8_t)(base + i);
}

static void fill_opening(uint8_t out[NIWI_KLP22_OPENING_SIZE], uint8_t base) {
    for (size_t i = 0; i < NIWI_KLP22_OPENING_SIZE; i++)
        out[i] = (uint8_t)(base + i);
}

static void run_happy_path(uint8_t c1[32], uint8_t c2[32]) {
    niwi_challenge_schedule_t s;
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t circuit[32], statement[32], root[32], response[32];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    fill(commitment, 0x10);
    fill(circuit, 0x20);
    fill(statement, 0x30);
    fill(root, 0x40);
    fill(response, 0x50);
    fill_opening(opening, 0x60);

    assert(niwi_schedule_init(&s, 1, 0, 0) == 0);
    assert(niwi_schedule_bind_share_commitment(&s, commitment) == 0);
    assert(niwi_schedule_bind_statement(&s, circuit, statement, root) == 0);
    assert(niwi_schedule_derive_challenge1(&s, c1) == 0);
    assert(niwi_schedule_open_share(&s, opening) == 0);
    assert(niwi_schedule_bind_response(&s, response) == 0);
    assert(niwi_schedule_derive_challenge2(&s, c2) == 0);
    assert(s.stage == NIWI_SCHEDULE_CHALLENGE2_DERIVED);
}

static void test_happy_path_deterministic(void) {
    uint8_t c1a[32], c2a[32], c1b[32], c2b[32];
    run_happy_path(c1a, c2a);
    run_happy_path(c1b, c2b);
    assert(memcmp(c1a, c1b, 32) == 0);
    assert(memcmp(c2a, c2b, 32) == 0);
    assert(memcmp(c1a, c2a, 32) != 0);
    printf("  PASS test_happy_path_deterministic\n");
}

static void test_rejects_out_of_order(void) {
    niwi_challenge_schedule_t s;
    uint8_t digest[32], opening[NIWI_KLP22_OPENING_SIZE], out[32];
    fill(digest, 0x70);
    fill_opening(opening, 0x80);

    assert(niwi_schedule_init(&s, 1, 0, 0) == 0);
    assert(niwi_schedule_derive_challenge1(&s, out) == -1);
    assert(niwi_schedule_open_share(&s, opening) == -1);
    assert(niwi_schedule_bind_response(&s, digest) == -1);
    assert(niwi_schedule_derive_challenge2(&s, out) == -1);
    printf("  PASS test_rejects_out_of_order\n");
}

static void test_mutations_change_challenges(void) {
    niwi_challenge_schedule_t a, b;
    uint8_t commitment[32], circuit[32], statement[32], root[32], out_a[32], out_b[32];

    fill(commitment, 0x01);
    fill(circuit, 0x02);
    fill(statement, 0x03);
    fill(root, 0x04);

    assert(niwi_schedule_init(&a, 1, 0, 0) == 0);
    assert(niwi_schedule_bind_share_commitment(&a, commitment) == 0);
    assert(niwi_schedule_bind_statement(&a, circuit, statement, root) == 0);
    assert(niwi_schedule_derive_challenge1(&a, out_a) == 0);

    statement[0] ^= 0x80;
    assert(niwi_schedule_init(&b, 1, 0, 0) == 0);
    assert(niwi_schedule_bind_share_commitment(&b, commitment) == 0);
    assert(niwi_schedule_bind_statement(&b, circuit, statement, root) == 0);
    assert(niwi_schedule_derive_challenge1(&b, out_b) == 0);
    assert(memcmp(out_a, out_b, 32) != 0);

    printf("  PASS test_mutations_change_challenges\n");
}

int main(void) {
    printf("lib/blindzap KLP22 challenge schedule tests:\n");
    test_happy_path_deterministic();
    test_rejects_out_of_order();
    test_mutations_change_challenges();
    printf("All challenge schedule tests passed.\n");
    return 0;
}
