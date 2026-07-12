# BlindZap Simplification And Optimization Review

This document is intentionally split into simplification and optimization.  A
simplification may reduce maintenance risk without improving runtime.  An
optimization may improve runtime but should be justified by the full-flow
benchmark before changing protocol code.

This review follows the coherence status in `2025-1992-coherence-review.md`:
protocol-claim changes are deferred until paper coherence is accepted.

## Simplification Review

### Boundary and validation duplication

| Area | Current complexity | Proposed simplification | Risk | Required tests |
| --- | --- | --- | --- | --- |
| RPBSch full statement parsing | Lua has `pbsch.parse_full_statement` fallback while native `niwi_rpbsch_parse_full_statement` / `niwi_rpbsch_validate_full_statement` is production authority | Keep native as authority; mark Lua fallback as compatibility/test path in comments and docs | Low if no behavior changes | `test/lua/rpbsch_cmt3_smoke.lua`, malformed envelope tests |
| C/S CMT3 validation | CMT3 size/tag checks occur in Lua statement parser, native parser, native CMT3 verifier, and relation code | Keep defense-in-depth. Potential later simplification: centralize size constants and parser error labels | Medium; duplicate checks are intentional at trust boundaries | `test/lua/rpbsch_cmt3_smoke.lua`, `test_rpbsch_commitment_circuit` |
| BIP340 normalization | Lua normalizes secrets/points and native relation validates circuit-level values again | Keep both. Lua protects API users; native protects proof boundary | Low | `test/lua/zkcc_bip340.lua`, `test_bip340_relation` |
| `niwi_lua_bindings.c` error paths | File is large and has many OCTET ownership cleanup paths | Introduce small local cleanup helpers only where repeated within a function family; avoid generic macros | Medium; ownership errors caused prior ASAN bug | API/Lua smoke tests, sanitizer CI |
| Native proof body parsing in `niwi.c` | `niwi.c` is large and contains envelope parsing, tableau verification, NPRO recovery, and relation revalidation | Future split into `proof_body.c`, `tableau.c`, `extract_native.c` with static-private helpers moved intact | Medium; large move risks regressions | `make -C lib/niwi test`, `test_extract` |
| C and S message preimage builders | Preimage builders exist in relation internals and Lua mirrors | Keep until the benchmark/review proves a single native ABI can serve Lua; do not remove Lua-readable construction yet | Medium; Lua readability helps protocol audit | `test_rpbsch_adapter`, Lua statement tests |

### Transitional and legacy formats

| Format / path | Current role | Simplification decision |
| --- | --- | --- |
| `CMT1` | private opening envelope / extraction material and historical compatibility | Keep until CMT3 extraction story is fully documented and tests no longer need it. |
| `CMT2` | deprecated Fiat-Shamir opening proof / debugging material | Keep but label as non-production. Candidate for test-only relocation after BlindZap README clarifies CMT3. |
| `CMT3` | production Fischlin-style profile for C/S | Keep and document as the only paper-facing production profile. |
| unchecked NIWI envelopes | regression/test isolation path | Keep with `_unchecked_test` naming; production Lua must reject raw unchecked envelopes. |
| `TBL0` leaves | legacy unchecked tableau leaves | Keep only if fixtures still require them; candidate for test-only docs. |
| `TBL1` leaves | relation-bound production tableau leaves | Keep. |

### Serialization and allocation simplifications

| Area | Current complexity | Proposed simplification | Risk | Required tests |
| --- | --- | --- | --- | --- |
| Repeated endian helpers | Several local encode/decode helpers exist across NIWI files | Do not merge before rename. After BlindZap rename, consider a tiny `encoding_internal.h` for internal-only helpers | Low/medium | encoding tests, envelope tests |
| Proof-size constants | Lua and C both encode CMT3 sizes | Generate no code yet. Add README table and benchmark sizes first; then consider a native constants export if drift appears | Low | CMT3 smoke, native validation |
| Manual free paths in `niwi.c` | Many failure paths free partially-built structures | Consider scoped cleanup helper structs in C only after benchmark work; current code is explicit and tested | Medium | ASAN CI, `test_extract`, NIWI smokes |
| Native/Lua statement table materialization | Lua binding converts parsed native statement into table | Keep for API usability; benchmark can reveal if it matters | Low | Lua parser/validation tests |

## Safe Simplifications To Consider First

These are behavior-preserving and should be small separate commits after the
rename and benchmark are in place:

1. Update comments in `crypto_pbsch.lua` to make `CMT3` the production path and
   `CMT1`/`CMT2` explicitly transitional/test-only.
2. Add a README table of stable byte sizes for CMT3, RPBSch statement envelope,
   `LIG0`, and `LZK0` once benchmark data exists.
3. Rename documentation/profile paths to BlindZap while preserving `niwi_*` ABI
   and protocol object names.
4. Add local helper comments around native statement validation to clarify that
   duplicate Lua/native checks are boundary hardening, not accidental drift.

## Simplifications To Defer

1. Removing `CMT1`/`CMT2` paths: defer until paper-coherence review explicitly
   says they are not required by fixtures or extraction tests.
2. Splitting `niwi.c`: worthwhile, but do only after the rename to avoid a huge
   move+refactor diff.
3. Renaming public `niwi_*` symbols: ABI-breaking; only do in a separately
   versioned API change if maintainers request it.
4. Replacing Lua-readable protocol assembly with opaque native calls: may reduce
   duplication but would harm auditability of the Zencode/Lua protocol flow.

## Optimization Review Placeholder

Optimization opportunities are documented below after benchmark row mapping.
The main rule is: do not optimize relation/proof code until the full-flow
benchmark identifies the dominant cost.
