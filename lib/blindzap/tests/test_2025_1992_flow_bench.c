/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#define _POSIX_C_SOURCE 199309L

#include "pbsch_commitment.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

static void fill_seq(uint8_t *out, size_t len, uint8_t start) {
    for (size_t i = 0; i < len; ++i) out[i] = (uint8_t)(start + i);
}

static void write_u32_be(uint8_t out[4], uint32_t v) {
    out[0] = (uint8_t)(v >> 24);
    out[1] = (uint8_t)(v >> 16);
    out[2] = (uint8_t)(v >> 8);
    out[3] = (uint8_t)v;
}

static void print_bench(const char *op, int iterations, double elapsed,
                        size_t bytes_in, size_t bytes_out, int rc) {
    const double per_us = iterations > 0 ? elapsed * 1000.0 / iterations : 0.0;
    printf("BENCH paper_flow op=%s iterations=%d total_ms=%.3f "
           "per_us=%.3f bytes_in=%zu bytes_out=%zu rc=%d\n",
           op, iterations, elapsed, per_us, bytes_in, bytes_out, rc);
}

static void make_full_statement(uint8_t full[NIWI_RPBSCH_FULL_STATEMENT_SIZE],
                                const uint8_t C[NIWI_PBSCH_CMP_SIZE],
                                const uint8_t S[NIWI_PBSCH_CMP_SIZE],
                                const uint8_t ck[32],
                                const uint8_t C_proof[NIWI_PBSCH_CMT3_PROOF_SIZE],
                                const uint8_t S_proof[NIWI_PBSCH_CMT3_PROOF_SIZE]) {
    size_t off = 0;
    memcpy(full + off, "RPB2", 4); off += 4;
    write_u32_be(full + off, NIWI_RPBSCH_CORE_STATEMENT_SIZE); off += 4;

    fill_seq(full + off, NIWI_RPBSCH_CORE_STATEMENT_SIZE, 0x21);
    memcpy(full + off + 128, C, NIWI_PBSCH_CMP_SIZE);
    memcpy(full + off + 193, ck, 32);
    memcpy(full + off + 225, S, NIWI_PBSCH_CMP_SIZE);
    off += NIWI_RPBSCH_CORE_STATEMENT_SIZE;

    write_u32_be(full + off, NIWI_PBSCH_CMT3_PROOF_SIZE); off += 4;
    memcpy(full + off, C_proof, NIWI_PBSCH_CMT3_PROOF_SIZE);
    off += NIWI_PBSCH_CMT3_PROOF_SIZE;

    write_u32_be(full + off, NIWI_PBSCH_CMT3_PROOF_SIZE); off += 4;
    memcpy(full + off, S_proof, NIWI_PBSCH_CMT3_PROOF_SIZE);
}

