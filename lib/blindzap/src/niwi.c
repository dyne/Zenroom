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

#include "niwi.h"
#include "challenge_schedule.h"
#include "commitment.h"
#include "hash.h"
#include "npro.h"
#include "relations/bip340_relation.h"
#include "relations/rpbsch_relation.h"
#include "relations/rpbsch_ligero_relation.h"
#include "relations/zkcc_p256_relation.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define NIWI_PROOF_HEADER_SIZE (4 + 4 + 4 + 32 + 32 + NIWI_KLP22_COMMIT_SIZE + NIWI_KLP22_OPENING_SIZE)
#define NIWI_PROOF_PARAM_SIZE (7 * 4)
#define NIWI_PROOF_TABLEAU_TAG "TAB0"
#define NIWI_PROOF_TABLEAU_ENTRY_SIZE (4 + 4 + 4 + 4 + 32)
#define NIWI_TABLEAU_LEAF_TAG "TBL0"
#define NIWI_TABLEAU_RELATION_LEAF_TAG "TBL1"
#define NIWI_TABLEAU_LEAF_HEADER_SIZE (4 + 4 + 4 + 4)
#define NIWI_TABLEAU_RELATION_LEAF_HEADER_SIZE (4 + 4 + 4 + 32 + 4 + 4 + 4)
#define NIWI_TABLEAU_CHUNK_SIZE 32
#define NIWI_TABLEAU_MAX_LEAVES 32768
#define NIWI_TABLEAU_MAX_MERKLE_DEPTH 15
#define NIWI_PROOF_NATIVE_BODY_TAG "LIG0"
#define NIWI_PROOF_LONGFELLOW_BODY_TAG "LZK0"
#define NIWI_PROOF_NATIVE_BODY_VERSION 0x00010000
#define NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID 0
#define NIWI_PROOF_NATIVE_BODY_PARAM_PROFILE 0x01000000u
#define NIWI_TABLEAU_MAX_ROWS 128
#define NIWI_PROOF_NATIVE_BODY_HEADER_WORDS 2
#define NIWI_PROOF_NATIVE_BODY_FIXED_WORDS 10
#define NIWI_PROOF_NATIVE_BODY_DIGEST_COUNT 8
#define NIWI_PROOF_NATIVE_BODY_DIGEST_SIZE 32
#define NIWI_PROOF_NATIVE_BODY_MERKLE_NODE_SIZE 32
#define NIWI_PROOF_NATIVE_BODY_TAG_SIZE 4
#define NIWI_PROOF_NATIVE_BODY_LENGTH_SIZE 4
#define NIWI_PROOF_NATIVE_RESPONSE_TAG "NRSP"
#define NIWI_PROOF_NATIVE_RESPONSE_VERSION 0x00010000
#define NIWI_PROOF_NATIVE_RESPONSE_COUNT 2
#define NIWI_PROOF_NATIVE_RESPONSE_QUERY_COUNT 1
#define NIWI_PROOF_NATIVE_RESPONSE_HEADER_WORDS 5
#define NIWI_PROOF_NATIVE_RESPONSE_ENTRY_WORDS 4
#define NIWI_PROOF_NATIVE_RESPONSE_EVAL_WORDS 3
#define NIWI_PROOF_NATIVE_RESPONSE_EVAL_U64S 2
#define NIWI_PROOF_NATIVE_RESPONSE_COLUMN_WORDS 2
#define NIWI_PROOF_NATIVE_RESPONSE_COLUMN_U64S 2
#define NIWI_PROOF_NATIVE_RESPONSE_ENTRY_SIZE \
    (NIWI_PROOF_NATIVE_RESPONSE_ENTRY_WORDS * 4 + \
     NIWI_PROOF_NATIVE_BODY_DIGEST_SIZE)
#define NIWI_PROOF_NATIVE_RESPONSE_EVAL_SIZE \
    (NIWI_PROOF_NATIVE_RESPONSE_EVAL_WORDS * 4 + \
     NIWI_PROOF_NATIVE_RESPONSE_EVAL_U64S * 8)
#define NIWI_PROOF_NATIVE_RESPONSE_COLUMN_SIZE \
    (NIWI_PROOF_NATIVE_RESPONSE_COLUMN_WORDS * 4 + \
     NIWI_PROOF_NATIVE_RESPONSE_COLUMN_U64S * 8)
#define NIWI_PROOF_NATIVE_RESPONSE_SIZE \
    (NIWI_PROOF_NATIVE_BODY_TAG_SIZE + \
     NIWI_PROOF_NATIVE_RESPONSE_HEADER_WORDS * 4 + \
     NIWI_PROOF_NATIVE_RESPONSE_ENTRY_SIZE + \
     NIWI_PROOF_NATIVE_RESPONSE_EVAL_SIZE + \
     NIWI_PROOF_NATIVE_RESPONSE_COLUMN_SIZE)
#define NIWI_LIGERO_FIELD_MODULUS UINT64_C(18446744073709551557)
#define NIWI_LIGERO_FIELD_CARRY UINT64_C(59)
#define NIWI_PROOF_NATIVE_BODY_BASE_PAYLOAD_SIZE \
    (NIWI_PROOF_NATIVE_BODY_FIXED_WORDS * 4 + \
     NIWI_PROOF_NATIVE_BODY_DIGEST_COUNT * NIWI_PROOF_NATIVE_BODY_DIGEST_SIZE + \
     NIWI_PROOF_NATIVE_RESPONSE_SIZE)
#define NIWI_PROOF_NATIVE_BODY_BASE_SIZE \
    (NIWI_PROOF_NATIVE_BODY_TAG_SIZE + NIWI_PROOF_NATIVE_BODY_LENGTH_SIZE + \
     NIWI_PROOF_NATIVE_BODY_BASE_PAYLOAD_SIZE)
#define NIWI_PROOF_NATIVE_BODY_PATH_OFFSET NIWI_PROOF_NATIVE_BODY_BASE_SIZE

typedef struct {
    uint32_t index;
    uint32_t row;
    uint32_t offset;
    uint32_t leaf_len;
    uint8_t digest[32];
} niwi_tableau_entry_t;

typedef struct {
    uint32_t response_version;
    uint32_t response_count;
    uint32_t query_count;
    uint32_t row_count;
    uint32_t chunk_size;
    uint32_t query_index;
    uint32_t row;
    uint32_t offset;
    uint32_t leaf_len;
    uint8_t leaf_digest[32];
    uint32_t eval_row;
    uint32_t eval_start;
    uint32_t eval_count;
    uint64_t eval_point;
    uint64_t eval_value;
    uint32_t column_index;
    uint32_t column_count;
    uint64_t column_point;
    uint64_t column_value;
} niwi_ligero_response_t;

struct niwi_ctx {
    uint8_t *artifact;
    size_t   artifact_len;
    niwi_relation_id_t relation_id;
    niwi_relation_validate_fn validate;
    void *validate_user_data;
    niwi_rpbsch_ligero_ctx_t *rpbsch_runtime;
    char     error[256];
};

static void set_error(niwi_ctx_t *ctx, const char *msg);

static void write_u32_be(uint8_t *out, uint32_t v) {
    out[0] = (uint8_t)((v >> 24) & 0xff);
    out[1] = (uint8_t)((v >> 16) & 0xff);
    out[2] = (uint8_t)((v >> 8) & 0xff);
    out[3] = (uint8_t)(v & 0xff);
}

static uint32_t read_u32_be(const uint8_t *in) {
    return ((uint32_t)in[0] << 24) |
           ((uint32_t)in[1] << 16) |
           ((uint32_t)in[2] << 8) |
           ((uint32_t)in[3]);
}

static void write_u64_be(uint8_t *out, uint64_t v) {
    out[0] = (uint8_t)((v >> 56) & 0xff);
    out[1] = (uint8_t)((v >> 48) & 0xff);
    out[2] = (uint8_t)((v >> 40) & 0xff);
    out[3] = (uint8_t)((v >> 32) & 0xff);
    out[4] = (uint8_t)((v >> 24) & 0xff);
    out[5] = (uint8_t)((v >> 16) & 0xff);
    out[6] = (uint8_t)((v >> 8) & 0xff);
    out[7] = (uint8_t)(v & 0xff);
}

static uint64_t read_u64_be(const uint8_t *in) {
    return ((uint64_t)in[0] << 56) |
           ((uint64_t)in[1] << 48) |
           ((uint64_t)in[2] << 40) |
           ((uint64_t)in[3] << 32) |
           ((uint64_t)in[4] << 24) |
           ((uint64_t)in[5] << 16) |
           ((uint64_t)in[6] << 8) |
           ((uint64_t)in[7]);
}

static size_t tableau_leaf_count(size_t priv_len) {
    if (priv_len == 0) return 1;
    return (priv_len + NIWI_TABLEAU_CHUNK_SIZE - 1) / NIWI_TABLEAU_CHUNK_SIZE;
}

static uint32_t tableau_row_count(size_t leaf_count) {
    if (leaf_count <= 1) return 1;
    uint32_t rows = 1;
    while ((size_t)rows * rows < leaf_count &&
           rows < NIWI_TABLEAU_MAX_ROWS)
        rows++;
    return rows;
}

static uint32_t tableau_column_count(size_t leaf_count, uint32_t row_count) {
    if (row_count == 0) return 0;
    return (uint32_t)((leaf_count + row_count - 1) / row_count);
}

static uint32_t ligero_param_id(uint32_t row_count, uint32_t column_count) {
    if (row_count == 0 || row_count > NIWI_TABLEAU_MAX_ROWS ||
        column_count == 0 || column_count > 0x3fffu)
        return 0;
    return NIWI_PROOF_NATIVE_BODY_PARAM_PROFILE |
           (row_count << 14) | column_count;
}

static int build_tableau_leaf_fragment(const uint8_t *private_inputs,
                                       size_t priv_len,
                                       size_t offset,
                                       uint32_t row,
                                       int relation_backed,
                                       niwi_relation_id_t relation_id,
                                       const uint8_t statement_digest[32],
                                       uint8_t **leaf_out,
                                       size_t *leaf_len) {
    if (!leaf_out || !leaf_len) return -1;
    if (!private_inputs && priv_len != 0) return -1;
    if (priv_len > UINT32_MAX) return -1;
    if (offset > priv_len) return -1;
    if (relation_backed && !statement_digest) return -1;

    size_t chunk_len = priv_len - offset;
    if (chunk_len > NIWI_TABLEAU_CHUNK_SIZE)
        chunk_len = NIWI_TABLEAU_CHUNK_SIZE;
    if (chunk_len > UINT32_MAX) return -1;

    size_t header_len = relation_backed ?
        NIWI_TABLEAU_RELATION_LEAF_HEADER_SIZE :
        NIWI_TABLEAU_LEAF_HEADER_SIZE;
    size_t len = header_len + chunk_len;
    uint8_t *leaf = (uint8_t *)malloc(len ? len : 1);
    if (!leaf) return -1;

    size_t off = 0;
    memcpy(leaf + off, relation_backed ? NIWI_TABLEAU_RELATION_LEAF_TAG :
                                         NIWI_TABLEAU_LEAF_TAG, 4);
    off += 4;
    if (relation_backed) {
        write_u32_be(leaf + off, NIWI_PROOF_NATIVE_BODY_VERSION); off += 4;
        write_u32_be(leaf + off, (uint32_t)relation_id); off += 4;
        memcpy(leaf + off, statement_digest, 32); off += 32;
    }
    write_u32_be(leaf + off, row); off += 4;
    write_u32_be(leaf + off, (uint32_t)offset); off += 4;
    write_u32_be(leaf + off, (uint32_t)priv_len); off += 4;
    if (chunk_len != 0) memcpy(leaf + off, private_inputs + offset, chunk_len);

    *leaf_out = leaf;
    *leaf_len = len;
    return 0;
}

