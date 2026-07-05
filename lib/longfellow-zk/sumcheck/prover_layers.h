// Copyright 2026 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_SUMCHECK_PROVER_LAYERS_H_
#define PRIVACY_PROOFS_ZK_LIB_SUMCHECK_PROVER_LAYERS_H_

#include <cstddef>
#include <memory>
#include <vector>

#include "arrays/affine.h"
#include "arrays/dense.h"
#include "arrays/eqs.h"
#include "sumcheck/circuit.h"
#include "sumcheck/equad.h"
#include "sumcheck/hquad.h"
#include "sumcheck/quad.h"
#include "sumcheck/transcript_sumcheck.h"
#include "util/panic.h"

namespace proofs {

// A high level idea is partially described in chapter 4.6.7 "Leveraging Data
// Parallelism for Further Speedups" in the book "Proofs, Arguments, and
// Zero-Knowledge" by Justin Thaler.
template <class Field>
class ProverLayers {
  using Elt = typename Field::Elt;
  using Accum = typename Field::Accum;

 public:
  using inputs = std::vector<std::unique_ptr<Dense<Field>>>;

  explicit ProverLayers(const Field& f) : f_(f) {}

  // Evaluate CIRCUIT on input wires W0.  This function stores the
  // input wires of each layer L into IN->at(L), and returns the
  // final output.  This asymmetry reflects the fact that for L
  // layers there are L+1 meaningful sets of wires, and that the
  // prover needs IN while the verifier needs the final output.
  std::unique_ptr<Dense<Field>> eval_circuit(inputs* in,
                                             const Circuit<Field>* circ,
                                             std::unique_ptr<Dense<Field>> W0,
                                             const Field& F) {
    if (in == nullptr || circ == nullptr || W0 == nullptr) return nullptr;

    std::unique_ptr<Dense<Field>> finalV;
    size_t nl = circ->nl, nc = circ->nc;
    check(nl >= 1, "nl >= 1");
    check(nc >= 1, "nc >= 1");

    Dense<Field>* W = W0.get();

    in->resize(nl);
    in->at(nl - 1).swap(W0);

    // Allocate memory and evaluate layer on input W and output V
    for (size_t l = nl; l-- > 0;) {
      Dense<Field>* V;
      if (l > 0) {
        // input of layer l-1 = output of layer l
        in->at(l - 1) = std::make_unique<Dense<Field>>(nc, circ->l[l - 1].nw);
        V = in->at(l - 1).get();
      } else {
        // final output = output of layer 0
        finalV = std::make_unique<Dense<Field>>(nc, circ->nv);
        V = finalV.get();
      }

      bool ok = eval_quad(circ->l[l].quad.get(), V, W, F);
      if (!ok) {
        // Early exit in case of assertion failure.
        // In this case IN is only partially allocated.
        // To avoid ambiguities, free all memory that we may have allocated.
        for (size_t i = 0; i < nl; ++i) {
          in->at(i) = nullptr;
        }
        finalV = nullptr;

        return /*finalV=*/nullptr;
      }

      W = V;
    }

    return finalV;
  }

 protected:
  const Field& f_;

  // A struct that collects the bindings generated while proving one
  // layer, to serve as initial bindings for the next layer.
  // This protected class must be defined before the public section.
  struct bindings {
    size_t logv;
    Elt q[Proof<Field>::kMaxBindings];
    Elt g[2][Proof<Field>::kMaxBindings];
  };

