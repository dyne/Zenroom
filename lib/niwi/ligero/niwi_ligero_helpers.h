// lib/niwi/ligero/niwi_ligero_helpers.h
//
// Copied private methods from lib/longfellow-zk/ligero/ligero_prover.h
// at commit 5dff932b.  Made public for NIWI phase splitting.
// Do not edit the original Longfellow file.

#ifndef NIWI_LIGERO_HELPERS_H
#define NIWI_LIGERO_HELPERS_H

#include "algebra/blas.h"
#include "algebra/interpolation.h"
#include "ligero/ligero_param.h"

namespace niwi {

/*
 * Thin wrappers that reimplement LigeroProver's private methods as
 * free functions.  These are direct copies of the original Longfellow
 * code, extracted to allow the KLP22 phase-split adapter to call them
 * independently.
 */

template <class Field, class InterpolatorFactory>
void niwi_low_degree_proof(
    typename Field::Elt y[/*block*/],
    const typename Field::Elt u_ldt[/*nwqrow*/],
    const typename Field::Elt* tableau,  // [nrow, block_enc], row-major
    const proofs::LigeroParam<Field>& p,
    const Field& F) {

  // ILDT blinding row with coefficient 1
  proofs::Blas<Field>::copy(p.block, y, 1,
                             &tableau[p.ildt * p.block_enc], 1);

  // all witness and quadratic rows with coefficient u_ldt[]
  for (size_t i = 0; i < p.nwqrow; ++i) {
    proofs::Blas<Field>::axpy(p.block, y, 1, u_ldt[i],
                               &tableau[(i + p.iw) * p.block_enc], 1, F);
  }
}

template <class Field, class InterpolatorFactory>
void niwi_dot_proof(
    typename Field::Elt y[/*dblock*/],
    const typename Field::Elt A[/*nwqrow, w*/],
    const typename Field::Elt* tableau,  // [nrow, block_enc], row-major
    const proofs::LigeroParam<Field>& p,
    const InterpolatorFactory& interpolator,
    const Field& F) {

  const auto interpA = interpolator.make(p.block, p.dblock);

  // IDOT blinding row with coefficient 1
  proofs::Blas<Field>::copy(p.dblock, y, 1,
                             &tableau[p.idot * p.block_enc], 1);

  std::vector<typename Field::Elt> Aext(p.dblock);
  for (size_t i = 0; i < p.nwqrow; ++i) {
    proofs::LigeroCommon<Field>::layout_Aext(&Aext[0], p, i, &A[0], F);
    interpA->interpolate(&Aext[0]);

    // Accumulate y += A \otimes W.
    proofs::Blas<Field>::vaxpy(p.dblock, &y[0], 1, &Aext[0], 1,
                                &tableau[(i + p.iw) * p.block_enc], 1, F);
  }
}

template <class Field, class InterpolatorFactory>
void niwi_quadratic_proof(
    typename Field::Elt y0[/*r*/],
    typename Field::Elt y2[/*dblock - block*/],
    const typename Field::Elt u_quad[/*nqtriples*/],
    const typename Field::Elt* tableau,  // [nrow, block_enc], row-major
    const proofs::LigeroParam<Field>& p,
    const Field& F) {

  std::vector<typename Field::Elt> y(p.dblock);
  std::vector<typename Field::Elt> tmp(p.dblock);

  // IQUAD blinding row with coefficient 1
  proofs::Blas<Field>::copy(p.dblock, &y[0], 1,
                             &tableau[p.iquad * p.block_enc], 1);

  size_t iqx = p.iq;
  size_t iqy = iqx + p.nqtriples;
  size_t iqz = iqy + p.nqtriples;

  for (size_t i = 0; i < p.nqtriples; ++i) {
    // y += u_quad[i] * (z[i] - x[i] * y[i])

    // tmp = z[i]
    proofs::Blas<Field>::copy(p.dblock, &tmp[0], 1,
                               &tableau[(iqz + i) * p.block_enc], 1);

    // tmp -= x[i] \otimes y[i]
    proofs::Blas<Field>::vymax(p.dblock, &tmp[0], 1,
                                &tableau[(iqx + i) * p.block_enc], 1,
                                &tableau[(iqy + i) * p.block_enc], 1, F);

    // y += u_quad[i] * tmp
    proofs::Blas<Field>::axpy(p.dblock, &y[0], 1, u_quad[i], &tmp[0], 1, F);
  }

  // sanity check: the W part of Y is zero
  bool ok = proofs::Blas<Field>::equal0(p.w, &y[p.r], 1, F);
  proofs::check(ok, "W part is nonzero");

  // extract the first and last parts
  proofs::Blas<Field>::copy(p.r, y0, 1, &y[0], 1);
  proofs::Blas<Field>::copy(p.dblock - p.block, y2, 1, &y[p.block], 1);
}

template <class Field>
void niwi_compute_req(
    typename Field::Elt* req,     // [nrow, nreq]
    const typename Field::Elt* tableau,  // [nrow, block_enc]
    const size_t idx[/*nreq*/],
    const proofs::LigeroParam<Field>& p) {

  for (size_t i = 0; i < p.nrow; ++i) {
    proofs::Blas<Field>::gather(p.nreq, &req[i * p.nreq],
                                 &tableau[i * p.block_enc + p.dblock], idx);
  }
}

}  // namespace niwi

#endif  // NIWI_LIGERO_HELPERS_H
