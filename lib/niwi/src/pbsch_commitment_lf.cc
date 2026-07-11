/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "pbsch_commitment.h"

#include <cstring>

#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_scalar.h"
#include "secp256k1/secp256k1_witness.h"

namespace {

using Field = niwi::FpSecp256k1Base;
using Point = niwi::Secp256k1::ECPoint;

Field::N be32_to_nat(const uint8_t bytes[32]) {
    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) {
        le[i] = bytes[31 - i];
    }
    return Field::N::of_bytes(le);
}

bool scalar_is_canonical_lf(const uint8_t scalar[32]) {
    return niwi::octet_to_secp256k1_scalar(scalar).has_value();
}

Field::Elt sqrt_even(const Field::Elt& y2) {
    Field::N exp(
        "0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffff0c");
    Field::Elt root = niwi::secp256k1_base.one();
    Field::Elt base = y2;
    for (int i = 255; i >= 0; --i) {
        root = niwi::secp256k1_base.mulf(root, root);
        if (exp.bit(i)) {
            root = niwi::secp256k1_base.mulf(root, base);
        }
    }
    Field::N nat = niwi::secp256k1_base.from_montgomery(root);
    return nat.bit(0) ? niwi::secp256k1_base.negf(root) : root;
}

bool h_point(Point *out) {
    uint8_t h_x_bytes[32];
    if (!out || niwi_pbsch_pedersen_h(h_x_bytes) != 0) {
        return false;
    }
    auto maybe_x = niwi::octet_to_secp256k1_base(h_x_bytes);
    if (!maybe_x.has_value()) {
        return false;
    }
    auto x = maybe_x.value();
    auto xx = niwi::secp256k1_base.mulf(x, x);
    auto xxx = niwi::secp256k1_base.mulf(x, xx);
    auto y2 = niwi::secp256k1_base.addf(
        xxx, niwi::secp256k1_base.of_scalar(7));
    auto y = sqrt_even(y2);
    if (niwi::secp256k1_base.mulf(y, y) != y2) {
        return false;
    }
    *out = {x, y, niwi::secp256k1_base.one()};
    return true;
}

bool compress_point(Point p, uint8_t out[NIWI_PBSCH_CMP_SIZE]) {
    if (!out || p.z == niwi::secp256k1_base.zero()) {
        return false;
    }
    niwi::secp256k1.normalize(p);
    niwi::secp256k1_base_to_octet(p.x, out + 1);
    Field::N y = niwi::secp256k1_base.from_montgomery(p.y);
    out[0] = y.bit(0) ? 0x03 : 0x02;
    return true;
}

}  // namespace

extern "C" int niwi_pbsch_pedersen_commit_lf(
    const uint8_t msg[32], const uint8_t rho[32],
    uint8_t c_out[NIWI_PBSCH_CMP_SIZE]) {
    if (!msg || !rho || !c_out) {
        return -1;
    }
    if (!scalar_is_canonical_lf(msg) || !scalar_is_canonical_lf(rho)) {
        return -1;
    }

    Point H;
    if (!h_point(&H)) {
        return -1;
    }

    Point G = niwi::secp256k1.generator();
    niwi::secp256k1.normalize(G);
    Point C = niwi::secp256k1.scalar_multf(G, be32_to_nat(msg));
    Point rH = niwi::secp256k1.scalar_multf(H, be32_to_nat(rho));
    niwi::secp256k1.addE(C, rH);
    return compress_point(C, c_out) ? 0 : -1;
}

extern "C" int niwi_pbsch_pedersen_verify_lf(
    const uint8_t c[NIWI_PBSCH_CMP_SIZE], const uint8_t msg[32],
    const uint8_t rho[32]) {
    if (!c || !msg || !rho) {
        return -1;
    }
    uint8_t recomputed[NIWI_PBSCH_CMP_SIZE];
    if (niwi_pbsch_pedersen_commit_lf(msg, rho, recomputed) != 0) {
        return -1;
    }
    return std::memcmp(c, recomputed, NIWI_PBSCH_CMP_SIZE) == 0 ? 0 : -1;
}
