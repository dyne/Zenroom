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

    /* Trigger an error. */
    uint8_t *out = NULL; size_t out_len = 0;
    int rc = niwi_prove(ctx, NULL, 0, NULL, 0, &out, &out_len);
    assert(rc != 0);

    e = niwi_last_error(ctx);
    assert(e != NULL);
    assert(strstr(e, "not yet implemented") != NULL);
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

static void test_all_stubs_return_error(void) {
    niwi_ctx_t *ctx = niwi_ctx_create(dummy_artifact, sizeof(dummy_artifact));
    assert(ctx != NULL);

    /* prove */
    {
        uint8_t *out = NULL; size_t out_len = 0;
        int rc = niwi_prove(ctx, NULL, 0, NULL, 0, &out, &out_len);
        assert(rc != 0);
        assert(out == NULL);
        assert(out_len == 0);
    }

    /* prove_observed */
    {
        uint8_t *out = NULL, *gamma = NULL;
        size_t out_len = 0, gamma_len = 0;
        int rc = niwi_prove_observed(ctx, NULL, 0, NULL, 0,
                                     &out, &out_len, &gamma, &gamma_len);
        assert(rc != 0);
        assert(out == NULL);
        assert(gamma == NULL);
    }

    /* verify */
    {
        int rc = niwi_verify(ctx, NULL, 0, NULL, 0);
        assert(rc != 0);
    }

    /* extract */
    {
        uint8_t *out = NULL; size_t out_len = 0;
        int rc = niwi_extract(ctx, NULL, 0, NULL, 0, NULL, 0,
                              &out, &out_len);
        assert(rc != 0);
        assert(out == NULL);
    }

    printf("  PASS test_all_stubs_return_error\n");
    niwi_ctx_free(ctx);
}

int main(void) {
    printf("lib/niwi C ABI tests:\n");
    test_create_free();
    test_null_ctx_free();
    test_last_error();
    test_last_error_null();
    test_protocol_version();
    test_free_buffer();
    test_all_stubs_return_error();
    printf("All C ABI tests passed.\n");
    return 0;
}