static int decode_tableau_leaf_fragment(const uint8_t *leaf, size_t leaf_len,
                                        int relation_backed,
                                        niwi_relation_id_t relation_id,
                                        const uint8_t statement_digest[32],
                                        uint32_t *row,
                                        uint32_t *offset,
                                        uint32_t *total_len,
                                        const uint8_t **chunk,
                                        size_t *chunk_len) {
    if (!leaf || !row || !offset || !total_len || !chunk || !chunk_len)
        return -1;
    if (leaf_len < NIWI_TABLEAU_LEAF_HEADER_SIZE) return -1;

    size_t off = 0;
    if (memcmp(leaf + off, NIWI_TABLEAU_LEAF_TAG, 4) == 0) {
        if (relation_backed) return -1;
        off += 4;
    } else if (memcmp(leaf + off, NIWI_TABLEAU_RELATION_LEAF_TAG, 4) == 0) {
        if (!relation_backed || !statement_digest ||
            leaf_len < NIWI_TABLEAU_RELATION_LEAF_HEADER_SIZE)
            return -1;
        off += 4;
        if (read_u32_be(leaf + off) != NIWI_PROOF_NATIVE_BODY_VERSION)
            return -1;
        off += 4;
        if (read_u32_be(leaf + off) != (uint32_t)relation_id)
            return -1;
        off += 4;
        if (memcmp(leaf + off, statement_digest, 32) != 0)
            return -1;
        off += 32;
    } else {
        return -1;
    }
    *row = read_u32_be(leaf + off); off += 4;
    *offset = read_u32_be(leaf + off); off += 4;
    *total_len = read_u32_be(leaf + off); off += 4;
    *chunk = leaf + off;
    *chunk_len = leaf_len - off;
    if (*offset > *total_len) return -1;
    if (*chunk_len > (size_t)(*total_len - *offset)) return -1;
    return 0;
}

static int compute_tableau_digest(const niwi_tableau_entry_t *entries,
                                  size_t count,
                                  uint8_t digest_out[32]) {
    if (!entries || !digest_out || count == 0 ||
        count > NIWI_TABLEAU_MAX_LEAVES)
        return -1;
    if (count > (SIZE_MAX - 4) / NIWI_PROOF_TABLEAU_ENTRY_SIZE)
        return -1;

    size_t len = 4 + count * NIWI_PROOF_TABLEAU_ENTRY_SIZE;
    uint8_t *buf = (uint8_t *)malloc(len);
    if (!buf) return -1;
    size_t off = 0;
    write_u32_be(buf + off, (uint32_t)count); off += 4;
    for (size_t i = 0; i < count; i++) {
        write_u32_be(buf + off, entries[i].index); off += 4;
        write_u32_be(buf + off, entries[i].row); off += 4;
        write_u32_be(buf + off, entries[i].offset); off += 4;
        write_u32_be(buf + off, entries[i].leaf_len); off += 4;
        memcpy(buf + off, entries[i].digest, 32); off += 32;
    }
    niwi_hash_one_shot(NIWI_TAG_EXTR, buf, len, digest_out);
    free(buf);
    return 0;
}

static uint32_t tableau_opening_index(const uint8_t challenge[32],
                                      size_t count) {
    uint32_t raw = read_u32_be(challenge);
    return count == 0 ? 0 : raw % (uint32_t)count;
}

static void hash_merkle_pair(const uint8_t left[32], const uint8_t right[32],
                             uint8_t out[32]) {
    uint8_t preimage[64];
    memcpy(preimage, left, 32);
    memcpy(preimage + 32, right, 32);
    niwi_hash_one_shot(NIWI_TAG_EXTR, preimage, sizeof(preimage), out);
}

static int compute_tableau_merkle_path(
    const niwi_tableau_entry_t *entries, size_t count, size_t opening_index,
    uint8_t root_out[32],
    uint8_t path_out[NIWI_TABLEAU_MAX_MERKLE_DEPTH][32],
    size_t *path_len_out) {
    if (!entries || !root_out || !path_len_out || count == 0 ||
        count > NIWI_TABLEAU_MAX_LEAVES || opening_index >= count)
        return -1;

    uint8_t level[NIWI_TABLEAU_MAX_LEAVES][32];
    uint8_t next[NIWI_TABLEAU_MAX_LEAVES][32];
    for (size_t i = 0; i < count; i++)
        memcpy(level[i], entries[i].digest, 32);

    size_t n = count;
    size_t idx = opening_index;
    size_t depth = 0;
    while (n > 1) {
        if (depth >= NIWI_TABLEAU_MAX_MERKLE_DEPTH) return -1;
        size_t sibling = (idx % 2 == 0) ? idx + 1 : idx - 1;
        if (sibling >= n) sibling = idx;
        if (path_out) memcpy(path_out[depth], level[sibling], 32);

        size_t out_count = 0;
        for (size_t i = 0; i < n; i += 2) {
            size_t right = i + 1 < n ? i + 1 : i;
            hash_merkle_pair(level[i], level[right], next[out_count]);
            out_count++;
        }
        memcpy(level, next, out_count * 32);
        idx /= 2;
        n = out_count;
        depth++;
    }

    memcpy(root_out, level[0], 32);
    *path_len_out = depth;
    return 0;
}

static int verify_tableau_merkle_path(
    const uint8_t opening_digest[32], uint32_t opening_index,
    size_t tableau_count,
    const uint8_t path[NIWI_TABLEAU_MAX_MERKLE_DEPTH][32],
    size_t path_len,
    const uint8_t expected_root[32]) {
    if (!opening_digest || !path || !expected_root ||
        tableau_count == 0 || opening_index >= tableau_count ||
        path_len > NIWI_TABLEAU_MAX_MERKLE_DEPTH)
        return -1;

    uint8_t acc[32];
    memcpy(acc, opening_digest, 32);
    size_t idx = opening_index;
    size_t n = tableau_count;
    if (n == 1 && path_len != 0) return -1;
    for (size_t depth = 0; depth < path_len; depth++) {
        uint8_t next[32];
        if (idx % 2 == 0)
            hash_merkle_pair(acc, path[depth], next);
        else
            hash_merkle_pair(path[depth], acc, next);
        memcpy(acc, next, 32);
        idx /= 2;
        n = (n + 1) / 2;
    }
    if (n != 1) return -1;
    return memcmp(acc, expected_root, 32) == 0 ? 0 : -1;
}

static int build_tableau_entries(const uint8_t *private_inputs, size_t priv_len,
                                 int relation_backed,
                                 niwi_relation_id_t relation_id,
                                 const uint8_t statement_digest[32],
                                 niwi_tableau_entry_t **entries_out,
                                 size_t *count_out,
                                 uint8_t tableau_digest[32]) {
    if (!entries_out || !count_out || !tableau_digest) return -1;
    if (!private_inputs && priv_len != 0) return -1;
    if (priv_len > UINT32_MAX) return -1;

    size_t count = tableau_leaf_count(priv_len);
    if (count == 0 || count > NIWI_TABLEAU_MAX_LEAVES) return -1;
    uint32_t row_count = tableau_row_count(count);
    niwi_tableau_entry_t *entries =
        (niwi_tableau_entry_t *)calloc(count, sizeof(*entries));
    if (!entries) return -1;

    for (size_t i = 0; i < count; i++) {
        size_t offset = i * NIWI_TABLEAU_CHUNK_SIZE;
        uint32_t row = (uint32_t)(i % row_count);
        uint8_t *leaf = NULL;
        size_t leaf_len = 0;
        if (build_tableau_leaf_fragment(private_inputs, priv_len, offset,
                                        row,
                                        relation_backed, relation_id,
                                        statement_digest,
                                        &leaf, &leaf_len) != 0 ||
            leaf_len > UINT32_MAX) {
            free(leaf);
            free(entries);
            return -1;
        }
        entries[i].index = (uint32_t)i;
        entries[i].row = row;
        entries[i].offset = (uint32_t)offset;
        entries[i].leaf_len = (uint32_t)leaf_len;
        niwi_hash_one_shot(NIWI_TAG_LEAF, leaf, leaf_len, entries[i].digest);
        free(leaf);
    }

    if (compute_tableau_digest(entries, count, tableau_digest) != 0) {
        free(entries);
        return -1;
    }
    *entries_out = entries;
    *count_out = count;
    return 0;
}

static int record_tableau_queries(niwi_npro_t *npro,
                                  const uint8_t *private_inputs,
                                  size_t priv_len,
                                  int relation_backed,
                                  niwi_relation_id_t relation_id,
                                  const uint8_t statement_digest[32]) {
    if (!npro) return -1;
    if (!private_inputs && priv_len != 0) return -1;

    size_t count = tableau_leaf_count(priv_len);
    if (count == 0 || count > NIWI_TABLEAU_MAX_LEAVES) return -1;
    uint32_t row_count = tableau_row_count(count);

    for (size_t i = 0; i < count; i++) {
        size_t offset = i * NIWI_TABLEAU_CHUNK_SIZE;
        uint32_t row = (uint32_t)(i % row_count);
        uint8_t *leaf = NULL;
        size_t leaf_len = 0;
        uint8_t digest[32];
        if (build_tableau_leaf_fragment(private_inputs, priv_len, offset,
                                        row,
                                        relation_backed, relation_id,
                                        statement_digest,
                                        &leaf, &leaf_len) != 0 ||
            niwi_npro_query(npro, NIWI_TAG_LEAF, leaf, leaf_len, digest) != 0) {
            free(leaf);
            return -1;
        }
        free(leaf);
    }
    return 0;
}

static int parse_tableau_section(const uint8_t *proof, size_t proof_len,
                                 size_t *off,
                                 uint8_t digest_out[32],
                                 niwi_tableau_entry_t **entries_out,
                                 size_t *count_out) {
    if (!proof || !off || !digest_out || !count_out) return -1;
    if (*off + 8 > proof_len) return -1;
    if (memcmp(proof + *off, NIWI_PROOF_TABLEAU_TAG, 4) != 0) return -1;
    *off += 4;
    uint32_t count = read_u32_be(proof + *off); *off += 4;
    if (count == 0 || count > NIWI_TABLEAU_MAX_LEAVES) return -1;
    if ((size_t)count > (proof_len - *off) / NIWI_PROOF_TABLEAU_ENTRY_SIZE)
        return -1;

    niwi_tableau_entry_t *entries =
        (niwi_tableau_entry_t *)calloc(count, sizeof(*entries));
    if (!entries) return -1;

    for (uint32_t i = 0; i < count; i++) {
        niwi_tableau_entry_t entry;
        memset(&entry, 0, sizeof(entry));
        entry.index = read_u32_be(proof + *off); *off += 4;
        entry.row = read_u32_be(proof + *off); *off += 4;
        entry.offset = read_u32_be(proof + *off); *off += 4;
        entry.leaf_len = read_u32_be(proof + *off); *off += 4;
        if (entry.index != i ||
            entry.leaf_len < NIWI_TABLEAU_LEAF_HEADER_SIZE) {
            free(entries);
            return -1;
        }
        memcpy(entry.digest, proof + *off, 32); *off += 32;
        entries[i] = entry;
    }

    if (compute_tableau_digest(entries, count, digest_out) != 0) {
        free(entries);
        return -1;
    }
    if (entries_out) {
        *entries_out = entries;
    } else {
        free(entries);
    }
    *count_out = count;
    return 0;
}

