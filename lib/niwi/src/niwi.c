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
#include "commitment.h"
#include "hash.h"
#include "npro.h"
#include "relations/bip340_relation.h"
#include "relations/zkcc_p256_relation.h"

#include <stdlib.h>
#include <string.h>

#define NIWI_PROOF_HEADER_SIZE (4 + 4 + 4 + 32 + 32 + NIWI_KLP22_COMMIT_SIZE + NIWI_KLP22_OPENING_SIZE)
#define NIWI_PROOF_PARAM_SIZE (7 * 4)
#define NIWI_PROOF_TABLEAU_TAG "TAB0"
#define NIWI_PROOF_TABLEAU_ENTRY_SIZE (4 + 4 + 4 + 4 + 32)
#define NIWI_TABLEAU_LEAF_TAG "TBL0"
#define NIWI_TABLEAU_LEAF_HEADER_SIZE (4 + 4 + 4 + 4)
#define NIWI_TABLEAU_CHUNK_SIZE 32
#define NIWI_TABLEAU_MAX_LEAVES 4096
#define NIWI_PROOF_NATIVE_BODY_TAG "LIG0"
#define NIWI_PROOF_NATIVE_BODY_VERSION 0x00010000
#define NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID 0
#define NIWI_PROOF_NATIVE_BODY_PARAM_ID 1
#define NIWI_PROOF_NATIVE_BODY_ROWS 1
#define NIWI_PROOF_NATIVE_BODY_PAYLOAD_SIZE (7 * 4 + 5 * 32)
#define NIWI_PROOF_NATIVE_BODY_SIZE (4 + 4 + NIWI_PROOF_NATIVE_BODY_PAYLOAD_SIZE)

typedef struct {
    uint32_t index;
    uint32_t row;
    uint32_t offset;
    uint32_t leaf_len;
    uint8_t digest[32];
} niwi_tableau_entry_t;

