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

#ifndef NIWI_SECP256K1_FIELD_H
#define NIWI_SECP256K1_FIELD_H

#include "algebra/fp.h"

namespace niwi {

/* secp256k1 base field F_p where
 * p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
 *
 * Uses Longfellow's generic Fp<4> path with Montgomery reduction.
 * The generic FpReduce handles any odd 256-bit modulus fitting in 4 limbs.
 */
using FpSecp256k1Base = proofs::Fp<4, true>;

/* Singleton instance initialized with the secp256k1 prime. */
extern const FpSecp256k1Base secp256k1_base;

}  // namespace niwi

#endif  // NIWI_SECP256K1_FIELD_H
