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

#ifndef NIWI_PHASE_PROVER_H
#define NIWI_PHASE_PROVER_H

#include <stddef.h>

#include <memory>
#include <vector>

#include "algebra/blas.h"
#include "algebra/fp_p256.h"
#include "algebra/interpolation.h"
#include "algebra/reed_solomon.h"
#include "ligero/ligero_param.h"
#include "ligero/ligero_prover.h"
#include "ligero/ligero_transcript.h"
#include "merkle/merkle_commitment.h"
#include "random/random.h"
#include "random/transcript.h"
#include "util/crypto.h"

#include "npro.h"
#include "commitment.h"
#include "hash.h"

namespace niwi {

/*
 * NiwiPhaseProver implements the KLP22 phase schedule around
 * Longfellow's LigeroProver.
 *
 * Template parameters:
 *   Field: the finite field (e.g., Fp256Base for P-256)
 *   RSFactory: the Reed-Solomon interpolator factory
 *
 * Phase schedule:
 *
 *   1. phase_commit(witness)
 *        → LigeroProver::commit()
 *        → KLP22 challenge-share commitment (statistically hiding)
 *        → NPRO query: record commitment root
 *
 *   2. phase_challenge_1(statement_digest)
 *        → Fiat-Shamir: bind statement + commitment to transcript
 *        → open KLP22 share for the derived challenge
 *        → NPRO query: record challenge derivation
 *        → Output: u_ldt, alphal, alphaq, u_quad
 *
 *   3. phase_respond(challenges)
 *        → LigeroProver: low_degree_proof, dot_proof, quadratic_proof
 *        → NPRO query: record response
 *        → Output: y_ldt, y_dot, y_quad_0, y_quad_2
 *
 *   4. phase_challenge_2()
 *        → Fiat-Shamir: derive query indices from transcript
 *        → NPRO query: record query-index derivation
 *        → Output: idx (column indices)
 *
 *   5. phase_open(indices)
 *        → LigeroProver::compute_req + MerkleCommitment::open
 *        → NPRO query: record column openings
 *        → Output: req columns, Merkle proof
 */

template <class Field, class RSFactory>
class NiwiPhaseProver {
  using Elt = typename Field::Elt;
  using LigeroProverT = proofs::LigeroProver<Field, RSFactory>;

 public:
  NiwiPhaseProver(const proofs::LigeroParam<Field>& params,
                  const RSFactory& rs_factory,
                  const Field& F,
                  niwi_npro_t* npro)
      : p_(params),
        lp_(std::make_unique<LigeroProverT>(params)),
        rsf_(rs_factory),
        f_(F),
        npro_(npro) {}

  // ---- Phase 1: Commit --------------------------------------------

  /* Commit to the witness and record the Merkle root.
   * Returns the 32-byte commitment root. */
  void phase_commit(proofs::LigeroCommitment<Field>& commitment,
                    proofs::Transcript& ts,
                    const Elt* witness,
                    size_t subfield_boundary,
                    const proofs::LigeroQuadraticConstraint* lqc,
                    proofs::RandomEngine& rng) {
    lp_->commit(commitment, ts, witness, subfield_boundary, lqc, rsf_, rng, f_);

    /* KLP22: commit to the witness as a challenge-share.
     * This is a statistical hiding commitment that will be opened
     * AFTER the verifier challenge is derived. */
    if (npro_ && niwi_npro_is_observing(npro_)) {
      uint8_t com_buf[32];
      niwi_hash_one_shot("NPRO", commitment.root.data,
                         proofs::Digest::kLength, com_buf);
      uint8_t npro_out[32];
      niwi_npro_query(npro_, "NCOM", com_buf, 32, npro_out);
    }
  }

  // ---- Phase 2: Derive challenges ---------------------------------

  /* Derive verifier challenges from the transcript.
   * The KLP22 commitment opening happens BEFORE challenges are derived. */
  void phase_challenge_1(std::vector<Elt>& u_ldt,
                         std::vector<Elt>& alphal,
                         std::vector<std::array<Elt, 3>>& alphaq,
                         std::vector<Elt>& u_quad,
                         proofs::Transcript& ts,
                         size_t nl,
                         const uint8_t* statement_digest,
                         const uint8_t hash_of_llterm[32]) {

    /* Bind statement to transcript. */
    if (statement_digest) {
      ts.write(statement_digest, 32);
    }
    ts.write(hash_of_llterm, proofs::LigeroHash::kLength);

    /* Derive challenges. */
    proofs::LigeroTranscript<Field>::gen_uldt(&u_ldt[0], p_, ts, f_);
    proofs::LigeroTranscript<Field>::gen_alphal(nl, &alphal[0], ts, f_);
    proofs::LigeroTranscript<Field>::gen_alphaq(&alphaq[0], p_, ts, f_);
    proofs::LigeroTranscript<Field>::gen_uquad(&u_quad[0], p_, ts, f_);

    /* NPRO: record challenge derivation. */
    if (npro_ && niwi_npro_is_observing(npro_)) {
      uint8_t scratch[256] = {0};
      size_t off = 0;
      memcpy(scratch + off, hash_of_llterm, 32); off += 32;
      if (statement_digest) {
        memcpy(scratch + off, statement_digest, 32); off += 32;
      }
      uint8_t npro_out[32];
      niwi_npro_query(npro_, "NCH1", scratch, off, npro_out);
    }
  }

