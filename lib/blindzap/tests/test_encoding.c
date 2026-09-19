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

#include "encoding.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- Helpers ---------------------------------------------------------- */

static void print_hex(const uint8_t *data, size_t len) {
    for (size_t i = 0; i < len; i++)
        printf("%02x", data[i]);
}

static int buf_eq(const uint8_t *a, const uint8_t *b, size_t len) {
    return memcmp(a, b, len) == 0;
}

/* ---- Test: bytes (length-prefixed) ----------------------------------- */

static void test_encode_bytes_empty(void) {
    uint8_t buf[128] = {0};
    size_t n = niwi_encode_bytes(NULL, 0, buf, sizeof(buf));
    assert(n == 4);
    /* 4-byte big-endian 0 */
    assert(buf[0] == 0 && buf[1] == 0 && buf[2] == 0 && buf[3] == 0);
    printf("  PASS test_encode_bytes_empty: ");
    print_hex(buf, n);
    printf("\n");
}

static void test_encode_bytes_hello(void) {
    uint8_t buf[128] = {0};
    const char *hello = "hello";
    size_t n = niwi_encode_bytes((const uint8_t *)hello, 5, buf, sizeof(buf));
    assert(n == 9);
    /* length = 5 */
    assert(buf[0] == 0 && buf[1] == 0 && buf[2] == 0 && buf[3] == 5);
    /* data = "hello" */
    assert(memcmp(buf + 4, hello, 5) == 0);
    printf("  PASS test_encode_bytes_hello: ");
    print_hex(buf, n);
    printf("\n");
}

static void test_encode_bytes_overflow(void) {
    uint8_t buf[3];
    size_t n = niwi_encode_bytes((const uint8_t *)"ab", 2, buf, sizeof(buf));
    assert(n == 0); /* 4-byte length won't fit */
    printf("  PASS test_encode_bytes_overflow\n");
}

/* ---- Test: u32 ------------------------------------------------------- */

static void test_encode_u32(void) {
    uint8_t buf[4];
    size_t n = niwi_encode_u32(0x12345678, buf, sizeof(buf));
    assert(n == 4);
    assert(buf[0] == 0x12 && buf[1] == 0x34 &&
           buf[2] == 0x56 && buf[3] == 0x78);
    printf("  PASS test_encode_u32\n");
}

/* ---- Test: u64 ------------------------------------------------------- */

static void test_encode_u64(void) {
    uint8_t buf[8];
    size_t n = niwi_encode_u64(0x1122334455667788ULL, buf, sizeof(buf));
    assert(n == 8);
    assert(buf[0] == 0x11 && buf[1] == 0x22 &&
           buf[2] == 0x33 && buf[3] == 0x44 &&
           buf[4] == 0x55 && buf[5] == 0x66 &&
           buf[6] == 0x77 && buf[7] == 0x88);
    printf("  PASS test_encode_u64\n");
}

/* ---- Test: byte array ------------------------------------------------- */

static void test_encode_byte_array(void) {
    const uint8_t *items[3];
    size_t lens[3];

    const uint8_t a[] = {0xaa};
    const uint8_t b[] = {0xbb, 0xcc};
    const uint8_t c[] = {};

    items[0] = a; lens[0] = 1;
    items[1] = b; lens[1] = 2;
    items[2] = c; lens[2] = 0;

    uint8_t buf[256];
    size_t n = niwi_encode_byte_array(items, lens, 3, buf, sizeof(buf));

    /* Expected: u32 count=3, then len-prefixed a, b, c */
    /* count: 0,0,0,3 */
    assert(buf[0] == 0); assert(buf[1] == 0);
    assert(buf[2] == 0); assert(buf[3] == 3);

    /* a: length 1, then 0xaa */
    size_t off = 4;
    assert(buf[off+0] == 0); assert(buf[off+1] == 0);
    assert(buf[off+2] == 0); assert(buf[off+3] == 1);
    assert(buf[off+4] == 0xaa);
    off += 5;

    /* b: length 2, then 0xbb, 0xcc */
    assert(buf[off+0] == 0); assert(buf[off+1] == 0);
    assert(buf[off+2] == 0); assert(buf[off+3] == 2);
    assert(buf[off+4] == 0xbb); assert(buf[off+5] == 0xcc);
    off += 6;

    /* c: length 0, no data */
    assert(buf[off+0] == 0); assert(buf[off+1] == 0);
    assert(buf[off+2] == 0); assert(buf[off+3] == 0);
    off += 4;

    assert(n == off);
    printf("  PASS test_encode_byte_array\n");
}

/* ---- Test: tagged ----------------------------------------------------- */

static void test_encode_tagged(void) {
    const char tag[4] = {'T', 'E', 'S', 'T'};
    const uint8_t payload[] = {0x01, 0x02, 0x03};
    uint8_t buf[128];
    size_t n = niwi_encode_tagged(tag, payload, 3, buf, sizeof(buf));

    /* 4 tag + 4 len + 3 data = 11 */
    assert(n == 11);
    assert(memcmp(buf, "TEST", 4) == 0);
    assert(buf[4] == 0 && buf[5] == 0 && buf[6] == 0 && buf[7] == 3);
    assert(memcmp(buf + 8, payload, 3) == 0);
    printf("  PASS test_encode_tagged\n");
}

/* ---- Test: protocol version ------------------------------------------- */

static void test_encode_protocol_version(void) {
    uint8_t buf[4];
    size_t n = niwi_encode_protocol_version(1, 0, buf, sizeof(buf));
    assert(n == 4);
    assert(buf[0] == 0 && buf[1] == 1); /* major = 1 */
    assert(buf[2] == 0 && buf[3] == 0); /* minor = 0 */
    printf("  PASS test_encode_protocol_version\n");
}

/* ---- Test: digest (fixed 32 bytes) ----------------------------------- */

static void test_encode_digest(void) {
    uint8_t digest[32];
    memset(digest, 0x42, 32);
    uint8_t buf[64];
    size_t n = niwi_encode_digest(digest, buf, sizeof(buf));
    assert(n == 32);
    assert(memcmp(buf, digest, 32) == 0);
    printf("  PASS test_encode_digest\n");
}

/* ---- Main ------------------------------------------------------------- */

int main(void) {
    printf("lib/blindzap encoding tests:\n");
    test_encode_bytes_empty();
    test_encode_bytes_hello();
    test_encode_bytes_overflow();
    test_encode_u32();
    test_encode_u64();
    test_encode_byte_array();
    test_encode_tagged();
    test_encode_protocol_version();
    test_encode_digest();
    printf("All encoding tests passed.\n");
    return 0;
}
