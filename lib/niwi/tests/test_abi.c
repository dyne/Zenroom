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
#include "npro.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* A dummy circuit artifact; the stub does not parse it. */
static const uint8_t dummy_artifact[] = {0x01, 0x02, 0x03, 0x04};

static int test_relation_validate(void *user_data,
                                  const uint8_t *public_inputs, size_t pub_len,
                                  const uint8_t *private_inputs, size_t priv_len) {
    (void)user_data;
    return pub_len == 1 && public_inputs[0] == 'p' &&
           priv_len == 1 && private_inputs[0] == 'w' ? 0 : -1;
}

static int test_relation_validate_nonempty(void *user_data,
                                           const uint8_t *public_inputs,
                                           size_t pub_len,
                                           const uint8_t *private_inputs,
                                           size_t priv_len) {
    (void)user_data;
    return pub_len == 1 && public_inputs[0] == 'p' &&
           private_inputs && priv_len > 0 ? 0 : -1;
}

static uint8_t *serialize_npro(niwi_npro_t *npro, size_t *gamma_len);

static int proof_has_tag(const uint8_t *proof, size_t proof_len,
                         const char tag[4]) {
    if (!proof || proof_len < 4) return 0;
    for (size_t i = 0; i + 4 <= proof_len; i++) {
        if (memcmp(proof + i, tag, 4) == 0) return 1;
    }
    return 0;
}

static uint32_t read_u32_be_test(const uint8_t *in) {
    return ((uint32_t)in[0] << 24) |
           ((uint32_t)in[1] << 16) |
           ((uint32_t)in[2] << 8) |
           (uint32_t)in[3];
}

#define TEST_NATIVE_LIG0_PAYLOAD_OFFSET 8
#define TEST_NATIVE_LIG0_FIXED_WORDS 10
#define TEST_NATIVE_LIG0_DIGEST_SIZE 32
#define TEST_NATIVE_LIG0_DIGESTS_BEFORE_RESPONSE 4
#define TEST_NATIVE_LIG0_RESPONSE_SIZE 72
#define TEST_NATIVE_LIG0_BASE_PAYLOAD_SIZE \
    (TEST_NATIVE_LIG0_FIXED_WORDS * 4 + \
     8 * TEST_NATIVE_LIG0_DIGEST_SIZE + TEST_NATIVE_LIG0_RESPONSE_SIZE)
#define TEST_NATIVE_LIG0_RESPONSE_OFFSET \
    (TEST_NATIVE_LIG0_PAYLOAD_OFFSET + TEST_NATIVE_LIG0_FIXED_WORDS * 4 + \
     TEST_NATIVE_LIG0_DIGESTS_BEFORE_RESPONSE * TEST_NATIVE_LIG0_DIGEST_SIZE)
#define TEST_NATIVE_LIG0_RESPONSE_DIGEST_OFFSET \
    (TEST_NATIVE_LIG0_RESPONSE_OFFSET + TEST_NATIVE_LIG0_RESPONSE_SIZE)
#define TEST_NATIVE_LIG0_CHALLENGE2_OFFSET \
    (TEST_NATIVE_LIG0_RESPONSE_DIGEST_OFFSET + TEST_NATIVE_LIG0_DIGEST_SIZE)
#define TEST_NATIVE_LIG0_OPENING_DIGEST_OFFSET \
    (TEST_NATIVE_LIG0_CHALLENGE2_OFFSET + TEST_NATIVE_LIG0_DIGEST_SIZE)
#define TEST_NATIVE_LIG0_PATH_OFFSET \
    (TEST_NATIVE_LIG0_OPENING_DIGEST_OFFSET + 2 * TEST_NATIVE_LIG0_DIGEST_SIZE)

static uint32_t proof_tableau_leaf_count(const uint8_t *proof,
                                         size_t proof_len) {
    if (!proof || proof_len < 8) return 0;
    for (size_t i = 0; i + 8 <= proof_len; i++) {
        if (memcmp(proof + i, "TAB0", 4) == 0)
            return read_u32_be_test(proof + i + 4);
    }
    return 0;
}

