/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#ifndef NIWI_LIGERO_EXPOSED_H
#define NIWI_LIGERO_EXPOSED_H

#include "ligero/ligero_param.h"
#include "ligero/ligero_prover.h"
#include "merkle/merkle_commitment.h"

namespace niwi {

template <class Field, class InterpolatorFactory>
class NiwiExposedProver : public proofs::LigeroProver<Field, InterpolatorFactory> {
  using super = proofs::LigeroProver<Field, InterpolatorFactory>;
  using Elt = typename Field::Elt;

 public:
  explicit NiwiExposedProver(const proofs::LigeroParam<Field>& p)
      : super(p) {}

  /* Re-expose commit via the base class. */
  using super::commit;

  /*
   * Phase accessors.
   *
   * The Ligero proof data is produced by the base class and stored
   * in a LigeroProof.  We provide per-phase wrappers that feed
   * challenges into the helper functions.
   */

  /* Derive Fiat-Shamir challenges from a transcript.
   * Returns challenges needed by the prover phases. */
  void derive_challenges(
      std::vector<Elt>& u_ldt,
      std::vector<Elt>& alphal,
      std::vector<std::array<Elt, 3>>& alphaq,
      std::vector<Elt>& u_quad,
      const proofs::LigeroParam<Field>& p,
      size_t nl,
      proofs::Transcript& ts,
      const Field& F) {
    proofs::LigeroTranscript<Field>::gen_uldt(&u_ldt[0], p, ts, F);
    proofs::LigeroTranscript<Field>::gen_alphal(nl, &alphal[0], ts, F);
    proofs::LigeroTranscript<Field>::gen_alphaq(&alphaq[0], p, ts, F);
    proofs::LigeroTranscript<Field>::gen_uquad(&u_quad[0], p, ts, F);
  }

  /* Derive query indices. */
  void derive_indices(
      std::vector<size_t>& idx,
      const proofs::LigeroParam<Field>& p,
      proofs::Transcript& ts,
      const Field& F) {
    proofs::LigeroTranscript<Field>::gen_idx(&idx[0], p, ts, F);
  }
};

}  // namespace niwi

#endif  // NIWI_LIGERO_EXPOSED_H
