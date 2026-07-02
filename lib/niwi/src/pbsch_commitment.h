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

/* ---- PBSch prototype Pedersen commitment --------------------------------
 *
 * In the 2025-1992 paper, Cmt is a straight-line extractable commitment
 * (Pedersen + Fischlin-style opening proof). This prototype implements:
 *
 *   1. A Pedersen commitment C = m*G + r*H over secp256k1
 *   2. A simple hash-based opening proof (SHA-256)
 *
 * This is NOT paper-level Cmt. The upgrade path is replacing the hash
 * opening proof with a Fischlin-style Sigma protocol in a future version.
 *
 * Commitment format (65 bytes):
 *   C_x (32 bytes) — x-coordinate of the Pedersen point (compressed)
 *   parity (1 byte) — 0x02 for even y, 0x03 for odd y
 *   pi (32 bytes)   — SHA-256 opening proof
 *       pi = SHA-256("PBSch/Cmt/v1" || C_x || parity ||
 *                     msg[0..31] || alpha[0..31] || beta[0..31] || rho[0..31])
 *
 * The generator H is derived deterministically:
 *   H = lift_x(SHA-256("Zenroom/PBSch/PedersenH/v1"))
 * with fallback: if lift_x fails, hash the previous hash until a valid
 * x-coordinate is found.
 */

#define NIWI_PBSCH_C_SIZE         65
#define NIWI_PBSCH_S_SIZE         65
#define NIWI_PBSCH_RAND_SIZE      32
#define NIWI_PBSCH_MSG_SIZE       32

/* Compute a PBSch C commitment.
 *
 * msg:    32-byte message
 * alpha:  32-byte scalar (blinding factor)
 * beta:   32-byte scalar (blinding factor)
 * rho:    32-byte randomness for the opening proof
 * c_out:  65-byte output commitment
 *
 * Returns 0 on success, -1 on error. */
int niwi_pbsch_cmt_commit(const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t alpha[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t beta[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                          uint8_t c_out[NIWI_PBSCH_C_SIZE]);

/* Verify a PBSch C commitment opening.
 *
 * c:       65-byte commitment
 * msg:     32-byte purported message
 * alpha:   32-byte purported alpha
 * beta:    32-byte purported beta
 * rho:     32-byte randomness used for the opening proof
 *
 * Returns 0 if valid, -1 if invalid. */
int niwi_pbsch_cmt_verify(const uint8_t c[NIWI_PBSCH_C_SIZE],
                          const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t alpha[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t beta[NIWI_PBSCH_RAND_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE]);

/* Compute a PBSch S commitment (same format as C, different tuple).
 *
 * sig0:   64-byte BIP-340 signature (Rx || s)
 * sig1:   64-byte BIP-340 signature (Rx || s)
 * nu_u:   32-byte scalar
 * nu_u':  32-byte scalar (must differ from nu_u)
 * nu_s:   32-byte message
 * rho:    32-byte randomness for the opening proof
 * s_out:  65-byte output commitment
 *
 * Returns 0 on success, -1 on error. */
int niwi_pbsch_cmt_s_commit(const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                            uint8_t s_out[NIWI_PBSCH_S_SIZE]);

/* Verify a PBSch S commitment opening. */
int niwi_pbsch_cmt_s_verify(const uint8_t s[NIWI_PBSCH_S_SIZE],
                            const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE]);

/* ---- H generator ------------------------------------------------------- */

/* Returns the x-coordinate (32 bytes) of the independent generator H.
 * H = lift_x(SHA-256("Zenroom/PBSch/PedersenH/v1")) with fallback. */
const uint8_t *niwi_pbsch_pedersen_h_x(void);

#ifdef __cplusplus
}
#endif

#endif  /* NIWI_PBSCH_COMMITMENT_H */