typedef struct {
    uint32_t payload_size;
    uint32_t version;
    uint32_t protocol_id;
    uint32_t param_id;
    uint32_t rows;
    uint32_t chunk_size;
    uint32_t tableau_count;
    uint32_t relation_id;
    uint32_t opening_index;
    uint32_t path_len;
    uint32_t opening_leaf_len;
    uint32_t response_version;
    uint32_t response_count;
    uint32_t query_count;
    uint32_t response_query_index;
    size_t path_offset;
    size_t tableau_entries_offset;
    size_t opening_leaf_offset;
    uint32_t selected_entry_leaf_len;
} native_ligero_meta_t;

static size_t find_proof_tag(const uint8_t *proof, size_t proof_len,
                             const char tag[4]) {
    if (!proof || proof_len < 4) return proof_len;
    for (size_t i = 0; i + 4 <= proof_len; i++) {
        if (memcmp(proof + i, tag, 4) == 0) return i;
    }
    return proof_len;
}

static void parse_native_ligero_meta(const uint8_t *proof, size_t proof_len,
                                     native_ligero_meta_t *meta) {
    size_t body = find_proof_tag(proof, proof_len, "LIG0");
    assert(body != proof_len);
    assert(body + 8 + TEST_NATIVE_LIG0_BASE_PAYLOAD_SIZE <= proof_len);

    meta->payload_size = read_u32_be_test(proof + body + 4);
    meta->version = read_u32_be_test(proof + body + 8);
    meta->protocol_id = read_u32_be_test(proof + body + 12);
    meta->param_id = read_u32_be_test(proof + body + 16);
    meta->rows = read_u32_be_test(proof + body + 20);
    meta->chunk_size = read_u32_be_test(proof + body + 24);
    meta->tableau_count = read_u32_be_test(proof + body + 28);
    meta->relation_id = read_u32_be_test(proof + body + 32);
    meta->opening_index = read_u32_be_test(proof + body + 36);
    meta->path_len = read_u32_be_test(proof + body + 40);
    meta->opening_leaf_len = read_u32_be_test(proof + body + 44);
    assert(memcmp(proof + body + TEST_NATIVE_LIG0_RESPONSE_OFFSET,
                  "NRSP", 4) == 0);
    meta->response_version = read_u32_be_test(
        proof + body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 4);
    meta->response_count = read_u32_be_test(
        proof + body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 8);
    meta->query_count = read_u32_be_test(
        proof + body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 12);
    meta->response_query_index = read_u32_be_test(
        proof + body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 24);
    meta->path_offset = body + TEST_NATIVE_LIG0_PATH_OFFSET;
    meta->tableau_entries_offset = meta->path_offset + meta->path_len * 32;
    assert(meta->opening_index < meta->tableau_count);
    meta->selected_entry_leaf_len = read_u32_be_test(
        proof + meta->tableau_entries_offset + meta->opening_index * 48 + 12);
    meta->opening_leaf_offset =
        meta->tableau_entries_offset + meta->tableau_count * 48;

    assert(body + 8 + meta->payload_size <= proof_len);
    assert(meta->opening_leaf_offset + meta->opening_leaf_len ==
           body + 8 + meta->payload_size);
}

static void assert_relation_verify_rejects_mutation(
    niwi_ctx_t *ctx, uint8_t *proof, size_t proof_len,
    const uint8_t *public_inputs, size_t pub_len, size_t offset) {
    uint8_t saved = proof[offset];
    proof[offset] ^= 0x01;
    assert(niwi_verify(ctx, proof, proof_len, public_inputs, pub_len) != 0);
    proof[offset] = saved;
}

static void assert_current_native_profile(const native_ligero_meta_t *meta,
                                          uint32_t expected_tableau_count,
                                          uint32_t expected_path_len,
                                          uint32_t expected_opening_leaf_len) {
    assert(meta->version == 0x00010000);
    assert(meta->protocol_id == 0);
    assert(meta->param_id == 1);
    assert(meta->rows == 1);
    assert(meta->chunk_size == 32);
    assert(meta->tableau_count == expected_tableau_count);
    assert(meta->relation_id == NIWI_RELATION_ZKCC_P256);
    assert(meta->path_len == expected_path_len);
    assert(meta->response_version == 0x00010000);
    assert(meta->response_count == 1);
    assert(meta->query_count == 1);
    assert(meta->response_query_index < meta->tableau_count);
    assert(meta->opening_leaf_len == meta->selected_entry_leaf_len);
    if (expected_opening_leaf_len != 0)
        assert(meta->opening_leaf_len == expected_opening_leaf_len);
    assert(meta->payload_size ==
           TEST_NATIVE_LIG0_BASE_PAYLOAD_SIZE + expected_path_len * 32 +
           expected_tableau_count * 48 + meta->opening_leaf_len);
}

