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

#ifndef NIWI_SECP256K1_WITNESS_H
#define NIWI_SECP256K1_WITNESS_H

#include <cstddef>
#include <cstdint>
#include <optional>

#include "algebra/nat.h"
#include "secp256k1_field.h"
#include "secp256k1_scalar.h"

namespace niwi {

/* Convert a 32-byte big-endian buffer to a secp256k1 base field element.
 *
 * The value is interpreted as a Nat<4> and then converted to Montgomery
 * representation. If the raw value >= p, a strict error is returned (no
 * modular reduction — the witness value must be canonically reduced).
 *
 * Returns an empty optional if x >= p. */
std::optional<FpSecp256k1Base::Elt> octet_to_secp256k1_base(
    const uint8_t bytes[32]);

/* Convert a 32-byte big-endian buffer to a secp256k1 scalar field element.
 *
 * Same semantics as octet_to_secp256k1_base but modulo n instead of p.
 * Returns an empty optional if x >= n. */
std::optional<FpSecp256k1Scalar::Elt> octet_to_secp256k1_scalar(
    const uint8_t bytes[32]);

/* Convert a secp256k1 base field element to a 32-byte big-endian buffer.
 * The element is unmapped from Montgomery form first. */
void secp256k1_base_to_octet(const FpSecp256k1Base::Elt& elt,
                              uint8_t bytes[32]);

/* Convert a secp256k1 scalar field element to a 32-byte big-endian buffer. */
void secp256k1_scalar_to_octet(const FpSecp256k1Scalar::Elt& elt,
                                uint8_t bytes[32]);

}  // namespace niwi

#endif  // NIWI_SECP256K1_WITNESS_H
