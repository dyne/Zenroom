// lib/niwi/ligero/niwi_ligero_adapt.cc
//
// Copied core logic from lib/longfellow-zk/ligero/ligero_prover.h
// and lib/longfellow-zk/zk/zk_prover.h at commit 5dff932b.
// Adapted for NIWI KLP22 phase boundaries.
// Do not edit the original Longfellow files.
//
// This adapter wraps Longfellow's Ligero prover/verifier to:
// 1. Split the monolithic prove() into KLP22 phases (commit, challenge,
//    respond, query, open).
// 2. Interpose NPRO queries between phases for extraction.
// 3. Produce NiwiProof wire format instead of LigeroProof.
//
// For milestone 1, this file serves as the design scaffold: it defines
// the phase boundaries and data flow, with thin wrappers around the
// existing Longfellow LigeroProver/LigeroVerifier classes.
//
// The actual KLP22 challenge injection (replacing Longfellow's
// transcript-derived challenges with externally-scheduled ones)
// will be completed once the challenge schedule L2 is implemented.

#include "niwi_ligero_adapt.h"

#include <cstdint>
#include <cstring>
#include <memory>
#include <vector>

/* ---- Existing Longfellow includes (read-only) ------------------------- */

// These headers come from lib/longfellow-zk/ which is on the include path.
#include "algebra/field.h"
#include "ligero/ligero_param.h"
#include "ligero/ligero_prover.h"
#include "ligero/ligero_transcript.h"
#include "ligero/ligero_verifier.h"
#include "merkle/merkle_commitment.h"
#include "random/random.h"
#include "random/transcript.h"
#include "util/crypto.h"

/* ---- NIWI internal headers -------------------------------------------- */

#include "commitment.h"
#include "encoding.h"
#include "hash.h"
#include "npro.h"

namespace niwi {
namespace {

/* ---- Phase boundary abstraction ---------------------------------------
 *
 * The KLP22 NIWI prover splits the monolithic Ligero prove() into:
 *
 *   Phase 1: Witness commitment
 *     - Layout tableau (randomize, extend)
 *     - Compute Merkle root
 *     - Commit to leaves via NPRO
 *     - Output: commitment root
 *
 *   Phase 2: Challenge derivation (Fiat-Shamir)
 *     - Bound statement + commitment to transcript
 *     - Derive challenges: u_ldt, alphal, alphaq, u_quad
 *     - KLP22: commit to prover challenge shares BEFORE challenges
 *     - Output: challenges
 *
 *   Phase 3: Algebraic response
 *     - Low-degree proof (y_ldt)
 *     - Dot proof (y_dot)
 *     - Quadratic proof (y_quad_0, y_quad_2)
 *     - Output: response polynomials
 *
 *   Phase 4: Query-index challenge
 *     - Derive query indices idx from transcript
 *     - Output: column indices
 *
 *   Phase 5: Openings
 *     - Reveal requested columns + Merkle paths
 *     - Output: req columns, Merkle proof
 *
 * The verifier replays this schedule using the proof data.
 */

/*
 * NiwiProverContext wraps Longfellow's LigeroProver and manages the
 * KLP22 phase schedule.  It uses a concrete field instantiation for
 * BLS381 (the curve used by Zenroom's zkcc backend).
 */

// For milestone 1, we define the interface and placeholder types.
// The actual template instantiation will use Longfellow's BLS381 Field.

using BLS381Field = proofs::Field;  // Will be replaced with actual field type.

}  // namespace
}  // namespace niwi
