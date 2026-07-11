# PBSch Cmt Profile

This document records the current PBSch commitment profile and the remaining
work before claiming paper-exact RPBSch from `niwi/2025-1992.pdf`.

## Current Profile

The current implementation has two Pedersen-backed profiles over secp256k1:

- `ck` is the x-only encoding of `H`, derived by
  `SHA-256("Zenroom/PBSch/PedersenH/v1" || iteration)` until lift succeeds
  with even y.
- `C = m * G + rho * H`, serialized as compressed secp256k1 point.
- `S` uses the same primitive with a different encoded message tuple.
- Lua encodes the paper tuples into 32-byte representatives before calling
  the native primitive.
- `CMT1` is the private opening envelope:
  `CMT1 || ck || message || randomness`.
- `CMT2` is a public Fiat-Shamir proof of a Pedersen opening:
  `CMT2 || ck || A || e || z_m || z_r`, where `A = a * G + b * H`,
  `e = H(ck, C, A)`, `z_m = a + e * m`, and `z_r = b + e * rho`.
- Extraction is straight-line from an opened proof: parse the `CMT1` envelope,
  verify `ck`, verify the native Pedersen opening, then return the typed
  `message` and `randomness`.
- Native code rejects non-canonical message and randomness scalars
  (`scalar >= secp256k1_order`) before committing or verifying.

This profile gives the extraction interface needed for opened PBSch
commitments while preserving the existing secp256k1 Pedersen commitment. The
native RPBSch Longfellow relation now verifies the `C` and `S` openings, but
this is still not enough to claim paper-exact RPBSch because the Cmt profile
remains the binding Pedersen profile rather than the paper's final Cmt
construction.

`CMT2` is deliberately not claimed as the final paper Cmt. It gives a public,
relation-representable opening proof and a stable serialization boundary for
the next step, but the v1 proof is the ordinary Fiat-Shamir transform of the
Pedersen-opening Sigma protocol, not the Fischlin/Pas-style straight-line
extractable transform required by the paper.

## Paper Requirement

Section 3 and Appendix A.5 of `niwi/2025-1992.pdf` require a non-interactive
straight-line extractable commitment `Cmt = (Setup, Com, Dec)`. The concrete
NPRO instantiation described there is not plain Pedersen. It is:

- a standard Pedersen commitment `c' = m * G + r * H`;
- a public proof `pi_c'` that proves knowledge of `(m, r)` opening `c'`;
- the proof is obtained from the Pedersen-opening Sigma protocol with a
  Fischlin/Pas-style transform, giving straight-line extraction from the NPRO
  transcript;
- the full commitment is `c = (c', pi_c')`;
- `Dec` checks both the Pedersen opening and acceptance of `pi_c'`.

For RPBSch paper-level claims, Cmt must therefore expose:

- canonical `ck` encoding bound into the public statement;
- canonical tuple-to-scalar encodings for `C` and `S`;
- verifier checks for commitment openings inside the RPBSch relation;
- a public, non-interactive extractable proof of opening attached to each
  commitment, or an explicitly justified equivalent to the paper's
  `(c', pi_c')` construction;
- straight-line extraction from the commitment/proof NPRO transcript, not only
  from the NIWI witness after proof extraction.

The first three items are implemented by the current native profile. The
remaining paper-level RPBSch work is the exact Cmt construction: the
Pedersen-backed `CMT1` envelope must become a new profile with a public
extractable proof of opening, or the implementation must carry a written proof
that NIWI-witness extraction is an acceptable equivalent for the paper claim.

## Decision

Keep the secp256k1 Pedersen group commitment and introduce a new versioned Cmt
profile for paper-aligned extraction. Do not mutate `CMT1`, because existing
tests and Lua helpers use it as a private opening envelope:

1. Keep `ck`, compressed commitment, scalar message, and scalar randomness
   encodings unchanged.
2. Keep `CMT1 || ck || message || randomness` as private opened-proof
   extraction material for tests and current relation witnesses.
3. Add `CMT2` as the versioned public proof surface. The current v1 body is
   `CMT2 || ck || A || e || z_m || z_r` and verifies knowledge of the opening.
   The paper-exact successor must replace or extend `pi_c_prime` with the
   Fischlin/Pas-style straight-line extractable proof, without changing `CMT1`.
4. Keep `C` and `S` opening checks inside the RPBSch relation circuits.
5. Remove the remaining RPBSch warnings only after `CMT2` exists, is verified
   where commitments are accepted, and has tests for extraction failure.

## Implementation Map

- Native Pedersen primitive: `lib/niwi/src/pbsch_commitment.c`
- Native primitive header: `lib/niwi/src/pbsch_commitment.h`
- Lua PBSch tuple encoding and wrappers: `src/lua/crypto_pbsch.lua`
- CMT2 public opening proof helpers: `src/lua/crypto_pbsch.lua`
- Current RPBSch branch fixture: `src/lua/crypto_rpbsch.lua`
- Cmt profile tests: `test/lua/pbsch_cmt.lua`
- Pedersen tests: `test/lua/pedersen.lua`
- PBSch/RPBSch smoke tests: `test/lua/pbsch_end_to_end.lua`,
  `test/lua/rpbsch_niwi.lua`
