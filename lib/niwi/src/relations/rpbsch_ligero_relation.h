/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_RELATIONS_RPBSCH_LIGERO_RELATION_H
#define NIWI_RELATIONS_RPBSCH_LIGERO_RELATION_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int niwi_rpbsch_ligero_prove(const uint8_t *public_inputs, size_t pub_len,
                             const uint8_t *private_inputs, size_t priv_len,
                             uint8_t **proof_out, size_t *proof_len);

int niwi_rpbsch_ligero_verify(const uint8_t *public_inputs, size_t pub_len,
                              const uint8_t *proof, size_t proof_len);

#ifdef __cplusplus
}
#endif

#endif  /* NIWI_RELATIONS_RPBSCH_LIGERO_RELATION_H */