static int append_tableau_entries(uint8_t *proof, size_t proof_len,
                                  size_t *off,
                                  const niwi_tableau_entry_t *entries,
                                  size_t count) {
    if (!proof || !off || !entries || count == 0 ||
        count > NIWI_TABLEAU_MAX_LEAVES)
        return -1;
    if ((size_t)count > (proof_len - *off) / NIWI_PROOF_TABLEAU_ENTRY_SIZE)
        return -1;

    for (size_t i = 0; i < count; i++) {
        write_u32_be(proof + *off, entries[i].index); *off += 4;
        write_u32_be(proof + *off, entries[i].row); *off += 4;
        write_u32_be(proof + *off, entries[i].offset); *off += 4;
        write_u32_be(proof + *off, entries[i].leaf_len); *off += 4;
        memcpy(proof + *off, entries[i].digest, 32); *off += 32;
    }
    return 0;
}

static int parse_tableau_entries(const uint8_t *proof, size_t proof_len,
                                 size_t *off, size_t count,
                                 uint32_t row_count,
                                 int require_canonical_layout,
                                 niwi_tableau_entry_t **entries_out,
                                 uint8_t digest_out[32]) {
    if (!proof || !off || !digest_out || count == 0 ||
        count > NIWI_TABLEAU_MAX_LEAVES ||
        (require_canonical_layout && row_count == 0))
        return -1;
    if (count > (proof_len - *off) / NIWI_PROOF_TABLEAU_ENTRY_SIZE)
        return -1;

    niwi_tableau_entry_t *entries =
        (niwi_tableau_entry_t *)calloc(count, sizeof(*entries));
    if (!entries) return -1;

    for (size_t i = 0; i < count; i++) {
        niwi_tableau_entry_t entry;
        memset(&entry, 0, sizeof(entry));
        entry.index = read_u32_be(proof + *off); *off += 4;
        entry.row = read_u32_be(proof + *off); *off += 4;
        entry.offset = read_u32_be(proof + *off); *off += 4;
        entry.leaf_len = read_u32_be(proof + *off); *off += 4;
        if (entry.index != i ||
            entry.leaf_len < NIWI_TABLEAU_LEAF_HEADER_SIZE ||
            (require_canonical_layout &&
             (entry.row != (uint32_t)(i % row_count) ||
              entry.offset != (uint32_t)(i * NIWI_TABLEAU_CHUNK_SIZE)))) {
            free(entries);
            return -1;
        }
        memcpy(entry.digest, proof + *off, 32); *off += 32;
        entries[i] = entry;
    }

    if (compute_tableau_digest(entries, count, digest_out) != 0) {
        free(entries);
        return -1;
    }
    if (entries_out) {
        *entries_out = entries;
    } else {
        free(entries);
    }
    return 0;
}

static void compute_relation_digest(niwi_relation_id_t relation_id,
                                    const uint8_t circuit_digest[32],
                                    const uint8_t statement_digest[32],
                                    const uint8_t tableau_digest[32],
                                    uint8_t out[32]) {
    uint8_t preimage[4 + 32 + 32 + 32];
    write_u32_be(preimage, (uint32_t)relation_id);
    memcpy(preimage + 4, circuit_digest, 32);
    memcpy(preimage + 36, statement_digest, 32);
    memcpy(preimage + 68, tableau_digest, 32);
    niwi_hash_one_shot(NIWI_TAG_PROOF, preimage, sizeof(preimage), out);
}

static uint64_t ligero_field_reduce_u64(uint64_t v) {
    return v >= NIWI_LIGERO_FIELD_MODULUS ?
        v - NIWI_LIGERO_FIELD_MODULUS : v;
}

static uint64_t ligero_field_add(uint64_t a, uint64_t b) {
    uint64_t sum = a + b;
    if (sum < a) {
        /* NIWI_LIGERO_FIELD_MODULUS is 2^64 - 59, so folding the
         * carry back into the field is equivalent to adding 59. */
        return sum + NIWI_LIGERO_FIELD_CARRY;
    }
    return ligero_field_reduce_u64(sum);
}

static uint64_t ligero_field_mul(uint64_t a, uint64_t b) {
#if defined(__SIZEOF_INT128__) && !defined(NIWI_FORCE_NO_UINT128)
    unsigned __int128 product = (unsigned __int128)a * b;
    product %= NIWI_LIGERO_FIELD_MODULUS;
    return (uint64_t)product;
#else
    uint64_t acc = 0;
    while (b != 0) {
        if ((b & 1u) != 0) acc = ligero_field_add(acc, a);
        b >>= 1;
        if (b != 0) a = ligero_field_add(a, a);
    }
    return acc;
#endif
}

static uint64_t ligero_digest_to_field(const uint8_t digest[32]) {
    return ligero_field_reduce_u64(read_u64_be(digest));
}

static int evaluate_tableau_digest_row(const niwi_tableau_entry_t *entries,
                                       size_t count,
                                       uint32_t row_count,
                                       uint32_t row,
                                       uint64_t point,
                                       uint64_t *value_out,
                                       uint32_t *eval_count_out) {
    if (!entries || !value_out || count == 0 ||
        count > NIWI_TABLEAU_MAX_LEAVES || row_count == 0 ||
        row >= row_count)
        return -1;
    uint64_t acc = 0;
    uint32_t columns = tableau_column_count(count, row_count);
    uint32_t used = 0;
    for (uint32_t col = columns; col > 0; col--) {
        size_t index = (size_t)(col - 1) * row_count + row;
        if (index >= count) continue;
        acc = ligero_field_mul(acc, point);
        acc = ligero_field_add(acc, ligero_digest_to_field(entries[index].digest));
        used++;
    }
    if (used == 0) return -1;
    *value_out = acc;
    if (eval_count_out) *eval_count_out = used;
    return 0;
}

static int evaluate_tableau_digest_column(const niwi_tableau_entry_t *entries,
                                          size_t count,
                                          uint32_t row_count,
                                          uint32_t column_index,
                                          uint64_t point,
                                          uint64_t *value_out,
                                          uint32_t *eval_count_out) {
    if (!entries || !value_out || count == 0 ||
        count > NIWI_TABLEAU_MAX_LEAVES || row_count == 0 ||
        column_index >= tableau_column_count(count, row_count))
        return -1;

    uint64_t acc = 0;
    uint32_t used = 0;
    for (uint32_t row = row_count; row > 0; row--) {
        size_t index = (size_t)column_index * row_count + (row - 1);
        if (index >= count) continue;
        acc = ligero_field_mul(acc, point);
        acc = ligero_field_add(acc, ligero_digest_to_field(entries[index].digest));
        used++;
    }
    if (used == 0) return -1;
    *value_out = acc;
    if (eval_count_out) *eval_count_out = used;
    return 0;
}

static int build_ligero_response(const uint8_t challenge1[32],
                                 const niwi_tableau_entry_t *entries,
                                 size_t count,
                                 uint32_t row_count,
                                 niwi_ligero_response_t *response) {
    if (!challenge1 || !entries || !response || count == 0 ||
        count > NIWI_TABLEAU_MAX_LEAVES || row_count == 0)
        return -1;
    uint32_t query_index = tableau_opening_index(challenge1, count);
    const niwi_tableau_entry_t *entry = &entries[query_index];

    memset(response, 0, sizeof(*response));
    response->response_version = NIWI_PROOF_NATIVE_RESPONSE_VERSION;
    response->response_count = NIWI_PROOF_NATIVE_RESPONSE_COUNT;
    response->query_count = NIWI_PROOF_NATIVE_RESPONSE_QUERY_COUNT;
    response->row_count = row_count;
    response->chunk_size = NIWI_TABLEAU_CHUNK_SIZE;
    response->query_index = query_index;
    response->row = entry->row;
    response->offset = entry->offset;
    response->leaf_len = entry->leaf_len;
    memcpy(response->leaf_digest, entry->digest, 32);
    response->eval_row = entry->row;
    response->eval_start = 0;
    response->eval_point = ligero_digest_to_field(challenge1);
    if (evaluate_tableau_digest_row(entries, count, row_count,
                                    response->eval_row,
                                    response->eval_point,
                                    &response->eval_value,
                                    &response->eval_count) != 0)
        return -1;
    response->column_index = query_index / row_count;
    response->column_point = ligero_field_reduce_u64(
        read_u64_be(challenge1 + 8));
    if (evaluate_tableau_digest_column(entries, count, row_count,
                                       response->column_index,
                                       response->column_point,
                                       &response->column_value,
                                       &response->column_count) != 0)
        return -1;
    return 0;
}

static int serialize_ligero_response(const niwi_ligero_response_t *response,
                                     uint8_t out[NIWI_PROOF_NATIVE_RESPONSE_SIZE]) {
    if (!response || !out) return -1;
    size_t off = 0;
    memcpy(out + off, NIWI_PROOF_NATIVE_RESPONSE_TAG, 4); off += 4;
    write_u32_be(out + off, response->response_version); off += 4;
    write_u32_be(out + off, response->response_count); off += 4;
    write_u32_be(out + off, response->query_count); off += 4;
    write_u32_be(out + off, response->row_count); off += 4;
    write_u32_be(out + off, response->chunk_size); off += 4;
    write_u32_be(out + off, response->query_index); off += 4;
    write_u32_be(out + off, response->row); off += 4;
    write_u32_be(out + off, response->offset); off += 4;
    write_u32_be(out + off, response->leaf_len); off += 4;
    memcpy(out + off, response->leaf_digest, 32); off += 32;
    write_u32_be(out + off, response->eval_row); off += 4;
    write_u32_be(out + off, response->eval_start); off += 4;
    write_u32_be(out + off, response->eval_count); off += 4;
    write_u64_be(out + off, response->eval_point); off += 8;
    write_u64_be(out + off, response->eval_value); off += 8;
    write_u32_be(out + off, response->column_index); off += 4;
    write_u32_be(out + off, response->column_count); off += 4;
    write_u64_be(out + off, response->column_point); off += 8;
    write_u64_be(out + off, response->column_value); off += 8;
    return off == NIWI_PROOF_NATIVE_RESPONSE_SIZE ? 0 : -1;
}

