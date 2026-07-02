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

#include "npro.h"
#include "hash.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- Helpers ---------------------------------------------------------- */

static void print_hex32(const uint8_t *data) {
    for (int i = 0; i < 32; i++) printf("%02x", data[i]);
}

/* ---- Test: production mode (no observation) -------------------------- */

static void test_production_mode(void) {
    niwi_npro_t *npro = niwi_npro_create(0);
    assert(npro != NULL);
    assert(!niwi_npro_is_observing(npro));

    uint8_t out[32];
    int rc = niwi_npro_query(npro, "TEST", (const uint8_t *)"hello", 5, out);
    assert(rc == 0);
    assert(niwi_npro_seq(npro) == 1);

    /* Gamma should be empty */
    assert(niwi_npro_gamma_size(npro) == 0);

    uint8_t buf[16];
    size_t sz = niwi_npro_serialize_gamma(npro, buf, sizeof(buf));
    assert(sz == 0);

    niwi_npro_free(npro);
    printf("  PASS test_production_mode\n");
}

/* ---- Test: observation with query recording --------------------------- */

static void test_observation_mode(void) {
    niwi_npro_t *npro = niwi_npro_create(1);
    assert(npro != NULL);
    assert(niwi_npro_is_observing(npro));

    uint8_t out1[32], out2[32];
    niwi_npro_query(npro, "AA01", (const uint8_t *)"msg1", 4, out1);
    niwi_npro_query(npro, "BB02", (const uint8_t *)"msg2", 4, out2);

    assert(niwi_npro_seq(npro) == 2);

    /* Gamma should have size > 0 */
    size_t gs = niwi_npro_gamma_size(npro);
    assert(gs > 0);

    /* Serialize and round-trip */
    uint8_t *gamma = (uint8_t *)malloc(gs);
    assert(gamma != NULL);

    size_t n = niwi_npro_serialize_gamma(npro, gamma, gs);
    assert(n == gs);

    niwi_npro_t *npro2 = niwi_npro_deserialize_gamma(gamma, gs);
    assert(npro2 != NULL);
    assert(niwi_npro_seq(npro2) == 2);

    /* Look up first query */
    uint8_t input[256];
    size_t ilen;
    int found = niwi_npro_lookup(npro2, "AA01", out1, input, &ilen);
    assert(found);
    assert(ilen == 4);
    assert(memcmp(input, "msg1", 4) == 0);

    /* Look up by wrong domain should fail */
    found = niwi_npro_lookup(npro2, "BAD0", out1, input, &ilen);
    assert(!found);

    /* Look up by wrong output should fail */
    uint8_t wrong[32];
    memset(wrong, 0, 32);
    found = niwi_npro_lookup(npro2, "AA01", wrong, input, &ilen);
    assert(!found);

    niwi_npro_free(npro2);
    free(gamma);
    niwi_npro_free(npro);
    printf("  PASS test_observation_mode\n");
}

/* ---- Test: cutoff enforcement ----------------------------------------- */

static void test_cutoff(void) {
    niwi_npro_t *npro = niwi_npro_create(1);
    assert(npro != NULL);

    uint8_t out[32];
    niwi_npro_query(npro, "CUT0", (const uint8_t *)"pre", 3, out);
    niwi_npro_set_cutoff(npro);
    niwi_npro_query(npro, "CUT0", (const uint8_t *)"post", 4, out);

    /* Post-cutoff query should not be found by lookup */
    uint8_t input[256]; size_t ilen;
    int found = niwi_npro_lookup(npro, "CUT0", out, input, &ilen);
    assert(!found); /* only "post" generates this digest, but it's post-cutoff */

    niwi_npro_free(npro);
    printf("  PASS test_cutoff\n");
}

/* ---- Test: deterministic replay --------------------------------------- */

static void test_deterministic_replay(void) {
    niwi_npro_t *npro1 = niwi_npro_create(1);
    niwi_npro_t *npro2 = niwi_npro_create(1);

    const char *msgs[] = {"aaa", "bbb", "ccc"};
    uint8_t out1[32], out2[32];

    for (int i = 0; i < 3; i++) {
        niwi_npro_query(npro1, "REPL", (const uint8_t *)msgs[i],
                        strlen(msgs[i]), out1);
        niwi_npro_query(npro2, "REPL", (const uint8_t *)msgs[i],
                        strlen(msgs[i]), out2);
        assert(memcmp(out1, out2, 32) == 0);
    }

    size_t gs = niwi_npro_gamma_size(npro1);
    uint8_t *g1 = (uint8_t *)malloc(gs);
    uint8_t *g2 = (uint8_t *)malloc(gs);
    niwi_npro_serialize_gamma(npro1, g1, gs);
    niwi_npro_serialize_gamma(npro2, g2, gs);
    assert(memcmp(g1, g2, gs) == 0);

    free(g1); free(g2);
    niwi_npro_free(npro1);
    niwi_npro_free(npro2);
    printf("  PASS test_deterministic_replay\n");
}

/* ---- Test: malformed Gamma -------------------------------------------- */

static void test_malformed_gamma(void) {
    /* Too short */
    uint8_t short_buf[4] = {0, 0, 0, 5};
    niwi_npro_t *npro = niwi_npro_deserialize_gamma(short_buf, 4);
    assert(npro == NULL);

    /* Corrupt: count too large */
    uint8_t huge_count[8] = {0xff, 0xff, 0, 0, 0, 0, 0, 0};
    npro = niwi_npro_deserialize_gamma(huge_count, 8);
    assert(npro == NULL);

    /* Truncated query */
    uint8_t truncated[12] = {0, 0, 0, 1, 0, 0, 0, 0, 'T', 'E', 'S', 50};
    npro = niwi_npro_deserialize_gamma(truncated, 12);
    assert(npro == NULL);

    printf("  PASS test_malformed_gamma\n");
}

/* ---- Test: query equality and domain separation ----------------------- */

static void test_domain_separation(void) {
    niwi_npro_t *npro = niwi_npro_create(0);
    uint8_t out_a[32], out_b[32];

    /* Same input, different domain -> different output */
    niwi_npro_query(npro, "DOMA", (const uint8_t *)"same", 4, out_a);
    niwi_npro_query(npro, "DOMB", (const uint8_t *)"same", 4, out_b);
    assert(memcmp(out_a, out_b, 32) != 0);

    /* Same domain, same input -> same output */
    uint8_t out_a2[32];
    niwi_npro_query(npro, "DOMA", (const uint8_t *)"same", 4, out_a2);
    assert(memcmp(out_a, out_a2, 32) == 0);

    niwi_npro_free(npro);
    printf("  PASS test_domain_separation\n");
}

/* ---- Main ------------------------------------------------------------- */

int main(void) {
    printf("lib/niwi NPRO tests:\n");
    test_production_mode();
    test_observation_mode();
    test_cutoff();
    test_deterministic_replay();
    test_malformed_gamma();
    test_domain_separation();
    printf("All NPRO tests passed.\n");
    return 0;
}