static void test_create_free(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);
    niwi_ctx_free(ctx);
    printf("  PASS test_create_free\n");
}

static void test_null_ctx_free(void) {
    niwi_ctx_free(NULL); /* must not crash */
    printf("  PASS test_null_ctx_free\n");
}

static void test_last_error(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);

    /* Should be NULL before any error. */
    const char *e = niwi_last_error(ctx);
    assert(e == NULL);

    uint8_t proof[] = {'b', 'a', 'd'};
    int rc = niwi_verify(ctx, proof, sizeof(proof), NULL, 0);
    assert(rc != 0);

    e = niwi_last_error(ctx);
    assert(e != NULL);
    assert(strstr(e, "short") != NULL);
    printf("  PASS test_last_error: %s\n", e);

    niwi_ctx_free(ctx);
}

static void test_last_error_null(void) {
    const char *e = niwi_last_error(NULL);
    assert(e != NULL);
    assert(strstr(e, "null") != NULL);
    printf("  PASS test_last_error_null\n");
}

static void test_protocol_version(void) {
    const char *v = niwi_protocol_version();
    assert(v != NULL);
    assert(strlen(v) > 0);
    printf("  PASS test_protocol_version: %s\n", v);
}

static void test_free_buffer(void) {
    /* Allocating our own buffer and freeing via niwi_free_buffer. */
    uint8_t *buf = (uint8_t *)malloc(16);
    assert(buf != NULL);
    memset(buf, 0, 16);
    niwi_free_buffer(buf); /* must not crash */

    /* Freeing NULL is safe. */
    niwi_free_buffer(NULL);
    printf("  PASS test_free_buffer\n");
}

static void test_prove_verify_extract(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);
    const uint8_t public_inputs[] = {'p', 'u', 'b'};
    const uint8_t private_inputs[] = {'w', 'i', 't', 'n', 'e', 's', 's'};
    uint8_t *proof = NULL;
    size_t proof_len = 0;

    int rc = niwi_envelope_prove_unchecked(ctx, public_inputs, sizeof(public_inputs),
                                           private_inputs, sizeof(private_inputs),
                                           &proof, &proof_len);
    assert(rc == 0);
    assert(proof != NULL);
    assert(proof_len > 0);
    assert(!proof_has_tag(proof, proof_len, "REL0"));
    assert(niwi_envelope_verify(ctx, proof, proof_len,
                                public_inputs, sizeof(public_inputs)) == 0);

    const uint8_t wrong_public[] = {'b', 'a', 'd'};
    assert(niwi_envelope_verify(ctx, proof, proof_len,
                                wrong_public, sizeof(wrong_public)) != 0);

    niwi_ctx_t *wrong_ctx = niwi_ctx_create((const uint8_t *)"other", 5);
    assert(wrong_ctx != NULL);
    assert(niwi_envelope_verify(wrong_ctx, proof, proof_len,
                                public_inputs, sizeof(public_inputs)) != 0);
    niwi_ctx_free(wrong_ctx);

    uint8_t saved = proof[proof_len - 1];
    proof[proof_len - 1] ^= 0x01;
    assert(niwi_envelope_verify(ctx, proof, proof_len,
                                public_inputs, sizeof(public_inputs)) != 0);
    proof[proof_len - 1] = saved;

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_envelope_extract_unchecked(ctx, proof, proof_len, NULL, 0,
                                           public_inputs, sizeof(public_inputs),
                                           &witness, &witness_len) != 0);
    assert(witness == NULL);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_prove_verify_extract\n");
}

