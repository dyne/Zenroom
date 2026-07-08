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

static uint8_t *build_leaf_gamma(size_t *gamma_len, uint8_t digests[3][32]) {
    niwi_npro_t *npro = niwi_npro_create(1);
    assert(npro);

    niwi_npro_query(npro, "NL05", (const uint8_t *)"leaf0", 5, digests[0]);
    niwi_npro_query(npro, "NL05", (const uint8_t *)"leaf1", 5, digests[1]);
    niwi_npro_query(npro, "NL05", (const uint8_t *)"leaf2", 5, digests[2]);
    niwi_npro_set_cutoff(npro);

    size_t sz = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(sz);
    assert(gamma);
    assert(niwi_npro_serialize_gamma(npro, gamma, sz) == sz);

    niwi_npro_free(npro);
    *gamma_len = sz;
    return gamma;
}

static uint8_t *build_post_cutoff_leaf_gamma(size_t *gamma_len, uint8_t digest[32]) {
    niwi_npro_t *npro = niwi_npro_create(1);
    assert(npro);

    uint8_t ignored[32];
    niwi_npro_query(npro, "NL05", (const uint8_t *)"pre", 3, ignored);
    niwi_npro_set_cutoff(npro);
    niwi_npro_query(npro, "NL05", (const uint8_t *)"post", 4, digest);

    size_t sz = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(sz);
    assert(gamma);
    assert(niwi_npro_serialize_gamma(npro, gamma, sz) == sz);

    niwi_npro_free(npro);
    *gamma_len = sz;
    return gamma;
}

static void append_u32_be(uint8_t *buf, size_t *off, uint32_t v) {
    buf[(*off)++] = (uint8_t)((v >> 24) & 0xff);
    buf[(*off)++] = (uint8_t)((v >> 16) & 0xff);
    buf[(*off)++] = (uint8_t)((v >> 8) & 0xff);
    buf[(*off)++] = (uint8_t)(v & 0xff);
}

static uint8_t *build_tableau_gamma(size_t *gamma_len,
                                    const uint8_t *witness,
                                    size_t witness_len,
                                    uint8_t digest[32],
                                    uint32_t *leaf_len) {
    uint8_t leaf[128];
    size_t off = 0;
    assert(witness_len <= sizeof(leaf) - 16);
    memcpy(leaf + off, "TBL0", 4); off += 4;
    append_u32_be(leaf, &off, 0);
    append_u32_be(leaf, &off, 0);
    append_u32_be(leaf, &off, (uint32_t)witness_len);
    memcpy(leaf + off, witness, witness_len); off += witness_len;
    *leaf_len = (uint32_t)off;

    niwi_npro_t *npro = niwi_npro_create(1);
    assert(npro);
    niwi_npro_query(npro, "NL05", leaf, off, digest);
    niwi_npro_set_cutoff(npro);

    size_t sz = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(sz);
    assert(gamma);
    assert(niwi_npro_serialize_gamma(npro, gamma, sz) == sz);

    niwi_npro_free(npro);
    *gamma_len = sz;
    return gamma;
}