  // Generate proof for circuit, as a protected member, the caller must
  // ensure that input parameters are valid.
  void prove(Proof<Field>* pr, const Proof<Field>* pad,
             const Circuit<Field>* circ, const inputs& in, ProofAux<Field>* aux,
             bindings& bnd, TranscriptSumcheck<Field>& ts, const Field& F) {
    size_t logc = circ->logc;
    corner_t nc = circ->nc;

    check(circ->logv <= Proof<Field>::kMaxBindings,
          "CIRCUIT->logv <= kMaxBindings");
    bnd.logv = circ->logv;

    // obtain the initial Q and G[0] bindings from the verifier
    ts.begin_circuit(bnd.q, bnd.g[0]);

    // Duplicate the g[0] binding.
    // In general, the prover step takes two claims G[0], G[1] on the output
    // wires and reduces them to one claim on G[0] + alpha * G[1] for random
    // alpha. However, in the first step, there is only one claim, so we
    // need to make up G[1]. The code sets G[1] = G[0] and it doesn't affect
    // soundness.
    for (size_t i = 0; i < bnd.logv; ++i) {
      bnd.g[1][i] = bnd.g[0][i];
    }

    // Unpadded claims on the two hands, initially zero and updated in
    // layer()
    Elt WC[2] = {F.zero(), F.zero()};

    for (size_t ly = 0; ly < circ->nl; ++ly) {
      auto clr = &circ->l.at(ly);
      Elt alpha, beta;
      ts.begin_layer(alpha, beta, ly);
      Eqs<Field> EQ(logc, nc, bnd.q, F);
      auto HQUAD =
          clr->quad->bind_g(bnd.logv, bnd.g[0], bnd.g[1], alpha, beta, F);

      layer(pr, pad, ts, bnd, ly, logc, clr->logw, &EQ, HQUAD.get(),
            in.at(ly).get(), alpha, WC, F);

      if (aux != nullptr) {
        aux->bound_quad[ly] = HQUAD->scalar();
      }
    }
  }

 private:
  using index_t = typename EQuad<Field>::index_t;
  using CPoly = typename LayerProof<Field>::CPoly;
  using WPoly = typename LayerProof<Field>::WPoly;

