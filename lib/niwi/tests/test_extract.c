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

#include "extract.h"
#include "hash.h"
#include "npro.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- Helper: build a minimal valid-looking proof header ------------- */

static void build_dummy_proof_header(uint8_t *buf, size_t *len) {
    size_t off = 0;

    /* Magic */
    memcpy(buf + off, "NIWI", 4); off += 4;

    /* Version: 1.0 */
    buf[off++] = 0; buf[off++] = 1;
    buf[off++] = 0; buf[off++] = 0;

    /* Protocol ID: 0 */
    buf[off++] = 0; buf[off++] = 0;
    buf[off++] = 0; buf[off++] = 0;

    /* Circuit digest (zeros) */
    memset(buf + off, 0, 32); off += 32;

    /* Statement digest (zeros) */
    memset(buf + off, 0, 32); off += 32;

    /* KLP22 commitment */
    memset(buf + off, 0xAA, 32); off += 32;

    /* KLP22 opening */
    memset(buf + off, 0xBB, 64); off += 64;

    /* Ligero parameters (7 x u32): block=16, dblock=31, r=8,
     * block_enc=64, nrow=32, nreq=8, mc_pathlen=5 */
    uint32_t params[7] = {16, 31, 8, 64, 32, 8, 5};
    for (int i = 0; i < 7; i++) {
        uint32_t v = params[i];
        buf[off++] = (uint8_t)((v >> 24) & 0xff);
        buf[off++] = (uint8_t)((v >> 16) & 0xff);
        buf[off++] = (uint8_t)((v >>  8) & 0xff);
        buf[off++] = (uint8_t)((v      ) & 0xff);
    }

    /* Add some dummy data to make a complete-looking proof */
    /* y_ldt: block * 48 bytes (field) */
    memset(buf + off, 0, 16 * 48); off += 16 * 48;

    /* y_dot: dblock * 48 */
    memset(buf + off, 0, 31 * 48); off += 31 * 48;

    /* y_quad_0: r * 48 */
    memset(buf + off, 0, 8 * 48); off += 8 * 48;

    /* y_quad_2: (dblock - block) * 48 */
    memset(buf + off, 0, 15 * 48); off += 15 * 48;

    /* req: nrow * nreq * 8 (subfield) */
    memset(buf + off, 0, 32 * 8 * 8); off += 32 * 8 * 8;

    /* Merkle root */
    memset(buf + off, 0xCC, 32); off += 32;

    *len = off;
}

/* Build a minimal Gamma for testing. */
static uint8_t *build_dummy_gamma(size_t *gamma_len) {
    niwi_npro_t *npro = niwi_npro_create(1);
    assert(npro);

    /* Add a few queries */
    uint8_t out[32];
    niwi_npro_query(npro, "NL05", (const uint8_t *)"leaf0", 5, out);
    niwi_npro_query(npro, "NL05", (const uint8_t *)"leaf1", 5, out);
    niwi_npro_query(npro, "NL05", (const uint8_t *)"leaf2", 5, out);
    niwi_npro_set_cutoff(npro);

    size_t sz = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(sz);
    assert(gamma);
    size_t n = niwi_npro_serialize_gamma(npro, gamma, sz);
    assert(n == sz);

    niwi_npro_free(npro);
    *gamma_len = sz;
    return gamma;
}

/* ---- Test: create/free lifecycle ------------------------------------- */

static void test_create_free(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    size_t gamma_len;
    uint8_t *gamma = build_dummy_gamma(&gamma_len);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    const char *err = niwi_extract_error(ex);
    assert(err == NULL); /* no error */

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_create_free\n");
}

/* ---- Test: null context safety --------------------------------------- */

static void test_null_context(void) {
    niwi_extract_free(NULL);
    const char *err = niwi_extract_error(NULL);
    assert(err != NULL && strstr(err, "null") != NULL);
    printf("  PASS test_null_context\n");
}

/* ---- Test: malformed proof (wrong magic) ----------------------------- */