static void append_tableau_section(uint8_t *proof, size_t *proof_len,
                                   const uint8_t digest[32],
                                   uint32_t leaf_len) {
    size_t off = *proof_len;
    memcpy(proof + off, "TAB0", 4); off += 4;
    append_u32_be(proof, &off, 1);
    append_u32_be(proof, &off, 0);
    append_u32_be(proof, &off, 0);
    append_u32_be(proof, &off, leaf_len);
    memcpy(proof + off, digest, 32); off += 32;
    *proof_len = off;
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

/* ---- Test: witness recovery requires tableau leaves ------------------- */

static void test_witness_recovery_requires_tableau(void) {
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
    assert(rc == NIWI_EXTRACT_ERR_WITNESS);
    assert(wlen == 0);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_witness_recovery_requires_tableau\n");
}

static void test_tableau_witness_recovery(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    const uint8_t expected[] = {'w', 'i', 't'};
    uint8_t digest[32];
    uint32_t leaf_len = 0;
    size_t gamma_len;
    uint8_t *gamma = build_tableau_gamma(&gamma_len, expected,
                                         sizeof(expected), digest,
                                         &leaf_len);
    append_tableau_section(proof, &proof_len, digest, leaf_len);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    uint8_t witness[64];
    size_t wlen = sizeof(witness);
    int rc = niwi_extract_witness(ex, witness, &wlen);
    assert(rc == NIWI_EXTRACT_OK);
    assert(wlen == sizeof(expected));
    assert(memcmp(witness, expected, sizeof(expected)) == 0);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_tableau_witness_recovery\n");
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

static void test_leaf_recovery_by_digest(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    uint8_t digests[3][32];
    size_t gamma_len;
    uint8_t *gamma = build_leaf_gamma(&gamma_len, digests);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    uint32_t col_indices[] = {0, 1, 2};
    niwi_extract_leaf_t leaves[3];
    size_t n = niwi_extract_recover_leaves_by_digest(
        ex, col_indices, digests, 3, leaves, 3);
    assert(n == 3);
    for (size_t i = 0; i < 3; i++) {
        assert(leaves[i].index == i);
        assert(leaves[i].recovered == 1);
        assert(leaves[i].data_len == 5);
        assert(memcmp(leaves[i].data, i == 0 ? "leaf0" : i == 1 ? "leaf1" : "leaf2", 5) == 0);
        assert(memcmp(leaves[i].digest, digests[i], 32) == 0);
    }

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_leaf_recovery_by_digest\n");
}

static void test_leaf_missing_digest(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    uint8_t digests[3][32];
    size_t gamma_len;
    uint8_t *gamma = build_leaf_gamma(&gamma_len, digests);
    memset(digests[1], 0x42, 32);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    uint32_t col_indices[] = {0, 1, 2};
    niwi_extract_leaf_t leaves[3];
    size_t n = niwi_extract_recover_leaves_by_digest(
        ex, col_indices, digests, 3, leaves, 3);
    assert(n == 0);
    assert(niwi_extract_error(ex) != NULL);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_leaf_missing_digest\n");
}

static void test_leaf_post_cutoff_rejected(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    uint8_t digest[32];
    size_t gamma_len;
    uint8_t *gamma = build_post_cutoff_leaf_gamma(&gamma_len, digest);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    uint32_t col_indices[] = {0};
    niwi_extract_leaf_t leaf[1];
    size_t n = niwi_extract_recover_leaves_by_digest(
        ex, col_indices, (const uint8_t (*)[32])&digest, 1, leaf, 1);
    assert(n == 0);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_leaf_post_cutoff_rejected\n");
}

static void test_leaf_wrong_domain_rejected(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    niwi_npro_t *npro = niwi_npro_create(1);
    uint8_t digest[32];
    niwi_npro_query(npro, "BAD0", (const uint8_t *)"leaf0", 5, digest);
    niwi_npro_set_cutoff(npro);
    size_t gamma_len = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(gamma_len);
    assert(gamma);
    assert(niwi_npro_serialize_gamma(npro, gamma, gamma_len) == gamma_len);
    niwi_npro_free(npro);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    uint32_t col_indices[] = {0};
    niwi_extract_leaf_t leaf[1];
    size_t n = niwi_extract_recover_leaves_by_digest(
        ex, col_indices, (const uint8_t (*)[32])&digest, 1, leaf, 1);
    assert(n == 0);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_leaf_wrong_domain_rejected\n");
}

static void test_leaf_ambiguous_digest_rejected(void) {
    uint8_t proof[8192];
    size_t proof_len;
    build_dummy_proof_header(proof, &proof_len);

    niwi_npro_t *npro = niwi_npro_create(1);
    uint8_t first_digest[32], second_digest[32];
    niwi_npro_query(npro, "NL05", (const uint8_t *)"leaf0", 5, first_digest);
    niwi_npro_query(npro, "NL05", (const uint8_t *)"other", 5, second_digest);
    niwi_npro_set_cutoff(npro);

    size_t gamma_len = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(gamma_len);
    assert(gamma);
    assert(niwi_npro_serialize_gamma(npro, gamma, gamma_len) == gamma_len);
    niwi_npro_free(npro);

    /* Force the second query to claim the first digest. */
    size_t second_digest_off = 8 + (4 + 1 + 5 + 32) + 4 + 1 + 5;
    memcpy(gamma + second_digest_off, first_digest, 32);

    niwi_extract_t *ex = niwi_extract_create(
        proof, proof_len, gamma, gamma_len, NULL, 0);
    assert(ex != NULL);

    uint32_t col_indices[] = {0};
    niwi_extract_leaf_t leaf[1];
    size_t n = niwi_extract_recover_leaves_by_digest(
        ex, col_indices, (const uint8_t (*)[32])&first_digest, 1, leaf, 1);
    assert(n == 0);

    niwi_extract_free(ex);
    free(gamma);
    printf("  PASS test_leaf_ambiguous_digest_rejected\n");
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
    test_witness_recovery_requires_tableau();
    test_tableau_witness_recovery();
    test_leaf_recovery();
    test_leaf_recovery_by_digest();
    test_leaf_missing_digest();
    test_leaf_post_cutoff_rejected();
    test_leaf_wrong_domain_rejected();
    test_leaf_ambiguous_digest_rejected();
    test_invalid_gamma();
    printf("All extract tests passed.\n");
    return 0;
}
