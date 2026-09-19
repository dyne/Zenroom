/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_RELATIONS_RPBSCH_RELATION_H
#define NIWI_RELATIONS_RPBSCH_RELATION_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Validate the native RPBSch branch relation.
 *
 * public_inputs is the 258-byte statement:
 *   X || X' || R || c || C || phi || ck || S
 *
 * private_inputs is the Lua-readable branch witness encoding documented in
 * crypto_rpbsch.lua. This handler validates C/S openings, branch-local
 * BIP340 public input binding, and the embedded BIP340 zkcc witnesses.
 */
int niwi_rpbsch_relation_validate(const uint8_t *public_inputs, size_t pub_len,
                                  const uint8_t *private_inputs, size_t priv_len);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_RELATIONS_RPBSCH_RELATION_H */
