# PBSch Cmt Profile

This document records the current PBSch commitment profile and the remaining
work before claiming paper-exact RPBSch from `niwi/2025-1992.pdf`.

## Current Profile

The current implementation uses a Pedersen-backed extractable opening profile
over secp256k1:

- `ck` is the x-only encoding of `H`, derived by
  `SHA-256("Zenroom/PBSch/PedersenH/v1" || iteration)` until lift succeeds
  with even y.
- `C = m * G + rho * H`, serialized as compressed secp256k1 point.
- `S` uses the same primitive with a different encoded message tuple.
- Lua encodes the paper tuples into 32-byte representatives before calling
  the native primitive.
- The opening envelope is `CMT1 || ck || message || randomness`.
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

## Paper Requirement

For RPBSch paper-level claims, Cmt must expose:

- canonical `ck` encoding bound into the public statement;
- canonical message and opening encodings for `C` and `S`;
- verifier checks for commitment openings inside the relation;
- a straight-line extraction mechanism matching the proof argument.

The first, second, and third items are implemented by the current native
profile. The remaining paper-level RPBSch work is the exact Cmt construction:
the Pedersen-backed `CMT1` envelope must be replaced or justified against the
paper's straight-line extractability requirement.

## Decision

Keep the Pedersen group commitment and augment it with the `CMT1`
straight-line extractable opening envelope. Do not claim paper-exact RPBSch
from this alone.

The preferred path is:

1. Keep `ck`, compressed commitment, scalar message, and scalar randomness
   encodings unchanged.
2. Use `CMT1 || ck || message || randomness` as the opened-proof extraction
   material.
3. Keep `C` and `S` opening checks inside the RPBSch relation circuits.
4. Remove the remaining RPBSch warnings only after the Cmt construction itself
   matches the paper profile and the selector relation is OR-gated rather than
   the stricter fixed two-slot v1 profile.

## Implementation Map

- Native Pedersen primitive: `lib/niwi/src/pbsch_commitment.c`
- Native primitive header: `lib/niwi/src/pbsch_commitment.h`
- Lua PBSch tuple encoding and wrappers: `src/lua/crypto_pbsch.lua`
- Current RPBSch branch fixture: `src/lua/crypto_rpbsch.lua`
- Cmt profile tests: `test/lua/pbsch_cmt.lua`
- Pedersen tests: `test/lua/pedersen.lua`
- PBSch/RPBSch smoke tests: `test/lua/pbsch_end_to_end.lua`,
  `test/lua/rpbsch_niwi.lua`
