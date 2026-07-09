/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/zkcc_p256_relation.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "algebra/fp_p256.h"
#include "arrays/dense.h"
#include "ec/p256.h"
#include "proto/circuit.h"
#include "sumcheck/circuit.h"
#include "sumcheck/prover_layers.h"
#include "util/readbuffer.h"

namespace {

using Field = proofs::Fp256Base;
using Circuit = proofs::Circuit<Field>;

constexpr size_t kEltBytes = 32;

bool decode_dense(const Field &field, const uint8_t *bytes, size_t len,
                  size_t expected_elts, proofs::Dense<Field> *out) {
  if (!bytes || !out) return false;
  if (len != expected_elts * kEltBytes) return false;
  for (size_t i = 0; i < expected_elts; ++i) {
    Field::N nat = Field::N::of_bytes(bytes + i * kEltBytes);
    auto elt = field.to_montgomery(nat);
    Field::N back = field.from_montgomery(elt);
    if (!(nat == back)) return false;
    out->v_[i] = elt;
  }
  return true;
}

bool load_circuit(const uint8_t *artifact, size_t artifact_len, Field *field,
                  std::unique_ptr<Circuit> *circuit) {
  if (!artifact || !field || !circuit) return false;
  proofs::ReadBuffer buf(artifact, artifact_len);
  proofs::CircuitRep<Field> rep(*field, proofs::FieldID::P256_ID);
  *circuit = rep.from_bytes(buf, false);
  return *circuit != nullptr && buf.remaining() == 0;
}

bool validate_with_native_longfellow(const Circuit &circuit,
                                     const Field &field,
                                     const proofs::Dense<Field> &witness) {
  proofs::ProverLayers<Field> evaluator(field);
  typename proofs::ProverLayers<Field>::inputs layers;
  auto outputs = evaluator.eval_circuit(&layers, &circuit, witness.clone(),
                                        field);
  if (outputs == nullptr) return false;
  for (size_t i = 0; i < outputs->n1_; ++i) {
    if (outputs->v_[i] != field.zero()) return false;
  }
  return true;
}

}  // namespace

extern "C" int niwi_zkcc_p256_relation_validate(
    const uint8_t *artifact, size_t artifact_len,
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len) {
  if (!artifact || !public_inputs || !private_inputs) return -1;

  Field field;
  std::unique_ptr<Circuit> circuit;
  if (!load_circuit(artifact, artifact_len, &field, &circuit)) return -1;
  if (circuit->ninputs == 0 || circuit->npub_in > circuit->ninputs) return -1;
  if (priv_len != circuit->ninputs * kEltBytes) return -1;
  if (pub_len != circuit->npub_in * kEltBytes) return -1;
  if (memcmp(private_inputs, public_inputs, pub_len) != 0) return -1;

  proofs::Dense<Field> witness(1, circuit->ninputs);
  proofs::Dense<Field> pub(1, circuit->npub_in);
  if (!decode_dense(field, private_inputs, priv_len, circuit->ninputs,
                    &witness)) {
    return -1;
  }
  if (!decode_dense(field, public_inputs, pub_len, circuit->npub_in, &pub)) {
    return -1;
  }
  for (size_t i = 0; i < circuit->npub_in; ++i) {
    if (witness.v_[i] != pub.v_[i]) return -1;
  }

  return validate_with_native_longfellow(*circuit, field, witness) ? 0 : -1;
}
