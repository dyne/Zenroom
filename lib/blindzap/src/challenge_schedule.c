/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "challenge_schedule.h"

#include "encoding.h"
#include "hash.h"

#include <string.h>

static int append_raw(niwi_challenge_schedule_t *s,
                      const uint8_t *data, size_t len) {
    if (!s || (!data && len != 0)) return -1;
    if (len > NIWI_SCHEDULE_TRANSCRIPT_MAX - s->len) return -1;
    if (len != 0) memcpy(s->transcript + s->len, data, len);
    s->len += len;
    return 0;
}

static int append_tagged(niwi_challenge_schedule_t *s,
                         const char tag[4],
                         const uint8_t *payload, size_t payload_len) {
    uint8_t encoded[4 + 4 + 128];
    if (payload_len > 128) return -1;
    size_t n = niwi_encode_tagged(tag, payload, payload_len,
                                  encoded, sizeof(encoded));
    if (n == 0) return -1;
    return append_raw(s, encoded, n);
}

int niwi_schedule_init(niwi_challenge_schedule_t *schedule,
                       uint16_t version_major, uint16_t version_minor,
                       uint32_t protocol_id) {
    if (!schedule) return -1;
    memset(schedule, 0, sizeof(*schedule));
    schedule->stage = NIWI_SCHEDULE_INIT;

    uint8_t version[4];
    uint8_t protocol[4];
    if (niwi_encode_protocol_version(version_major, version_minor,
                                     version, sizeof(version)) == 0)
        return -1;
    if (niwi_encode_u32(protocol_id, protocol, sizeof(protocol)) == 0)
        return -1;
    if (append_tagged(schedule, "NIVR", version, sizeof(version)) != 0)
        return -1;
    return append_tagged(schedule, "NIPR", protocol, sizeof(protocol));
}

int niwi_schedule_bind_share_commitment(
    niwi_challenge_schedule_t *schedule,
    const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE]) {
    if (!schedule || !commitment) return -1;
    if (schedule->stage != NIWI_SCHEDULE_INIT) return -1;
    if (append_tagged(schedule, "NK04", commitment, NIWI_KLP22_COMMIT_SIZE) != 0)
        return -1;
    schedule->stage = NIWI_SCHEDULE_SHARES_COMMITTED;
    return 0;
}

int niwi_schedule_bind_statement(
    niwi_challenge_schedule_t *schedule,
    const uint8_t circuit_digest[NIWI_SCHEDULE_DIGEST_SIZE],
    const uint8_t statement_digest[NIWI_SCHEDULE_DIGEST_SIZE],
    const uint8_t leaf_root[NIWI_SCHEDULE_DIGEST_SIZE]) {
    if (!schedule || !circuit_digest || !statement_digest || !leaf_root)
        return -1;
    if (schedule->stage != NIWI_SCHEDULE_SHARES_COMMITTED) return -1;
    if (append_tagged(schedule, "NCRT", circuit_digest, 32) != 0) return -1;
    if (append_tagged(schedule, "NS02", statement_digest, 32) != 0) return -1;
    if (append_tagged(schedule, "NROT", leaf_root, 32) != 0) return -1;
    schedule->stage = NIWI_SCHEDULE_STATEMENT_BOUND;
    return 0;
}

int niwi_schedule_derive_challenge1(niwi_challenge_schedule_t *schedule,
                                    uint8_t out[NIWI_SCHEDULE_DIGEST_SIZE]) {
    if (!schedule || !out) return -1;
    if (schedule->stage != NIWI_SCHEDULE_STATEMENT_BOUND) return -1;
    niwi_hash_one_shot(NIWI_TAG_FSCH, schedule->transcript, schedule->len, out);
    if (append_tagged(schedule, "NC03", out, 32) != 0) return -1;
    schedule->stage = NIWI_SCHEDULE_CHALLENGE1_DERIVED;
    return 0;
}

int niwi_schedule_open_share(
    niwi_challenge_schedule_t *schedule,
    const uint8_t opening[NIWI_KLP22_OPENING_SIZE]) {
    if (!schedule || !opening) return -1;
    if (schedule->stage != NIWI_SCHEDULE_CHALLENGE1_DERIVED) return -1;
    if (append_tagged(schedule, "NKOP", opening, NIWI_KLP22_OPENING_SIZE) != 0)
        return -1;
    schedule->stage = NIWI_SCHEDULE_SHARE_OPENED;
    return 0;
}

int niwi_schedule_bind_response(niwi_challenge_schedule_t *schedule,
                                const uint8_t response_digest[32]) {
    if (!schedule || !response_digest) return -1;
    if (schedule->stage != NIWI_SCHEDULE_SHARE_OPENED) return -1;
    if (append_tagged(schedule, "NRSP", response_digest, 32) != 0) return -1;
    schedule->stage = NIWI_SCHEDULE_RESPONSE_BOUND;
    return 0;
}

int niwi_schedule_derive_challenge2(niwi_challenge_schedule_t *schedule,
                                    uint8_t out[NIWI_SCHEDULE_DIGEST_SIZE]) {
    if (!schedule || !out) return -1;
    if (schedule->stage != NIWI_SCHEDULE_RESPONSE_BOUND) return -1;
    niwi_hash_one_shot("NC10", schedule->transcript, schedule->len, out);
    if (append_tagged(schedule, "NC10", out, 32) != 0) return -1;
    schedule->stage = NIWI_SCHEDULE_CHALLENGE2_DERIVED;
    return 0;
}
