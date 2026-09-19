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

#ifndef NIWI_SECP256K1_CURVE_H
#define NIWI_SECP256K1_CURVE_H

#include "ec/elliptic_curve.h"
#include "secp256k1_field.h"

namespace niwi {

/* secp256k1 elliptic curve (y^2 = x^3 + 7 over FpSecp256k1Base).
 *
 * Parameters: a = 0, b = 7, with generator G.
 * Uses EllipticCurve<FpSecp256k1Base, 4, 256> matching the P-256 pattern.
 * Since a = 0, the is_zero_a_ optimization applies in addition formulas.
 */
using Secp256k1 = proofs::EllipticCurve<FpSecp256k1Base, 4, 256>;

/* Singleton curve instance with the secp256k1 parameters. */
extern const Secp256k1 secp256k1;

}  // namespace niwi

#endif  // NIWI_SECP256K1_CURVE_H
