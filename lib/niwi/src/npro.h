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

#ifndef NIWI_NPRO_H
#define NIWI_NPRO_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Types ------------------------------------------------------------ */

typedef struct niwi_npro niwi_npro_t;

/* A single recorded query. */
typedef struct {
    char     domain[4];     /* 4-byte domain tag */
    uint8_t *input;         /* canonical input (variable-length) */
    size_t   input_len;
    uint8_t  output[32];    /* SHA-256 output */
    uint32_t seq;           /* monotonic sequence number */
} niwi_npro_query_t;

/* ---- Lifecycle -------------------------------------------------------- */

/* Create a new NPRO instance.
 * If observe != 0, all queries are recorded for extraction.
 * If observe == 0, queries execute but are not stored (production mode). */
niwi_npro_t *niwi_npro_create(int observe);

/* Free the NPRO and all recorded queries. */
void niwi_npro_free(niwi_npro_t *npro);

/* ---- Query ------------------------------------------------------------ */

/* Query the random oracle.  The 4-byte domain tag + canonical input
 * are hashed with SHA-256.  If observation is enabled, the query is
 * recorded with a monotonic sequence number.
 *
 * Returns 0 on success, -1 on error. */
int niwi_npro_query(niwi_npro_t *npro,
                    const char domain[4],
                    const uint8_t *input, size_t input_len,
                    uint8_t output[32]);

/* ---- Observation control ---------------------------------------------- */

/* Mark the end of the proving phase.  Queries after this point are not
 * part of the proof transcript and will be rejected by the extractor's
 * cutoff check. */
void niwi_npro_set_cutoff(niwi_npro_t *npro);

/* Return the current sequence number (next to be assigned). */
uint32_t niwi_npro_seq(const niwi_npro_t *npro);

/* Return 1 if observation is enabled, 0 otherwise. */
int niwi_npro_is_observing(const niwi_npro_t *npro);

/* ---- Serialization (Gamma) -------------------------------------------- */

/* Compute the size needed to serialize Gamma.  Returns 0 if no queries
 * are recorded. */
size_t niwi_npro_gamma_size(const niwi_npro_t *npro);

/* Serialize Gamma into out.  Format:
 *   u32:  query count
 *   u32:  cutoff sequence number (all queries < cutoff are proof queries)
 *   per query:
 *     4-byte domain tag
 *     u32: input length
 *     input bytes
 *     32-byte output
 * Returns the number of bytes written, or 0 on overflow. */
size_t niwi_npro_serialize_gamma(const niwi_npro_t *npro,
                                  uint8_t *out, size_t out_cap);

/* Deserialize Gamma.  Returns a new npro with all queries loaded and
 * observation disabled (extractor mode).  Returns NULL on parse error. */
niwi_npro_t *niwi_npro_deserialize_gamma(const uint8_t *data, size_t len);

/* ---- Extractor API ---------------------------------------------------- */

/* Look up a query by domain and output digest.  *input_len is the input
 * buffer capacity on entry and the recovered length on success.  If input is
 * NULL, the function only reports the recovered length.  Returns 1 on a unique
 * hit, or 0 if missing, ambiguous, or the caller's buffer is too small. */
int niwi_npro_lookup(const niwi_npro_t *npro,
                     const char domain[4],
                     const uint8_t output_digest[32],
                     uint8_t *input, size_t *input_len);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_NPRO_H */
