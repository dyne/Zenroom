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

#ifndef NIWI_SECP256K1_PROOF_H
#define NIWI_SECP256K1_PROOF_H

#include "proto/circuit.h"
#include "secp256k1_field.h"

namespace niwi {

/* Wire the SECP_ID field identifier to the secp256k1 circuit representation.
 *
 * Usage:
 *   proofs::CircuitRep<FpSecp256k1Base> circuit_rep(secp256k1_base,
 *                                                    proofs::SECP_ID);
 *
 * This ensures:
 * 1. Circuit serialization writes SECP_ID (10) in the bytecode header
 * 2. Circuit deserialization validates the field ID matches
 * 3. Circuits serialized under SECP_ID are rejected under P256_ID and vice versa
 */

/* Pre-built CircuitRep for secp256k1 circuits. */
inline proofs::CircuitRep<FpSecp256k1Base> secp256k1_circuit_rep() {
    return proofs::CircuitRep<FpSecp256k1Base>(secp256k1_base,
                                                proofs::SECP_ID);
}

}  // namespace niwi

#endif  // NIWI_SECP256K1_PROOF_H
