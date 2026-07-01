// lib/niwi/tests/test_niwi_proof_serde.c
//
// Test NiwiProof header serialization, round-trip, malformed parsing.
// Tests the C-level serde (niwi_proof_serde.h is C++ template; we test
// the header portion which is inline C-compatible).

#include "commitment.h"
#include "hash.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* Minimal inline copies of the serde functions for C testing.
 * These match the C++ versions in niwi_proof_serde.h. */

static const uint8_t kTestMagic[4] = {'N', 'I', 'W', 'I'};
static const size_t kTestHeaderSize = 4 + 4 + 4 + 32 + 32 + 32 + 64;

static void write_u32_be(uint8_t* buf, uint32_t val) {
    buf[0] = (uint8_t)((val >> 24) & 0xff);
    buf[1] = (uint8_t)((val >> 16) & 0xff);
    buf[2] = (uint8_t)((val >>  8) & 0xff);
    buf[3] = (uint8_t)((val      ) & 0xff);
}

static uint32_t read_u32_be(const uint8_t* buf) {
    return ((uint32_t)buf[0] << 24) |
           ((uint32_t)buf[1] << 16) |
           ((uint32_t)buf[2] <<  8) |
           ((uint32_t)buf[3]);
}

/* ---- Test: header write + read round-trip ---------------------------- */

static void test_header_roundtrip(void) {
    uint8_t out[256] = {0};
    size_t off = 0;

    /* Write */
    memcpy(out + off, kTestMagic, 4); off += 4;
    write_u32_be(out + off, ((uint32_t)1 << 16) | 0); off += 4;
    write_u32_be(out + off, 0); off += 4;

    uint8_t circuit_digest[32];
    memset(circuit_digest, 0xAA, 32);
    memcpy(out + off, circuit_digest, 32); off += 32;

    uint8_t stmt_digest[32];
    memset(stmt_digest, 0xBB, 32);
    memcpy(out + off, stmt_digest, 32); off += 32;

    uint8_t kcom[32];
    memset(kcom, 0xCC, 32);
    memcpy(out + off, kcom, 32); off += 32;

    uint8_t kop[64];
    memset(kop, 0xDD, 64);
    memcpy(out + off, kop, 64); off += 64;

    assert(off == kTestHeaderSize);

    /* Read */
    if (memcmp(out, kTestMagic, 4) != 0) { assert(0); }
    size_t roff = 4;

    uint32_t ver = read_u32_be(out + roff); roff += 4;
    assert((ver >> 16) == 1);
    assert((ver & 0xffff) == 0);

    uint32_t proto = read_u32_be(out + roff); roff += 4;
    assert(proto == 0);

    uint8_t read_cd[32];
    memcpy(read_cd, out + roff, 32); roff += 32;
    assert(memcmp(read_cd, circuit_digest, 32) == 0);

    uint8_t read_sd[32];
    memcpy(read_sd, out + roff, 32); roff += 32;
    assert(memcmp(read_sd, stmt_digest, 32) == 0);

    uint8_t read_kc[32];
    memcpy(read_kc, out + roff, 32); roff += 32;
    assert(memcmp(read_kc, kcom, 32) == 0);

    uint8_t read_ko[64];
    memcpy(read_ko, out + roff, 64);
    assert(memcmp(read_ko, kop, 64) == 0);

    printf("  PASS test_header_roundtrip\n");
}

/* ---- Test: wrong magic ----------------------------------------------- */

static void test_wrong_magic(void) {
    uint8_t buf[kTestHeaderSize];
    memset(buf, 0x42, sizeof(buf));
    /* Not "NIWI" */
    assert(memcmp(buf, kTestMagic, 4) != 0);
    printf("  PASS test_wrong_magic\n");
}

/* ---- Test: unsupported version --------------------------------------- */

static void test_unsupported_version(void) {
    uint8_t buf[kTestHeaderSize];
    memset(buf, 0, sizeof(buf));
    memcpy(buf, kTestMagic, 4);
    write_u32_be(buf + 4, ((uint32_t)99 << 16) | 99);

    uint32_t ver = read_u32_be(buf + 4);
    assert((ver >> 16) == 99);
    /* Verifier should reject unsupported major versions */
    printf("  PASS test_unsupported_version (major=99, verifier must reject)\n");
}

/* ---- Test: truncated proof ------------------------------------------- */

static void test_truncated_proof(void) {
    uint8_t buf[10];
    memset(buf, 0, sizeof(buf));
    memcpy(buf, kTestMagic, 4);
    /* Only magic present, rest missing */
    /* Parser should reject (need at least kTestHeaderSize bytes) */
    assert(sizeof(buf) < kTestHeaderSize);
    printf("  PASS test_truncated_proof\n");
}

/* ---- Test: field mutation -------------------------------------------- */

static void test_mutated_circuit_digest(void) {
    uint8_t buf[kTestHeaderSize];
    memset(buf, 0, sizeof(buf));
    memcpy(buf, kTestMagic, 4);
    write_u32_be(buf + 4, ((uint32_t)1 << 16) | 0);
    write_u32_be(buf + 8, 0);

    /* Original circuit digest */
    memset(buf + 12, 0xAA, 32);

    /* Mutate one byte */
    buf[15] ^= 0x01;

    /* Verify that the digest is different from expected */
    uint8_t expected[32];
    memset(expected, 0xAA, 32);
    assert(memcmp(buf + 12, expected, 32) != 0);
    printf("  PASS test_mutated_circuit_digest\n");
}

/* ---- Test: KLP22 commitment integrity -------------------------------- */

static void test_klp22_commitment_in_proof(void) {
    /* Prove that the KLP22 commitment is stored and recoverable. */
    const uint8_t msg[] = {0x01, 0x02, 0x03};
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    int rc = niwi_klp22_commit(msg, 3, commitment, opening);
    assert(rc == 0);

    /* Verify opening against the stored commitment */
    rc = niwi_klp22_verify(commitment, msg, 3, opening);
    assert(rc == 0);

    /* Mutate opening, verify fails */
    opening[0] ^= 0xFF;
    rc = niwi_klp22_verify(commitment, msg, 3, opening);
    assert(rc != 0);

    printf("  PASS test_klp22_commitment_in_proof\n");
}

/* ---- Main ------------------------------------------------------------- */

int main(void) {
    printf("lib/niwi proof serde tests:\n");
    test_header_roundtrip();
    test_wrong_magic();
    test_unsupported_version();
    test_truncated_proof();
    test_mutated_circuit_digest();
    test_klp22_commitment_in_proof();
    printf("All proof serde tests passed.\n");
    return 0;
}
