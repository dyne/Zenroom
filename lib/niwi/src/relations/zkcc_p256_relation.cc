/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/zkcc_p256_relation.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <vector>

#include "algebra/convolution.h"
#include "algebra/fp_p256.h"
#include "algebra/fp2.h"
#include "algebra/reed_solomon.h"
#include "arrays/dense.h"
#include "ec/p256.h"
#include "proto/circuit.h"
#include "random/secure_random_engine.h"
#include "random/transcript.h"
#include "sumcheck/circuit.h"
#include "sumcheck/prover_layers.h"
#include "util/readbuffer.h"
#include "zk/zk_proof.h"
#include "zk/zk_prover.h"
#include "zk/zk_verifier.h"

namespace {

using Field = proofs::Fp256Base;
using Circuit = proofs::Circuit<Field>;
using FieldExt = proofs::Fp2<Field>;
using ConvolutionFactory = proofs::FFTExtConvolutionFactory<Field, FieldExt>;
using RSFactory = proofs::ReedSolomonFactory<Field, ConvolutionFactory>;

constexpr size_t kEltBytes = 32;
constexpr size_t kLigeroRate = 4;
constexpr size_t kLigeroNreq = 128;
constexpr char kRootX[] =
    "112649224146410281873500457609690258373018840430489408729223714171582664"
    "680802";
constexpr char kRootY[] =
    "84087994358540907695740461427818660560182168997182378749313018254450460212"
    "908";

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

extern "C" int niwi_zkcc_p256_ligero_prove(
    const uint8_t *artifact, size_t artifact_len,
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *private_inputs, size_t priv_len,
    uint8_t **proof_out, size_t *proof_len) {
  if (!artifact || !public_inputs || !private_inputs || !proof_out ||
      !proof_len)
    return -1;
  *proof_out = nullptr;
  *proof_len = 0;

  try {
    Field field;
    std::unique_ptr<Circuit> circuit;
    if (!load_circuit(artifact, artifact_len, &field, &circuit)) return -1;
    if (circuit->ninputs == 0 || circuit->npub_in > circuit->ninputs)
      return -1;
    if (priv_len != circuit->ninputs * kEltBytes ||
        pub_len != circuit->npub_in * kEltBytes ||
        memcmp(private_inputs, public_inputs, pub_len) != 0)
      return -1;

    proofs::Dense<Field> witness(1, circuit->ninputs);
    if (!decode_dense(field, private_inputs, priv_len, circuit->ninputs,
                      &witness))
      return -1;

    FieldExt field_ext(field);
    const auto omega = field_ext.of_string(kRootX, kRootY);
    const ConvolutionFactory factory(field, field_ext, omega, 1ull << 31);
    const RSFactory rsf(factory, field);

    proofs::ZkProof<Field> zk(*circuit, kLigeroRate, kLigeroNreq);
    proofs::ZkProver<Field, RSFactory> prover(*circuit, field, rsf);

    uint8_t seed[32] = {0};
    proofs::SecureRandomEngine rng;
    rng.bytes(seed, sizeof(seed));
    proofs::Transcript tp(seed, sizeof(seed), 4);
    prover.commit(zk, witness, tp, rng);
    if (!prover.prove(zk, witness, tp)) return -1;

    std::vector<uint8_t> serialized;
    serialized.insert(serialized.end(), seed, seed + sizeof(seed));
    zk.write(serialized, field);

    uint8_t *out = static_cast<uint8_t *>(malloc(serialized.size()));
    if (!out) return -1;
    memcpy(out, serialized.data(), serialized.size());
    *proof_out = out;
    *proof_len = serialized.size();
    return 0;
  } catch (...) {
    return -1;
  }
}

extern "C" int niwi_zkcc_p256_ligero_verify(
    const uint8_t *artifact, size_t artifact_len,
    const uint8_t *public_inputs, size_t pub_len,
    const uint8_t *proof, size_t proof_len) {
  if (!artifact || !public_inputs || !proof || proof_len <= 32) return -1;

  try {
    Field field;
    std::unique_ptr<Circuit> circuit;
    if (!load_circuit(artifact, artifact_len, &field, &circuit)) return -1;
    if (circuit->ninputs == 0 || circuit->npub_in > circuit->ninputs)
      return -1;
    if (pub_len != circuit->npub_in * kEltBytes) return -1;

    proofs::Dense<Field> pub(1, circuit->npub_in);
    if (!decode_dense(field, public_inputs, pub_len, circuit->npub_in, &pub))
      return -1;

    proofs::ReadBuffer rb(proof + 32, proof_len - 32);
    proofs::ZkProof<Field> zk(*circuit, kLigeroRate, kLigeroNreq);
    if (!zk.read(rb, field) || rb.remaining() != 0) return -1;

    FieldExt field_ext(field);
    const auto omega = field_ext.of_string(kRootX, kRootY);
    const ConvolutionFactory factory(field, field_ext, omega, 1ull << 31);
    const RSFactory rsf(factory, field);

    proofs::Transcript tv(proof, 32, 4);
    proofs::ZkVerifier<Field, RSFactory> verifier(*circuit, rsf, kLigeroRate,
                                                  kLigeroNreq,
                                                  zk.param.block_enc, field);
    verifier.recv_commitment(zk, tv);
    return verifier.verify(zk, pub, tv) ? 0 : -1;
  } catch (...) {
    return -1;
  }
}
