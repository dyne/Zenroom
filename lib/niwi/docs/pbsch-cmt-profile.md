# PBSch Cmt Profile

This document records the current PBSch commitment profile and the work
needed before claiming the paper-exact Cmt from `niwi/2025-1992.pdf`.

## Current Profile

The current implementation uses a binding Pedersen profile over secp256k1:

- `ck` is the x-only encoding of `H`, derived by
  `SHA-256("Zenroom/PBSch/PedersenH/v1" || iteration)` until lift succeeds
  with even y.
- `C = m * G + rho * H`, serialized as compressed secp256k1 point.
- `S` uses the same primitive with a different encoded message tuple.
- Lua encodes the paper tuples into 32-byte representatives before calling
  the native primitive.

This profile is useful for implementation progress because openings can be
checked deterministically inside Lua/native relation adapters. It is not the
paper-exact Cmt profile because Pedersen opening verification alone does not
give the straight-line extraction interface assumed by the RPBSch proof.

## Paper Requirement

For RPBSch paper-level claims, Cmt must expose:

- canonical `ck` encoding bound into the public statement;
- canonical message and opening encodings for `C` and `S`;
- verifier checks for commitment openings inside the relation;
- a straight-line extraction mechanism matching the proof argument.

Until that mechanism is implemented, code and tests must describe this as:

> binding Pedersen profile, not paper-exact Cmt

## Decision

Keep the Pedersen profile as the transitional implementation, but do not
claim paper-exact RPBSch from it. The next production step is to augment or
replace it with the exact straight-line extractable Cmt profile required by
`2025-1992`.

The preferred path is:

1. Keep `ck`, compressed commitment, scalar message, and scalar randomness
   encodings unchanged if they satisfy the final profile.
2. Add the extraction transcript/opening material required by the paper.
3. Move `C` and `S` opening checks into the RPBSch relation circuits.
4. Update this document and remove transitional warnings only after tests
   cover commit, open, verify, extract, malformed `ck`, malformed commitment,
   invalid scalar, wrong message, wrong randomness, and missing extraction
   material.

## Implementation Map

- Native Pedersen primitive: `lib/niwi/src/pbsch_commitment.c`
- Native primitive header: `lib/niwi/src/pbsch_commitment.h`
- Lua PBSch tuple encoding and wrappers: `src/lua/crypto_pbsch.lua`
- Current RPBSch branch fixture: `src/lua/crypto_rpbsch.lua`
- Pedersen tests: `test/lua/pedersen.lua`
- PBSch/RPBSch smoke tests: `test/lua/pbsch_end_to_end.lua`,
  `test/lua/rpbsch_niwi.lua`