static void test_relation_checked_prove(void) {
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        dummy_artifact, sizeof(dummy_artifact),
        NIWI_RELATION_ZKCC_P256, test_relation_validate, NULL);
    assert(ctx != NULL);

    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {'w'};
    const uint8_t bad_private[] = {'x'};
    uint8_t *proof = NULL;
    size_t proof_len = 0;

    assert(niwi_prove(ctx, public_inputs, sizeof(public_inputs),
                      bad_private, sizeof(bad_private),
                      &proof, &proof_len) != 0);
    assert(proof == NULL);

    assert(niwi_prove(ctx, public_inputs, sizeof(public_inputs),
                      private_inputs, sizeof(private_inputs),
                      &proof, &proof_len) == 0);
    assert(proof != NULL);
    assert(!proof_has_tag(proof, proof_len, "REL0"));
    assert(!proof_has_tag(proof, proof_len, "TAB0"));
    assert(proof_has_tag(proof, proof_len, "LIG0"));
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) == 0);

    size_t body = find_proof_tag(proof, proof_len, "LIG0");
    assert(body != proof_len);
    native_ligero_meta_t meta;
    parse_native_ligero_meta(proof, proof_len, &meta);
    assert_current_native_profile(&meta, 1, 0, 57);
    assert(meta.opening_index == 0);
    assert(meta.tableau_entries_offset == body + TEST_NATIVE_LIG0_PATH_OFFSET);
    assert(meta.opening_leaf_offset == body + TEST_NATIVE_LIG0_PATH_OFFSET + 48);

    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + 11);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + 15);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + 19);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + 31);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + 39);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + 43);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + 80);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_RESPONSE_OFFSET);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 11);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 15);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 24);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_RESPONSE_OFFSET + 40);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_RESPONSE_DIGEST_OFFSET);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_CHALLENGE2_OFFSET);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_OPENING_DIGEST_OFFSET);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_PATH_OFFSET + 16);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_PATH_OFFSET + 48 + 16);

    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_relation_checked_prove\n");
}

static void test_relation_observed_uses_bound_tableau_leaves(void) {
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        dummy_artifact, sizeof(dummy_artifact),
        NIWI_RELATION_ZKCC_P256, test_relation_validate, NULL);
    assert(ctx != NULL);

    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {'w'};
    uint8_t *proof = NULL;
    uint8_t *gamma = NULL;
    size_t proof_len = 0;
    size_t gamma_len = 0;

    assert(niwi_prove_observed(ctx, public_inputs, sizeof(public_inputs),
                               private_inputs, sizeof(private_inputs),
                               &proof, &proof_len, &gamma, &gamma_len) == 0);
    assert(proof != NULL);
    assert(gamma != NULL);
    assert(proof_has_tag(proof, proof_len, "LIG0"));
    assert(!proof_has_tag(proof, proof_len, "TAB0"));
    assert(proof_has_tag(gamma, gamma_len, "TBL1"));
    assert(!proof_has_tag(gamma, gamma_len, "TBL0"));

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_extract(ctx, proof, proof_len, gamma, gamma_len,
                        public_inputs, sizeof(public_inputs),
                        &witness, &witness_len) == 0);
    assert(witness_len == sizeof(private_inputs));
    assert(memcmp(witness, private_inputs, sizeof(private_inputs)) == 0);
    niwi_free_buffer(witness);

    niwi_free_buffer(gamma);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_relation_observed_uses_bound_tableau_leaves\n");
}

static void test_relation_merkle_path_for_multi_leaf_tableau(void) {
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        dummy_artifact, sizeof(dummy_artifact),
        NIWI_RELATION_ZKCC_P256, test_relation_validate_nonempty, NULL);
    assert(ctx != NULL);

    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {
        'm', 'u', 'l', 't', 'i', '-', 'l', 'e',
        'a', 'f', '-', 'w', 'i', 't', 'n', 'e',
        's', 's', '-', '0', '1', '2', '3', '4',
        '5', '6', '7', '8', '9', '-', 'a', 'b',
        'c', 'd', 'e', 'f'
    };
    uint8_t *proof = NULL;
    size_t proof_len = 0;

    assert(niwi_prove(ctx, public_inputs, sizeof(public_inputs),
                      private_inputs, sizeof(private_inputs),
                      &proof, &proof_len) == 0);
    assert(proof != NULL);
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) == 0);
    assert(!proof_has_tag(proof, proof_len, "TAB0"));

    size_t body = find_proof_tag(proof, proof_len, "LIG0");
    assert(body != proof_len);
    native_ligero_meta_t meta;
    parse_native_ligero_meta(proof, proof_len, &meta);
    assert_current_native_profile(&meta, 2, 1, 0);
    assert(meta.opening_index < meta.tableau_count);
    assert(meta.tableau_entries_offset == body + TEST_NATIVE_LIG0_PATH_OFFSET + 32);
    assert(meta.opening_leaf_offset ==
           body + TEST_NATIVE_LIG0_PATH_OFFSET + 32 + 2 * 48);
    assert_relation_verify_rejects_mutation(
        ctx, proof, proof_len, public_inputs, sizeof(public_inputs),
        body + TEST_NATIVE_LIG0_PATH_OFFSET);

    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_relation_merkle_path_for_multi_leaf_tableau\n");
}

