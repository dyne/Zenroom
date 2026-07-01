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

#ifndef NIWI_H
#define NIWI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque context holding a compiled circuit artifact. */
typedef struct niwi_ctx niwi_ctx_t;

/* -------------------- Lifecycle ---------------------------------------- */

/* Create a context from a compiled zkcc circuit artifact.
 * Returns NULL on failure; call niwi_last_error for details. */
niwi_ctx_t *niwi_ctx_create(const uint8_t *circuit_artifact, size_t len);

/* Free a context and all associated resources. */
void niwi_ctx_free(niwi_ctx_t *ctx);

/* -------------------- Prove (production) ------------------------------- */

/* Prove private inputs satisfy the circuit under public inputs.
 * Uses secure system randomness.
 * On success, *proof_out and *proof_len are set; caller must free with
 * niwi_free_buffer. Returns 0 on success, non-zero on failure. */
int niwi_prove(niwi_ctx_t *ctx,
               const uint8_t *public_inputs, size_t pub_len,
               const uint8_t *private_inputs, size_t priv_len,
               uint8_t **proof_out, size_t *proof_len);

/* -------------------- Prove with observation (test-only) --------------- */

/* Like niwi_prove but also records the NPRO query log (Gamma).
 * On success, *gamma_out and *gamma_len are also set.
 * This function is not available in production builds. */
int niwi_prove_observed(niwi_ctx_t *ctx,
                        const uint8_t *public_inputs, size_t pub_len,
                        const uint8_t *private_inputs, size_t priv_len,
                        uint8_t **proof_out, size_t *proof_len,
                        uint8_t **gamma_out, size_t *gamma_len);

/* -------------------- Verify ------------------------------------------- */

/* Verify a NIWI proof against the circuit and public inputs.
 * Returns 0 if the proof is valid, non-zero otherwise. */
int niwi_verify(niwi_ctx_t *ctx,
                const uint8_t *proof, size_t proof_len,
                const uint8_t *public_inputs, size_t pub_len);

/* -------------------- Extract (test-only) ------------------------------ */

/* Extract a witness from a proof and Gamma (NPRO query log).
 * Only available in test builds. The extracted witness is a private
 * input assignment for the circuit. */
int niwi_extract(niwi_ctx_t *ctx,
                 const uint8_t *proof, size_t proof_len,
                 const uint8_t *gamma, size_t gamma_len,
                 const uint8_t *public_inputs, size_t pub_len,
                 uint8_t **witness_out, size_t *witness_len);

/* -------------------- Utilities ---------------------------------------- */

/* Free a buffer returned by niwi_prove, niwi_prove_observed, or
 * niwi_extract. */
void niwi_free_buffer(uint8_t *buf);

/* Return a human-readable description of the last error, or NULL if
 * no error occurred. The returned pointer is valid until the next call
 * into the same niwi_ctx_t. */
const char *niwi_last_error(niwi_ctx_t *ctx);

/* Return the protocol version string (e.g. "niwi-v1"). */
const char *niwi_protocol_version(void);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_H */
