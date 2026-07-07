/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_CHALLENGE_SCHEDULE_H
#define NIWI_CHALLENGE_SCHEDULE_H

#include <stddef.h>
#include <stdint.h>

#include "commitment.h"

#ifdef __cplusplus
extern "C" {
#endif

#define NIWI_SCHEDULE_DIGEST_SIZE 32
#define NIWI_SCHEDULE_TRANSCRIPT_MAX 1024

typedef enum {
    NIWI_SCHEDULE_INIT = 0,
    NIWI_SCHEDULE_SHARES_COMMITTED = 1,
    NIWI_SCHEDULE_STATEMENT_BOUND = 2,
    NIWI_SCHEDULE_CHALLENGE1_DERIVED = 3,
    NIWI_SCHEDULE_SHARE_OPENED = 4,
    NIWI_SCHEDULE_RESPONSE_BOUND = 5,
    NIWI_SCHEDULE_CHALLENGE2_DERIVED = 6,
} niwi_schedule_stage_t;

typedef struct {
    uint8_t transcript[NIWI_SCHEDULE_TRANSCRIPT_MAX];
    size_t len;
    niwi_schedule_stage_t stage;
} niwi_challenge_schedule_t;

/* Initialize the KLP22 Fiat-Shamir schedule transcript. */
int niwi_schedule_init(niwi_challenge_schedule_t *schedule,
                       uint16_t version_major, uint16_t version_minor,
                       uint32_t protocol_id);

/* Bind the prover share commitment before any verifier challenge exists. */
int niwi_schedule_bind_share_commitment(
    niwi_challenge_schedule_t *schedule,
    const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE]);

/* Bind the public statement and circuit/commitment roots. */
int niwi_schedule_bind_statement(
    niwi_challenge_schedule_t *schedule,
    const uint8_t circuit_digest[NIWI_SCHEDULE_DIGEST_SIZE],
    const uint8_t statement_digest[NIWI_SCHEDULE_DIGEST_SIZE],
    const uint8_t leaf_root[NIWI_SCHEDULE_DIGEST_SIZE]);

/* Derive the verifier challenge after all prior public messages are bound. */
int niwi_schedule_derive_challenge1(niwi_challenge_schedule_t *schedule,
                                    uint8_t out[NIWI_SCHEDULE_DIGEST_SIZE]);

/* Open the corresponding prover share after challenge 1 is fixed. */
int niwi_schedule_open_share(
    niwi_challenge_schedule_t *schedule,
    const uint8_t opening[NIWI_KLP22_OPENING_SIZE]);

/* Bind the algebraic Ligero responses before query-index derivation. */
int niwi_schedule_bind_response(niwi_challenge_schedule_t *schedule,
                                const uint8_t response_digest[32]);

/* Derive query-index challenge after responses are bound. */
int niwi_schedule_derive_challenge2(niwi_challenge_schedule_t *schedule,
                                    uint8_t out[NIWI_SCHEDULE_DIGEST_SIZE]);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_CHALLENGE_SCHEDULE_H */