static void test_native_ligero_profile_vectors(void) {
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        dummy_artifact, sizeof(dummy_artifact),
        NIWI_RELATION_ZKCC_P256, test_relation_validate_nonempty, NULL);
    assert(ctx != NULL);

    const uint8_t public_inputs[] = {'p'};
    const uint8_t one_leaf_private[] = {'w'};
    const uint8_t other_one_leaf_private[] = {'x'};
    const uint8_t two_leaf_private[] = {
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
        'x'
    };
    uint8_t *proof = NULL;
    uint8_t *other_proof = NULL;
    size_t proof_len = 0;
    size_t other_proof_len = 0;
    native_ligero_meta_t meta;

    assert(niwi_prove(ctx, public_inputs, sizeof(public_inputs),
                      one_leaf_private, sizeof(one_leaf_private),
                      &proof, &proof_len) == 0);
    parse_native_ligero_meta(proof, proof_len, &meta);
    assert_current_native_profile(&meta, 1, 0, 57);
    assert(meta.opening_index == 0);
    assert(niwi_prove(ctx, public_inputs, sizeof(public_inputs),
                      other_one_leaf_private, sizeof(other_one_leaf_private),
                      &other_proof, &other_proof_len) == 0);
    assert(other_proof != NULL);
    assert(memcmp(proof + find_proof_tag(proof, proof_len, "LIG0") +
                      TEST_NATIVE_LIG0_RESPONSE_DIGEST_OFFSET,
                  other_proof + find_proof_tag(other_proof, other_proof_len, "LIG0") +
                      TEST_NATIVE_LIG0_RESPONSE_DIGEST_OFFSET,
                  TEST_NATIVE_LIG0_DIGEST_SIZE) != 0);
    niwi_free_buffer(other_proof);
    other_proof = NULL;
    other_proof_len = 0;
    niwi_free_buffer(proof);
    proof = NULL;
    proof_len = 0;

    assert(niwi_prove(ctx, public_inputs, sizeof(public_inputs),
                      two_leaf_private, sizeof(two_leaf_private),
                      &proof, &proof_len) == 0);
    parse_native_ligero_meta(proof, proof_len, &meta);
    assert_current_native_profile(&meta, 2, 1, 0);
    assert(meta.opening_index < meta.tableau_count);

    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_native_ligero_profile_vectors\n");
}

static void test_prove_observed(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);
    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {'w'};
    uint8_t *proof = NULL;
    uint8_t *gamma = NULL;
    size_t proof_len = 0;
    size_t gamma_len = 0;

    assert(niwi_envelope_prove_observed_unchecked(
               ctx, public_inputs, sizeof(public_inputs),
               private_inputs, sizeof(private_inputs),
               &proof, &proof_len, &gamma, &gamma_len) == 0);
    assert(proof != NULL);
    assert(gamma != NULL);
    assert(proof_len > 0);
    assert(gamma_len > 0);
    assert(!proof_has_tag(proof, proof_len, "REL0"));
    assert(niwi_envelope_verify(ctx, proof, proof_len,
                                public_inputs, sizeof(public_inputs)) == 0);

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_envelope_extract_unchecked(ctx, proof, proof_len, gamma, gamma_len,
                                           public_inputs, sizeof(public_inputs),
                                           &witness, &witness_len) == 0);
    assert(witness_len == sizeof(private_inputs));
    assert(memcmp(witness, private_inputs, sizeof(private_inputs)) == 0);

    niwi_free_buffer(witness);

    gamma[20] ^= 0x01; /* mutate recorded tableau input, keep recorded digest */
    witness = NULL;
    witness_len = 0;
    assert(niwi_envelope_extract_unchecked(ctx, proof, proof_len, gamma, gamma_len,
                                           public_inputs, sizeof(public_inputs),
                                           &witness, &witness_len) != 0);
    assert(witness == NULL);
    gamma[16] ^= 0x01;

    gamma[gamma_len - 1] ^= 0x01;
    witness = NULL;
    witness_len = 0;
    assert(niwi_envelope_extract_unchecked(ctx, proof, proof_len, gamma, gamma_len,
                                           public_inputs, sizeof(public_inputs),
                                           &witness, &witness_len) != 0);
    assert(witness == NULL);

    niwi_free_buffer(gamma);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_prove_observed\n");
}

