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

#ifndef NIWI_ENCODING_H
#define NIWI_ENCODING_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Max size of a single encoded value. */
#define NIWI_ENCODING_MAX_SIZE 4096

/* -------------------- Primitive encoders ------------------------------ */

/* Encode a raw byte string as 4-byte big-endian length + data.
 * Returns the number of bytes written, or 0 on overflow. */
size_t niwi_encode_bytes(const uint8_t *data, size_t data_len,
                          uint8_t *out, size_t out_cap);

/* Encode a single byte. */
size_t niwi_encode_u8(uint8_t val, uint8_t *out, size_t out_cap);

/* Encode a 32-bit unsigned integer (big-endian). */
size_t niwi_encode_u32(uint32_t val, uint8_t *out, size_t out_cap);

/* Encode a 64-bit unsigned integer (big-endian). */
size_t niwi_encode_u64(uint64_t val, uint8_t *out, size_t out_cap);

/* Encode an array of byte strings as count (u32) + each length-prefixed.
 * Returns the total bytes written, or 0 on overflow. */
size_t niwi_encode_byte_array(const uint8_t *const *items,
                               const size_t *item_lens,
                               size_t count,
                               uint8_t *out, size_t out_cap);

/* -------------------- Composite encoders ------------------------------ */

/* Encode a domain tag as a fixed-width tag + optional payload.
 * The domain tag is a 4-byte string literal (e.g. "NP01"). */
size_t niwi_encode_tagged(const char tag[4],
                           const uint8_t *payload, size_t payload_len,
                           uint8_t *out, size_t out_cap);

/* Encode a protocol version (major.minor) as two u16 values. */
size_t niwi_encode_protocol_version(uint16_t major, uint16_t minor,
                                     uint8_t *out, size_t out_cap);

/* Encode a SHA-256 digest (exactly 32 bytes, no length prefix). */
size_t niwi_encode_digest(const uint8_t digest[32],
                           uint8_t *out, size_t out_cap);

/* -------------------- Sizing helpers ---------------------------------- */

/* Compute the encoded size of a byte string. */
#define NIWI_BYTES_SIZE(len) (4 + (len))

/* Compute the encoded size of an array of byte strings. */
static inline size_t niwi_byte_array_size(const size_t *item_lens,
                                           size_t count) {
    size_t total = 4; /* count */
    for (size_t i = 0; i < count; i++)
        total += NIWI_BYTES_SIZE(item_lens[i]);
    return total;
}

#ifdef __cplusplus
}
#endif

#endif /* NIWI_ENCODING_H */
