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

#ifndef NIWI_PBSCH_COMMITMENT_H
#define NIWI_PBSCH_COMMITMENT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- PBSch Pedersen primitives (C layer) ---------------------------------
 *
 * Cmt status: binding Pedersen profile, not paper-exact Cmt. This module does
 * not provide the straight-line extractability mechanism required for final
 * RPBSch claims; see lib/niwi/docs/pbsch-cmt-profile.md.
 *
 * The Lua layer owns tuple encoding, protocol orchestration, and
 * commitment object assembly. This C module exposes only the three
 * primitive operations needed:
 *
 *   1. Derive the independent Pedersen generator H
 *   2. Compute C = m·G + r·H over secp256k1
 *   3. Verify a Pedersen opening
 */

#define NIWI_PBSCH_CMP_SIZE      33   /* 0x02/0x03 || x (32 bytes) */

/* Derive the Pedersen H generator's x-coordinate (32 bytes, even-y).
 * H = lift_x(SHA-256("Zenroom/PBSch/PedersenH/v1" || iteration))
 * with iterative fallback until a valid even-y point is found.
 *
 * Returns 0 on success, -1 on error. The result is deterministic. */
int niwi_pbsch_pedersen_h(uint8_t h_x_out[32]);

/* Compute Pedersen commitment C = m·G + r·H.
 *
 * msg:   32-byte message (interpreted as a secp256k1 scalar)
 * rho:   32-byte hiding randomness (Pedersen blinding factor)
 * c_out: 33-byte compressed point (0x02/0x03 || x)
 *
 * Returns 0 on success, -1 on error. */
int niwi_pbsch_pedersen_commit(const uint8_t msg[32], const uint8_t rho[32],
                               uint8_t c_out[NIWI_PBSCH_CMP_SIZE]);

/* Verify a Pedersen commitment opening.
 *
 * c:      33-byte compressed point
 * msg:    32-byte purported message scalar
 * rho:    32-byte purported randomness
 *
 * Returns 0 if valid, -1 if invalid. */
int niwi_pbsch_pedersen_verify(const uint8_t c[NIWI_PBSCH_CMP_SIZE],
                               const uint8_t msg[32], const uint8_t rho[32]);

/* Longfellow/secp canonical Pedersen commitment profile for NIWI relations.
 *
 * These functions use the same H.x derivation as niwi_pbsch_pedersen_h(), but
 * all point arithmetic is performed with lib/niwi's Longfellow secp256k1
 * curve implementation. RPBSch/PBSch NIWI proof bodies use this profile so
 * witness generation and circuit evaluation share one curve model.
 */
int niwi_pbsch_pedersen_commit_lf(const uint8_t msg[32],
                                  const uint8_t rho[32],
                                  uint8_t c_out[NIWI_PBSCH_CMP_SIZE]);

int niwi_pbsch_pedersen_verify_lf(const uint8_t c[NIWI_PBSCH_CMP_SIZE],
                                  const uint8_t msg[32],
                                  const uint8_t rho[32]);

/* CMT3 Fischlin05 public proof for a Pedersen opening.
 *
 * This is the native fast path for the paper-facing Lua CMT3 profile:
 * CMT3 || profile_byte || ck || A[10] || ch[10] || z_m[10] || z_r[10].
 * It keeps the public proof format owned by Lua, but moves the tight
 * challenge-search loop out of Lua.
 */
#define NIWI_PBSCH_CMT3_PROOF_SIZE 1027

int niwi_pbsch_cmt3_prove_seeded(
    const uint8_t c[NIWI_PBSCH_CMP_SIZE], const uint8_t msg[32],
    const uint8_t rho[32], const uint8_t seed[32],
    uint8_t proof_out[NIWI_PBSCH_CMT3_PROOF_SIZE]);

int niwi_pbsch_cmt3_verify(const uint8_t c[NIWI_PBSCH_CMP_SIZE],
                           const uint8_t proof[NIWI_PBSCH_CMT3_PROOF_SIZE]);

#ifdef __cplusplus
}
#endif

#endif  /* NIWI_PBSCH_COMMITMENT_H */
