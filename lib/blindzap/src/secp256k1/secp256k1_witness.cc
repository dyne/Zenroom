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

#include "secp256k1_witness.h"

namespace niwi {

using FpBaseNat = FpSecp256k1Base::N;
using FpScalarNat = FpSecp256k1Scalar::N;

/* Convert 32-byte big-endian bytes to little-endian Nat. */
static FpBaseNat be32_to_nat(const uint8_t bytes[32]) {
    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) {
        le[i] = bytes[31 - i];
    }
    return FpBaseNat::of_bytes(le);
}

std::optional<FpSecp256k1Base::Elt> octet_to_secp256k1_base(
    const uint8_t bytes[32]) {
    FpBaseNat nat = be32_to_nat(bytes);

    /* Reject values >= p (the generic Fp does not provide a direct
     * comparison method, but to_montgomery will work for all values
     * < p and fail for invalid inputs). We validate by round-tripping:
     * from_montgomery(to_montgomery(nat)) should equal nat.
     * For values >= p, the reduction wraps around, producing a different
     * value. */
    FpSecp256k1Base::Elt elt = secp256k1_base.to_montgomery(nat);
    FpBaseNat back = secp256k1_base.from_montgomery(elt);
    if (!(nat == back)) {
        return std::nullopt;
    }
    return elt;
}

std::optional<FpSecp256k1Scalar::Elt> octet_to_secp256k1_scalar(
    const uint8_t bytes[32]) {
    FpScalarNat nat;
    /* FpScalarNat and FpBaseNat are both Nat<4> but possibly with
     * different template args. We do the raw byte conversion. */
    {
        uint8_t le[32];
        for (size_t i = 0; i < 32; ++i) {
            le[i] = bytes[31 - i];
        }
        nat = FpScalarNat::of_bytes(le);
    }

    FpSecp256k1Scalar::Elt elt = secp256k1_scalar.to_montgomery(nat);
    FpScalarNat back = secp256k1_scalar.from_montgomery(elt);
    if (!(nat == back)) {
        return std::nullopt;
    }
    return elt;
}

void secp256k1_base_to_octet(const FpSecp256k1Base::Elt& elt,
                              uint8_t bytes[32]) {
    FpBaseNat nat = secp256k1_base.from_montgomery(elt);
    uint8_t le[32];
    nat.to_bytes(le);
    for (size_t i = 0; i < 32; ++i) {
        bytes[i] = le[31 - i];
    }
}

void secp256k1_scalar_to_octet(const FpSecp256k1Scalar::Elt& elt,
                                uint8_t bytes[32]) {
    FpScalarNat nat = secp256k1_scalar.from_montgomery(elt);
    uint8_t le[32];
    nat.to_bytes(le);
    for (size_t i = 0; i < 32; ++i) {
        bytes[i] = le[31 - i];
    }
}

}  // namespace niwi
