/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_RELATIONS_ZKCC_P256_RELATION_H
#define NIWI_RELATIONS_ZKCC_P256_RELATION_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int niwi_zkcc_p256_relation_validate(const uint8_t *artifact,
                                      size_t artifact_len,
                                      const uint8_t *public_inputs,
                                      size_t pub_len,
                                      const uint8_t *private_inputs,
                                      size_t priv_len);

#ifdef __cplusplus
}
#endif

#endif /* NIWI_RELATIONS_ZKCC_P256_RELATION_H */