int main(void) {
    uint8_t ck[32];
    uint8_t c_msg[32], c_rho[32], C[NIWI_PBSCH_CMP_SIZE];
    uint8_t s_msg[32], s_rho[32], S[NIWI_PBSCH_CMP_SIZE];
    uint8_t seed[32];
    uint8_t C_proof[NIWI_PBSCH_CMT3_PROOF_SIZE];
    uint8_t S_proof[NIWI_PBSCH_CMT3_PROOF_SIZE];
    uint8_t full[NIWI_RPBSCH_FULL_STATEMENT_SIZE];
    niwi_rpbsch_statement_t parsed;
    int rc = 0;

    fill_seq(c_msg, sizeof(c_msg), 0x11);
    fill_seq(c_rho, sizeof(c_rho), 0x51);
    fill_seq(s_msg, sizeof(s_msg), 0x31);
    fill_seq(s_rho, sizeof(s_rho), 0x71);
    fill_seq(seed, sizeof(seed), 0x91);

    assert(niwi_pbsch_pedersen_h(ck) == 0);
    assert(niwi_pbsch_pedersen_commit(c_msg, c_rho, C) == 0);
    assert(niwi_pbsch_pedersen_commit(s_msg, s_rho, S) == 0);
    assert(niwi_pbsch_cmt3_prove_seeded(C, c_msg, c_rho, seed, C_proof) == 0);
    seed[0] ^= 0x42;
    assert(niwi_pbsch_cmt3_prove_seeded(S, s_msg, s_rho, seed, S_proof) == 0);
    assert(niwi_pbsch_cmt3_verify(C, C_proof) == 0);
    assert(niwi_pbsch_cmt3_verify(S, S_proof) == 0);
    make_full_statement(full, C, S, ck, C_proof, S_proof);
    assert(niwi_rpbsch_validate_full_statement(full, sizeof(full), &parsed) == 0);

    printf("lib/blindzap 2025/1992 paper-flow boundary benchmarks:\n");

    {
        const int N = 100;
        double start = now_ms();
        for (int i = 0; i < N; ++i) rc |= niwi_pbsch_pedersen_h(ck);
        print_bench("commitment_key", N, now_ms() - start, 0, sizeof(ck), rc);
    }

    {
        const int N = 250;
        double start = now_ms();
        for (int i = 0; i < N; ++i) {
            c_msg[31] = (uint8_t)i;
            rc |= niwi_pbsch_pedersen_commit(c_msg, c_rho, C);
        }
        print_bench("C_pedersen_commit", N, now_ms() - start,
                    sizeof(c_msg) + sizeof(c_rho), sizeof(C), rc);
    }

    c_msg[31] = 0x30;
    assert(niwi_pbsch_pedersen_commit(c_msg, c_rho, C) == 0);

    {
        const int N = 20;
        double start = now_ms();
        for (int i = 0; i < N; ++i) {
            seed[0] = (uint8_t)i;
            rc |= niwi_pbsch_cmt3_prove_seeded(C, c_msg, c_rho, seed, C_proof);
        }
        print_bench("C_cmt3_prove_seeded", N, now_ms() - start,
                    sizeof(C) + sizeof(c_msg) + sizeof(c_rho) + sizeof(seed),
                    sizeof(C_proof), rc);
    }

    {
        const int N = 100;
        double start = now_ms();
        for (int i = 0; i < N; ++i) rc |= niwi_pbsch_cmt3_verify(C, C_proof);
        print_bench("C_cmt3_verify", N, now_ms() - start,
                    sizeof(C) + sizeof(C_proof), 0, rc);
    }

    {
        const int N = 250;
        double start = now_ms();
        for (int i = 0; i < N; ++i) {
            s_msg[31] = (uint8_t)i;
            rc |= niwi_pbsch_pedersen_commit(s_msg, s_rho, S);
        }
        print_bench("S_pedersen_commit", N, now_ms() - start,
                    sizeof(s_msg) + sizeof(s_rho), sizeof(S), rc);
    }

    s_msg[31] = 0x70;
    assert(niwi_pbsch_pedersen_commit(s_msg, s_rho, S) == 0);

    {
        const int N = 20;
        double start = now_ms();
        for (int i = 0; i < N; ++i) {
            seed[0] = (uint8_t)(0x80 + i);
            rc |= niwi_pbsch_cmt3_prove_seeded(S, s_msg, s_rho, seed, S_proof);
        }
        print_bench("S_cmt3_prove_seeded", N, now_ms() - start,
                    sizeof(S) + sizeof(s_msg) + sizeof(s_rho) + sizeof(seed),
                    sizeof(S_proof), rc);
    }

    {
        const int N = 100;
        double start = now_ms();
        for (int i = 0; i < N; ++i) rc |= niwi_pbsch_cmt3_verify(S, S_proof);
        print_bench("S_cmt3_verify", N, now_ms() - start,
                    sizeof(S) + sizeof(S_proof), 0, rc);
    }

    {
        const int N = 10000;
        double start = now_ms();
        for (int i = 0; i < N; ++i) make_full_statement(full, C, S, ck, C_proof, S_proof);
        print_bench("RPB2_full_statement_encode", N, now_ms() - start,
                    NIWI_RPBSCH_CORE_STATEMENT_SIZE + 2 * NIWI_PBSCH_CMT3_PROOF_SIZE,
                    sizeof(full), rc);
    }

    {
        const int N = 10000;
        double start = now_ms();
        for (int i = 0; i < N; ++i)
            rc |= niwi_rpbsch_parse_full_statement(full, sizeof(full), &parsed);
        print_bench("RPB2_parse_full_statement", N, now_ms() - start,
                    sizeof(full), sizeof(parsed), rc);
    }

    {
        const int N = 100;
        double start = now_ms();
        for (int i = 0; i < N; ++i)
            rc |= niwi_rpbsch_validate_full_statement(full, sizeof(full), &parsed);
        print_bench("RPB2_validate_full_statement", N, now_ms() - start,
                    sizeof(full), sizeof(parsed), rc);
    }

    assert(rc == 0);
    printf("Benchmarks complete. Full RPBSch NIWI prove/verify timings are covered by relation-specific Ligero tests; this target tracks the public CMT3/RPB2 boundary used by the paper-flow profile.\n");
    return 0;
}
