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

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* A dummy circuit artifact; the stub does not parse it. */
static const uint8_t dummy_artifact[] = {0x01, 0x02, 0x03, 0x04};

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

    int rc = niwi_prove(ctx, public_inputs, sizeof(public_inputs),
                        private_inputs, sizeof(private_inputs),
                        &proof, &proof_len);
    assert(rc == 0);
    assert(proof != NULL);
    assert(proof_len > 0);
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) == 0);

    const uint8_t wrong_public[] = {'b', 'a', 'd'};
    assert(niwi_verify(ctx, proof, proof_len,
                       wrong_public, sizeof(wrong_public)) != 0);

    niwi_ctx_t *wrong_ctx = niwi_ctx_create((const uint8_t *)"other", 5);
    assert(wrong_ctx != NULL);
    assert(niwi_verify(wrong_ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) != 0);
    niwi_ctx_free(wrong_ctx);

    uint8_t saved = proof[proof_len - 1];
    proof[proof_len - 1] ^= 0x01;
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) != 0);
    proof[proof_len - 1] = saved;

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_extract(ctx, proof, proof_len, NULL, 0,
                        public_inputs, sizeof(public_inputs),
                        &witness, &witness_len) != 0);
    assert(witness == NULL);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_prove_verify_extract\n");
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

    assert(niwi_prove_observed(ctx, public_inputs, sizeof(public_inputs),
                               private_inputs, sizeof(private_inputs),
                               &proof, &proof_len, &gamma, &gamma_len) == 0);
    assert(proof != NULL);
    assert(gamma != NULL);
    assert(proof_len > 0);
    assert(gamma_len > 0);
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs, sizeof(public_inputs)) == 0);

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    assert(niwi_extract(ctx, proof, proof_len, gamma, gamma_len,
                        public_inputs, sizeof(public_inputs),
                        &witness, &witness_len) == 0);
    assert(witness_len == sizeof(private_inputs));
    assert(memcmp(witness, private_inputs, sizeof(private_inputs)) == 0);

    niwi_free_buffer(witness);

    gamma[gamma_len - 1] ^= 0x01;
    witness = NULL;
    witness_len = 0;
    assert(niwi_extract(ctx, proof, proof_len, gamma, gamma_len,
                        public_inputs, sizeof(public_inputs),
                        &witness, &witness_len) != 0);
    assert(witness == NULL);

    niwi_free_buffer(gamma);
    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    printf("  PASS test_prove_observed\n");
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
    test_prove_observed();
    printf("All C ABI tests passed.\n");
    return 0;
}