static void test_observed_proof_uses_tableau_fragments(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);
    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {
        'w', 'i', 't', 'n', 'e', 's', 's', '-', 'r', 'o', 'w', '-',
        'f', 'r', 'a', 'g', 'm', 'e', 'n', 't', 'a', 't', 'i', 'o',
        'n', '-', 'c', 'h', 'e', 'c', 'k', '-', '0', '1', '2', '3'
    };
    uint8_t *proof = NULL;
    uint8_t *gamma = NULL;
    size_t proof_len = 0;
    size_t gamma_len = 0;

    assert(niwi_envelope_prove_observed_unchecked(
               ctx, public_inputs, sizeof(public_inputs),
               private_inputs, sizeof(private_inputs),
               &proof, &proof_len, &gamma, &gamma_len) == 0);
    assert(proof_tableau_leaf_count(proof, proof_len) > 1);

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_envelope_extract_unchecked(ctx, proof, proof_len, gamma, gamma_len,
                                           public_inputs, sizeof(public_inputs),
                                           &witness, &witness_len) == 0);
    assert(witness_len == sizeof(private_inputs));
    assert(memcmp(witness, private_inputs, sizeof(private_inputs)) == 0);

    niwi_free_buffer(witness);
    niwi_free_buffer(gamma);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_observed_proof_uses_tableau_fragments\n");
}

static void test_wit0_shortcut_is_not_trusted(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);
    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {'w'};
    uint8_t *proof = NULL;
    size_t proof_len = 0;

    assert(niwi_envelope_prove_unchecked(ctx, public_inputs, sizeof(public_inputs),
                                         private_inputs, sizeof(private_inputs),
                                         &proof, &proof_len) == 0);

    niwi_npro_t *raw = niwi_npro_create(1);
    assert(raw != NULL);
    uint8_t digest[32];
    assert(niwi_npro_query(raw, "NL05", private_inputs, sizeof(private_inputs),
                           digest) == 0);
    niwi_npro_set_cutoff(raw);
    size_t gamma_len = 0;
    uint8_t *gamma = serialize_npro(raw, &gamma_len);

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_envelope_extract_unchecked(ctx, proof, proof_len, gamma, gamma_len,
                                           public_inputs, sizeof(public_inputs),
                                           &witness, &witness_len) != 0);
    assert(witness == NULL);

    free(gamma);
    niwi_npro_free(raw);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_wit0_shortcut_is_not_trusted\n");
}

static void test_extract_validates_recovered_relation(void) {
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        dummy_artifact, sizeof(dummy_artifact),
        NIWI_RELATION_ZKCC_P256, test_relation_validate, NULL);
    assert(ctx != NULL);
    const uint8_t public_inputs[] = {'p'};
    const uint8_t invalid_private[] = {'x'};
    uint8_t *proof = NULL;
    uint8_t *gamma = NULL;
    size_t proof_len = 0;
    size_t gamma_len = 0;

    assert(niwi_envelope_prove_observed_unchecked(
               ctx, public_inputs, sizeof(public_inputs),
               invalid_private, sizeof(invalid_private),
               &proof, &proof_len, &gamma, &gamma_len) == 0);
    assert(niwi_envelope_verify(ctx, proof, proof_len,
                                public_inputs, sizeof(public_inputs)) == 0);
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) != 0);

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_extract(ctx, proof, proof_len, gamma, gamma_len,
                        public_inputs, sizeof(public_inputs),
                        &witness, &witness_len) != 0);
    assert(witness == NULL);

    niwi_free_buffer(gamma);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_extract_validates_recovered_relation\n");
}

static void test_production_rejects_unchecked_envelope(void) {
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        dummy_artifact, sizeof(dummy_artifact),
        NIWI_RELATION_ZKCC_P256, test_relation_validate, NULL);
    assert(ctx != NULL);
    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {'w'};
    uint8_t *proof = NULL;
    uint8_t *gamma = NULL;
    size_t proof_len = 0;
    size_t gamma_len = 0;

    assert(niwi_envelope_prove_observed_unchecked(
               ctx, public_inputs, sizeof(public_inputs),
               private_inputs, sizeof(private_inputs),
               &proof, &proof_len, &gamma, &gamma_len) == 0);
    assert(!proof_has_tag(proof, proof_len, "REL0"));
    assert(niwi_envelope_verify(ctx, proof, proof_len,
                                public_inputs, sizeof(public_inputs)) == 0);
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) != 0);

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_extract(ctx, proof, proof_len, gamma, gamma_len,
                        public_inputs, sizeof(public_inputs),
                        &witness, &witness_len) != 0);
    assert(witness == NULL);

    niwi_free_buffer(gamma);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_production_rejects_unchecked_envelope\n");
}

