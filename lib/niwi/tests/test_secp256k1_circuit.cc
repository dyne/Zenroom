/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <memory>

#include "arrays/dense.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/logic.h"
#include "circuits/secp256k1_circuit.h"
#include "secp256k1/secp256k1_curve.h"
#include "sumcheck/prover_layers.h"

namespace {

using Field = niwi::FpSecp256k1Base;
using Backend = proofs::CompilerBackend<Field>;
using Logic = proofs::Logic<Field, Backend>;

void fill_bits_msb(proofs::DenseFiller<Field>& filler, const Field::N& nat) {
    for (int i = 255; i >= 0; --i) {
        filler.push_back(niwi::secp256k1_base.of_scalar(nat.bit(i) ? 1 : 0));
    }
}

std::unique_ptr<proofs::Circuit<Field>> build_x_only_lift_circuit(void) {
    proofs::QuadCircuit<Field> q(niwi::secp256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, niwi::secp256k1_base);
    const niwi::Secp256k1Circuit<Logic> secp(logic, niwi::secp256k1);

    auto x = logic.eltw_input();
    q.private_input();
    auto y = logic.eltw_input();
    Logic::EltW y_bits[256];
    for (auto& bit : y_bits) {
        bit = logic.eltw_input();
    }
    secp.x_only_lift(x, y, y_bits);
    return q.mkcircuit(1);
}

bool evaluates(const proofs::Circuit<Field>& circuit,
               const proofs::Dense<Field>& witness) {
    proofs::ProverLayers<Field> layers(niwi::secp256k1_base);
    proofs::ProverLayers<Field>::inputs inputs;
    auto final = layers.eval_circuit(&inputs, &circuit, witness.clone(),
                                     niwi::secp256k1_base);
    return final != nullptr;
}

void fill_x_only_inputs(const Field::Elt& x, const Field::Elt& y,
                        proofs::Dense<Field> *witness,
                        proofs::Dense<Field> *pub) {
    proofs::DenseFiller<Field> pub_filler(*pub);
    pub_filler.push_back(niwi::secp256k1_base.one());
    pub_filler.push_back(x);
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> witness_filler(*witness);
    witness_filler.push_back(niwi::secp256k1_base.one());
    witness_filler.push_back(x);
    witness_filler.push_back(y);
    fill_bits_msb(witness_filler, niwi::secp256k1_base.from_montgomery(y));
    assert(witness_filler.size() == witness->n1_);
}

void test_x_only_lift_enforces_even_y(void) {
    auto circuit = build_x_only_lift_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 2);

    auto g = niwi::secp256k1.generator();
    niwi::secp256k1.normalize(g);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    fill_x_only_inputs(g.x, g.y, &witness, &pub);
    assert(evaluates(*circuit, witness));

    auto odd_y = niwi::secp256k1_base.negf(g.y);
    proofs::Dense<Field> odd_witness(1, circuit->ninputs);
    proofs::Dense<Field> odd_pub(1, circuit->npub_in);
    fill_x_only_inputs(g.x, odd_y, &odd_witness, &odd_pub);
    assert(!evaluates(*circuit, odd_witness));

    std::printf("  PASS test_x_only_lift_enforces_even_y\n");
}

}  // namespace

int main(void) {
    std::printf("lib/niwi secp256k1 circuit tests:\n");
    test_x_only_lift_enforces_even_y();
    std::printf("All secp256k1 circuit tests passed.\n");
    return 0;
}
