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
#include "circuits/rpbsch/rpbsch_commitment_circuit.h"
#include "pbsch_commitment.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_witness.h"
#include "sumcheck/prover_layers.h"

namespace {

using Field = niwi::FpSecp256k1Base;
using Backend = proofs::CompilerBackend<Field>;
using Logic = proofs::Logic<Field, Backend>;
using Point = niwi::Secp256k1::ECPoint;

void fill_bits_msb(proofs::DenseFiller<Field>& filler, const Field::N& nat) {
    for (int i = 255; i >= 0; --i) {
        filler.push_back(niwi::secp256k1_base.of_scalar(nat.bit(i) ? 1 : 0));
    }
}

void field_to_bytes(const Field::Elt& elt, uint8_t bytes[32]) {
    niwi::secp256k1_base_to_octet(elt, bytes);
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

bool compressed_y(uint8_t prefix, const uint8_t x_bytes[32],
                  uint8_t y_bytes[32]) {
    auto maybe_x = niwi::octet_to_secp256k1_base(x_bytes);
    if (!maybe_x.has_value()) {
        return false;
    }
    auto x = maybe_x.value();
    auto xx = niwi::secp256k1_base.mulf(x, x);
    auto xxx = niwi::secp256k1_base.mulf(x, xx);
    auto y2 = niwi::secp256k1_base.addf(
        xxx, niwi::secp256k1_base.of_scalar(7));
    auto y = sqrt_even(y2);
    if ((prefix & 1u) != 0) {
        y = niwi::secp256k1_base.negf(y);
    }
    auto check = niwi::secp256k1_base.mulf(y, y);
    if (check != y2) {
        return false;
    }
    niwi::secp256k1_base_to_octet(y, y_bytes);
    return true;
}

bool is_on_curve_bytes(const uint8_t x_bytes[32], const uint8_t y_bytes[32]) {
    auto maybe_x = niwi::octet_to_secp256k1_base(x_bytes);
    auto maybe_y = niwi::octet_to_secp256k1_base(y_bytes);
    assert(maybe_x.has_value());
    assert(maybe_y.has_value());
    auto x = maybe_x.value();
    auto y = maybe_y.value();
    auto yy = niwi::secp256k1_base.mulf(y, y);
    auto xx = niwi::secp256k1_base.mulf(x, x);
    auto xxx = niwi::secp256k1_base.mulf(x, xx);
    auto rhs = niwi::secp256k1_base.addf(
        xxx, niwi::secp256k1_base.of_scalar(7));
    return yy == rhs;
}

Field::N be32_to_nat(const uint8_t bytes[32]) {
    uint8_t le[32];
    for (size_t i = 0; i < 32; ++i) {
        le[i] = bytes[31 - i];
    }
    return Field::N::of_bytes(le);
}

Point fill_scalar_mult_witness(proofs::DenseFiller<Field>& filler,
                               const Point& point, const Field::N& scalar) {
    const auto& F = niwi::secp256k1_base;
    Point acc{F.zero(), F.one(), F.zero()};
    Field::Elt bits[256];
    Field::Elt int_x[256];
    Field::Elt int_y[256];
    Field::Elt int_z[256];
    bool started = false;

    for (size_t i = 0; i < 256; ++i) {
        size_t bit_idx = 255 - i;
        int bit = scalar.bit(bit_idx);
        bits[i] = F.of_scalar(bit);

        if (!started) {
            if (bit == 1) {
                acc = point;
                started = true;
            }
        } else {
            Point doubled = acc;
            niwi::secp256k1.doubleE(doubled);
            if (bit == 1) {
                acc = doubled;
                niwi::secp256k1.addE(acc, point);
            } else {
                acc = doubled;
            }
        }
        int_x[i] = acc.x;
        int_y[i] = acc.y;
        int_z[i] = acc.z;
    }

    for (size_t i = 0; i < 256; ++i) {
        filler.push_back(bits[i]);
        if (i < 255) {
            filler.push_back(int_x[i]);
            filler.push_back(int_y[i]);
            filler.push_back(int_z[i]);
        }
    }
    return {int_x[255], int_y[255], int_z[255]};
}

Point pedersen_h_point(void) {
    uint8_t h_x_bytes[32];
    uint8_t h_y_bytes[32];
    assert(niwi_pbsch_pedersen_h(h_x_bytes) == 0);
    assert(compressed_y(0x02, h_x_bytes, h_y_bytes));
    auto h_x = niwi::octet_to_secp256k1_base(h_x_bytes);
    auto h_y = niwi::octet_to_secp256k1_base(h_y_bytes);
    assert(h_x.has_value());
    assert(h_y.has_value());
    return {h_x.value(), h_y.value(), niwi::secp256k1_base.one()};
}

void longfellow_pedersen_commit(const uint8_t msg[32],
                                const uint8_t rho[32],
                                uint8_t compressed[33],
                                uint8_t y_bytes[32]) {
    Point G = niwi::secp256k1.generator();
    niwi::secp256k1.normalize(G);
    Point H = pedersen_h_point();
    Point C = niwi::secp256k1.scalar_multf(G, be32_to_nat(msg));
    Point rH = niwi::secp256k1.scalar_multf(H, be32_to_nat(rho));
    niwi::secp256k1.addE(C, rH);
    niwi::secp256k1.normalize(C);
    field_to_bytes(C.x, compressed + 1);
    field_to_bytes(C.y, y_bytes);
    compressed[0] =
        niwi::secp256k1_base.from_montgomery(C.y).bit(0) ? 0x03 : 0x02;
}

std::unique_ptr<proofs::Circuit<Field>> build_compressed_point_circuit(void) {
    proofs::QuadCircuit<Field> q(niwi::secp256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, niwi::secp256k1_base);
    const niwi::rpbsch::RpbschCommitmentCircuit<Logic> c(logic);

    auto prefix = logic.eltw_input();
    auto x = logic.eltw_input();
    q.private_input();
    auto y = logic.eltw_input();
    Logic::EltW y_bits[256];
    for (auto& bit : y_bits) {
        bit = logic.eltw_input();
    }
    c.assert_compressed_point(prefix, x, y, y_bits);
    return q.mkcircuit(1);
}

std::unique_ptr<proofs::Circuit<Field>> build_pedersen_opening_circuit(
    bool use_wrong_h = false) {
    proofs::QuadCircuit<Field> q(niwi::secp256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, niwi::secp256k1_base);
    const niwi::rpbsch::RpbschCommitmentCircuit<Logic> c(logic);

    auto prefix = logic.eltw_input();
    auto c_x = logic.eltw_input();
    q.private_input();
    auto c_y = logic.eltw_input();
    Logic::EltW c_y_bits[256];
    for (auto& bit : c_y_bits) {
        bit = logic.eltw_input();
    }
    auto msg = logic.eltw_input();
    auto rho = logic.eltw_input();
    auto h_x = logic.konst(niwi::secp256k1_base.zero());
    auto h_y = logic.konst(niwi::secp256k1_base.zero());
    Point H = use_wrong_h ? niwi::secp256k1.generator() : pedersen_h_point();
    niwi::secp256k1.normalize(H);
    h_x = logic.konst(H.x);
    h_y = logic.konst(H.y);

    typename niwi::rpbsch::RpbschCommitmentCircuit<Logic>
        ::PedersenOpeningWitness opening;
    opening.input(logic);

    c.assert_pedersen_opening(prefix, c_x, c_y, c_y_bits, msg, rho,
                              h_x, h_y, opening);
    return q.mkcircuit(1);
}

bool evaluates(const proofs::Circuit<Field>& circuit,
               const proofs::Dense<Field>& witness,
               bool debug = false) {
    proofs::ProverLayers<Field> layers(niwi::secp256k1_base);
    proofs::ProverLayers<Field>::inputs inputs;
    auto final = layers.eval_circuit(&inputs, &circuit, witness.clone(),
                                     niwi::secp256k1_base);
    if (final == nullptr) {
        if (debug) {
            std::printf("    circuit evaluation returned null\n");
        }
        return false;
    }
    for (size_t i = 0; i < final->n0_ * final->n1_; ++i) {
        if (final->v_[i] != niwi::secp256k1_base.zero()) {
            if (debug) {
                std::printf("    non-zero final output at %zu\n", i);
            }
            return false;
        }
    }
    return true;
}

void build_test_commitment(uint8_t compressed[33], uint8_t y_bytes[32]) {
    uint8_t msg[32] = {0};
    uint8_t rho[32] = {0};
    msg[31] = 7;
    rho[31] = 11;
    longfellow_pedersen_commit(msg, rho, compressed, y_bytes);
}

void fill_pedersen_opening_inputs(uint8_t prefix, const uint8_t x_bytes[32],
                                  const uint8_t y_bytes[32],
                                  const uint8_t msg_bytes[32],
                                  const uint8_t rho_bytes[32],
                                  proofs::Dense<Field> *witness,
                                  proofs::Dense<Field> *pub) {
    auto c_x = niwi::octet_to_secp256k1_base(x_bytes);
    auto c_y = niwi::octet_to_secp256k1_base(y_bytes);
    auto msg = niwi::octet_to_secp256k1_base(msg_bytes);
    auto rho = niwi::octet_to_secp256k1_base(rho_bytes);
    assert(c_x.has_value());
    assert(c_y.has_value());
    assert(msg.has_value());
    assert(rho.has_value());

    Point H = pedersen_h_point();

    proofs::DenseFiller<Field> pub_filler(*pub);
    pub_filler.push_back(niwi::secp256k1_base.one());
    pub_filler.push_back(niwi::secp256k1_base.of_scalar(prefix));
    pub_filler.push_back(c_x.value());
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> witness_filler(*witness);
    witness_filler.push_back(niwi::secp256k1_base.one());
    witness_filler.push_back(niwi::secp256k1_base.of_scalar(prefix));
    witness_filler.push_back(c_x.value());
    witness_filler.push_back(c_y.value());
    fill_bits_msb(witness_filler,
                  niwi::secp256k1_base.from_montgomery(c_y.value()));
    witness_filler.push_back(msg.value());
    witness_filler.push_back(rho.value());

    Point G = niwi::secp256k1.generator();
    niwi::secp256k1.normalize(G);
    Point msg_g = fill_scalar_mult_witness(witness_filler, G,
                                           be32_to_nat(msg_bytes));
    Point rho_h = fill_scalar_mult_witness(witness_filler, H,
                                           be32_to_nat(rho_bytes));
    Point msg_g_check = msg_g;
    Point msg_g_ref = niwi::secp256k1.scalar_multf(G, be32_to_nat(msg_bytes));
    Point msg_g_raw = msg_g_ref;
    niwi::secp256k1.normalize(msg_g_check);
    niwi::secp256k1.normalize(msg_g_ref);
    assert(msg_g_check.x == msg_g_ref.x);
    assert(msg_g_check.y == msg_g_ref.y);
    Point rho_h_check = rho_h;
    Point rho_h_ref = niwi::secp256k1.scalar_multf(H, be32_to_nat(rho_bytes));
    Point rho_h_raw = rho_h_ref;
    niwi::secp256k1.normalize(rho_h_check);
    niwi::secp256k1.normalize(rho_h_ref);
    assert(rho_h_check.x == rho_h_ref.x);
    assert(rho_h_check.y == rho_h_ref.y);
    witness_filler.push_back(msg_g_raw.x);
    witness_filler.push_back(msg_g_raw.y);
    witness_filler.push_back(msg_g_raw.z);
    witness_filler.push_back(rho_h_raw.x);
    witness_filler.push_back(rho_h_raw.y);
    witness_filler.push_back(rho_h_raw.z);
    msg_g = msg_g_raw;
    rho_h = rho_h_raw;
    niwi::secp256k1.addE(msg_g, rho_h);
    witness_filler.push_back(niwi::secp256k1_base.invertf(msg_g.z));

    assert(witness_filler.size() == witness->n1_);
}

void fill_compressed_point_inputs(uint8_t prefix, const uint8_t x_bytes[32],
                                  const uint8_t y_bytes[32],
                                  proofs::Dense<Field> *witness,
                                  proofs::Dense<Field> *pub) {
    auto x = niwi::octet_to_secp256k1_base(x_bytes);
    auto y = niwi::octet_to_secp256k1_base(y_bytes);
    assert(x.has_value());
    assert(y.has_value());

    proofs::DenseFiller<Field> pub_filler(*pub);
    pub_filler.push_back(niwi::secp256k1_base.one());
    pub_filler.push_back(niwi::secp256k1_base.of_scalar(prefix));
    pub_filler.push_back(x.value());
    assert(pub_filler.size() == pub->n1_);

    proofs::DenseFiller<Field> witness_filler(*witness);
    witness_filler.push_back(niwi::secp256k1_base.one());
    witness_filler.push_back(niwi::secp256k1_base.of_scalar(prefix));
    witness_filler.push_back(x.value());
    witness_filler.push_back(y.value());
    fill_bits_msb(witness_filler, niwi::secp256k1_base.from_montgomery(y.value()));
    assert(witness_filler.size() == witness->n1_);
}

void test_compressed_point_prefix_and_lift(void) {
    auto circuit = build_compressed_point_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 3);

    uint8_t compressed[33];
    uint8_t y_bytes[32];
    build_test_commitment(compressed, y_bytes);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    fill_compressed_point_inputs(compressed[0], compressed + 1, y_bytes,
                                 &witness, &pub);
    assert(evaluates(*circuit, witness));

    proofs::Dense<Field> bad_prefix_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_prefix_pub(1, circuit->npub_in);
    fill_compressed_point_inputs(compressed[0] == 2 ? 3 : 2, compressed + 1,
                                 y_bytes, &bad_prefix_witness,
                                 &bad_prefix_pub);
    assert(!evaluates(*circuit, bad_prefix_witness));

    uint8_t bad_x[32];
    memcpy(bad_x, compressed + 1, sizeof(bad_x));
    bad_x[31] ^= 1u;
    assert(!is_on_curve_bytes(bad_x, y_bytes));
    proofs::Dense<Field> bad_x_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_x_pub(1, circuit->npub_in);
    fill_compressed_point_inputs(compressed[0], bad_x, y_bytes,
                                 &bad_x_witness, &bad_x_pub);
    assert(!evaluates(*circuit, bad_x_witness));

    proofs::Dense<Field> bad_bit_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_bit_pub(1, circuit->npub_in);
    fill_compressed_point_inputs(compressed[0], compressed + 1, y_bytes,
                                 &bad_bit_witness, &bad_bit_pub);
    bad_bit_witness.v_[bad_bit_witness.n1_ - 1] =
        niwi::secp256k1_base.addf(bad_bit_witness.v_[bad_bit_witness.n1_ - 1],
                                  niwi::secp256k1_base.one());
    assert(!evaluates(*circuit, bad_bit_witness));

    std::printf("  PASS test_compressed_point_prefix_and_lift\n");
}

void test_pedersen_c_opening(void) {
    auto circuit = build_pedersen_opening_circuit();
    assert(circuit != nullptr);
    assert(circuit->npub_in == 3);

    uint8_t msg[32] = {0};
    uint8_t rho[32] = {0};
    msg[31] = 7;
    rho[31] = 11;
    uint8_t compressed[33];
    uint8_t y_bytes[32];
    longfellow_pedersen_commit(msg, rho, compressed, y_bytes);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], compressed + 1, y_bytes,
                                 msg, rho, &witness, &pub);
    assert(evaluates(*circuit, witness, true));

    uint8_t wrong_rho[32];
    memcpy(wrong_rho, rho, sizeof(wrong_rho));
    wrong_rho[31] = 12;
    proofs::Dense<Field> bad_rho_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_rho_pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], compressed + 1, y_bytes,
                                 msg, wrong_rho, &bad_rho_witness,
                                 &bad_rho_pub);
    assert(!evaluates(*circuit, bad_rho_witness));

    uint8_t wrong_msg[32];
    memcpy(wrong_msg, msg, sizeof(wrong_msg));
    wrong_msg[31] = 8;
    proofs::Dense<Field> bad_msg_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_msg_pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], compressed + 1, y_bytes,
                                 wrong_msg, rho, &bad_msg_witness,
                                 &bad_msg_pub);
    assert(!evaluates(*circuit, bad_msg_witness));

    uint8_t bad_x[32];
    memcpy(bad_x, compressed + 1, sizeof(bad_x));
    bad_x[31] ^= 1u;
    proofs::Dense<Field> bad_c_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_c_pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], bad_x, y_bytes,
                                 msg, rho, &bad_c_witness, &bad_c_pub);
    assert(!evaluates(*circuit, bad_c_witness));

    auto wrong_h_circuit = build_pedersen_opening_circuit(true);
    assert(wrong_h_circuit != nullptr);
    proofs::Dense<Field> wrong_h_witness(1, wrong_h_circuit->ninputs);
    proofs::Dense<Field> wrong_h_pub(1, wrong_h_circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], compressed + 1, y_bytes,
                                 msg, rho, &wrong_h_witness, &wrong_h_pub);
    assert(!evaluates(*wrong_h_circuit, wrong_h_witness));

    std::printf("  PASS test_pedersen_c_opening\n");
}

