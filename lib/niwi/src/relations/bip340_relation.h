/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_RELATIONS_BIP340_RELATION_H
#define NIWI_RELATIONS_BIP340_RELATION_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Validate dense zkcc BIP-340 public/private inputs.
 *
 * The layout is the native bip340_compute_inputs layout:
 *   public_inputs = one || rx || px || e
 *   private_inputs = public_inputs || Bip340Verify::Witness::input()
 * with each field element encoded as a 32-byte little-endian canonical
 * secp256k1 base-field value.
 */
int niwi_bip340_relation_validate(const uint8_t *public_inputs, size_t pub_len,
                                  const uint8_t *private_inputs, size_t priv_len);

/* Build and verify a native Longfellow/Ligero ZkProof for the BIP340
 * relation. The proof bytes are allocated with malloc and must be freed by the
 * caller. */
int niwi_bip340_ligero_prove(const uint8_t *public_inputs, size_t pub_len,
                             const uint8_t *private_inputs, size_t priv_len,
                             uint8_t **proof_out, size_t *proof_len);

int niwi_bip340_ligero_verify(const uint8_t *public_inputs, size_t pub_len,
                              const uint8_t *proof, size_t proof_len);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_RELATIONS_BIP340_RELATION_H */
