// Copyright 2025 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_LIGERO_LIGERO_TRANSCRIPT_H_
#define PRIVACY_PROOFS_ZK_LIB_LIGERO_LIGERO_TRANSCRIPT_H_

#include <stddef.h>

#include <array>

#include "ligero/ligero_param.h"
#include "random/transcript.h"

namespace proofs {
template <class Field>
class LigeroTranscript {
 public:
  using Elt = typename Field::Elt;

  static void write_commitment(const LigeroCommitment<Field>& commitment,
                               Transcript& ts) {
    ts.write(commitment.root.data, commitment.root.kLength);
  }

  static void gen_uldt(Elt u[/*nwqrow*/], const LigeroParam<Field>& p,
                       Transcript& ts, const Field& F) {
    ts.elt(u, p.nwqrow, F);
  }

  static void gen_alphal(size_t nl, Elt alpha[/*nl*/], Transcript& ts,
                         const Field& F) {
    ts.elt(alpha, nl, F);
  }

  static void gen_alphaq(std::array<Elt, 3> alpha[/*nq*/],
                         const LigeroParam<Field>& p, Transcript& ts,
                         const Field& F) {
    ts.elt(&alpha[0][0], 3 * p.nq, F);
  }

  static void gen_uquad(Elt u[/*nqtriples*/], const LigeroParam<Field>& p,
                        Transcript& ts, const Field& F) {
    ts.elt(u, p.nqtriples, F);
  }

  // Choose p.nreq distinct naturals in [0, p.block_enc - p.dblock)
  static void gen_idx(size_t idx[/*p.nreq*/], const LigeroParam<Field>& p,
                      Transcript& ts, const Field& F) {
    check(p.block_enc >= p.dblock, "p.block_enc >= p.dblock");
    check(p.block_enc - p.dblock >= p.nreq, "p.block_enc - p.dblock >= p.nreq");
    ts.choose(idx, p.block_enc - p.dblock, p.nreq);
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_LIGERO_LIGERO_TRANSCRIPT_H_
