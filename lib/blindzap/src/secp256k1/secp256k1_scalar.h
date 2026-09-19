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

#ifndef NIWI_SECP256K1_SCALAR_H
#define NIWI_SECP256K1_SCALAR_H

#include "algebra/fp.h"

namespace niwi {

/* Scalar field for secp256k1 (modulo the curve order n).
 * n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
 *
 * This field is used for BIP-340 signature verification inside circuits
 * where scalar arithmetic must be modulo n, not modulo p.
 */
using FpSecp256k1Scalar = proofs::Fp<4, true>;

/* Singleton instance initialized with the secp256k1 curve order. */
extern const FpSecp256k1Scalar secp256k1_scalar;

}  // namespace niwi

#endif  // NIWI_SECP256K1_SCALAR_H
