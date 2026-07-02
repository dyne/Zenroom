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
 * 2025-1992 requires a straight-line extractable Cmt (Pedersen + Fischlin).
 * This prototype implements only the Pedersen commitment:
 *
 *   C = m·G + rho·H   over secp256k1
 *
 * where:
 *   G  = secp256k1 base point
 *   H  = independent generator (derived from domain-separated hash)
 *   m  = message scalar
 *   rho = hiding randomness
 *
 * The Fischlin-style opening proof is DEFERRED. This prototype Cmt does
 * not claim extractability. The commitment IS the Pedersen point.
 *
 * Cmt format (33 bytes):
 *   0x02 or 0x03 || C_x (32 bytes)   — secp256k1 compressed point
 *
 * No auxiliary hash proof is embedded; the Pedersen point is the commitment.
 * Opening verification is simple: recompute C and compare.
 *
 * Tuple binding for S-cmt:
 *   S commits to (sig0, sig1, nu_u, nu_u', nu_s) by first serializing the
 *   tuple as a canonical byte string and lifting it to a scalar via
 *   SHA-256, then using that scalar as m in the Pedersen equation.
 */

#define NIWI_PBSCH_C_CMP_SIZE    33   /* compressed Pedersen point */
#define NIWI_PBSCH_S_CMP_SIZE    33
#define NIWI_PBSCH_RAND_SIZE     32
#define NIWI_PBSCH_MSG_SIZE      32

/* Compute a PBSch C commitment: C = msg·G + rho·H.
 *
 * msg:   32-byte message (interpreted as scalar)
 * rho:   32-byte hiding randomness (Pedersen blinding factor)
 * c_out: 33-byte output commitment (0x02/0x03 || x)
 *
 * Returns 0 on success, -1 on error. */
int niwi_pbsch_cmt_commit(const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                          uint8_t c_out[NIWI_PBSCH_C_CMP_SIZE]);

/* Verify a PBSch C commitment opening.
 *
 * c:     33-byte commitment
 * msg:   32-byte purported message
 * rho:   32-byte purported randomness
 *
 * Returns 0 if valid, -1 if invalid. */
int niwi_pbsch_cmt_verify(const uint8_t c[NIWI_PBSCH_C_CMP_SIZE],
                          const uint8_t msg[NIWI_PBSCH_MSG_SIZE],
                          const uint8_t rho[NIWI_PBSCH_RAND_SIZE]);

/* Compute a PBSch S commitment.
 *
 * sig0:     64-byte BIP-340 signature (Rx || s)
 * sig1:     64-byte BIP-340 signature (Rx || s)
 * nu_u:     32-byte scalar
 * nu_u':    32-byte scalar (must differ from nu_u)
 * nu_s:     32-byte message
 * rho:      32-byte hiding randomness
 * s_out:    33-byte output commitment
 *
 * The tuple (sig0, sig1, nu_u, nu_u', nu_s) is serialized and hashed to a
 * 32-byte scalar m, then C = m·G + rho·H. */
int niwi_pbsch_cmt_s_commit(const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE],
                            uint8_t s_out[NIWI_PBSCH_S_CMP_SIZE]);

/* Verify a PBSch S commitment opening. */
int niwi_pbsch_cmt_s_verify(const uint8_t s[NIWI_PBSCH_S_CMP_SIZE],
                            const uint8_t sig0[64], const uint8_t sig1[64],
                            const uint8_t nu_u[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_u_prime[NIWI_PBSCH_RAND_SIZE],
                            const uint8_t nu_s[NIWI_PBSCH_MSG_SIZE],
                            const uint8_t rho[NIWI_PBSCH_RAND_SIZE]);

/* ---- H generator ------------------------------------------------------- */

/* Returns the x-coordinate (32 bytes) of the independent generator H.
 * H = lift_x(SHA-256("Zenroom/PBSch/PedersenH/v1") || iteration)
 * with iterative fallback until a valid even-y point is found. */
const uint8_t *niwi_pbsch_pedersen_h_x(void);

#ifdef __cplusplus
}
#endif

#endif  /* NIWI_PBSCH_COMMITMENT_H */
