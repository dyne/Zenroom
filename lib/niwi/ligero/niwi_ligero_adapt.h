// Copyright 2025-2026 Dyne.org foundation.
// Adapted from lib/longfellow-zk/ligero/ligero_param.h for NIWI.
//
// Copied from lib/longfellow-zk/ligero/ligero_param.h at commit 5dff932b.
// Adapted for NIWI KLP22 phase boundaries and NiwiProof serialization.
// Do not edit the original Longfellow file.

#ifndef NIWI_LIGERO_ADAPT_H
#define NIWI_LIGERO_ADAPT_H

#include <stddef.h>
#include <stdint.h>

#include <vector>

/*
 * NIWI adaptation of Ligero: this header defines the NiwiProof format
 * that carries KLP22 commitments, openings, Merkle paths, and the
 * Ligero response data needed by the verifier.  It is separate from
 * the Longfellow LigeroProof to avoid coupling the two formats.
 *
 * The NIWI proof flow follows 2025-1992 Definition 12:
 *
 *   Prover                          Verifier
 *   ------                          --------
 *   commit(witness)      ---->
 *                         <----     challenge_1 (Fiat-Shamir)
 *   respond(algebr)      ---->
 *                         <----     challenge_2 (query indices)
 *   open(columns)        ---->
 *
 * with KLP22 challenge-share commitments occurring before challenge_1.
 */

namespace niwi {

/* Magic bytes identifying a NiwiProof: "NIWI" */
static constexpr uint8_t kNiwiMagic[4] = {'N', 'I', 'W', 'I'};

/* Protocol version. */
static constexpr uint16_t kNiwiVersionMajor = 1;
static constexpr uint16_t kNiwiVersionMinor = 0;

/* Domain tags for NIWI-specific hashing (extend hash.h tags). */
static constexpr char kNiwiTagChallenge1[4] = {'N', 'C', '0', '3'};
static constexpr char kNiwiTagChallenge2[4] = {'N', 'C', '1', '0'};

/*
 * NiwiProof wire format (all integers big-endian):
 *
 *   magic[4]              "NIWI"
 *   version[4]            u16 major, u16 minor
 *   protocol_id[4]        u32 (0 = generic NIWI)
 *   circuit_digest[32]    SHA-256 of circuit artifact
 *   statement_digest[32]  SHA-256 of public inputs
 *
 *   // KLP22 challenge-share commitments
 *   klp22_commitments[32]  KLP22 commitment to prover shares
 *   klp22_openings[64]     32 bytes message + 32 bytes randomness
 *
 *   // Ligero proof body (from Longfellow)
 *   // layout matches LigeroProof fields
 *   param_block[4]        u32 block
 *   param_dblock[4]       u32 dblock
 *   param_r[4]            u32 r
 *   param_block_enc[4]    u32 block_enc
 *   param_nrow[4]         u32 nrow
 *   param_nreq[4]         u32 nreq
 *   param_mc_pathlen[4]   u32 mc_pathlen
 *
 *   y_ldt[...]            block field elements
 *   y_dot[...]            dblock field elements
 *   y_quad_0[...]         r field elements
 *   y_quad_2[...]         dblock - block field elements
 *   req[...]              nrow * nreq field elements
 *   merkle[...]           Merkle proof (nreq paths)
 *
 *   // Merkle root (from the commitment)
 *   merkle_root[32]       SHA-256 root
 *
 *   // KLP22: challenge share openings are above in klp22_openings
 *
 * All field elements are serialized via Field::to_bytes_field (BLS381 = 48 bytes).
 * Subfield elements use Field::to_bytes_subfield (8 bytes for BLS381 subfield).
 *
 * The proof is self-identifying: verifier reads magic + version first,
 * then dispatches to the correct verification path.
 */

/* Size constants for the NIWI proof header (before variable-length fields). */
static constexpr size_t kNiwiHeaderSize = 4    /* magic */
                                          + 4  /* version */
                                          + 4  /* protocol_id */
                                          + 32 /* circuit_digest */
                                          + 32 /* statement_digest */
                                          + 32 /* klp22_commitment */
                                          + 64 /* klp22_opening */;

}  // namespace niwi

#endif  // NIWI_LIGERO_ADAPT_H