static void test_wrong_magic(void) {
    uint8_t proof[512];
    memset(proof, 0x42, sizeof(proof));
    /* First 4 bytes are 0x42424242, not "NIWI" */

    size_t gamma_len;
    uint8_t *gamma = build_dummy_gamma(&gamma_len);

    niwi_extract_t *ex = niwi_extract_create(
        proof, sizeof(proof), gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    const char *err = niwi_extract_error(ex);
    assert(err != NULL && strstr(err, "magic") != NULL);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_wrong_magic\n");
}

/* ---- Test: proof too short ------------------------------------------- */

static void test_proof_too_short(void) {
    uint8_t proof[8];
    memset(proof, 0, sizeof(proof));

    size_t gamma_len;
    uint8_t *gamma = build_dummy_gamma(&gamma_len);

    niwi_extract_t *ex = niwi_extract_create(
        proof, sizeof(proof), gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    const char *err = niwi_extract_error(ex);
    assert(err != NULL && strstr(err, "short") != NULL);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_proof_too_short\n");
}

/* ---- Test: gamma with post-cutoff queries ---------------------------- */

static void test_gamma_with_cutoff(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    /* Build Gamma with pre- and post-cutoff queries */
    niwi_npro_t *npro = niwi_npro_create(1);
    uint8_t out[32];
    niwi_npro_query(npro, "NL05", (const uint8_t *)"pre", 3, out);
    niwi_npro_set_cutoff(npro);
    niwi_npro_query(npro, "NL05", (const uint8_t *)"post", 4, out);

    size_t sz = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(sz);
    niwi_npro_serialize_gamma(npro, gamma, sz);
    niwi_npro_free(npro);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, sz, NULL, 0);
    assert(ex != NULL);

    /* No error — the extractor created successfully.
     * The post-cutoff query would be rejected during leaf recovery. */
    assert(niwi_extract_error(ex) == NULL);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_gamma_with_cutoff\n");
}

/* ---- Test: witness recovery stub ------------------------------------- */

static void test_witness_recovery_stub(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    size_t gamma_len;
    uint8_t *gamma = build_dummy_gamma(&gamma_len);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    uint8_t witness[64];
    size_t wlen = sizeof(witness);
    int rc = niwi_extract_witness(ex, witness, &wlen);
    assert(rc == NIWI_EXTRACT_OK);
    assert(wlen == 32); /* placeholder */

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_witness_recovery_stub\n");
}

/* ---- Test: leaf recovery pattern ------------------------------------- */

static void test_leaf_recovery(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    size_t gamma_len;
    uint8_t *gamma = build_dummy_gamma(&gamma_len);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    /* Request recovery of columns 0, 1, 2 */
    uint32_t col_indices[] = {0, 1, 2};
    niwi_extract_leaf_t leaves[3];
    size_t n = niwi_extract_recover_leaves(
        ex, col_indices, 3, leaves, 3);
    assert(n == 3);
    for (size_t i = 0; i < 3; i++) {
        assert(leaves[i].index == i);
    }

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_leaf_recovery\n");
}

/* ---- Test: extract from invalid Gamma ---------------------------------*/

static void test_invalid_gamma(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    /* Corrupted Gamma */
    uint8_t bad_gamma[4] = {0xFF, 0xFF, 0xFF, 0xFF};

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, bad_gamma, 4, NULL, 0);
    assert(ex != NULL);

    const char *err = niwi_extract_error(ex);
    assert(err != NULL && strstr(err, "Gamma") != NULL);

    niwi_extract_free(ex);
    printf("  PASS test_invalid_gamma\n");
}

/* ---- Main ------------------------------------------------------------- */

int main(void) {
    printf("lib/niwi extract tests:\n");
    test_create_free();
    test_null_context();
    test_wrong_magic();
    test_proof_too_short();
    test_gamma_with_cutoff();
    test_witness_recovery_stub();
    test_leaf_recovery();
    test_invalid_gamma();
    printf("All extract tests passed.\n");
    return 0;
}