  /*
  Engage in single-layer sumcheck on

          EQ[c] QUAD[r,l] W[r,c] W[l,c]

  Bind c to C, r to R, and l to L (in that order).  Store claims
  W[R,C] and W[L,C] in the proof, and set BND to the new bindings for
  the next layer.

  logw: number of sumcheck rounds in r, l
  logc: number of sumcheck rounds in c
  */
  void layer(Proof<Field>* pr, const Proof<Field>* pad,
             TranscriptSumcheck<Field>& ts, bindings& bnd, size_t layer,
             size_t logc, size_t logw, Eqs<Field>* EQ, HQuad<Field>* HQUAD,
             Dense<Field>* W, const Elt& alpha, Elt WC[2], const Field& F) {
    check(EQ->n() == W->n0_, "EQ->n() == W->n0_");

    check(logw <= Proof<Field>::kMaxBindings, "logw <= kMaxBindings");
    check(logc <= Proof<Field>::kMaxBindings, "logc <= kMaxBindings");
    bnd.logv = logw;

    // Reconstruct the sum from the claims of the previous
    // layer.
    Elt sum = F.addf(WC[0], F.mulf(alpha, WC[1]));

    // Now  SUM = \sum_{c,l,r} EQ[c] Q[l,r] W[l,c] W[r,c]
    //
    // Bind the C variables
    for (size_t round = 0; round < logc; ++round) {
      CPoly evals = evaluations_c(EQ, W, HQUAD, sum, F);

      Elt rnd = round_c(pr, pad, ts, layer, round, evals, F);
      bnd.q[round] = rnd;

      // bind the C variable in both EQ and W
      EQ->bind(rnd, F);
      W->bind(rnd, F);
      sum = evals.eval_lagrange(rnd, F);
    }

    Elt eq0 = EQ->scalar();

    W->reshape(W->n1_);
    check(W->n1_ == 1, "W->n1_ == 1");

    // To save memory, we avoid cloning W. Instead, we use a single temporary
    // buffer Wtmp of size N/2 and start with both hand-pointers WH[0,1]
    // pointing to W. In the first round of the loop, hand 0 is bound
    // out-of-place from W into Wtmp, and we then update WH[0] to point to Wtmp.
    // Hand 1 is then bound in-place in W. This strategy uses 1.5N space instead
    // of 2N.
    auto Wtmp = std::make_unique<Dense<Field>>((W->n0_ + 1) / 2, 1);
    Dense<Field>* WH[2] = {W, W};

    // Now  SUM = \sum_{l,r} eq0 Q[l,r] Wl[l] Wr[r].  Bind l and
    // r in alternating "hands".
    for (size_t round = 0; round < logw; ++round) {
      for (size_t hand = 0; hand < 2; hand++) {
        // In \sum_{l,r} eq0 Q[l,r] Wl[l] Wl[r], first precompute
        // QW[l] = \sum_{r} Q[l,r] W[r] as a dense array, and then do
        // a round on  \sum_{l} eq0 QW[l] W[l].
        std::vector<Elt> QW(WH[hand]->n0_, Elt{});
        size_t ohand = 1 - hand;

        // QW[l] = \sum_{r} Q[l,r] W[r]
        for (index_t i = 0; i < HQUAD->n_; ++i) {
          const corner_t p0(HQUAD->hc_[i].h[hand]);
          const corner_t p1(HQUAD->hc_[i].h[ohand]);
          F.add(QW[p0], F.mulf(HQUAD->vc_[i].v, WH[ohand]->v_[p1]));
        }

        // Compute the binding of \sum_{l} eq0 QW[l] W[l] as
        // a quadratic polynomial.
        WPoly evals = evaluations(WH[hand]->n0_, eq0, QW.data(),
                                  &WH[hand]->v_[0], sum, F);

        Elt rnd = round_h(pr, pad, ts, layer, hand, round, evals, F);
        bnd.g[hand][round] = rnd;
        sum = evals.eval_lagrange(rnd, F);

        // bind the r variable in W[hand] and QUAD
        if (round == 0 && hand == 0) {
          WH[0] = Wtmp.get();
          WH[0]->bind(rnd, *W, F);
        } else {
          WH[hand]->bind(rnd, F);
        }
        HQUAD->bind_h(rnd, hand, F);
      }
    }

    Elt hquad = HQUAD->scalar();
    WC[0] = WH[0]->scalar();
    WC[1] = WH[1]->scalar();
    Elt expected_sum = F.mulf(eq0, F.mulf(hquad, F.mulf(WC[0], WC[1])));
    check(sum == expected_sum, "reconstructed sum == eq0 * quad * wl * wr");
    end_layer(pr, pad, ts, layer, WC, F);
  }

  // Evaluate the quadratic form
  //
  //         V[g,c] = QUAD[g|r,l] W[r,c] W[l,c]
  //
  // Returns false in the case the quad is an assert0 check that fails.
  bool eval_quad(const Quad<Field>* quad, Dense<Field>* V,
                 const Dense<Field>* W, const Field& F) {
    check(V->n0_ == W->n0_, "V->n0_ == W->n0_");
    corner_t n0 = V->n0_;

    V->clear(F);
    for (const auto& ec : *quad) {
      const corner_t g(ec.g);
      const corner_t r(ec.h[0]);
      const corner_t l(ec.h[1]);
      for (corner_t c = 0; c < n0; ++c) {
        if (ec.v == F.zero()) {
          // assert that the computed W[l]W[r] is zero.
          Elt y = W->v_[n0 * l + c];
          F.mul(y, W->v_[n0 * r + c]);
          if (y != F.zero()) {
            return false;
          }
        } else {
          Elt x = ec.v;
          F.mul(x, W->v_[n0 * l + c]);
          F.mul(x, W->v_[n0 * r + c]);
          F.add(V->v_[n0 * g + c], x);
        }
      }
    }
    return true;
  }

