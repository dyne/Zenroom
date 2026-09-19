/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "niwi.h"

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <memory>
#include <vector>

#include "algebra/fp_p256.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/logic.h"
#include "ec/p256.h"
#include "proto/circuit.h"

namespace {

using Field = proofs::Fp256Base;
using Backend = proofs::CompilerBackend<Field>;
using Logic = proofs::Logic<Field, Backend>;

constexpr size_t kEltBytes = 32;

void append_field(std::vector<uint8_t>& out, const Field& field,
                  const Field::Elt& elt) {
    uint8_t buf[kEltBytes];
    field.from_montgomery(elt).to_bytes(buf);
    out.insert(out.end(), buf, buf + sizeof(buf));
}

std::vector<uint8_t> build_addition_artifact(void) {
    const Field& field = proofs::p256_base;
    proofs::QuadCircuit<Field> q(field);
    const Backend backend(&q);
    const Logic logic(&backend, field);

    auto z = logic.eltw_input();
    q.private_input();
    auto x = logic.eltw_input();
    auto y = logic.eltw_input();
    logic.assert0(logic.sub(logic.add(x, y), z));

    auto circuit = q.mkcircuit(1);
    proofs::CircuitRep<Field> rep(field, proofs::FieldID::P256_ID);
    std::vector<uint8_t> artifact;
    rep.to_bytes(*circuit, artifact);
    return artifact;
}

void build_witness(std::vector<uint8_t>& public_inputs,
                   std::vector<uint8_t>& private_inputs) {
    const Field& field = proofs::p256_base;
    public_inputs.clear();
    private_inputs.clear();
    append_field(private_inputs, field, field.one());
    append_field(private_inputs, field, field.of_scalar(10));
    append_field(private_inputs, field, field.of_scalar(3));
    append_field(private_inputs, field, field.of_scalar(7));
    public_inputs.assign(private_inputs.begin(),
                         private_inputs.begin() + 2 * kEltBytes);
}

size_t find_tag(const uint8_t *buf, size_t len, const char tag[4]) {
    if (!buf || len < 4) return len;
    for (size_t i = 0; i + 4 <= len; ++i) {
        if (memcmp(buf + i, tag, 4) == 0) return i;
    }
    return len;
}

void test_p256_niwi_ligero_body_roundtrip(void) {
    std::vector<uint8_t> artifact = build_addition_artifact();
    std::vector<uint8_t> public_inputs;
    std::vector<uint8_t> private_inputs;
    build_witness(public_inputs, private_inputs);

    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        artifact.data(), artifact.size(), NIWI_RELATION_ZKCC_P256, nullptr,
        nullptr);
    assert(ctx != nullptr);

    uint8_t *proof = nullptr;
    size_t proof_len = 0;
    assert(niwi_prove(ctx, public_inputs.data(), public_inputs.size(),
                      private_inputs.data(), private_inputs.size(),
                      &proof, &proof_len) == 0);
    assert(proof != nullptr);
    assert(find_tag(proof, proof_len, "LZK0") != proof_len);
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs.data(), public_inputs.size()) == 0);

    proof[proof_len - 1] ^= 1u;
    assert(niwi_verify(ctx, proof, proof_len,
                       public_inputs.data(), public_inputs.size()) != 0);
    proof[proof_len - 1] ^= 1u;

    private_inputs[3 * kEltBytes + 31] ^= 1u;
    uint8_t *bad_proof = nullptr;
    size_t bad_proof_len = 0;
    assert(niwi_prove(ctx, public_inputs.data(), public_inputs.size(),
                      private_inputs.data(), private_inputs.size(),
                      &bad_proof, &bad_proof_len) != 0);
    assert(bad_proof == nullptr);

    niwi_free_buffer(proof);
    niwi_ctx_free(ctx);
    std::printf("  PASS test_p256_niwi_ligero_body_roundtrip\n");
}

}  // namespace

int main(void) {
    std::printf("lib/blindzap P256 zkcc native relation tests:\n");
    test_p256_niwi_ligero_body_roundtrip();
    std::printf("All P256 zkcc native relation tests passed.\n");
    return 0;
}
