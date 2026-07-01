/* lib/niwi/src/extract.h — Straight-line extraction from Gamma.
 *
 * Implements 2025-1992 Definition 13: given a NiwiProof and a Gamma
 * (NPRO query log recorded during proving), recover the witness
 * without rewinding the prover.
 *
 * The extractor works by:
 *  1. Parsing the NiwiProof to extract Merkle paths and column indices
 *  2. Looking up each Merkle leaf digest in Gamma to recover the leaf
 *     preimage (nonce + encoded column data)
 *  3. Rebuilding the Merkle root from recovered leaves
 *  4. Decoding column data back into tableau rows
 *  5. Extracting witness elements from the witness rows
 *  6. Validating the recovered witness against the circuit
 *
 * All lookups are domain-tagged and respect the before-proof cutoff.
 */

#ifndef NIWI_EXTRACT_H
#define NIWI_EXTRACT_H

#include <stddef.h>
#include <stdint.h>

#include "npro.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Extraction result codes ----------------------------------------- */

typedef enum {
    NIWI_EXTRACT_OK = 0,
    NIWI_EXTRACT_ERR_PARSE = -1,
    NIWI_EXTRACT_ERR_VERIFY = -2,
    NIWI_EXTRACT_ERR_MISSING_LEAF = -3,
    NIWI_EXTRACT_ERR_POST_CUTOFF = -4,
    NIWI_EXTRACT_ERR_MERKLE = -5,
    NIWI_EXTRACT_ERR_WITNESS = -6,
    NIWI_EXTRACT_ERR_MEMORY = -7,
} niwi_extract_status_t;

/* ---- Extraction context ---------------------------------------------- */

typedef struct niwi_extract niwi_extract_t;

/* Create an extractor context from a NiwiProof and Gamma.
 * The extractor parses the proof, recovers leaves from Gamma,
 * and validates the Merkle tree.
 *
 * proof: serialized NiwiProof bytes
 * proof_len: length of proof
 * gamma: Gamma (NPRO query log) from niwi_npro_serialize_gamma()
 * gamma_len: length of gamma
 * public_inputs: the public statement (for witness validation)
 * pub_len: length of public_inputs
 *
 * Returns NULL on error. */
niwi_extract_t *niwi_extract_create(
    const uint8_t *proof, size_t proof_len,
    const uint8_t *gamma, size_t gamma_len,
    const uint8_t *public_inputs, size_t pub_len);

/* Free the extractor context. */
void niwi_extract_free(niwi_extract_t *ex);

/* Return the last error as a human-readable string. */
const char *niwi_extract_error(const niwi_extract_t *ex);

/* Recover the witness from the extraction context.
 * The extracted witness is a byte-encoded representation of
 * private circuit inputs in the same format as the original
 * witness assignment.
 *
 * witness_out: output buffer for the recovered witness
 * witness_len: on input, size of witness_out; on output, actual size
 *
 * Returns NIWI_EXTRACT_OK on success, or an error code. */
int niwi_extract_witness(niwi_extract_t *ex,
                          uint8_t *witness_out, size_t *witness_len);

/* ---- Leaf recovery --------------------------------------------------- */

/* Maximum number of leaves in a Ligero Merkle tree (block_ext). */
#define NIWI_EXTRACT_MAX_LEAVES 65536

/* Max leaf preimage size (32-byte nonce + nrow * field bytes). */
#define NIWI_EXTRACT_MAX_LEAF_DATA 16384

/* A recovered leaf. */
typedef struct {
    uint32_t index;                          /* column index (0-based) */
    uint8_t  digest[32];                     /* Merkle leaf digest */
    uint8_t  nonce[32];                      /* Merkle nonce */
    uint8_t  data[NIWI_EXTRACT_MAX_LEAF_DATA];  /* encoded column elements */
    size_t   data_len;
    int      recovered;                      /* 1 if recovered from Gamma */
} niwi_extract_leaf_t;

/* Recover all leaves from Gamma for the given column indices.
 * Returns the number of leaves recovered, or 0 on error. */
size_t niwi_extract_recover_leaves(
    niwi_extract_t *ex,
    const uint32_t *col_indices, size_t num_indices,
    niwi_extract_leaf_t *leaves_out, size_t max_leaves);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_EXTRACT_H */
