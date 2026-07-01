/* lib/niwi/src/npro.h — Observable Non-Programmable Random Oracle.
 *
 * Implements 2025-1992 Definition 13's requirement: every random oracle
 * query is recorded with its domain tag, input, and output.  When
 * observation is enabled, the query log Gamma is serializable for
 * the extractor.  Production mode disables observation.
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
    uint8_t  input[256];    /* canonical input (variable-length, up to 255) */
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
 *     u8:  input length (max 255)
 *     input bytes
 *     32-byte output
 * Returns the number of bytes written, or 0 on overflow. */
size_t niwi_npro_serialize_gamma(const niwi_npro_t *npro,
                                  uint8_t *out, size_t out_cap);

/* Deserialize Gamma.  Returns a new npro with all queries loaded and
 * observation disabled (extractor mode).  Returns NULL on parse error. */
niwi_npro_t *niwi_npro_deserialize_gamma(const uint8_t *data, size_t len);

/* ---- Extractor API ---------------------------------------------------- */

/* Look up a query by domain and output digest.  Returns 1 and fills
 * *input and *input_len if found.  *input must point to a buffer of
 * at least 256 bytes.  Returns 0 if not found. */
int niwi_npro_lookup(const niwi_npro_t *npro,
                     const char domain[4],
                     const uint8_t output_digest[32],
                     uint8_t *input, size_t *input_len);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_NPRO_H */