struct niwi_ctx {
    uint8_t *artifact;
    size_t   artifact_len;
    niwi_relation_id_t relation_id;
    niwi_relation_validate_fn validate;
    void *validate_user_data;
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

static size_t tableau_leaf_count(size_t priv_len) {
    if (priv_len == 0) return 1;
    return (priv_len + NIWI_TABLEAU_CHUNK_SIZE - 1) / NIWI_TABLEAU_CHUNK_SIZE;
}

static int build_tableau_leaf_fragment(const uint8_t *private_inputs,
                                       size_t priv_len,
                                       size_t offset,
                                       uint8_t **leaf_out,
                                       size_t *leaf_len) {
    if (!leaf_out || !leaf_len) return -1;
    if (!private_inputs && priv_len != 0) return -1;
    if (priv_len > UINT32_MAX) return -1;
    if (offset > priv_len) return -1;

    size_t chunk_len = priv_len - offset;
    if (chunk_len > NIWI_TABLEAU_CHUNK_SIZE)
        chunk_len = NIWI_TABLEAU_CHUNK_SIZE;
    if (chunk_len > UINT32_MAX) return -1;

    size_t len = NIWI_TABLEAU_LEAF_HEADER_SIZE + chunk_len;
    uint8_t *leaf = (uint8_t *)malloc(len ? len : 1);
    if (!leaf) return -1;

    size_t off = 0;
    memcpy(leaf + off, NIWI_TABLEAU_LEAF_TAG, 4); off += 4;
    write_u32_be(leaf + off, 0); off += 4; /* witness row */
    write_u32_be(leaf + off, (uint32_t)offset); off += 4;
    write_u32_be(leaf + off, (uint32_t)priv_len); off += 4;
    if (chunk_len != 0) memcpy(leaf + off, private_inputs + offset, chunk_len);

    *leaf_out = leaf;
    *leaf_len = len;
    return 0;
}

static int decode_tableau_leaf_fragment(const uint8_t *leaf, size_t leaf_len,
                                        uint32_t *row,
                                        uint32_t *offset,
                                        uint32_t *total_len,
                                        const uint8_t **chunk,
                                        size_t *chunk_len) {
    if (!leaf || !row || !offset || !total_len || !chunk || !chunk_len)
        return -1;
    if (leaf_len < NIWI_TABLEAU_LEAF_HEADER_SIZE) return -1;

    size_t off = 0;
    if (memcmp(leaf + off, NIWI_TABLEAU_LEAF_TAG, 4) != 0) return -1;
    off += 4;
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

static int build_tableau_entries(const uint8_t *private_inputs, size_t priv_len,
                                 niwi_tableau_entry_t **entries_out,
                                 size_t *count_out,
                                 uint8_t tableau_digest[32]) {
    if (!entries_out || !count_out || !tableau_digest) return -1;
    if (!private_inputs && priv_len != 0) return -1;
    if (priv_len > UINT32_MAX) return -1;

    size_t count = tableau_leaf_count(priv_len);
    if (count == 0 || count > NIWI_TABLEAU_MAX_LEAVES) return -1;
    niwi_tableau_entry_t *entries =
        (niwi_tableau_entry_t *)calloc(count, sizeof(*entries));
    if (!entries) return -1;

    for (size_t i = 0; i < count; i++) {
        size_t offset = i * NIWI_TABLEAU_CHUNK_SIZE;
        uint8_t *leaf = NULL;
        size_t leaf_len = 0;
        if (build_tableau_leaf_fragment(private_inputs, priv_len, offset,
                                        &leaf, &leaf_len) != 0 ||
            leaf_len > UINT32_MAX) {
            free(leaf);
            free(entries);
            return -1;
        }
        entries[i].index = (uint32_t)i;
        entries[i].row = 0;
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
                                  size_t priv_len) {
    if (!npro) return -1;
    if (!private_inputs && priv_len != 0) return -1;

    size_t count = tableau_leaf_count(priv_len);
    if (count == 0 || count > NIWI_TABLEAU_MAX_LEAVES) return -1;

    for (size_t i = 0; i < count; i++) {
        size_t offset = i * NIWI_TABLEAU_CHUNK_SIZE;
        uint8_t *leaf = NULL;
        size_t leaf_len = 0;
        uint8_t digest[32];
        if (build_tableau_leaf_fragment(private_inputs, priv_len, offset,
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

static void compute_native_body_challenges(const uint8_t relation_digest[32],
                                           const uint8_t tableau_digest[32],
                                           uint8_t challenge1[32],
                                           uint8_t challenge2[32]) {
    uint8_t preimage1[64];
    memcpy(preimage1, relation_digest, 32);
    memcpy(preimage1 + 32, tableau_digest, 32);
    niwi_hash_one_shot(NIWI_TAG_FSCH, preimage1, sizeof(preimage1),
                       challenge1);

    uint8_t preimage2[64];
    memcpy(preimage2, challenge1, 32);
    memcpy(preimage2 + 32, tableau_digest, 32);
    niwi_hash_one_shot(NIWI_TAG_PROOF, preimage2, sizeof(preimage2),
                       challenge2);
}

static void compute_native_body_final_digest(
    niwi_relation_id_t relation_id,
    uint32_t tableau_count,
    const uint8_t tableau_digest[32],
    const uint8_t relation_digest[32],
    const uint8_t challenge1[32],
    const uint8_t challenge2[32],
    uint8_t out[32]) {
    uint8_t preimage[7 * 4 + 4 * 32];
    size_t off = 0;
    write_u32_be(preimage + off, NIWI_PROOF_NATIVE_BODY_VERSION); off += 4;
    write_u32_be(preimage + off, NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID); off += 4;
    write_u32_be(preimage + off, NIWI_PROOF_NATIVE_BODY_PARAM_ID); off += 4;
    write_u32_be(preimage + off, NIWI_PROOF_NATIVE_BODY_ROWS); off += 4;
    write_u32_be(preimage + off, NIWI_TABLEAU_CHUNK_SIZE); off += 4;
    write_u32_be(preimage + off, tableau_count); off += 4;
    write_u32_be(preimage + off, (uint32_t)relation_id); off += 4;
    memcpy(preimage + off, tableau_digest, 32); off += 32;
    memcpy(preimage + off, relation_digest, 32); off += 32;
    memcpy(preimage + off, challenge1, 32); off += 32;
    memcpy(preimage + off, challenge2, 32); off += 32;
    niwi_hash_one_shot(NIWI_TAG_PROOF, preimage, off, out);
}

static int append_native_proof_body(niwi_ctx_t *ctx,
                                    const uint8_t circuit_digest[32],
                                    const uint8_t statement_digest[32],
                                    const uint8_t tableau_digest[32],
                                    size_t tableau_count,
                                    uint8_t *proof, size_t proof_len,
                                    size_t *off) {
    if (!ctx || !proof || !off) return -1;
    if (*off + NIWI_PROOF_NATIVE_BODY_SIZE > proof_len) return -1;
    if (ctx->relation_id == NIWI_RELATION_NONE) return -1;
    if (tableau_count == 0 || tableau_count > UINT32_MAX) return -1;

    uint8_t relation_digest[32];
    uint8_t challenge1[32];
    uint8_t challenge2[32];
    uint8_t final_digest[32];
    compute_relation_digest(ctx->relation_id, circuit_digest,
                            statement_digest, tableau_digest,
                            relation_digest);
    compute_native_body_challenges(relation_digest, tableau_digest,
                                   challenge1, challenge2);
    compute_native_body_final_digest(ctx->relation_id,
                                     (uint32_t)tableau_count,
                                     tableau_digest, relation_digest,
                                     challenge1, challenge2, final_digest);

    memcpy(proof + *off, NIWI_PROOF_NATIVE_BODY_TAG, 4); *off += 4;
    write_u32_be(proof + *off, NIWI_PROOF_NATIVE_BODY_PAYLOAD_SIZE); *off += 4;
    write_u32_be(proof + *off, NIWI_PROOF_NATIVE_BODY_VERSION); *off += 4;
    write_u32_be(proof + *off, NIWI_PROOF_NATIVE_BODY_PROTOCOL_ID); *off += 4;
    write_u32_be(proof + *off, NIWI_PROOF_NATIVE_BODY_PARAM_ID); *off += 4;
    write_u32_be(proof + *off, NIWI_PROOF_NATIVE_BODY_ROWS); *off += 4;
    write_u32_be(proof + *off, NIWI_TABLEAU_CHUNK_SIZE); *off += 4;
    write_u32_be(proof + *off, (uint32_t)tableau_count); *off += 4;
    write_u32_be(proof + *off, (uint32_t)ctx->relation_id); *off += 4;
    memcpy(proof + *off, tableau_digest, 32); *off += 32;
    memcpy(proof + *off, relation_digest, 32); *off += 32;
    memcpy(proof + *off, challenge1, 32); *off += 32;
    memcpy(proof + *off, challenge2, 32); *off += 32;
    memcpy(proof + *off, final_digest, 32); *off += 32;
    return 0;
}

static int parse_native_proof_body(niwi_ctx_t *ctx,
                                   const uint8_t *proof, size_t proof_len,
                                   size_t *off,
                                   const uint8_t circuit_digest[32],
                                   const uint8_t statement_digest[32],
                                   const uint8_t tableau_digest[32],
                                   size_t tableau_count,
                                   int require_relation) {
    if (!ctx || !proof || !off) return -1;
    if (*off == proof_len) {
        if (require_relation) {
            set_error(ctx, "niwi_verify: missing native proof body");
            return -1;
        }
        return 0;
    }
    if (*off + NIWI_PROOF_NATIVE_BODY_SIZE != proof_len ||
        memcmp(proof + *off, NIWI_PROOF_NATIVE_BODY_TAG, 4) != 0) {
        set_error(ctx, "niwi_verify: invalid trailing proof section");
        return -1;
    }
    *off += 4;
    if (read_u32_be(proof + *off) != NIWI_PROOF_NATIVE_BODY_PAYLOAD_SIZE) {
        set_error(ctx, "niwi_verify: invalid native proof body length");
        return -1;
    }
    *off += 4;
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
    if (read_u32_be(proof + *off) != NIWI_PROOF_NATIVE_BODY_PARAM_ID) {
        set_error(ctx, "niwi_verify: unsupported native proof body parameters");
        return -1;
    }
    *off += 4;
    if (read_u32_be(proof + *off) != NIWI_PROOF_NATIVE_BODY_ROWS) {
        set_error(ctx, "niwi_verify: native proof tableau row mismatch");
        return -1;
    }
    *off += 4;
    if (read_u32_be(proof + *off) != NIWI_TABLEAU_CHUNK_SIZE) {
        set_error(ctx, "niwi_verify: native proof tableau chunk mismatch");
        return -1;
    }
    *off += 4;
    if (read_u32_be(proof + *off) != tableau_count) {
        set_error(ctx, "niwi_verify: native proof tableau count mismatch");
        return -1;
    }
    *off += 4;
    uint32_t relation_id = read_u32_be(proof + *off); *off += 4;
    if (ctx->relation_id == NIWI_RELATION_NONE ||
        relation_id != (uint32_t)ctx->relation_id) {
        set_error(ctx, "niwi_verify: relation id mismatch");
        return -1;
    }

    if (memcmp(proof + *off, tableau_digest, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof tableau mismatch");
        return -1;
    }
    *off += 32;

    uint8_t expected[32];
    compute_relation_digest(ctx->relation_id, circuit_digest,
                            statement_digest, tableau_digest, expected);
    if (memcmp(proof + *off, expected, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof relation mismatch");
        return -1;
    }
    *off += 32;

    uint8_t challenge1[32];
    uint8_t challenge2[32];
    compute_native_body_challenges(expected, tableau_digest,
                                   challenge1, challenge2);
    if (memcmp(proof + *off, challenge1, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof challenge mismatch");
        return -1;
    }
    *off += 32;
    if (memcmp(proof + *off, challenge2, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof query challenge mismatch");
        return -1;
    }
    *off += 32;
    uint8_t final_digest[32];
    compute_native_body_final_digest(ctx->relation_id,
                                     (uint32_t)tableau_count,
                                     tableau_digest, expected,
                                     challenge1, challenge2, final_digest);
    if (memcmp(proof + *off, final_digest, 32) != 0) {
        set_error(ctx, "niwi_verify: native proof final digest mismatch");
        return -1;
    }
    *off += 32;
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
    ctx->error[0] = '\0';
    return ctx;
}

void niwi_ctx_free(niwi_ctx_t *ctx) {
    if (!ctx) return;
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
    size_t len = NIWI_PROOF_HEADER_SIZE + NIWI_PROOF_PARAM_SIZE +
                 tableau_section_size +
                 (relation_backed ? NIWI_PROOF_NATIVE_BODY_SIZE : 0);
    uint8_t *proof = (uint8_t *)calloc(1, len);
    if (!proof) {
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

    memcpy(proof + off, NIWI_PROOF_TABLEAU_TAG, 4); off += 4;
    write_u32_be(proof + off, (uint32_t)tableau_count); off += 4;
    for (size_t i = 0; i < tableau_count; i++) {
        write_u32_be(proof + off, tableau_entries[i].index); off += 4;
        write_u32_be(proof + off, tableau_entries[i].row); off += 4;
        write_u32_be(proof + off, tableau_entries[i].offset); off += 4;
        write_u32_be(proof + off, tableau_entries[i].leaf_len); off += 4;
        memcpy(proof + off, tableau_entries[i].digest, 32); off += 32;
    }

    if (relation_backed &&
        append_native_proof_body(ctx, circuit_digest, statement_digest,
                                 tableau_digest, tableau_count,
                                 proof, len, &off) != 0) {
        free(tableau_entries);
        free(proof);
        set_error(ctx, "niwi_prove: failed to build native proof body");
        return -1;
    }

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

    off += NIWI_PROOF_PARAM_SIZE;
    uint8_t tableau_digest[32];
    size_t tableau_count = 0;
    if (parse_tableau_section(proof, proof_len, &off,
                              tableau_digest, NULL, &tableau_count) != 0) {
        set_error(ctx, "niwi_verify: invalid tableau section");
        return -1;
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

    if (parse_native_proof_body(ctx, proof, proof_len, &off,
                                expected_circuit, expected_statement,
                                tableau_digest, tableau_count,
                                require_relation) != 0)
        return -1;
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
    if (record_tableau_queries(npro, private_inputs, priv_len) != 0) {
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
    if (record_tableau_queries(npro, private_inputs, priv_len) != 0) {
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
    if (parse_tableau_section(proof, proof_len, &off,
                              tableau_digest, &entries, &entry_count) != 0) {
        set_error(ctx, "niwi_extract: invalid tableau section");
        return -1;
    }
    if (off < proof_len &&
        parse_native_proof_body(ctx, proof, proof_len, &off,
                                proof + 12, proof + 44, tableau_digest,
                                entry_count, 0) != 0) {
        free(entries);
        return -1;
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
    size_t witness_total = 0;
    for (size_t i = 0; i < entry_count; i++) {
        size_t recovered_len = 0;
        if (!niwi_npro_lookup(npro, NIWI_TAG_LEAF, entries[i].digest,
                              NULL, &recovered_len) ||
            recovered_len != entries[i].leaf_len) {
            free(covered);
            free(witness);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: missing tableau leaf query in Gamma");
            return -1;
        }

        uint8_t *leaf = (uint8_t *)malloc(recovered_len ? recovered_len : 1);
        if (!leaf) {
            free(covered);
            free(witness);
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
        if (decode_tableau_leaf_fragment(leaf, recovered_len, &row,
                                         &chunk_offset, &total_len,
                                         &chunk, &chunk_len) != 0 ||
            row != entries[i].row || chunk_offset != entries[i].offset) {
            free(leaf);
            free(covered);
            free(witness);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: malformed tableau leaf");
            return -1;
        }
        if (!witness) {
            witness_total = total_len;
            witness = (uint8_t *)calloc(witness_total ? witness_total : 1, 1);
            covered = (uint8_t *)calloc(witness_total ? witness_total : 1, 1);
            if (!witness || !covered) {
                free(leaf);
                free(covered);
                free(witness);
                free(entries);
                niwi_npro_free(npro);
                set_error(ctx, "niwi_extract: out of memory");
                return -1;
            }
        } else if (witness_total != total_len) {
            free(leaf);
            free(covered);
            free(witness);
            free(entries);
            niwi_npro_free(npro);
            set_error(ctx, "niwi_extract: inconsistent tableau leaf length");
            return -1;
        }
        if ((size_t)chunk_offset + chunk_len > witness_total) {
            free(leaf);
            free(covered);
            free(witness);
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
    niwi_npro_free(npro);
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
