// lib/niwi/ligero/niwi_ligero_exposed.h
//
// Derived class from proofs::LigeroProver that exposes private
// internals for KLP22 phase splitting.
//
// This is a copy-and-adapt strategy: we inherit from the original
// Longfellow LigeroProver and add public accessors for methods that
// are private in the original.  We do NOT modify the original file.

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
