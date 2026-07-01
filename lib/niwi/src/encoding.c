/* lib/niwi/src/encoding.c — Canonical length-prefixed encoders.
 *
 * All output is deterministic big-endian with explicit length prefixes.
 */

#include "encoding.h"

#include <string.h>

/* ---- Internal helpers ------------------------------------------------- */

static size_t safe_write(const uint8_t *src, size_t len,
                          uint8_t *out, size_t out_cap,
                          size_t offset) {
    if (offset + len > out_cap) return 0;
    memcpy(out + offset, src, len);
    return offset + len;
}

/* ---- Primitive encoders ----------------------------------------------- */

size_t niwi_encode_bytes(const uint8_t *data, size_t data_len,
                          uint8_t *out, size_t out_cap) {
    size_t off = 0;

    /* 4-byte big-endian length */
    uint8_t len_buf[4] = {
        (uint8_t)((data_len >> 24) & 0xff),
        (uint8_t)((data_len >> 16) & 0xff),
        (uint8_t)((data_len >>  8) & 0xff),
        (uint8_t)((data_len      ) & 0xff),
    };
    off = safe_write(len_buf, 4, out, out_cap, off);
    if (!off) return 0;

    /* data */
    off = safe_write(data, data_len, out, out_cap, off);
    if (!off && data_len > 0) return 0;

    return off;
}

size_t niwi_encode_u8(uint8_t val, uint8_t *out, size_t out_cap) {
    if (out_cap < 1) return 0;
    out[0] = val;
    return 1;
}

size_t niwi_encode_u32(uint32_t val, uint8_t *out, size_t out_cap) {
    if (out_cap < 4) return 0;
    out[0] = (uint8_t)((val >> 24) & 0xff);
    out[1] = (uint8_t)((val >> 16) & 0xff);
    out[2] = (uint8_t)((val >>  8) & 0xff);
    out[3] = (uint8_t)((val      ) & 0xff);
    return 4;
}

size_t niwi_encode_u64(uint64_t val, uint8_t *out, size_t out_cap) {
    if (out_cap < 8) return 0;
    out[0] = (uint8_t)((val >> 56) & 0xff);
    out[1] = (uint8_t)((val >> 48) & 0xff);
    out[2] = (uint8_t)((val >> 40) & 0xff);
    out[3] = (uint8_t)((val >> 32) & 0xff);
    out[4] = (uint8_t)((val >> 24) & 0xff);
    out[5] = (uint8_t)((val >> 16) & 0xff);
    out[6] = (uint8_t)((val >>  8) & 0xff);
    out[7] = (uint8_t)((val      ) & 0xff);
    return 8;
}

size_t niwi_encode_byte_array(const uint8_t *const *items,
                               const size_t *item_lens,
                               size_t count,
                               uint8_t *out, size_t out_cap) {
    size_t off = 0;

    /* u32 count */
    uint8_t count_buf[4] = {
        (uint8_t)((count >> 24) & 0xff),
        (uint8_t)((count >> 16) & 0xff),
        (uint8_t)((count >>  8) & 0xff),
        (uint8_t)((count      ) & 0xff),
    };
    if ((off = safe_write(count_buf, 4, out, out_cap, off)) != 4) return 0;

    for (size_t i = 0; i < count; i++) {
        size_t wrote = niwi_encode_bytes(items[i], item_lens[i],
                                          out + off, out_cap - off);
        if (!wrote) return 0;
        off += wrote;
    }
    return off;
}

/* ---- Composite encoders ----------------------------------------------- */

size_t niwi_encode_tagged(const char tag[4],
                           const uint8_t *payload, size_t payload_len,
                           uint8_t *out, size_t out_cap) {
    size_t off = 0;

    /* 4-byte domain tag */
    off = safe_write((const uint8_t *)tag, 4, out, out_cap, off);
    if (!off) return 0;

    /* length-prefixed payload */
    size_t wrote = niwi_encode_bytes(payload, payload_len,
                                      out + off, out_cap - off);
    if (!wrote) return 0;

    return off + wrote;
}

size_t niwi_encode_protocol_version(uint16_t major, uint16_t minor,
                                     uint8_t *out, size_t out_cap) {
    if (out_cap < 4) return 0;
    out[0] = (uint8_t)((major >> 8) & 0xff);
    out[1] = (uint8_t)((major     ) & 0xff);
    out[2] = (uint8_t)((minor >> 8) & 0xff);
    out[3] = (uint8_t)((minor     ) & 0xff);
    return 4;
}

size_t niwi_encode_digest(const uint8_t digest[32],
                           uint8_t *out, size_t out_cap) {
    if (out_cap < 32) return 0;
    memcpy(out, digest, 32);
    return 32;
}
