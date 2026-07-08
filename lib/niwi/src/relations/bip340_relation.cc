/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/bip340_relation.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "algebra/fp_p256k1.h"
#include "circuits/bip340/bip340_verify.h"
#include "circuits/logic/evaluation_backend.h"
#include "circuits/logic/logic.h"
#include "ec/p256k1.h"

namespace {

using Field = proofs::Fp256k1Base;
using Backend = proofs::EvaluationBackend<Field>;
using Logic = proofs::Logic<Field, Backend>;
using Verify = proofs::Bip340Verify<Logic, Field, proofs::P256k1>;
using Elt = Field::Elt;
using EltW = Logic::EltW;

constexpr size_t kEltBytes = 32;
constexpr size_t kPublicElts = 4;
constexpr size_t kInputElts = 2305;
constexpr size_t kBits = proofs::P256k1::kBits;

bool decode_field(const uint8_t *bytes, Elt *out) {
    Field::N nat = Field::N::of_bytes(bytes);
    Elt elt = proofs::p256k1_base.to_montgomery(nat);
    Field::N back = proofs::p256k1_base.from_montgomery(elt);
    if (!(nat == back)) return false;
    *out = elt;
    return true;
}

bool read_field(const uint8_t *inputs, size_t n_elts, size_t *idx, EltW *out) {
    if (*idx >= n_elts) return false;
    Elt elt;
    if (!decode_field(inputs + (*idx * kEltBytes), &elt)) return false;
    *out = EltW{elt};
    ++*idx;
    return true;
}

bool read_field_array(const uint8_t *inputs, size_t n_elts, size_t *idx,
                      EltW out[kBits], size_t count) {
    for (size_t i = 0; i < count; ++i) {
        if (!read_field(inputs, n_elts, idx, &out[i])) return false;
    }
    return true;
}

}  // namespace

extern "C" int niwi_bip340_relation_validate(
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len) {
    if (!public_inputs || !private_inputs) return -1;
    if (pub_len != kPublicElts * kEltBytes) return -1;
    if (priv_len != kInputElts * kEltBytes) return -1;
    if (memcmp(public_inputs, private_inputs, pub_len) != 0) return -1;

    uint8_t one_bytes[kEltBytes];
    Field::N one_nat = proofs::p256k1_base.from_montgomery(
        proofs::p256k1_base.one());
    one_nat.to_bytes(one_bytes);
    if (memcmp(public_inputs, one_bytes, sizeof(one_bytes)) != 0) return -1;

    Backend backend(proofs::p256k1_base, /*panic_on_assertion_failure=*/false);
    Logic logic(&backend, proofs::p256k1_base);
    Verify verifier(logic, proofs::p256k1);

    size_t idx = 0;
    EltW one;
    EltW rx;
    EltW px;
    EltW e;
    Verify::Witness witness;

    if (!read_field(private_inputs, kInputElts, &idx, &one)) return -1;
    if (one.elt() != proofs::p256k1_base.one()) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &rx)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &px)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &e)) return -1;

    for (size_t i = 0; i < kBits; ++i) {
        if (!read_field(private_inputs, kInputElts, &idx, &witness.bits_s[i]))
            return -1;
        if (i < kBits - 1) {
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_sx[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_sy[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_sz[i]))
                return -1;
        }
    }
    for (size_t i = 0; i < kBits; ++i) {
        if (!read_field(private_inputs, kInputElts, &idx, &witness.bits_e[i]))
            return -1;
        if (i < kBits - 1) {
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_ex[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_ey[i]))
                return -1;
            if (!read_field(private_inputs, kInputElts, &idx, &witness.int_ez[i]))
                return -1;
        }
    }
    if (!read_field(private_inputs, kInputElts, &idx, &witness.py)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &witness.ry)) return -1;
    if (!read_field(private_inputs, kInputElts, &idx, &witness.rz_inv)) return -1;
    if (!read_field_array(private_inputs, kInputElts, &idx, witness.bits_ry,
                          kBits)) {
        return -1;
    }
    if (idx != kInputElts) return -1;

    verifier.assert_verify(rx, px, e, witness);
    return backend.assertion_failed() ? -1 : 0;
}
