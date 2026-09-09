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

#include "secp256k1_curve.h"
#include "secp256k1_scalar.h"

namespace niwi {

/* All singletons defined in one translation unit to avoid
 * static initialization order fiasco (same pattern as p256.cc). */

const FpSecp256k1Base secp256k1_base(
    "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f");

const FpSecp256k1Scalar secp256k1_scalar(
    "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");

const Secp256k1 secp256k1(
    /* a = 0 */
    secp256k1_base.of_string("0"),
    /* b = 7 */
    secp256k1_base.of_string("7"),
    /* G_x */
    secp256k1_base.of_string(
        "0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"),
    /* G_y */
    secp256k1_base.of_string(
        "0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"),
    secp256k1_base);

}  // namespace niwi