static int parse_ligero_response(const uint8_t *proof, size_t proof_len,
                                 size_t *off,
                                 niwi_ligero_response_t *response) {
    if (!proof || !off || !response ||
        *off > proof_len ||
        proof_len - *off < NIWI_PROOF_NATIVE_RESPONSE_SIZE)
        return -1;
    if (memcmp(proof + *off, NIWI_PROOF_NATIVE_RESPONSE_TAG, 4) != 0)
        return -1;
    *off += 4;
    memset(response, 0, sizeof(*response));
    response->response_version = read_u32_be(proof + *off); *off += 4;
    response->response_count = read_u32_be(proof + *off); *off += 4;
    response->query_count = read_u32_be(proof + *off); *off += 4;
    response->row_count = read_u32_be(proof + *off); *off += 4;
    response->chunk_size = read_u32_be(proof + *off); *off += 4;
    response->query_index = read_u32_be(proof + *off); *off += 4;
    response->row = read_u32_be(proof + *off); *off += 4;
    response->offset = read_u32_be(proof + *off); *off += 4;
    response->leaf_len = read_u32_be(proof + *off); *off += 4;
    memcpy(response->leaf_digest, proof + *off, 32); *off += 32;
    response->eval_row = read_u32_be(proof + *off); *off += 4;
    response->eval_start = read_u32_be(proof + *off); *off += 4;
    response->eval_count = read_u32_be(proof + *off); *off += 4;
    response->eval_point = read_u64_be(proof + *off); *off += 8;
    response->eval_value = read_u64_be(proof + *off); *off += 8;
    response->column_index = read_u32_be(proof + *off); *off += 4;
    response->column_count = read_u32_be(proof + *off); *off += 4;
    response->column_point = read_u64_be(proof + *off); *off += 8;
    response->column_value = read_u64_be(proof + *off); *off += 8;

    if (response->response_version != NIWI_PROOF_NATIVE_RESPONSE_VERSION ||
        response->response_count != NIWI_PROOF_NATIVE_RESPONSE_COUNT ||
        response->query_count != NIWI_PROOF_NATIVE_RESPONSE_QUERY_COUNT ||
        response->row_count == 0 ||
        response->chunk_size != NIWI_TABLEAU_CHUNK_SIZE ||
        response->eval_row >= response->row_count ||
        response->eval_start != 0 ||
        response->column_count == 0 ||
        response->column_count > response->row_count ||
        response->eval_point >= NIWI_LIGERO_FIELD_MODULUS ||
        response->eval_value >= NIWI_LIGERO_FIELD_MODULUS ||
        response->column_point >= NIWI_LIGERO_FIELD_MODULUS ||
        response->column_value >= NIWI_LIGERO_FIELD_MODULUS)
        return -1;
    return 0;
}

static int compute_native_response_digest(
    const uint8_t relation_digest[32],
    const uint8_t tableau_digest[32],
    const uint8_t tableau_root[32],
    const uint8_t challenge1[32],
    const niwi_ligero_response_t *response,
    uint8_t response_digest[32]) {
    if (!relation_digest || !tableau_digest || !challenge1 ||
        !tableau_root || !response || !response_digest)
        return -1;

    size_t len = 32 + 32 + 32 + 32 + NIWI_PROOF_NATIVE_RESPONSE_SIZE;
    uint8_t *buf = (uint8_t *)malloc(len);
    if (!buf) return -1;
    uint8_t response_bytes[NIWI_PROOF_NATIVE_RESPONSE_SIZE];
    if (serialize_ligero_response(response, response_bytes) != 0) {
        free(buf);
        return -1;
    }
    size_t off = 0;
    memcpy(buf + off, relation_digest, 32); off += 32;
    memcpy(buf + off, tableau_digest, 32); off += 32;
    memcpy(buf + off, tableau_root, 32); off += 32;
    memcpy(buf + off, challenge1, 32); off += 32;
    memcpy(buf + off, response_bytes, NIWI_PROOF_NATIVE_RESPONSE_SIZE);
    off += NIWI_PROOF_NATIVE_RESPONSE_SIZE;
    niwi_hash_one_shot("NRSP", buf, len, response_digest);
    free(buf);
    return off == len ? 0 : -1;
}

static int compute_native_body_challenges(
    const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE],
    const uint8_t opening[NIWI_KLP22_OPENING_SIZE],
    const uint8_t circuit_digest[32],
    const uint8_t statement_digest[32],
    const uint8_t tableau_root[32],
    const uint8_t response_digest[32],
    uint8_t challenge1[32],
    uint8_t challenge2[32]) {
    niwi_challenge_schedule_t schedule;
    if (!commitment || !opening || !circuit_digest || !statement_digest ||
        !tableau_root || !response_digest || !challenge1 || !challenge2)
        return -1;
    if (niwi_schedule_init(&schedule, 1, 0,
                           NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID) != 0 ||
        niwi_schedule_bind_share_commitment(&schedule, commitment) != 0 ||
        niwi_schedule_bind_statement(&schedule, circuit_digest,
                                     statement_digest, tableau_root) != 0 ||
        niwi_schedule_derive_challenge1(&schedule, challenge1) != 0 ||
        niwi_schedule_open_share(&schedule, opening) != 0 ||
        niwi_schedule_bind_response(&schedule, response_digest) != 0 ||
        niwi_schedule_derive_challenge2(&schedule, challenge2) != 0)
        return -1;
    return 0;
}

static int compute_native_body_challenge1(
    const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE],
    const uint8_t circuit_digest[32],
    const uint8_t statement_digest[32],
    const uint8_t tableau_root[32],
    uint8_t challenge1[32]) {
    niwi_challenge_schedule_t schedule;
    if (!commitment || !circuit_digest || !statement_digest ||
        !tableau_root || !challenge1)
        return -1;
    if (niwi_schedule_init(&schedule, 1, 0,
                           NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID) != 0 ||
        niwi_schedule_bind_share_commitment(&schedule, commitment) != 0 ||
        niwi_schedule_bind_statement(&schedule, circuit_digest,
                                     statement_digest, tableau_root) != 0 ||
        niwi_schedule_derive_challenge1(&schedule, challenge1) != 0)
        return -1;
    return 0;
}

static void compute_native_body_final_digest(
    niwi_relation_id_t relation_id,
    uint32_t param_id,
    uint32_t tableau_count,
    uint32_t row_count,
    const uint8_t tableau_digest[32],
    const uint8_t tableau_root[32],
    const uint8_t relation_digest[32],
    const uint8_t challenge1[32],
    const uint8_t response_digest[32],
    const uint8_t challenge2[32],
    uint32_t opening_index,
    uint32_t path_len,
    uint32_t opening_leaf_len,
    const uint8_t opening_digest[32],
    uint8_t out[32]) {
    uint8_t preimage[10 * 4 + 7 * 32];
    size_t off = 0;
    write_u32_be(preimage + off, NIWI_PROOF_NATIVE_BODY_VERSION); off += 4;
    write_u32_be(preimage + off, NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID); off += 4;
    write_u32_be(preimage + off, param_id); off += 4;
    write_u32_be(preimage + off, row_count); off += 4;
    write_u32_be(preimage + off, NIWI_TABLEAU_CHUNK_SIZE); off += 4;
    write_u32_be(preimage + off, tableau_count); off += 4;
    write_u32_be(preimage + off, (uint32_t)relation_id); off += 4;
    write_u32_be(preimage + off, opening_index); off += 4;
    write_u32_be(preimage + off, path_len); off += 4;
    write_u32_be(preimage + off, opening_leaf_len); off += 4;
    memcpy(preimage + off, tableau_digest, 32); off += 32;
    memcpy(preimage + off, tableau_root, 32); off += 32;
    memcpy(preimage + off, relation_digest, 32); off += 32;
    memcpy(preimage + off, challenge1, 32); off += 32;
    memcpy(preimage + off, response_digest, 32); off += 32;
    memcpy(preimage + off, challenge2, 32); off += 32;
    memcpy(preimage + off, opening_digest, 32); off += 32;
    niwi_hash_one_shot(NIWI_TAG_PROOF, preimage, off, out);
}

static int append_native_proof_body(niwi_ctx_t *ctx,
                                    const uint8_t circuit_digest[32],
                                    const uint8_t statement_digest[32],
                                    const uint8_t tableau_digest[32],
                                    const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE],
                                    const uint8_t opening[NIWI_KLP22_OPENING_SIZE],
                                    const niwi_tableau_entry_t *tableau_entries,
                                    size_t tableau_count,
                                    const uint8_t *private_inputs,
                                    size_t priv_len,
                                    uint8_t *proof, size_t proof_len,
                                    size_t *off) {
    if (!ctx || !proof || !off) return -1;
    if (!tableau_entries) return -1;
    if (!private_inputs && priv_len != 0) return -1;
    if (ctx->relation_id == NIWI_RELATION_NONE) return -1;
    if (tableau_count == 0 || tableau_count > UINT32_MAX) return -1;
    uint32_t row_count = tableau_row_count(tableau_count);
    uint32_t column_count = tableau_column_count(tableau_count, row_count);
    uint32_t param_id = ligero_param_id(row_count, column_count);
    if (param_id == 0) return -1;
    if (tableau_count > (SIZE_MAX - NIWI_PROOF_NATIVE_BODY_BASE_SIZE) /
                            NIWI_PROOF_TABLEAU_ENTRY_SIZE)
        return -1;
    uint8_t relation_digest[32];
    uint8_t tableau_root[32];
    uint8_t merkle_path[NIWI_TABLEAU_MAX_MERKLE_DEPTH][32];
    size_t path_len = 0;
    uint8_t challenge1[32];
    niwi_ligero_response_t response;
    uint8_t response_bytes[NIWI_PROOF_NATIVE_RESPONSE_SIZE];
    uint8_t response_digest[32];
    uint8_t challenge2[32];
    uint8_t final_digest[32];
    if (compute_tableau_merkle_path(tableau_entries, tableau_count, 0,
                                    tableau_root, NULL, &path_len) != 0)
        return -1;
    compute_relation_digest(ctx->relation_id, circuit_digest,
                            statement_digest, tableau_digest,
                            relation_digest);
    if (compute_native_body_challenge1(commitment, circuit_digest,
                                       statement_digest, tableau_root,
                                       challenge1) != 0)
        return -1;
    if (build_ligero_response(challenge1, tableau_entries, tableau_count,
                              row_count,
                              &response) != 0 ||
        serialize_ligero_response(&response, response_bytes) != 0 ||
        compute_native_response_digest(relation_digest, tableau_digest,
                                       tableau_root, challenge1, &response,
                                       response_digest) != 0)
        return -1;
    if (compute_native_body_challenges(commitment, opening,
                                       circuit_digest, statement_digest,
                                       tableau_root, response_digest,
                                       challenge1, challenge2) != 0)
        return -1;
    uint32_t opening_index =
        tableau_opening_index(challenge2, tableau_count);
    if (compute_tableau_merkle_path(tableau_entries, tableau_count,
                                    opening_index, tableau_root,
                                    merkle_path, &path_len) != 0 ||
        path_len > NIWI_TABLEAU_MAX_MERKLE_DEPTH)
        return -1;
    const uint8_t *opening_digest =
        tableau_entries[opening_index].digest;
    uint8_t *opening_leaf = NULL;
    size_t opening_leaf_len = 0;
    if (build_tableau_leaf_fragment(private_inputs, priv_len,
                                    tableau_entries[opening_index].offset,
                                    tableau_entries[opening_index].row,
                                    1, ctx->relation_id, statement_digest,
                                    &opening_leaf, &opening_leaf_len) != 0 ||
        opening_leaf_len != tableau_entries[opening_index].leaf_len ||
        opening_leaf_len > UINT32_MAX) {
        free(opening_leaf);
        return -1;
    }
    size_t payload_size = NIWI_PROOF_NATIVE_BODY_BASE_PAYLOAD_SIZE +
                          path_len * 32 +
                          tableau_count * NIWI_PROOF_TABLEAU_ENTRY_SIZE +
                          opening_leaf_len;
    if (payload_size > UINT32_MAX || *off + 8 + payload_size > proof_len) {
        free(opening_leaf);
        return -1;
    }
    compute_native_body_final_digest(ctx->relation_id,
                                     param_id,
                                     (uint32_t)tableau_count,
                                     row_count,
                                     tableau_digest, tableau_root,
                                     relation_digest,
                                     challenge1, response_digest,
                                     challenge2,
                                     opening_index, (uint32_t)path_len,
                                     (uint32_t)opening_leaf_len,
                                     opening_digest,
                                     final_digest);

    memcpy(proof + *off, NIWI_PROOF_NATIVE_BODY_TAG, 4); *off += 4;
    write_u32_be(proof + *off, (uint32_t)payload_size); *off += 4;
    write_u32_be(proof + *off, NIWI_PROOF_NATIVE_BODY_VERSION); *off += 4;
    write_u32_be(proof + *off, NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID); *off += 4;
    write_u32_be(proof + *off, param_id); *off += 4;
    write_u32_be(proof + *off, row_count); *off += 4;
    write_u32_be(proof + *off, NIWI_TABLEAU_CHUNK_SIZE); *off += 4;
    write_u32_be(proof + *off, (uint32_t)tableau_count); *off += 4;
    write_u32_be(proof + *off, (uint32_t)ctx->relation_id); *off += 4;
    write_u32_be(proof + *off, opening_index); *off += 4;
    write_u32_be(proof + *off, (uint32_t)path_len); *off += 4;
    write_u32_be(proof + *off, (uint32_t)opening_leaf_len); *off += 4;
    memcpy(proof + *off, tableau_digest, 32); *off += 32;
    memcpy(proof + *off, tableau_root, 32); *off += 32;
    memcpy(proof + *off, relation_digest, 32); *off += 32;
    memcpy(proof + *off, challenge1, 32); *off += 32;
    memcpy(proof + *off, response_bytes, NIWI_PROOF_NATIVE_RESPONSE_SIZE);
    *off += NIWI_PROOF_NATIVE_RESPONSE_SIZE;
    memcpy(proof + *off, response_digest, 32); *off += 32;
    memcpy(proof + *off, challenge2, 32); *off += 32;
    memcpy(proof + *off, opening_digest, 32); *off += 32;
    memcpy(proof + *off, final_digest, 32); *off += 32;
    for (size_t i = 0; i < path_len; i++) {
        memcpy(proof + *off, merkle_path[i], 32);
        *off += 32;
    }
    if (append_tableau_entries(proof, proof_len, off,
                               tableau_entries, tableau_count) != 0) {
        free(opening_leaf);
        return -1;
    }
    memcpy(proof + *off, opening_leaf, opening_leaf_len);
    *off += opening_leaf_len;
    free(opening_leaf);
    return 0;
}

