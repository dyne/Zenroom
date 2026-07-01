/* lib/niwi/src/hash.h — Domain-separated hashing for NIWI protocols.
 *
 * Every hash operation is tagged with a 4-byte domain identifier to
 * prevent cross-protocol or cross-mode collisions.
 *
 * Uses Milagro's HASH256_* (SHA-256) internally.
 */

#ifndef NIWI_HASH_H
#define NIWI_HASH_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Domain tags ----------------------------------------------------- */

/* Protocol initialization */
#define NIWI_TAG_PROTO  "NP01"

/* Statement binding */
#define NIWI_TAG_STMT   "NS02"

/* Fiat-Shamir challenge (KLP22 schedule) */
#define NIWI_TAG_FSCH   "NC03"

/* KLP22 challenge-share commitment */
#define NIWI_TAG_KCS    "NK04"

/* Pass leaf commitment (NPRO-observable) */
#define NIWI_TAG_LEAF   "NL05"

/* Merkle leaf node */
#define NIWI_TAG_MLEAF  "NM06"

/* Merkle internal node */
#define NIWI_TAG_MINT   "NM07"

/* Proof serialization header */
#define NIWI_TAG_PROOF  "NP08"

/* Extractor replay */
#define NIWI_TAG_EXTR   "NE09"

/* ---- Hash context ---------------------------------------------------- */

/* Opaque hash state wrapping Milagro's hash256. */
typedef struct niwi_hash_ctx niwi_hash_ctx_t;

/* Create a new hash context seeded with the given domain tag.
 * Returns NULL on allocation failure. */
niwi_hash_ctx_t *niwi_hash_create(const char domain_tag[4]);

/* Free a hash context. */
void niwi_hash_free(niwi_hash_ctx_t *ctx);

/* Feed data into the hash. Multiple calls are equivalent to
 * feeding the concatenation. */
void niwi_hash_update(niwi_hash_ctx_t *ctx,
                       const uint8_t *data, size_t len);

/* Finalize and write the 32-byte digest. The context is consumed
 * (no further updates allowed on this context). */
void niwi_hash_final(niwi_hash_ctx_t *ctx, uint8_t digest_out[32]);

/* ---- One-shot convenience --------------------------------------------- */

/* Compute a domain-tagged hash of a single buffer.
 * Equivalent to: create(tag), update(data, len), final(out). */
void niwi_hash_one_shot(const char domain_tag[4],
                        const uint8_t *data, size_t len,
                        uint8_t digest_out[32]);

/* Compute a domain-tagged hash of two concatenated buffers. */
void niwi_hash_two_shot(const char domain_tag[4],
                        const uint8_t *data1, size_t len1,
                        const uint8_t *data2, size_t len2,
                        uint8_t digest_out[32]);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_HASH_H */
