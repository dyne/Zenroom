// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef PRIVACY_PROOFS_ZK_LIB_SUMCHECK_TRANSCRIPT_SUMCHECK_H_
#define PRIVACY_PROOFS_ZK_LIB_SUMCHECK_TRANSCRIPT_SUMCHECK_H_

#include <stddef.h>

#include "arrays/affine.h"
#include "arrays/dense.h"
#include "random/transcript.h"
#include "sumcheck/circuit.h"

namespace proofs {
/*
Fiat-Shamir abstraction for sumcheck protocol.
This class takes wraps a transcript object and provides the interface for
sumcheck challenge and response.
*/
template <typename Field>
class TranscriptSumcheck {
  using Elt = typename Field::Elt;
  using CPoly = typename Proof<Field>::CPoly;
  using WPoly = typename Proof<Field>::WPoly;
  static constexpr size_t kMaxBindings = Proof<Field>::kMaxBindings;

 public:
  explicit TranscriptSumcheck(Transcript& ts, const Field& F)
      : ts_(ts), f_(F) {}

  void write_input(const Dense<Field>* X) {
    // Write column by column to make it compatible with oracle.
    for (corner_t c = 0; c < X->n0_; ++c) {
      ts_.write(&X->v_[c], X->n0_, X->n1_, f_);
    }
  }

  void begin_circuit(Elt* Q, Elt* G) {
    ts_.elt(Q, kMaxBindings, f_);
    ts_.elt(G, kMaxBindings, f_);
  }

  void begin_layer(Elt& alpha, Elt& beta, size_t layer) {
    alpha = ts_.elt(f_);
    beta = ts_.elt(f_);
  }

  void write(const Elt e[/*n*/], size_t ince, size_t n) {
    ts_.write(e, ince, n, f_);
  }

  template <class Poly>
  Elt /*R*/ round(const Poly& poly) {
    write_poly(&poly);
    return ts_.elt(f_);
  }

 private:
  template <class Poly>
  void write_poly(const Poly* poly) {
    // Do not write the p(1) value to the transcript, as its value is
    // implied by the constraints, and we can omit it from the proof.
    for (size_t i = 0; i < Poly::kN; ++i) {
      if (i != 1) {
        ts_.write(poly->t_[i], f_);
      }
    }
  }
  Transcript& ts_;
  const Field& f_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_SUMCHECK_TRANSCRIPT_SUMCHECK_H_