static int parse_longfellow_body(niwi_ctx_t *ctx,
                                 const uint8_t *proof, size_t proof_len,
                                 size_t *off,
                                 const uint8_t *public_inputs, size_t pub_len,
                                 int require_for_relation) {
    if (!ctx || !proof || !off || *off > proof_len) return -1;
    int needs_body = require_for_relation && !ctx->validate &&
                     (ctx->relation_id == NIWI_RELATION_ZKCC_BIP340 ||
                      ctx->relation_id == NIWI_RELATION_ZKCC_P256 ||
                      ctx->relation_id == NIWI_RELATION_RPBSCH);
    if (*off == proof_len) {
        if (needs_body) {
            set_error(ctx, "niwi_verify: missing Longfellow proof body");
            return -1;
        }
        return 0;
    }
    if (proof_len - *off < 8 ||
        memcmp(proof + *off, NIWI_PROOF_LONGFELLOW_BODY_TAG, 4) != 0) {
        if (needs_body) {
            set_error(ctx, "niwi_verify: missing Longfellow proof body");
            return -1;
        }
        return 0;
    }
    *off += 4;
    uint32_t body_len = read_u32_be(proof + *off); *off += 4;
    if ((size_t)body_len > proof_len - *off) {
        set_error(ctx, "niwi_verify: invalid Longfellow proof body length");
        return -1;
    }
    if (ctx->relation_id == NIWI_RELATION_ZKCC_BIP340 &&
        niwi_bip340_ligero_verify(public_inputs, pub_len,
                                   proof + *off, body_len) != 0) {
        set_error(ctx, "niwi_verify: invalid Longfellow proof body");
        return -1;
    }
    if (ctx->relation_id == NIWI_RELATION_ZKCC_P256 &&
        niwi_zkcc_p256_ligero_verify(ctx->artifact, ctx->artifact_len,
                                      public_inputs, pub_len,
                                      proof + *off, body_len) != 0) {
        set_error(ctx, "niwi_verify: invalid Longfellow proof body");
        return -1;
    }
    if (ctx->relation_id == NIWI_RELATION_RPBSCH &&
        niwi_rpbsch_ligero_verify_ctx(ctx->rpbsch_runtime,
                                      public_inputs, pub_len,
                                      proof + *off, body_len) != 0) {
        set_error(ctx, "niwi_verify: invalid Longfellow proof body");
        return -1;
    }
    *off += body_len;
    return 0;
}

static int parse_native_proof_body(niwi_ctx_t *ctx,
                                   const uint8_t *proof, size_t proof_len,
                                   size_t *off,
                                   const uint8_t circuit_digest[32],
                                   const uint8_t statement_digest[32],
                                   const uint8_t commitment[NIWI_KLP22_COMMIT_SIZE],
                                   const uint8_t opening[NIWI_KLP22_OPENING_SIZE],
                                   uint8_t tableau_digest_out[32],
                                   niwi_tableau_entry_t **entries_out,
                                   size_t *tableau_count_out,
                                   niwi_ligero_response_t *response_out,
                                   int require_relation) {
    if (!ctx || !proof || !off || !tableau_digest_out || !tableau_count_out)
        return -1;
    if (*off == proof_len) {
        if (require_relation) {
            set_error(ctx, "niwi_verify: missing native proof body");
            return -1;
        }
        return 0;
    }
    if (*off + NIWI_PROOF_NATIVE_BODY_BASE_SIZE > proof_len ||
        memcmp(proof + *off, NIWI_PROOF_NATIVE_BODY_TAG, 4) != 0) {
        set_error(ctx, "niwi_verify: invalid trailing proof section");
        return -1;
    }
    *off += 4;
    uint32_t payload_size = read_u32_be(proof + *off);
    if (payload_size < NIWI_PROOF_NATIVE_BODY_BASE_PAYLOAD_SIZE ||
        *off + 4 + payload_size > proof_len) {
        set_error(ctx, "niwi_verify: invalid native proof body length");
        return -1;
    }
    *off += 4;
    size_t payload_end = *off + payload_size;
    if (read_u32_be(proof + *off) != NIWI_PROOF_NATIVE_BODY_VERSION) {
        set_error(ctx, "niwi_verify: unsupported native proof body version");
        return -1;
    }
    *off += 4;
    if (read_u32_be(proof + *off) != NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID) {
        set_error(ctx, "niwi_verify: unsupported native proof body protocol");
        return -1;
    }
    *off += 4;
    uint32_t param_id = read_u32_be(proof + *off);
    *off += 4;
    uint32_t row_count = read_u32_be(proof + *off);
    if (row_count == 0 || row_count > NIWI_TABLEAU_MAX_ROWS) {
        set_error(ctx, "niwi_verify: native proof tableau row mismatch");
        return -1;
    }
    *off += 4;
    if (read_u32_be(proof + *off) != NIWI_TABLEAU_CHUNK_SIZE) {
        set_error(ctx, "niwi_verify: native proof tableau chunk mismatch");
        return -1;
    }
    *off += 4;
    uint32_t tableau_count = read_u32_be(proof + *off);
    if (tableau_count == 0 || tableau_count > NIWI_TABLEAU_MAX_LEAVES ||
        row_count != tableau_row_count(tableau_count)) {
        set_error(ctx, "niwi_verify: native proof tableau count mismatch");
        return -1;
    }
    uint32_t column_count = tableau_column_count(tableau_count, row_count);
    if (param_id != ligero_param_id(row_count, column_count)) {
        set_error(ctx, "niwi_verify: unsupported native proof body parameters");
        return -1;
    }
    *off += 4;
    uint32_t relation_id = read_u32_be(proof + *off); *off += 4;
    if (ctx->relation_id == NIWI_RELATION_NONE ||
        relation_id != (uint32_t)ctx->relation_id) {
        set_error(ctx, "niwi_verify: relation id mismatch");
        return -1;
    }
    uint32_t opening_index = read_u32_be(proof + *off); *off += 4;
    if (opening_index >= tableau_count) {
        set_error(ctx, "niwi_verify: native proof opening index mismatch");
        return -1;
    }
    uint32_t path_len = read_u32_be(proof + *off); *off += 4;
    if (path_len > NIWI_TABLEAU_MAX_MERKLE_DEPTH) {
        set_error(ctx, "niwi_verify: native proof Merkle path mismatch");
        return -1;
    }
    uint32_t opening_leaf_len = read_u32_be(proof + *off); *off += 4;
    if (opening_leaf_len < NIWI_TABLEAU_RELATION_LEAF_HEADER_SIZE ||
        opening_leaf_len > NIWI_TABLEAU_RELATION_LEAF_HEADER_SIZE +
                           NIWI_TABLEAU_CHUNK_SIZE) {
        set_error(ctx, "niwi_verify: native proof opening leaf mismatch");
        return -1;
    }

    uint8_t claimed_tableau_digest[32];
    memcpy(claimed_tableau_digest, proof + *off, 32);
    *off += 32;
    uint8_t claimed_tableau_root[32];
    memcpy(claimed_tableau_root, proof + *off, 32);
    *off += 32;

    uint8_t expected[32];
    compute_relation_digest(ctx->relation_id, circuit_digest,
                            statement_digest, claimed_tableau_digest, expected);
    if (memcmp(proof + *off, expected, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof relation mismatch");
        return -1;
    }
    *off += 32;

    uint8_t challenge1[32];
    uint8_t challenge2[32];
    niwi_ligero_response_t response;
    uint8_t claimed_response_digest[32];
    if (compute_native_body_challenge1(commitment, circuit_digest,
                                       statement_digest,
                                       claimed_tableau_root,
                                       challenge1) != 0) {
        set_error(ctx, "niwi_verify: native proof challenge mismatch");
        return -1;
    }
    if (memcmp(proof + *off, challenge1, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof challenge mismatch");
        return -1;
    }
    *off += 32;
    if (parse_ligero_response(proof, payload_end, off, &response) != 0) {
        set_error(ctx, "niwi_verify: invalid native proof response");
        return -1;
    }
    memcpy(claimed_response_digest, proof + *off, 32);
    *off += 32;
    if (compute_native_body_challenges(commitment, opening,
                                       circuit_digest, statement_digest,
                                       claimed_tableau_root,
                                       claimed_response_digest,
                                       challenge1, challenge2) != 0) {
        set_error(ctx, "niwi_verify: native proof query challenge mismatch");
        return -1;
    }
    if (memcmp(proof + *off, challenge2, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof query challenge mismatch");
        return -1;
    }
    *off += 32;
    uint8_t claimed_opening_digest[32];
    memcpy(claimed_opening_digest, proof + *off, 32);
    *off += 32;
    uint8_t final_digest[32];
    compute_native_body_final_digest(ctx->relation_id,
                                     param_id,
                                     (uint32_t)tableau_count,
                                     row_count,
                                     claimed_tableau_digest,
                                     claimed_tableau_root, expected,
                                     challenge1, claimed_response_digest,
                                     challenge2,
                                     opening_index, path_len,
                                     opening_leaf_len,
                                     claimed_opening_digest,
                                     final_digest);
    if (memcmp(proof + *off, final_digest, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof final digest mismatch");
        return -1;
    }
    *off += 32;
    if ((size_t)path_len > (payload_end - *off) / 32) {
        set_error(ctx, "niwi_verify: native proof Merkle path mismatch");
        return -1;
    }
    uint8_t merkle_path[NIWI_TABLEAU_MAX_MERKLE_DEPTH][32];
    for (uint32_t i = 0; i < path_len; i++) {
        memcpy(merkle_path[i], proof + *off, 32);
        *off += 32;
    }

    uint8_t computed_tableau_digest[32];
    niwi_tableau_entry_t *parsed_entries = NULL;
    niwi_tableau_entry_t **parsed_entries_out =
        entries_out ? entries_out : &parsed_entries;
    if (parse_tableau_entries(proof, payload_end, off, tableau_count,
                              row_count, 1,
                              parsed_entries_out,
                              computed_tableau_digest) != 0) {
        set_error(ctx, "niwi_verify: invalid native proof tableau entries");
        return -1;
    }
    if ((size_t)opening_leaf_len > payload_end - *off) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof opening leaf mismatch");
        return -1;
    }
    const uint8_t *opening_leaf = proof + *off;
    *off += opening_leaf_len;
    if (*off != payload_end) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: invalid native proof body length");
        return -1;
    }
    if (memcmp(claimed_tableau_digest, computed_tableau_digest, 32) != 0) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof tableau mismatch");
        return -1;
    }
    niwi_tableau_entry_t *entries_for_root =
        entries_out ? *entries_out : parsed_entries;
    niwi_ligero_response_t expected_response;
    uint8_t computed_response_digest[32];
    if (build_ligero_response(challenge1, entries_for_root, tableau_count,
                              row_count,
                              &expected_response) != 0 ||
        response.query_index >= tableau_count ||
        response.query_index != expected_response.query_index ||
        response.row != expected_response.row ||
        response.offset != expected_response.offset ||
        response.leaf_len != expected_response.leaf_len ||
        response.eval_row != expected_response.eval_row ||
        response.eval_start != expected_response.eval_start ||
        response.eval_count != expected_response.eval_count ||
        response.eval_point != expected_response.eval_point ||
        response.eval_value != expected_response.eval_value ||
        response.column_index != expected_response.column_index ||
        response.column_count != expected_response.column_count ||
        response.column_point != expected_response.column_point ||
        response.column_value != expected_response.column_value ||
        memcmp(response.leaf_digest, expected_response.leaf_digest, 32) != 0 ||
        compute_native_response_digest(expected, claimed_tableau_digest,
                                       claimed_tableau_root,
                                       challenge1, &response,
                                       computed_response_digest) != 0 ||
        memcmp(claimed_response_digest, computed_response_digest, 32) != 0) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof response mismatch");
        return -1;
    }
    if (tableau_opening_index(challenge2, tableau_count) != opening_index) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof opening index mismatch");
        return -1;
    }
    if (memcmp(entries_for_root[opening_index].digest,
               claimed_opening_digest, 32) != 0) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof opening digest mismatch");
        return -1;
    }
    uint8_t computed_opening_digest[32];
    niwi_hash_one_shot(NIWI_TAG_LEAF, opening_leaf, opening_leaf_len,
                       computed_opening_digest);
    if (memcmp(computed_opening_digest, claimed_opening_digest, 32) != 0) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof opening leaf mismatch");
        return -1;
    }
    uint32_t row = 0;
    uint32_t leaf_offset = 0;
    uint32_t total_len = 0;
    const uint8_t *chunk = NULL;
    size_t chunk_len = 0;
    if (decode_tableau_leaf_fragment(opening_leaf, opening_leaf_len,
                                     1, ctx->relation_id, statement_digest,
                                     &row, &leaf_offset, &total_len,
                                     &chunk, &chunk_len) != 0 ||
        row != entries_for_root[opening_index].row ||
        leaf_offset != entries_for_root[opening_index].offset ||
        opening_leaf_len != entries_for_root[opening_index].leaf_len ||
        leaf_offset > total_len ||
        leaf_offset + chunk_len > total_len ||
        (leaf_offset + chunk_len < total_len &&
         chunk_len != NIWI_TABLEAU_CHUNK_SIZE)) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof opening leaf mismatch");
        return -1;
    }
    if (verify_tableau_merkle_path(claimed_opening_digest, opening_index,
                                   tableau_count, merkle_path, path_len,
                                   claimed_tableau_root) != 0) {
        free(parsed_entries);
        set_error(ctx, "niwi_verify: native proof Merkle path mismatch");
        return -1;
    }
    if (response_out) *response_out = response;
    free(parsed_entries);
    memcpy(tableau_digest_out, claimed_tableau_digest, 32);
    *tableau_count_out = tableau_count;
    return 0;
}