void test_pedersen_s_opening(void) {
    auto circuit = build_pedersen_opening_circuit();
    assert(circuit != nullptr);

    uint8_t msg[32] = {0};
    uint8_t rho[32] = {0};
    msg[0] = 0x53;  /* S profile fixture, standing in for H_S(...). */
    msg[31] = 0x21;
    rho[0] = 0x72;
    rho[31] = 0x34;
    uint8_t compressed[33];
    uint8_t y_bytes[32];
    longfellow_pedersen_commit(msg, rho, compressed, y_bytes);

    proofs::Dense<Field> witness(1, circuit->ninputs);
    proofs::Dense<Field> pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], compressed + 1, y_bytes,
                                 msg, rho, &witness, &pub);
    assert(evaluates(*circuit, witness));

    uint8_t wrong_sigma0[32];
    memcpy(wrong_sigma0, msg, sizeof(wrong_sigma0));
    wrong_sigma0[1] ^= 0x01;
    proofs::Dense<Field> bad_sigma0_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_sigma0_pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], compressed + 1, y_bytes,
                                 wrong_sigma0, rho, &bad_sigma0_witness,
                                 &bad_sigma0_pub);
    assert(!evaluates(*circuit, bad_sigma0_witness));

    uint8_t wrong_rho[32];
    memcpy(wrong_rho, rho, sizeof(wrong_rho));
    wrong_rho[31] ^= 0x01;
    proofs::Dense<Field> bad_rho_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_rho_pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], compressed + 1, y_bytes,
                                 msg, wrong_rho, &bad_rho_witness,
                                 &bad_rho_pub);
    assert(!evaluates(*circuit, bad_rho_witness));

    uint8_t bad_s_x[32];
    memcpy(bad_s_x, compressed + 1, sizeof(bad_s_x));
    bad_s_x[30] ^= 0x01;
    proofs::Dense<Field> bad_s_witness(1, circuit->ninputs);
    proofs::Dense<Field> bad_s_pub(1, circuit->npub_in);
    fill_pedersen_opening_inputs(compressed[0], bad_s_x, y_bytes,
                                 msg, rho, &bad_s_witness, &bad_s_pub);
    assert(!evaluates(*circuit, bad_s_witness));

    std::printf("  PASS test_pedersen_s_opening\n");
}

}  // namespace

int main(void) {
    std::printf("lib/niwi RPBSch commitment circuit tests:\n");
    test_compressed_point_prefix_and_lift();
    test_pedersen_c_opening();
    test_pedersen_s_opening();
    std::printf("All RPBSch commitment circuit tests passed.\n");
    return 0;
}