  Elt /*R*/ round_c(Proof<Field>* pr, const Proof<Field>* pad,
                    TranscriptSumcheck<Field>& ts, size_t layer, size_t round,
                    CPoly poly, const Field& F) {
    check(round < Proof<Field>::kMaxBindings, "round < kMaxBindings");

    if (pad) {
      poly.sub(pad->l[layer].cp[round], F);
    }

    pr->l[layer].cp[round] = poly;
    return ts.round(poly);
  }

  Elt /*R*/ round_h(Proof<Field>* pr, const Proof<Field>* pad,
                    TranscriptSumcheck<Field>& ts, size_t layer, size_t hand,
                    size_t round, WPoly poly, const Field& F) {
    check(round < Proof<Field>::kMaxBindings, "round < kMaxBindings");
    if (pad) {
      poly.sub(pad->l[layer].hp[hand][round], F);
    }
    pr->l[layer].hp[hand][round] = poly;
    return ts.round(poly);
  }

  void end_layer(Proof<Field>* pr, const Proof<Field>* pad,
                 TranscriptSumcheck<Field>& ts, size_t layer, const Elt wc[2],
                 const Field& F) {
    Elt tt[2] = {wc[0], wc[1]};
    if (pad) {
      F.sub(tt[0], pad->l[layer].wc[0]);
      F.sub(tt[1], pad->l[layer].wc[1]);
    }

    pr->l[layer].wc[0] = tt[0];
    pr->l[layer].wc[1] = tt[1];

    ts.write(tt, 1, 2);
  }

  // now
  //
  //   SUM = \sum_{l,r} eq0 Q[l,r] Wl[l] Wr[r]
  //       = \sum_{l} eq0 QW[l] W[l]
  //
  // having precomputed QW[l] = \sum_r Q[l, r] Wl[l], and renaming
  // Wr to W.
  //
  // Return the quadratic polynomial p(t) that represents what SUM
  // will be after binding l to t in Q and Wl.
  //
  WPoly evaluations(size_t n, const Elt& eq0, const Elt* QW, const Elt* W,
                    const Elt& sum, const Field& F) {
    // Compute the polynomial coefficients, and multiply the coefficients.
    size_t nodd = n / 2;

    // Compute the coefficients of p(t) = a0 + a1*t + a2*t^2, but we
    // don't need to compute a1 since we reconstruct it at the end
    // from sum.
    Accum a0{}, a2{};
    for (size_t i = 0; i < nodd; i++) {
      Elt qw0 = QW[2 * i];
      Elt qw1 = QW[2 * i + 1];
      Elt w0 = W[2 * i];
      Elt w1 = W[2 * i + 1];

      F.mac(a0, qw0, w0);
      Elt dqw = F.subf(qw1, qw0);
      Elt dw = F.subf(w1, w0);
      F.mac(a2, dqw, dw);
    }
    if (2 * nodd < n) {
      size_t i = nodd;
      Elt qw0 = QW[2 * i];
      Elt w0 = W[2 * i];

      F.mac(a0, qw0, w0);
      F.mac(a2, qw0, w0);
    }

    WPoly coef;
    coef[0] = F.mulf(eq0, F.reduce(a0));
    coef[2] = F.mulf(eq0, F.reduce(a2));
    // SUM = P(0) + P(1) = 2*C0 + C1 + C2. Reconstruct C1.
    coef[1] = sum;
    F.sub(coef[1], coef[0]);
    F.sub(coef[1], coef[0]);
    F.sub(coef[1], coef[2]);

    // evaluate at the standard points
    WPoly evals{};
    for (int k = 0; k < 3; ++k) {
      evals[k] = coef.eval_monomial(F.poly_evaluation_point(k), F);
    }

    return evals;
  }

