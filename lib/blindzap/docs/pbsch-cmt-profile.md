# PBSch Cmt Profile

This document records the current PBSch commitment profiles and the remaining
work for paper-exact RPBSch from `niwi/2025-1992.pdf`.

## Current Profile

The implementation keeps versioned Pedersen-backed profiles over secp256k1:

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
- `CMT3` is the paper-facing profile under implementation. It keeps the same
  compressed Pedersen point `c'`, but replaces the CMT2 Fiat-Shamir proof with
  a Fischlin05 straight-line extractable proof of knowledge for the Pedersen
  opening.
- Extraction is straight-line from an opened proof: parse the `CMT1` envelope,
  verify `ck`, verify the native Pedersen opening, then return the typed
  `message` and `randomness`.
- Native code rejects non-canonical message and randomness scalars
  (`scalar >= secp256k1_order`) before committing or verifying.
- Lua code performs secp256k1 scalar algebra only through `SECP` helpers
  (`bip340_scalar_add`, `bip340_scalar_mul`, `bip340_scalar_negate`, and
  `bip340_scalar_div`). Lua `BIG` must not be used for PBSch/RPBSch
  secp256k1 scalar arithmetic because it is not the secp256k1 field API in
  this runtime.

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

CMT2 stays available for compatibility, debugging, and regression tests. New
paper-facing PBSch/RPBSch helpers must not select it as their production Cmt
body because it lacks the Fischlin/Pas straight-line extraction argument. The
production default is CMT3 once the API can carry the public Cmt proof object.
The native Longfellow relation still proves the underlying Pedersen openings
from private witness material.

The current production boundary for RPBSch is the Lua relation-backed API. It
must validate the full public Cmt object before any native relation call by
carrying an `RPB2` statement envelope:

```
RPB2 || len(core_statement) || core_statement ||
        len(C_proof) || C_proof ||
        len(S_proof) || S_proof
```

The native 258-byte statement ABI remains `X || X' || R || c || C || phi || ck
|| S`; the envelope is the Lua-side paper object that binds the two CMT3 proof
bodies to that core statement. Direct native C APIs are low-level building
blocks, not complete RPBSch production verification. Native CMT3 verification
can be promoted from fast accept path to canonical verifier only after it has
parity against Lua-generated and native-generated CMT3 proofs, including
negative mutation tests.

## Native protocol boundary

Lua expresses the paper protocol through typed records, envelopes, and readable
protocol wiring. C enforces algebra, transcript, and proof invariants. In
production paths, native code owns challenge loops, gate/tableau loops, SECP
arithmetic, binary transcript hashing, relation evaluation, CMT3
verification/extraction, and production proof bodies. Lua may assemble and name
protocol objects, but native APIs are the authority for cryptographic truth.

## CMT3 Fischlin05 Profile

`CMT3` is the best paper-level default for PBSch/RPBSch once implemented. It
maps the concrete requirement in `niwi/2025-1992.pdf` Appendix A.5 to the
Fischlin transform in `niwi/Fischl05b.pdf` Construction 1:

- base commitment: `c' = m * G + rho * H`;
- base Sigma protocol commitment: `A_i = a_i * G + b_i * H`;
- challenge space: `ch_i` is an integer with `0 <= ch_i < 2^12`;
- response: `z_m_i = a_i + ch_i * m mod q` and
  `z_r_i = b_i + ch_i * rho mod q`;
- transcript verification:
  `z_m_i * G + z_r_i * H == A_i + ch_i * c'`;
- threshold hash domain:
  `Zenroom/PBSch/CMT3/Fischlin05/v1`;
- threshold hash input:
  `ck || c' || A_1 || ... || A_r || i || ch_i || z_m_i || z_r_i`;
- initial profile parameters: `b=9`, `t=12`, `r=10`, `S=10`;
- verifier accepts only if every transcript verifies and the sum of the ten
  9-bit threshold hash values is at most `S`.

The full CMT3 proof serialization is fixed as:

```
CMT3 || profile_byte || ck || A[10] || ch[10] || z_m[10] || z_r[10]
```

where each `A` is a 33-byte compressed secp256k1 point, each `ch` is a 2-byte
unsigned big-endian integer, and each response is a canonical 32-byte scalar.
The initial `profile_byte` is `0x01` for `b=9,t=12,r=10,S=10`. Changing those
parameters requires a new profile id.

Straight-line extraction uses the observed NPRO query transcript. For an
accepted proof, the extractor scans queries with the same
`ck || c' || A_1 || ... || A_r || i` prefix and looks for a second valid
transcript with a different challenge. From two accepting transcripts for the
same `A_i`, extraction computes:

```
m   = (z_m_i - z_m_i') / (ch_i - ch_i') mod q
rho = (z_r_i - z_r_i') / (ch_i - ch_i') mod q
```

The extracted opening is returned only if recomputing the Pedersen commitment
matches `c'`.

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
3. Keep `CMT2` as the versioned public Fiat-Shamir proof surface for
   compatibility and debugging.
4. Add `CMT3` as the paper-facing default:
   `CMT3 || profile_byte || ck || A[10] || ch[10] || z_m[10] || z_r[10]`.
   This is the concrete `pi_c_prime` body for the first Fischlin05 profile.
5. Keep `C` and `S` opening checks inside the RPBSch relation circuits.
6. Remove the remaining RPBSch Cmt warnings only after CMT3 exists, is verified
   where commitments are accepted, and has observed-query extraction tests.

## Implementation Map

- Native Pedersen primitive: `lib/blindzap/src/pbsch_commitment.c`
- Native primitive header: `lib/blindzap/src/pbsch_commitment.h`
- Lua PBSch tuple encoding and wrappers: `src/lua/crypto_pbsch.lua`
- CMT2/CMT3 public opening proof helpers: `src/lua/crypto_pbsch.lua`
- Current RPBSch branch fixture: `src/lua/crypto_rpbsch.lua`
- Cmt profile tests: `test/lua/pbsch_cmt.lua`
- Pedersen tests: `test/lua/pedersen.lua`
- PBSch/RPBSch smoke tests: `test/lua/pbsch_end_to_end.lua`,
  `test/lua/rpbsch_niwi.lua`
