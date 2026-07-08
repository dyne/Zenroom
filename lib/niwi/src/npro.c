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

#include "npro.h"
#include "hash.h"

#include <stdlib.h>
#include <string.h>

#define NPRO_MAX_QUERIES 65536
#define NPRO_INITIAL_CAP 256

struct niwi_npro {
    niwi_npro_query_t *queries;
    size_t             count;
    size_t             cap;
    uint32_t           seq;
    uint32_t           cutoff;
    int                observe;
};

/* ---- Lifecycle -------------------------------------------------------- */

niwi_npro_t *niwi_npro_create(int observe) {
    niwi_npro_t *npro = (niwi_npro_t *)calloc(1, sizeof(*npro));
    if (!npro) return NULL;

    npro->observe = observe;
    npro->seq = 0;
    npro->cutoff = UINT32_MAX; /* no cutoff yet */

    if (observe) {
        npro->cap = NPRO_INITIAL_CAP;
        npro->queries = (niwi_npro_query_t *)calloc(npro->cap,
                                                     sizeof(*npro->queries));
        if (!npro->queries) {
            free(npro);
            return NULL;
        }
    }

    return npro;
}

void niwi_npro_free(niwi_npro_t *npro) {
    if (!npro) return;
    if (npro->queries) {
        for (size_t i = 0; i < npro->count; i++)
            free(npro->queries[i].input);
    }
    free(npro->queries);
    free(npro);
}

/* ---- Query ------------------------------------------------------------ */

int niwi_npro_query(niwi_npro_t *npro,
                    const char domain[4],
                    const uint8_t *input, size_t input_len,
                    uint8_t output[32]) {
    if (!npro || !domain || !output) return -1;
    if (!input && input_len != 0) return -1;
    if (input_len > UINT32_MAX) return -1;

    /* Compute the domain-separated hash. */
    niwi_hash_one_shot(domain, input, input_len, output);

    /* Record if observing. */
    if (npro->observe) {
        if (npro->count >= NPRO_MAX_QUERIES) return -1;

        /* Grow if needed. */
        if (npro->count >= npro->cap) {
            size_t new_cap = npro->cap * 2;
            if (new_cap > NPRO_MAX_QUERIES) new_cap = NPRO_MAX_QUERIES;
            niwi_npro_query_t *new_q = (niwi_npro_query_t *)realloc(
                npro->queries, new_cap * sizeof(*npro->queries));
            if (!new_q) return -1;
            npro->queries = new_q;
            npro->cap = new_cap;
        }

        niwi_npro_query_t *q = &npro->queries[npro->count];
        memcpy(q->domain, domain, 4);
        q->input_len = input_len;
        q->input = NULL;
        if (input_len > 0) {
            q->input = (uint8_t *)malloc(input_len);
            if (!q->input) return -1;
            memcpy(q->input, input, input_len);
        }
        memcpy(q->output, output, 32);
        q->seq = npro->seq;
        npro->count++;
    }

    npro->seq++;
    return 0;
}

/* ---- Observation control ---------------------------------------------- */

void niwi_npro_set_cutoff(niwi_npro_t *npro) {
    if (!npro) return;
    npro->cutoff = npro->seq;
}

uint32_t niwi_npro_seq(const niwi_npro_t *npro) {
    return npro ? npro->seq : 0;
}

int niwi_npro_is_observing(const niwi_npro_t *npro) {
    return npro ? npro->observe : 0;
}

/* ---- Serialization ---------------------------------------------------- */

size_t niwi_npro_gamma_size(const niwi_npro_t *npro) {
    if (!npro || !npro->observe || npro->count == 0) return 0;

    size_t size = 4 + 4; /* count + cutoff */
    for (size_t i = 0; i < npro->count; i++) {
        size += 4;              /* domain */
        size += 4;              /* input length */
        size += npro->queries[i].input_len;
        size += 32;             /* output */
    }
    return size;
}

