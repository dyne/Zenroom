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

#define _POSIX_C_SOURCE 199309L

#include "commitment.h"
#include "encoding.h"
#include "hash.h"
#include "npro.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

/* ---- NPRO query throughput ------------------------------------------- */

static void bench_npro_queries(void) {
    niwi_npro_t *npro = niwi_npro_create(1);
    assert(npro);

    const int N = 10000;
    uint8_t input[64];
    memset(input, 0x42, sizeof(input));
    uint8_t out[32];

    double start = now_ms();
    for (int i = 0; i < N; i++) {
        input[0] = (uint8_t)(i & 0xff);
        niwi_npro_query(npro, "BENC", input, sizeof(input), out);
    }
    double elapsed = now_ms() - start;

    printf("  NPRO queries: %d in %.1f ms (%.1f us/query)\n",
           N, elapsed, elapsed * 1000 / N);

    /* Gamma size for N queries */
    size_t gs = niwi_npro_gamma_size(npro);
    printf("  Gamma size: %zu bytes for %d queries (%.1f bytes/query)\n",
           gs, N, (double)gs / N);

    /* Serialize benchmark */
    uint8_t *gamma_buf = (uint8_t *)malloc(gs);
    assert(gamma_buf);

    start = now_ms();
    niwi_npro_serialize_gamma(npro, gamma_buf, gs);
    elapsed = now_ms() - start;
    printf("  Gamma serialize: %.1f ms\n", elapsed);

    /* Deserialize benchmark */
    start = now_ms();
    niwi_npro_t *npro2 = niwi_npro_deserialize_gamma(gamma_buf, gs);
    elapsed = now_ms() - start;
    printf("  Gamma deserialize: %.1f ms\n", elapsed);

    assert(npro2);
    assert(niwi_npro_seq(npro2) == (uint32_t)N);

    /* Lookup benchmark */
    niwi_npro_query(npro, "BENC", input, sizeof(input), out); /* get a digest to find */
    start = now_ms();
    for (int i = 0; i < 10000; i++) {
        uint8_t found_input[256];
        size_t found_len;
        niwi_npro_lookup(npro2, "BENC", out, found_input, &found_len);
    }
    elapsed = now_ms() - start;
    printf("  NPRO lookup: 10000 lookups in %.1f ms (%.1f us/lookup)\n",
           elapsed, elapsed * 1000 / 10000);

    niwi_npro_free(npro2);
    free(gamma_buf);
    niwi_npro_free(npro);
}

/* ---- Hash throughput ------------------------------------------------- */

static void bench_hash(void) {
    const int N = 100000;
    uint8_t data[64];
    memset(data, 0xAB, sizeof(data));
    uint8_t digest[32];

    double start = now_ms();
    for (int i = 0; i < N; i++) {
        niwi_hash_one_shot(NIWI_TAG_FSCH, data, sizeof(data), digest);
    }
    double elapsed = now_ms() - start;

    printf("  SHA-256 (domain-tagged): %d in %.1f ms (%.1f us/hash)\n",
           N, elapsed, elapsed * 1000 / N);
}

/* ---- Commitment throughput ------------------------------------------- */

static void bench_commitments(void) {
    const int N = 1000;
    uint8_t msg[32];
    memset(msg, 0xCC, sizeof(msg));
    uint8_t commit[32];
    uint8_t opening[64];

    double start = now_ms();
    for (int i = 0; i < N; i++) {
        msg[0] = (uint8_t)(i & 0xff);
        niwi_klp22_commit(msg, sizeof(msg), commit, opening);
    }
    double elapsed = now_ms() - start;
    printf("  KLP22 commit: %d in %.1f ms (%.1f us/commit)\n",
           N, elapsed, elapsed * 1000 / N);

    /* Verify benchmark */
    niwi_klp22_commit(msg, 32, commit, opening);

    start = now_ms();
    for (int i = 0; i < N; i++) {
        niwi_klp22_verify(commit, msg, 32, opening);
    }
    elapsed = now_ms() - start;
    printf("  KLP22 verify: %d in %.1f ms (%.1f us/verify)\n",
           N, elapsed, elapsed * 1000 / N);

    /* Leaf commit benchmark */
    uint8_t leaf[32];
    uint8_t leaf_commit[32];
    uint8_t preimage[64];

    start = now_ms();
    for (int i = 0; i < N; i++) {
        leaf[0] = (uint8_t)(i & 0xff);
        niwi_leaf_commit(leaf, sizeof(leaf), leaf_commit, preimage);
    }
    elapsed = now_ms() - start;
    printf("  Pass/NPRO leaf commit: %d in %.1f ms (%.1f us/commit)\n",
           N, elapsed, elapsed * 1000 / N);
}

/* ---- Encoding throughput --------------------------------------------- */

static void bench_encoding(void) {
    const int N = 100000;
    uint8_t buf[256];

    double start = now_ms();
    for (int i = 0; i < N; i++) {
        niwi_encode_u32((uint32_t)i, buf, sizeof(buf));
    }
    double elapsed = now_ms() - start;
    printf("  u32 encode: %d in %.1f ms (%.1f ns/encode)\n",
           N, elapsed, elapsed * 1000000 / N);

    /* Byte array encode */
    const uint8_t *items[3];
    size_t lens[3] = {4, 8, 16};
    uint8_t a[4], b[8], c[16];
    memset(a, 0x01, 4); memset(b, 0x02, 8); memset(c, 0x03, 16);
    items[0] = a; items[1] = b; items[2] = c;

    start = now_ms();
    for (int i = 0; i < 10000; i++) {
        niwi_encode_byte_array(items, lens, 3, buf, sizeof(buf));
    }
    elapsed = now_ms() - start;
    printf("  byte array (3 items, 28 bytes): 10000 in %.1f ms (%.1f us/encode)\n",
           elapsed, elapsed * 1000 / 10000);
}

/* ---- Main ------------------------------------------------------------- */

int main(void) {
    printf("lib/blindzap micro-benchmarks:\n");
    bench_npro_queries();
    bench_hash();
    bench_commitments();
    bench_encoding();
    printf("Benchmarks complete.\n");
    return 0;
}
