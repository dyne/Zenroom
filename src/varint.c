// https://github.com/tidwall/varint.c
//
// Copyright 2024 Joshua J Baker. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.
//
// varint.c: Read and write variable sized integers in C.

#include <stdint.h>
#include <stddef.h>

#ifdef VARINT_STATIC
#define VARINT_EXTERN static
#endif

#ifndef VARINT_EXTERN
#define VARINT_EXTERN
#endif

/// varint_write_u64 writes a uint64 varint to data, which could be to 10 bytes.
/// Make sure that you provide a data buffer that can take 10 bytes!
/// Returns the number of bytes written.
VARINT_EXTERN
int varint_write_u64(void *data, uint64_t x) {
    uint8_t *bytes = data;
    if (x < 128) {
        *bytes = x;
        return 1;
    }
    int n = 0;
    do {
        bytes[n++] = (uint8_t)x | 128;
        x >>= 7;
    } while (x >= 128);
    bytes[n++] = (uint8_t)x;
    return n;
}

/// varint_write_i64 writes a int64 varint to data, which could be to 10 bytes.
/// Make sure that you provide a data buffer that can take 10 bytes!
/// Returns the number of bytes written.
VARINT_EXTERN
int varint_write_i64(void *data, int64_t x) {
    uint64_t ux = (uint64_t)x << 1;
    ux = x < 0 ? ~ux : ux;
    return varint_write_u64(data, ux);
}

/// varint_read_u64 reads a uint64 varint from data. 
/// Returns the number of bytes reads, or returns 0 if there's not enough data
/// to complete the read, or returns -1 if the data buffer does not represent
/// a valid uint64 varint.
VARINT_EXTERN
int varint_read_u64(const void *data, size_t len, uint64_t *x) {
    const uint8_t *bytes = data;
    if (len > 0 && bytes[0] < 128) {
        *x = bytes[0];
        return 1;
    }
    uint64_t b;
    *x = 0;
    size_t i = 0;
    while (i < len && i < 10) {
        b = bytes[i]; 
        *x |= (b & 127) << (7 * i); 
        if (b < 128) {
            return i + 1;
        }
        i++;
    }
    return i == 10 ? -1 : 0;
}

/// varint_read_i64 reads a int64 varint from data. 
/// Returns the number of bytes reads, or returns 0 if there's not enough data
/// to complete the read, or returns -1 if the data buffer does not represent
/// a valid int64 varint.
VARINT_EXTERN
int varint_read_i64(const void *data, size_t len, int64_t *x) {
    uint64_t ux;
    int n = varint_read_u64(data, len, &ux);
    *x = (int64_t)(ux >> 1);
    *x = ux&1 ? ~*x : *x;
    return n;
}

/// deprecated: use varint_write_i64
VARINT_EXTERN
int varint_write_i(void *data, int64_t x) {
    return varint_write_i64(data, x);
}

/// deprecated: use varint_write_u64
VARINT_EXTERN
int varint_write_u(void *data, uint64_t x) {
    return varint_write_u64(data, x);
}

/// deprecated: use varint_read_i64
VARINT_EXTERN
int varint_read_i(const void *data, size_t len, int64_t *x) {
    return varint_read_i64(data, len, x);
}

/// deprecated: use varint_read_u64
VARINT_EXTERN
int varint_read_u(const void *data, size_t len, uint64_t *x) {
    return varint_read_u64(data, len, x);
}