static uint8_t *serialize_npro(niwi_npro_t *npro, size_t *gamma_len) {
    size_t len = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(len);
    assert(gamma != NULL);
    assert(niwi_npro_serialize_gamma(npro, gamma, len) == len);
    *gamma_len = len;
    return gamma;
}

static void assert_extract_fails(niwi_ctx_t *ctx,
                                 const uint8_t *proof, size_t proof_len,
                                 uint8_t *gamma, size_t gamma_len,
                                 const uint8_t *public_inputs,
                                 size_t pub_len) {
    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_envelope_extract_unchecked(ctx, proof, proof_len, gamma, gamma_len,
                                           public_inputs, pub_len,
                                           &witness, &witness_len) != 0);
    assert(witness == NULL);
}

static void test_adversarial_gamma(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);
    const uint8_t public_inputs[] = {'p'};
    const uint8_t private_inputs[] = {'w'};
    uint8_t *proof = NULL;
    size_t proof_len = 0;

    assert(niwi_envelope_prove_unchecked(ctx, public_inputs, sizeof(public_inputs),
                                         private_inputs, sizeof(private_inputs),
                                         &proof, &proof_len) == 0);

    uint8_t digest[32];
    size_t gamma_len = 0;

    niwi_npro_t *missing = niwi_npro_create(1);
    assert(missing != NULL);
    assert(niwi_npro_query(missing, "NL05", (const uint8_t *)"x", 1,
                           digest) == 0);
    niwi_npro_set_cutoff(missing);
    uint8_t *gamma = serialize_npro(missing, &gamma_len);
    assert_extract_fails(ctx, proof, proof_len, gamma, gamma_len,
                         public_inputs, sizeof(public_inputs));
    free(gamma);
    niwi_npro_free(missing);

    niwi_npro_t *post_cutoff = niwi_npro_create(1);
    assert(post_cutoff != NULL);
    niwi_npro_set_cutoff(post_cutoff);
    assert(niwi_npro_query(post_cutoff, "NL05",
                           private_inputs, sizeof(private_inputs),
                           digest) == 0);
    gamma = serialize_npro(post_cutoff, &gamma_len);
    assert_extract_fails(ctx, proof, proof_len, gamma, gamma_len,
                         public_inputs, sizeof(public_inputs));
    free(gamma);
    niwi_npro_free(post_cutoff);

    niwi_npro_t *ambiguous = niwi_npro_create(1);
    assert(ambiguous != NULL);
    assert(niwi_npro_query(ambiguous, "NL05",
                           private_inputs, sizeof(private_inputs),
                           digest) == 0);
    uint8_t other_digest[32];
    assert(niwi_npro_query(ambiguous, "NL05", (const uint8_t *)"x", 1,
                           other_digest) == 0);
    niwi_npro_set_cutoff(ambiguous);
    gamma = serialize_npro(ambiguous, &gamma_len);
    memcpy(gamma + 8 + (4 + 1 + 1 + 32) + 4 + 1 + 1, digest, 32);
    assert_extract_fails(ctx, proof, proof_len, gamma, gamma_len,
                         public_inputs, sizeof(public_inputs));
    free(gamma);
    niwi_npro_free(ambiguous);

    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_adversarial_gamma\n");
}

int main(void) {
    printf("lib/niwi C ABI tests:\n");
    test_create_free();
    test_null_ctx_free();
    test_last_error();
    test_last_error_null();
    test_protocol_version();
    test_free_buffer();
    test_prove_verify_extract();
    test_relation_checked_prove();
    test_relation_observed_uses_bound_tableau_leaves();
    test_relation_merkle_path_for_multi_leaf_tableau();
    test_native_ligero_profile_vectors();
    test_prove_observed();
    test_observed_proof_uses_tableau_fragments();
    test_wit0_shortcut_is_not_trusted();
    test_extract_validates_recovered_relation();
    test_production_rejects_unchecked_envelope();
    test_adversarial_gamma();
    printf("All C ABI tests passed.\n");
    return 0;
}