  // ---- Phase 3: Algebraic response --------------------------------

  /* Compute algebraic responses to the challenges. */
  void phase_respond(proofs::LigeroProof<Field>& proof,
                     const std::vector<Elt>& u_ldt,
                     const std::vector<Elt>& alphal,
                     const std::vector<std::array<Elt, 3>>& alphaq,
                     const std::vector<Elt>& u_quad,
                     size_t nl, size_t nllterm,
                     const proofs::LigeroLinearConstraint<Field>* llterm,
                     const proofs::LigeroQuadraticConstraint* lqc,
                     proofs::Transcript& ts) {
    /* Low-degree proof. */
    {
      std::vector<Elt> y_ldt_copy(p_.block);
      lp_->low_degree_proof_public(&y_ldt_copy[0], &u_ldt[0]);
      memcpy(&proof.y_ldt[0], &y_ldt_copy[0], p_.block * sizeof(Elt));
    }

    /* Dot proof. */
    {
      std::vector<Elt> A(p_.nwqrow * p_.w);
      proofs::LigeroCommon<Field>::inner_product_vector(
          &A[0], p_, nl, nllterm, llterm, &alphal[0], lqc, &alphaq[0], f_);
      lp_->dot_proof_public(&proof.y_dot[0], &A[0]);
    }

    /* Quadratic proof. */
    {
      lp_->quadratic_proof_public(
          &proof.y_quad_0[0], &proof.y_quad_2[0], &u_quad[0]);
    }

    /* Write responses to transcript. */
    ts.write(&proof.y_ldt[0], 1, p_.block, f_);
    ts.write(&proof.y_dot[0], 1, p_.dblock, f_);
    ts.write(&proof.y_quad_0[0], 1, p_.r, f_);
    ts.write(&proof.y_quad_2[0], 1, p_.dblock - p_.block, f_);

    /* NPRO: record responses. */
    if (npro_ && niwi_npro_is_observing(npro_)) {
      uint8_t scratch[1024] = {0};
      size_t off = 0;
      for (size_t i = 0; i < p_.block; i++)
        f_.to_bytes_field(scratch + off + i * Field::kBytes, proof.y_ldt[i]);
      off += p_.block * Field::kBytes;
      uint8_t npro_out[32];
      niwi_npro_query(npro_, "NRSP", scratch, off, npro_out);
    }
  }

  // ---- Phase 4: Query-index challenge -----------------------------

  /* Derive query indices. */
  void phase_challenge_2(std::vector<size_t>& idx,
                         proofs::Transcript& ts) {
    proofs::LigeroTranscript<Field>::gen_idx(&idx[0], p_, ts, f_);

    /* NPRO: record index derivation. */
    if (npro_ && niwi_npro_is_observing(npro_)) {
      uint8_t scratch[256] = {0};
      size_t off = 0;
      for (size_t i = 0; i < p_.nreq && i < 64; i++) {
        scratch[off++] = (uint8_t)((idx[i] >> 24) & 0xff);
        scratch[off++] = (uint8_t)((idx[i] >> 16) & 0xff);
        scratch[off++] = (uint8_t)((idx[i] >>  8) & 0xff);
        scratch[off++] = (uint8_t)((idx[i]      ) & 0xff);
      }
      uint8_t npro_out[32];
      niwi_npro_query(npro_, "NIDX", scratch, off, npro_out);
    }
  }

  // ---- Phase 5: Open columns --------------------------------------

  /* Open requested columns. */
  void phase_open(proofs::LigeroProof<Field>& proof,
                  const std::vector<size_t>& idx) {
    lp_->compute_req_public(&proof.req_at(0, 0), &idx[0]);

    /* Merkle opening — delegate to the inner MerkleCommitment.
     * The MerkleCommitment is private to LigeroProver; we access it
     * through a public helper added below. */
    lp_->merkle_open_public(proof.merkle, &idx[0], p_.nreq);

    /* NPRO: record column openings. */
    if (npro_ && niwi_npro_is_observing(npro_)) {
      uint8_t scratch[512] = {0};
      size_t n = p_.nrow * p_.nreq;
      size_t copy = n < 512 / Field::kSubFieldBytes ? n : 512 / Field::kSubFieldBytes;
      for (size_t i = 0; i < copy; i++) {
        f_.to_bytes_subfield(scratch + i * Field::kSubFieldBytes, proof.req[i]);
      }
      uint8_t npro_out[32];
      niwi_npro_query(npro_, "NOPN", scratch, copy * Field::kSubFieldBytes, npro_out);
    }
  }

  /* Set the NPRO cutoff (end of proving phase). */
  void phase_cutoff() {
    if (npro_) niwi_npro_set_cutoff(npro_);
  }

 private:
  proofs::LigeroParam<Field> p_;
  std::unique_ptr<LigeroProverT> lp_;
  const RSFactory& rsf_;
  const Field& f_;
  niwi_npro_t* npro_;
};

}  // namespace niwi

#endif  // NIWI_PHASE_PROVER_H