niwi_ctx_t *niwi_ctx_create(const uint8_t *circuit_artifact, size_t len) {
    return niwi_ctx_create_with_relation(circuit_artifact, len,
                                         NIWI_RELATION_NONE, NULL, NULL);
}

niwi_ctx_t *niwi_ctx_create_with_relation(
    const uint8_t *circuit_artifact, size_t len,
    niwi_relation_id_t relation_id,
    niwi_relation_validate_fn validate,
    void *validate_user_data) {
    if (!circuit_artifact && len != 0) return NULL;

    niwi_ctx_t *ctx = (niwi_ctx_t *)calloc(1, sizeof(*ctx));
    if (!ctx) return NULL;
    if (len != 0) {
        ctx->artifact = (uint8_t *)malloc(len);
        if (!ctx->artifact) {
            free(ctx);
            return NULL;
        }
        memcpy(ctx->artifact, circuit_artifact, len);
    }
    ctx->artifact_len = len;
    ctx->relation_id = relation_id;
    ctx->validate = validate;
    ctx->validate_user_data = validate_user_data;
    if (relation_id == NIWI_RELATION_RPBSCH) {
        ctx->rpbsch_runtime = niwi_rpbsch_ligero_ctx_create();
        if (!ctx->rpbsch_runtime) {
            free(ctx->artifact);
            free(ctx);
            return NULL;
        }
    }
    ctx->error[0] = '\0';
    return ctx;
}

void niwi_ctx_free(niwi_ctx_t *ctx) {
    if (!ctx) return;
    niwi_rpbsch_ligero_ctx_free(ctx->rpbsch_runtime);
    free(ctx->artifact);
    free(ctx);
}

static void set_error(niwi_ctx_t *ctx, const char *msg) {
    if (ctx && msg) {
        strncpy(ctx->error, msg, sizeof(ctx->error) - 1);
        ctx->error[sizeof(ctx->error) - 1] = '\0';
    }
}

const char *niwi_last_error(niwi_ctx_t *ctx) {
    if (!ctx) return "null context";
    return ctx->error[0] ? ctx->error : NULL;
}

const char *niwi_protocol_version(void) {
    return "niwi-v1";
}

static int validate_relation(niwi_ctx_t *ctx,
                             const uint8_t *public_inputs, size_t pub_len,
                             const uint8_t *private_inputs, size_t priv_len,
                             const char *caller) {
    if (!ctx || ctx->relation_id == NIWI_RELATION_NONE) {
        set_error(ctx, "niwi: missing relation validator");
        return -1;
    }

    int rc = -1;
    if (ctx->validate) {
        rc = ctx->validate(ctx->validate_user_data,
                           public_inputs, pub_len,
                           private_inputs, priv_len);
    } else if (ctx->relation_id == NIWI_RELATION_ZKCC_BIP340) {
        rc = niwi_bip340_relation_validate(public_inputs, pub_len,
                                           private_inputs, priv_len);
    } else if (ctx->relation_id == NIWI_RELATION_ZKCC_P256) {
        rc = niwi_zkcc_p256_relation_validate(
            ctx->artifact, ctx->artifact_len,
            public_inputs, pub_len, private_inputs, priv_len);
    } else if (ctx->relation_id == NIWI_RELATION_RPBSCH) {
        rc = niwi_rpbsch_relation_validate(public_inputs, pub_len,
                                           private_inputs, priv_len);
    } else {
        set_error(ctx, "niwi: missing relation validator");
        return -1;
    }

    if (rc != 0) {
        set_error(ctx, caller);
        return -1;
    }
    return 0;
}

