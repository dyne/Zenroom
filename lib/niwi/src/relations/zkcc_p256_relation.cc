/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include "relations/zkcc_p256_relation.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "algebra/convolution.h"
#include "algebra/fft.h"
#include "algebra/fp_p256.h"
#include "algebra/fp2.h"
#include "algebra/reed_solomon.h"
#include "arrays/dense.h"
#include "ec/p256.h"
#include "proto/circuit.h"
#include "random/random.h"
#include "random/transcript.h"
#include "sumcheck/circuit.h"
#include "util/readbuffer.h"
#include "zk/zk_proof.h"
#include "zk/zk_prover.h"

namespace {

using Field = proofs::Fp256Base;
using Circuit = proofs::Circuit<Field>;

constexpr size_t kEltBytes = 32;
constexpr size_t kLigeroRate = 4;
constexpr size_t kLigeroNreq = 128;

static constexpr char kRootX[] =
    "112649224146410281873500457609690258373018840430489408729223714171582664"
    "680802";
static constexpr char kRootY[] =
    "84087994358540907695740461427818660560182168997182378749313018254450460212"
    "908";

class ZeroRandomEngine : public proofs::RandomEngine {
 public:
  void bytes(uint8_t *buf, size_t n) override { memset(buf, 0, n); }
};

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
  using Fp2 = proofs::Fp2<Field>;
  using FFT = proofs::FFTExtConvolutionFactory<Field, Fp2>;
  using RS = proofs::ReedSolomonFactory<Field, FFT>;

  Fp2 field2(field);
  auto omega = field2.of_string(kRootX, kRootY);
  FFT fft(field, field2, omega, 1ull << 31);
  RS rsf(fft, field);

  /* This is native and avoids the Lua zkcc.prove_circuit gate.  It still uses
   * Longfellow's prover path as the temporary relation-satisfaction oracle.
   * The next production hardening step is a direct Circuit evaluator that
   * checks constraints without constructing a legacy proof object. */
  proofs::ZkProof<Field> zk(circuit, kLigeroRate, kLigeroNreq);
  proofs::ZkProver<Field, RS> prover(circuit, field, rsf);
  uint8_t seed[32] = {0};
  proofs::Transcript transcript(seed, sizeof(seed), /*version=*/4);
  ZeroRandomEngine rng;
  prover.commit(zk, witness, transcript, rng);
  return prover.prove(zk, witness, transcript);
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