size_t niwi_npro_serialize_gamma(const niwi_npro_t *npro,
                                  uint8_t *out, size_t out_cap) {
    if (!npro || !npro->observe || !out) return 0;

    size_t needed = niwi_npro_gamma_size(npro);
    if (needed == 0 || needed > out_cap) return 0;

    size_t off = 0;

    /* u32 count (big-endian) */
    uint32_t count = (uint32_t)npro->count;
    out[off++] = (uint8_t)((count >> 24) & 0xff);
    out[off++] = (uint8_t)((count >> 16) & 0xff);
    out[off++] = (uint8_t)((count >>  8) & 0xff);
    out[off++] = (uint8_t)((count      ) & 0xff);

    /* u32 cutoff */
    out[off++] = (uint8_t)((npro->cutoff >> 24) & 0xff);
    out[off++] = (uint8_t)((npro->cutoff >> 16) & 0xff);
    out[off++] = (uint8_t)((npro->cutoff >>  8) & 0xff);
    out[off++] = (uint8_t)((npro->cutoff      ) & 0xff);

    for (size_t i = 0; i < npro->count; i++) {
        const niwi_npro_query_t *q = &npro->queries[i];

        /* domain */
        memcpy(out + off, q->domain, 4); off += 4;

        /* input length + input */
        uint32_t input_len = (uint32_t)q->input_len;
        out[off++] = (uint8_t)((input_len >> 24) & 0xff);
        out[off++] = (uint8_t)((input_len >> 16) & 0xff);
        out[off++] = (uint8_t)((input_len >>  8) & 0xff);
        out[off++] = (uint8_t)((input_len      ) & 0xff);
        if (q->input_len > 0) {
            memcpy(out + off, q->input, q->input_len);
            off += q->input_len;
        }

        /* output */
        memcpy(out + off, q->output, 32); off += 32;
    }

    return off;
}

niwi_npro_t *niwi_npro_deserialize_gamma(const uint8_t *data, size_t len) {
    if (!data || len < 8) return NULL;

    size_t off = 0;

    /* u32 count */
    uint32_t count = ((uint32_t)data[off] << 24) |
                     ((uint32_t)data[off+1] << 16) |
                     ((uint32_t)data[off+2] << 8) |
                     ((uint32_t)data[off+3]);
    off += 4;

    /* u32 cutoff */
    uint32_t cutoff = ((uint32_t)data[off] << 24) |
                      ((uint32_t)data[off+1] << 16) |
                      ((uint32_t)data[off+2] << 8) |
                      ((uint32_t)data[off+3]);
    off += 4;

    if (count > NPRO_MAX_QUERIES) return NULL;

    niwi_npro_t *npro = niwi_npro_create(1); /* observe for lookup */
    if (!npro) return NULL;

    npro->cutoff = cutoff;
    npro->seq = count;
    npro->cap = count > NPRO_INITIAL_CAP ? count : NPRO_INITIAL_CAP;
    free(npro->queries);
    npro->queries = (niwi_npro_query_t *)calloc(npro->cap,
                                                 sizeof(*npro->queries));
    if (!npro->queries) {
        free(npro);
        return NULL;
    }

    for (uint32_t i = 0; i < count; i++) {
        if (off + 4 + 4 > len) { niwi_npro_free(npro); return NULL; }

        niwi_npro_query_t *q = &npro->queries[i];
        memcpy(q->domain, data + off, 4); off += 4;

        uint32_t input_len = ((uint32_t)data[off] << 24) |
                             ((uint32_t)data[off+1] << 16) |
                             ((uint32_t)data[off+2] << 8) |
                             ((uint32_t)data[off+3]);
        off += 4;
        q->input_len = input_len;

        if (off + q->input_len + 32 > len) { niwi_npro_free(npro); return NULL; }

        q->input = NULL;
        if (q->input_len > 0) {
            q->input = (uint8_t *)malloc(q->input_len);
            if (!q->input) { niwi_npro_free(npro); return NULL; }
            memcpy(q->input, data + off, q->input_len);
            off += q->input_len;
        }

        memcpy(q->output, data + off, 32); off += 32;
        q->seq = i;
        npro->count++;
    }

    return npro;
}

/* ---- Extractor API ---------------------------------------------------- */

int niwi_npro_lookup(const niwi_npro_t *npro,
                     const char domain[4],
                     const uint8_t output_digest[32],
                     uint8_t *input, size_t *input_len) {
    if (!npro || !domain || !output_digest || !input_len)
        return 0;

    int found = 0;
    size_t found_len = 0;
    const uint8_t *found_input = NULL;
    size_t input_cap = input ? *input_len : 0;

    for (size_t i = 0; i < npro->count; i++) {
        const niwi_npro_query_t *q = &npro->queries[i];

        /* Skip post-cutoff queries (not part of the proof). */
        if (q->seq >= npro->cutoff) continue;

        if (memcmp(q->domain, domain, 4) == 0 &&
            memcmp(q->output, output_digest, 32) == 0) {
            uint8_t recomputed[32];
            niwi_hash_one_shot(q->domain, q->input, q->input_len, recomputed);
            if (memcmp(recomputed, q->output, 32) != 0) continue;
            if (found) return 0; /* ambiguous Gamma */
            found_input = q->input;
            found_len = q->input_len;
            found = 1;
        }
    }

    if (!found) return 0;
    *input_len = found_len;
    if (input) {
        if (input_cap < found_len) return 0;
        if (found_len != 0) memcpy(input, found_input, found_len);
    }
    return 1;
}