static int build_proof(niwi_ctx_t *ctx,
                       const uint8_t *public_inputs, size_t pub_len,
                       const uint8_t *private_inputs, size_t priv_len,
                       uint8_t **proof_out, size_t *proof_len,
                       int relation_backed) {
    if (!ctx || !proof_out || !proof_len) return -1;
    if (!public_inputs && pub_len != 0) return -1;
    if (!private_inputs && priv_len != 0) return -1;
    if (priv_len > UINT32_MAX) return -1;

    uint8_t circuit_digest[32];
    uint8_t statement_digest[32];
    uint8_t tableau_digest[32];
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];
    niwi_tableau_entry_t *tableau_entries = NULL;
    size_t tableau_count = 0;

    niwi_hash_one_shot(NIWI_TAG_PROTO, ctx->artifact, ctx->artifact_len,
                       circuit_digest);
    niwi_hash_one_shot(NIWI_TAG_STMT, public_inputs, pub_len,
                       statement_digest);
    if (build_tableau_entries(private_inputs, priv_len,
                              relation_backed, ctx->relation_id,
                              statement_digest,
                              &tableau_entries, &tableau_count,
                              tableau_digest) != 0) {
        set_error(ctx, "niwi_prove: failed to build witness tableau leaf");
        return -1;
    }

    uint8_t commit_preimage[64];
    uint8_t commit_message[32];
    memcpy(commit_preimage, statement_digest, 32);
    memcpy(commit_preimage + 32, tableau_digest, 32);
    niwi_hash_one_shot(NIWI_TAG_EXTR, commit_preimage, sizeof(commit_preimage),
                       commit_message);
    if (niwi_klp22_commit(commit_message, sizeof(commit_message),
                          commitment, opening) != 0) {
        free(tableau_entries);
        set_error(ctx, "niwi_prove: failed to commit challenge share");
        return -1;
    }

    size_t tableau_section_size =
        4 + 4 + tableau_count * NIWI_PROOF_TABLEAU_ENTRY_SIZE;
    uint8_t *longfellow_body = NULL;
    size_t longfellow_body_len = 0;
    if (relation_backed && !ctx->validate &&
        ctx->relation_id == NIWI_RELATION_ZKCC_BIP340 &&
        niwi_bip340_ligero_prove(public_inputs, pub_len,
                                  private_inputs, priv_len,
                                  &longfellow_body,
                                  &longfellow_body_len) != 0) {
        free(tableau_entries);
        set_error(ctx, "niwi_prove: failed to build Longfellow proof body");
        return -1;
    }
    if (relation_backed && !ctx->validate &&
        ctx->relation_id == NIWI_RELATION_ZKCC_P256 &&
        niwi_zkcc_p256_ligero_prove(ctx->artifact, ctx->artifact_len,
                                     public_inputs, pub_len,
                                     private_inputs, priv_len,
                                     &longfellow_body,
                                     &longfellow_body_len) != 0) {
        free(tableau_entries);
        set_error(ctx, "niwi_prove: failed to build Longfellow proof body");
        return -1;
    }
    if (relation_backed && !ctx->validate &&
        ctx->relation_id == NIWI_RELATION_RPBSCH &&
        niwi_rpbsch_ligero_prove_ctx(ctx->rpbsch_runtime,
                                     public_inputs, pub_len,
                                     private_inputs, priv_len,
                                     &longfellow_body,
                                     &longfellow_body_len) != 0) {
        free(tableau_entries);
        set_error(ctx, "niwi_prove: failed to build Longfellow proof body");
        return -1;
    }
    if (longfellow_body_len > UINT32_MAX) {
        free(longfellow_body);
        free(tableau_entries);
        set_error(ctx, "niwi_prove: Longfellow proof body too large");
        return -1;
    }
    size_t native_body_size =
        NIWI_PROOF_NATIVE_BODY_BASE_SIZE +
        NIWI_TABLEAU_MAX_MERKLE_DEPTH * 32 +
        tableau_count * NIWI_PROOF_TABLEAU_ENTRY_SIZE +
        NIWI_TABLEAU_RELATION_LEAF_HEADER_SIZE + NIWI_TABLEAU_CHUNK_SIZE;
    size_t len = NIWI_PROOF_HEADER_SIZE + NIWI_PROOF_PARAM_SIZE +
                 (relation_backed ? native_body_size : tableau_section_size) +
                 (longfellow_body_len ? 8 + longfellow_body_len : 0);
    uint8_t *proof = (uint8_t *)calloc(1, len);
    if (!proof) {
        free(longfellow_body);
        free(tableau_entries);
        set_error(ctx, "niwi_prove: out of memory");
        return -1;
    }

    size_t off = 0;
    memcpy(proof + off, "NIWI", 4); off += 4;
    write_u32_be(proof + off, 0x00010000); off += 4;
    write_u32_be(proof + off, 0); off += 4;
    memcpy(proof + off, circuit_digest, 32); off += 32;
    memcpy(proof + off, statement_digest, 32); off += 32;
    memcpy(proof + off, commitment, NIWI_KLP22_COMMIT_SIZE);
    off += NIWI_KLP22_COMMIT_SIZE;
    memcpy(proof + off, opening, NIWI_KLP22_OPENING_SIZE);
    off += NIWI_KLP22_OPENING_SIZE;

    /* Minimal parameter block accepted by the extractor scaffold. */
    write_u32_be(proof + off, 1); off += 4; /* block */
    write_u32_be(proof + off, 1); off += 4; /* dblock */
    write_u32_be(proof + off, 1); off += 4; /* r */
    write_u32_be(proof + off, 1); off += 4; /* block_enc */
    write_u32_be(proof + off, 4); off += 4; /* nrow */
    write_u32_be(proof + off, 1); off += 4; /* nreq */
    write_u32_be(proof + off, 0); off += 4; /* mc_pathlen */

    if (!relation_backed) {
        memcpy(proof + off, NIWI_PROOF_TABLEAU_TAG, 4); off += 4;
        write_u32_be(proof + off, (uint32_t)tableau_count); off += 4;
        if (append_tableau_entries(proof, len, &off,
                                   tableau_entries, tableau_count) != 0) {
            free(tableau_entries);
            free(proof);
            set_error(ctx, "niwi_prove: failed to build tableau section");
            return -1;
        }
    } else if (append_native_proof_body(ctx, circuit_digest, statement_digest,
                                        tableau_digest, commitment, opening,
                                        tableau_entries,
                                        tableau_count,
                                        private_inputs, priv_len,
                                        proof, len, &off) != 0) {
        free(longfellow_body);
        free(tableau_entries);
        free(proof);
        set_error(ctx, "niwi_prove: failed to build native proof body");
        return -1;
    }
    if (longfellow_body_len != 0) {
        if (off + 8 + longfellow_body_len > len) {
            free(longfellow_body);
            free(tableau_entries);
            free(proof);
            set_error(ctx, "niwi_prove: failed to append Longfellow proof body");
            return -1;
        }
        memcpy(proof + off, NIWI_PROOF_LONGFELLOW_BODY_TAG, 4); off += 4;
        write_u32_be(proof + off, (uint32_t)longfellow_body_len); off += 4;
        memcpy(proof + off, longfellow_body, longfellow_body_len);
        off += longfellow_body_len;
    }

    free(longfellow_body);
    free(tableau_entries);
    *proof_out = proof;
    *proof_len = off;
    ctx->error[0] = '\0';
    return 0;
}

static int verify_proof_envelope(niwi_ctx_t *ctx,
                                 const uint8_t *proof, size_t proof_len,
                                 const uint8_t *public_inputs, size_t pub_len,
                                 int require_relation) {
    if (!ctx || !proof || (!public_inputs && pub_len != 0)) return -1;
    if (proof_len < NIWI_PROOF_HEADER_SIZE + NIWI_PROOF_PARAM_SIZE +
                    4 + 4 + NIWI_PROOF_TABLEAU_ENTRY_SIZE) {
        set_error(ctx, "niwi_verify: proof too short");
        return -1;
    }

    size_t off = 0;
    if (memcmp(proof + off, "NIWI", 4) != 0) {
        set_error(ctx, "niwi_verify: invalid proof magic");
        return -1;
    }
    off += 4;
    if (read_u32_be(proof + off) != 0x00010000) {
        set_error(ctx, "niwi_verify: unsupported proof version");
        return -1;
    }
    off += 4;
    if (read_u32_be(proof + off) != 0) {
        set_error(ctx, "niwi_verify: unsupported protocol id");
        return -1;
    }
    off += 4;

    uint8_t expected_circuit[32];
    uint8_t expected_statement[32];
    niwi_hash_one_shot(NIWI_TAG_PROTO, ctx->artifact, ctx->artifact_len,
                       expected_circuit);
    niwi_hash_one_shot(NIWI_TAG_STMT, public_inputs, pub_len,
                       expected_statement);

    if (memcmp(proof + off, expected_circuit, 32) != 0) {
        set_error(ctx, "niwi_verify: circuit digest mismatch");
        return -1;
    }
    off += 32;
    if (memcmp(proof + off, expected_statement, 32) != 0) {
        set_error(ctx, "niwi_verify: statement digest mismatch");
        return -1;
    }
    off += 32;

    const uint8_t *commitment = proof + off;
    off += NIWI_KLP22_COMMIT_SIZE;
    const uint8_t *opening = proof + off;
    off += NIWI_KLP22_OPENING_SIZE;

    uint8_t tableau_digest[32];
    size_t tableau_count = 0;
    off += NIWI_PROOF_PARAM_SIZE;
    if (require_relation) {
        if (parse_native_proof_body(ctx, proof, proof_len, &off,
                                    expected_circuit, expected_statement,
                                    commitment, opening,
                                    tableau_digest, NULL, &tableau_count,
                                    NULL,
                                    require_relation) != 0)
            return -1;
        if (parse_longfellow_body(ctx, proof, proof_len, &off,
                                  public_inputs, pub_len, 1) != 0)
            return -1;
    } else {
        if (off + 4 <= proof_len &&
            memcmp(proof + off, NIWI_PROOF_NATIVE_BODY_TAG, 4) == 0) {
            if (parse_native_proof_body(ctx, proof, proof_len, &off,
                                        expected_circuit, expected_statement,
                                        commitment, opening,
                                        tableau_digest, NULL, &tableau_count,
                                        NULL,
                                        0) != 0)
                return -1;
            if (parse_longfellow_body(ctx, proof, proof_len, &off,
                                      public_inputs, pub_len, 0) != 0)
                return -1;
        } else {
            if (parse_tableau_section(proof, proof_len, &off,
                                      tableau_digest, NULL, &tableau_count) != 0) {
                set_error(ctx, "niwi_verify: invalid tableau section");
                return -1;
            }
            if (off < proof_len &&
                parse_native_proof_body(ctx, proof, proof_len, &off,
                                        expected_circuit, expected_statement,
                                        commitment, opening,
                                        tableau_digest, NULL, &tableau_count,
                                        NULL,
                                        0) != 0)
                return -1;
            if (parse_longfellow_body(ctx, proof, proof_len, &off,
                                      public_inputs, pub_len, 0) != 0)
                return -1;
        }
    }

    uint8_t commit_preimage[64];
    uint8_t commit_message[32];
    memcpy(commit_preimage, expected_statement, 32);
    memcpy(commit_preimage + 32, tableau_digest, 32);
    niwi_hash_one_shot(NIWI_TAG_EXTR, commit_preimage, sizeof(commit_preimage),
                       commit_message);
    if (niwi_klp22_verify(commitment, commit_message, sizeof(commit_message),
                          opening) != 0) {
        set_error(ctx, "niwi_verify: invalid KLP22 opening");
        return -1;
    }

    if (off != proof_len) {
        set_error(ctx, "niwi_verify: trailing bytes");
        return -1;
    }

    ctx->error[0] = '\0';
    return 0;
}

int niwi_envelope_prove_unchecked(niwi_ctx_t *ctx,
                                  const uint8_t *public_inputs, size_t pub_len,
                                  const uint8_t *private_inputs, size_t priv_len,
                                  uint8_t **proof_out, size_t *proof_len) {
    return build_proof(ctx, public_inputs, pub_len, private_inputs, priv_len,
                       proof_out, proof_len, 0);
}

int niwi_prove(niwi_ctx_t *ctx,
               const uint8_t *public_inputs, size_t pub_len,
               const uint8_t *private_inputs, size_t priv_len,
               uint8_t **proof_out, size_t *proof_len) {
    if (validate_relation(ctx, public_inputs, pub_len,
                          private_inputs, priv_len,
                          "niwi_prove: relation validation failed") != 0)
        return -1;
    return build_proof(ctx, public_inputs, pub_len, private_inputs, priv_len,
                       proof_out, proof_len, 1);
}

int niwi_envelope_prove_observed_unchecked(
    niwi_ctx_t *ctx,
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len,
    uint8_t **proof_out, size_t *proof_len,
    uint8_t **gamma_out, size_t *gamma_len) {
    if (!gamma_out || !gamma_len) return -1;
    if (build_proof(ctx, public_inputs, pub_len, private_inputs, priv_len,
                    proof_out, proof_len, 0) != 0)
        return -1;

    niwi_npro_t *npro = niwi_npro_create(1);
    if (!npro) {
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to create NPRO");
        return -1;
    }
    if (record_tableau_queries(npro, private_inputs, priv_len,
                               0, NIWI_RELATION_NONE, NULL) != 0) {
        niwi_npro_free(npro);
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to record witness leaf");
        return -1;
    }
    niwi_npro_set_cutoff(npro);
    size_t gs = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(gs);
    if (!gamma || niwi_npro_serialize_gamma(npro, gamma, gs) != gs) {
        free(gamma);
        niwi_npro_free(npro);
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to serialize Gamma");
        return -1;
    }
    niwi_npro_free(npro);
    *gamma_out = gamma;
    *gamma_len = gs;
    ctx->error[0] = '\0';
    return 0;
}

