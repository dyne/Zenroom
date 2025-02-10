// https://github.com/tidwall/varint.c
//
// Copyright 2024 Joshua J Baker. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.
//
// varint.c: Read and write variable sized integers in C.

#ifndef VARINT_H
#define VARINT_H

#include <stdint.h>
#include <stddef.h>

int varint_read_u64(const void *data, size_t len, uint64_t *x);
int varint_read_i64(const void *data, size_t len, int64_t *x);
int varint_write_u64(void *data, uint64_t x);
int varint_write_i64(void *data, int64_t x);

// deprecated
int varint_read_u(const void *data, size_t len, uint64_t *x);
int varint_read_i(const void *data, size_t len, int64_t *x);
int varint_write_u(void *data, uint64_t x);
int varint_write_i(void *data, int64_t x);

#endif