  // Now  SUM = \sum_{c,l,r} EQ[c] Q[l,r] W[l,c] W[r,c]
  //
  // Return the polynomial p(t) that represents what SUM
  // will be after binding c to t in Q and W.  Since p(t) is cubic
  // we return its values at four points.
  //
  // Compute the polynomial in the monomial basis, but since
  // we know that sum = p(0) + p(1), we can skip the computation
  // of coef[1], which we reconstruct at the end.  coef[2] would
  // work as well.
  //
  CPoly evaluations_c(const Eqs<Field>* EQ, const Dense<Field>* W,
                      const HQuad<Field>* HQUAD, const Elt& sum,
                      const Field& F) {
    Accum acc[4]{};
    for (index_t i = 0; i < HQUAD->n_; i++) {
      const corner_t r(HQUAD->hc_[i].h[0]);
      const corner_t l(HQUAD->hc_[i].h[1]);
      const Elt& vc = HQUAD->vc_[i].v;

      const Elt* wr_v = &W->v_[r * W->n0_];
      const Elt* wl_v = &W->v_[l * W->n0_];

      Accum l0{}, l2{}, l3{};

      size_t nodd = W->n0_ / 2;
      for (corner_t c = 0; c < nodd; ++c) {
        Elt eq0 = EQ->at(2 * c);
        Elt eq1 = EQ->at(2 * c + 1);
        Elt wr0 = wr_v[2 * c];
        Elt wr1 = wr_v[2 * c + 1];
        Elt wl0 = wl_v[2 * c];
        Elt wl1 = wl_v[2 * c + 1];

        Elt a0 = eq0, a1 = F.subf(eq1, eq0);
        Elt b0 = wr0, b1 = F.subf(wr1, wr0);
        Elt c0 = wl0, c1 = F.subf(wl1, wl0);

        // Letting a(t) = a0 + a1 t, and similarly for b(t) and d(t),
        // compute d0, d1, and d2 via Karatsuba convolution.
        // This is simlper than usual because a0 + a1 = eq1 and
        // b0 + b1 = wr1.
        Elt d0 = F.mulf(a0, b0);
        Elt d2 = F.mulf(a1, b1);
        Elt d1 = F.mulf(eq1, wr1);
        F.sub(d1, d0);
        F.sub(d1, d2);

        // 2x3 convolution into the accumulators, but skip the
        // [1] output.
        F.mac(l0, d0, c0);
        F.mac(l2, d1, c1);
        F.mac(l2, d2, c0);
        F.mac(l3, d2, c1);
      }

      if (2 * nodd < W->n0_) {
        size_t c = nodd;
        Elt eq0 = EQ->at(2 * c);
        Elt wr0 = wr_v[2 * c];
        Elt wl0 = wl_v[2 * c];

        Elt d0 = F.mulf(eq0, wr0);
        Elt three_wl0 = F.addf(wl0, F.addf(wl0, wl0));

        F.mac(l0, d0, wl0);
        F.mac(l2, d0, three_wl0);
        F.mac(l3, d0, F.negf(wl0));
      }

      F.mac(acc[0], F.reduce(l0), vc);
      F.mac(acc[2], F.reduce(l2), vc);
      F.mac(acc[3], F.reduce(l3), vc);
    }

    CPoly coefs;
    coefs[0] = F.reduce(acc[0]);
    coefs[2] = F.reduce(acc[2]);
    coefs[3] = F.reduce(acc[3]);
    // SUM = P(0) + P(1) = 2*C0 + C1 + C2 + C3.  Reconstruct C1.
    coefs[1] = sum;
    F.sub(coefs[1], coefs[0]);
    F.sub(coefs[1], coefs[0]);
    F.sub(coefs[1], coefs[2]);
    F.sub(coefs[1], coefs[3]);

    // evaluate at the standard points
    CPoly evals_c{};
    for (int k = 0; k < 4; ++k) {
      evals_c[k] = coefs.eval_monomial(F.poly_evaluation_point(k), F);
    }
    return evals_c;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_SUMCHECK_PROVER_LAYERS_H_