int niwi_prove_observed(niwi_ctx_t *ctx,
                        const uint8_t *public_inputs, size_t pub_len,
                        const uint8_t *private_inputs, size_t priv_len,
                        uint8_t **proof_out, size_t *proof_len,
                        uint8_t **gamma_out, size_t *gamma_len) {
    if (validate_relation(ctx, public_inputs, pub_len,
                          private_inputs, priv_len,
                          "niwi_prove_observed: relation validation failed") != 0)
        return -1;
    if (!gamma_out || !gamma_len) return -1;
    if (build_proof(ctx, public_inputs, pub_len, private_inputs, priv_len,
                    proof_out, proof_len, 1) != 0)
        return -1;

    niwi_npro_t *npro = niwi_npro_create(1);
    if (!npro) {
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to create NPRO");
        return -1;
    }
    uint8_t statement_digest[32];
    niwi_hash_one_shot(NIWI_TAG_STMT, public_inputs, pub_len,
                       statement_digest);
    if (record_tableau_queries(npro, private_inputs, priv_len,
                               1, ctx->relation_id,
                               statement_digest) != 0) {
        niwi_npro_free(npro);
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to record witness leaf");
        return -1;
    }
    niwi_npro_set_cutoff(npro);
    size_t gs = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(gs);
    if (!gamma || niwi_npro_serialize_gamma(npro, gamma, gs) != gs) {
        free(gamma);
        niwi_npro_free(npro);
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to serialize Gamma");
        return -1;
    }
    niwi_npro_free(npro);
    *gamma_out = gamma;
    *gamma_len = gs;
    ctx->error[0] = '\0';
    return 0;
}

int niwi_envelope_verify(niwi_ctx_t *ctx,
                         const uint8_t *proof, size_t proof_len,
                         const uint8_t *public_inputs, size_t pub_len) {
    return verify_proof_envelope(ctx, proof, proof_len, public_inputs, pub_len, 0);
}

int niwi_verify(niwi_ctx_t *ctx,
                const uint8_t *proof, size_t proof_len,
                const uint8_t *public_inputs, size_t pub_len) {
    return verify_proof_envelope(ctx, proof, proof_len, public_inputs, pub_len, 1);
}

int niwi_envelope_extract_unchecked(niwi_ctx_t *ctx,
                                    const uint8_t *proof, size_t proof_len,
                                    const uint8_t *gamma, size_t gamma_len,
                                    const uint8_t *public_inputs, size_t pub_len,
                                    uint8_t **witness_out, size_t *witness_len) {
    if (!ctx || !gamma || !witness_out || !witness_len) return -1;
    if (verify_proof_envelope(ctx, proof, proof_len, public_inputs, pub_len, 0) != 0)
        return -1;
    if (gamma_len == 0) {
        set_error(ctx, "niwi_extract: missing Gamma");
        return -1;
    }

    size_t off = NIWI_PROOF_HEADER_SIZE + NIWI_PROOF_PARAM_SIZE;
    uint8_t tableau_digest[32];
    niwi_tableau_entry_t *entries = NULL;
    size_t entry_count = 0;
    niwi_ligero_response_t extracted_response;
    memset(&extracted_response, 0, sizeof(extracted_response));
    int has_native_response = 0;
    if (off + 4 <= proof_len &&
        memcmp(proof + off, NIWI_PROOF_NATIVE_BODY_TAG, 4) == 0) {
        if (parse_native_proof_body(ctx, proof, proof_len, &off,
                                    proof + 12, proof + 44,
                                    proof + 76, proof + 108,
                                    tableau_digest, &entries, &entry_count,
                                    &extracted_response,
                                    0) != 0)
            return -1;
        if (parse_longfellow_body(ctx, proof, proof_len, &off,
                                  public_inputs, pub_len, 0) != 0)
            return -1;
        has_native_response = 1;
    } else {
        if (parse_tableau_section(proof, proof_len, &off,
                                  tableau_digest, &entries, &entry_count) != 0) {
            set_error(ctx, "niwi_extract: invalid tableau section");
            return -1;
        }
        if (off < proof_len &&
            parse_native_proof_body(ctx, proof, proof_len, &off,
                                    proof + 12, proof + 44,
                                    proof + 76, proof + 108,
                                    tableau_digest, NULL, &entry_count,
                                    NULL,
                                    0) != 0) {
            free(entries);
            return -1;
        }
        if (parse_longfellow_body(ctx, proof, proof_len, &off,
                                  public_inputs, pub_len, 0) != 0) {
            free(entries);
            return -1;
        }
    }
    if (off != proof_len) {
        free(entries);
        set_error(ctx, "niwi_extract: trailing bytes");
        return -1;
    }
    niwi_npro_t *npro = niwi_npro_deserialize_gamma(gamma, gamma_len);
    if (!npro) {
        free(entries);
        set_error(ctx, "niwi_extract: failed to parse Gamma");
        return -1;
    }

    uint8_t *witness = NULL;
    uint8_t *covered = NULL;
    niwi_tableau_entry_t *recovered_entries = NULL;
    size_t witness_total = 0;
    if (has_native_response) {
        recovered_entries = (niwi_tableau_entry_t *)
            calloc(entry_count, sizeof(*recovered_entries));
        if (!recovered_entries) {
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: out of memory");
            return -1;
        }
    }
    for (size_t i = 0; i < entry_count; i++) {
        size_t recovered_len = 0;
        if (!niwi_npro_lookup(npro, NIWI_TAG_LEAF, entries[i].digest,
                              NULL, &recovered_len) ||
            recovered_len != entries[i].leaf_len) {
            free(covered);
            free(witness);
            free(recovered_entries);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: missing tableau leaf query in Gamma");
            return -1;
        }

        uint8_t *leaf = (uint8_t *)malloc(recovered_len ? recovered_len : 1);
        if (!leaf) {
            free(covered);
            free(witness);
            free(recovered_entries);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: out of memory");
            return -1;
        }
        size_t out_cap = recovered_len;
        if (!niwi_npro_lookup(npro, NIWI_TAG_LEAF, entries[i].digest,
                              leaf, &out_cap) || out_cap != recovered_len) {
            free(leaf);
            free(covered);
            free(witness);
            free(recovered_entries);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: failed to copy tableau leaf query");
            return -1;
        }

        uint32_t row = 0;
        uint32_t chunk_offset = 0;
        uint32_t total_len = 0;
        const uint8_t *chunk = NULL;
        size_t chunk_len = 0;
        int relation_leaf =
            recovered_len >= 4 &&
            memcmp(leaf, NIWI_TABLEAU_RELATION_LEAF_TAG, 4) == 0;
        if (decode_tableau_leaf_fragment(leaf, recovered_len,
                                         relation_leaf, ctx->relation_id,
                                         proof + 44, &row,
                                         &chunk_offset, &total_len,
                                         &chunk, &chunk_len) != 0 ||
            row != entries[i].row || chunk_offset != entries[i].offset) {
            free(leaf);
            free(covered);
            free(witness);
            free(recovered_entries);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: malformed tableau leaf");
            return -1;
        }
        if (recovered_entries) {
            recovered_entries[i] = entries[i];
            niwi_hash_one_shot(NIWI_TAG_LEAF, leaf, recovered_len,
                               recovered_entries[i].digest);
            if (memcmp(recovered_entries[i].digest, entries[i].digest, 32) != 0) {
                free(leaf);
                free(covered);
                free(witness);
                free(recovered_entries);
                free(entries);
                niwi_npro_free(npro);
                set_error(ctx, "niwi_extract: recovered tableau digest mismatch");
                return -1;
            }
        }
        if (!witness) {
            witness_total = total_len;
            witness = (uint8_t *)calloc(witness_total ? witness_total : 1, 1);
            covered = (uint8_t *)calloc(witness_total ? witness_total : 1, 1);
            if (!witness || !covered) {
                free(leaf);
                free(covered);
                free(witness);
                free(recovered_entries);
                free(entries);
                niwi_npro_free(npro);
                set_error(ctx, "niwi_extract: out of memory");
                return -1;
            }
        } else if (witness_total != total_len) {
            free(leaf);
            free(covered);
            free(witness);
            free(recovered_entries);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: inconsistent tableau leaf length");
            return -1;
        }
        if ((size_t)chunk_offset + chunk_len > witness_total) {
            free(leaf);
            free(covered);
            free(witness);
            free(recovered_entries);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: tableau leaf out of range");
            return -1;
        }
        for (size_t j = 0; j < chunk_len; j++) {
            size_t pos = (size_t)chunk_offset + j;
            if (covered[pos]) {
                free(leaf);
                free(covered);
                free(witness);
                free(recovered_entries);
                free(entries);
                niwi_npro_free(npro);
                set_error(ctx, "niwi_extract: overlapping tableau leaves");
                return -1;
            }
            covered[pos] = 1;
        }
        if (chunk_len != 0) memcpy(witness + chunk_offset, chunk, chunk_len);
        free(leaf);
    }
    if (has_native_response) {
        uint8_t recovered_tableau_digest[32];
        uint64_t recovered_eval = 0;
        uint64_t recovered_column_eval = 0;
        uint32_t recovered_eval_count = 0;
        uint32_t recovered_column_count = 0;
        if (compute_tableau_digest(recovered_entries, entry_count,
                                   recovered_tableau_digest) != 0 ||
            memcmp(recovered_tableau_digest, tableau_digest, 32) != 0 ||
            extracted_response.row_count != tableau_row_count(entry_count) ||
            extracted_response.eval_start != 0 ||
            extracted_response.eval_row >= extracted_response.row_count ||
            evaluate_tableau_digest_row(recovered_entries, entry_count,
                                        extracted_response.row_count,
                                        extracted_response.eval_row,
                                        extracted_response.eval_point,
                                        &recovered_eval,
                                        &recovered_eval_count) != 0 ||
            extracted_response.eval_count != recovered_eval_count ||
            recovered_eval != extracted_response.eval_value ||
            extracted_response.column_count > extracted_response.row_count ||
            evaluate_tableau_digest_column(recovered_entries, entry_count,
                                           extracted_response.row_count,
                                           extracted_response.column_index,
                                           extracted_response.column_point,
                                           &recovered_column_eval,
                                           &recovered_column_count) != 0 ||
            extracted_response.column_count != recovered_column_count ||
            recovered_column_eval != extracted_response.column_value) {
            free(covered);
            free(witness);
            free(recovered_entries);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: recovered response mismatch");
            return -1;
        }
    }
    niwi_npro_free(npro);
    free(recovered_entries);
    free(entries);

    for (size_t i = 0; i < witness_total; i++) {
        if (!covered[i]) {
            free(covered);
            free(witness);
            set_error(ctx, "niwi_extract: incomplete tableau witness");
            return -1;
        }
    }
    free(covered);
    *witness_out = witness;
    *witness_len = witness_total;
    ctx->error[0] = '\0';
    return 0;
}

int niwi_extract(niwi_ctx_t *ctx,
                 const uint8_t *proof, size_t proof_len,
                 const uint8_t *gamma, size_t gamma_len,
                 const uint8_t *public_inputs, size_t pub_len,
                 uint8_t **witness_out, size_t *witness_len) {
    uint8_t *witness = NULL;
    size_t len = 0;
    if (verify_proof_envelope(ctx, proof, proof_len, public_inputs, pub_len, 1) != 0)
        return -1;
    if (niwi_envelope_extract_unchecked(ctx, proof, proof_len, gamma, gamma_len,
                                        public_inputs, pub_len,
                                        &witness, &len) != 0)
        return -1;
    if (validate_relation(ctx, public_inputs, pub_len, witness, len,
                          "niwi_extract: extracted witness does not satisfy relation") != 0) {
        free(witness);
        return -1;
    }
    *witness_out = witness;
    *witness_len = len;
    ctx->error[0] = '\0';
    return 0;
}

void niwi_free_buffer(uint8_t *buf) {
    free(buf);
}
