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
| Native proof body parsing in `niwi.c` | `niwi.c` is large and contains envelope parsing, tableau verification, NPRO recovery, and relation revalidation | Future split into `proof_body.c`, `tableau.c`, `extract_native.c` with static-private helpers moved intact | Medium; large move risks regressions | `make -C lib/blindzap test`, `test_extract` |
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

## Optimization Review

Do not optimize relation/proof code until `bench-2025-1992-flow` provides a
baseline.  The likely hot paths are relation proof generation/verification,
RPBSch circuit construction, CMT3 proof generation, statement/witness encoding,
NPRO/Gamma serialization, and extraction.

| Area | Likely cost driver | Category | Benchmark row(s) needed | Notes |
| --- | --- | --- | --- | --- |
| RPBSch NIWI proof generation | Longfellow/Ligero proving over the fixed-shape RPBSch relation | `needs benchmark` | `niwi_prove_rpbsch`, `rpbsch_relation_validate`, `rpbsch_witness_encode_or_build` | Expected dominant cost. Measure before changing circuit shape. |
| RPBSch NIWI verification | Longfellow/Ligero verifier and native envelope checks | `needs benchmark` | `niwi_verify_rpbsch` | Verification may be cheaper than proving but still high enough for user-facing latency. |
| BIP340 full-challenge circuit reuse | repeated circuit construction / challenge reduction wiring | `needs benchmark` | `rpbsch_relation_validate`, `niwi_prove_rpbsch` | Existing shared full-challenge circuit should be preserved; cache only if benchmark shows construction overhead. |
| CMT3 proving for C and S | repeated Fischlin rounds, Pedersen commitments, challenge hashing | `needs benchmark` | `cmt3_prove_C`, `cmt3_prove_S`, `cmt3_verify_C`, `cmt3_verify_S` | Candidate for native batching or precomputed H point if proof generation is visible in total latency. |
| Pedersen H derivation | repeated deterministic derivation / lift | `safe now` if localized | `commitment_key_derivation`, CMT3 rows | Cache within a local call graph only; avoid global mutable state. |
| Statement parsing and validation | repeated length/tag checks in Lua and C | `not worth it` unless benchmark says otherwise | `rpbsch_statement_parse`, `rpbsch_full_statement_validate` | These checks are boundary hardening; optimize only if unexpectedly expensive. |
| NPRO/Gamma serialization | transcript allocation and linear serialization | `needs benchmark` | `npro_gamma_serialize` | Likely small compared with proof generation, but important for extraction-size reporting. |
| Extraction | tableau lookup, Merkle path checks, relation revalidation | `needs benchmark` | `niwi_extract_rpbsch`, `extracted_relation_revalidate` | Optimize only after separating extraction from relation revalidation timing. |
| Portable Ligero field fallback | double-and-add multiplication when no uint128 | `needs platform benchmark` | future musl/arm_hf CI benchmark | Correctness first; only optimize if arm_hf runtime matters. |
| `niwi_lua_bindings.c` OCTET copies | Lua/native boundary copies | `not worth it` initially | full Lua smoke outside C benchmark | Safety/ownership clarity matters more than micro-optimizing copies. |

## Optimization Candidates By Priority

1. **Measure RPBSch prove/verify first.**  If `niwi_prove_rpbsch` dominates,
   inspect circuit construction and Longfellow parameter selection before any
   serialization micro-optimization.
2. **Measure CMT3 proof generation separately.**  If C/S proofs are visible,
   consider precomputing fixed points or batching scalar operations inside a
   single native helper.
3. **Measure extraction as two phases.**  Keep `niwi_extract_rpbsch` and
   `extracted_relation_revalidate` separate so we know whether Gamma/tableau
   recovery or relation validation dominates.
4. **Do not optimize Lua fallback parsers.**  Native validation is production
   authority and parsing cost should be negligible compared with proof work.
5. **Do not remove duplicate validation for speed.**  Boundary checks are part
   of the safety model.

## Benchmark Rows Required Before Optimization Code Changes

| Benchmark row | Optimization question answered |
| --- | --- |
| `commitment_key_derivation` | Is deterministic `ck`/H derivation worth caching? |
| `cmt3_prove_C`, `cmt3_prove_S` | Is CMT3 proving a material part of total latency? |
| `cmt3_verify_C`, `cmt3_verify_S` | Is proof checking visible enough to batch or cache? |
| `rpbsch_statement_encode`, `rpbsch_statement_parse`, `rpbsch_full_statement_validate` | Are boundary parsers negligible as expected? |
| `rpbsch_witness_encode_or_build` | Does witness assembly deserve native consolidation? |
| `rpbsch_relation_validate` | Is relation validation expensive before proving? |
| `niwi_prove_rpbsch` | Main proving latency and output size. |
| `niwi_verify_rpbsch` | Main verifier latency. |
| `npro_gamma_serialize` | Gamma size and serialization cost. |
| `niwi_extract_rpbsch` | Extraction latency and output size. |
| `extracted_relation_revalidate` | Cost of safety revalidation after extraction. |

## Current Benchmark Gaps

`bench-2025-1992-flow` intentionally measures the deterministic public
CMT3/RPB2 boundary. The following rows remain unmeasured rather than using
synthetic inputs: a valid measurement needs the existing C++ RPBSch relation
witness, Longfellow/Ligero proof body, and observed Gamma fixture. Rebuilding
that fixture in the C boundary benchmark would be a larger fixture rewrite.

| Benchmark row | Status | Reason |
| --- | --- | --- |
| `rpbsch_witness_encode_or_build` | not yet measured | The target has no canonical RPBSch private witness fixture. |
| `rpbsch_relation_validate` | not yet measured | Requires a valid relation statement/witness pair, not only `RPB2`. |
| `niwi_prove_rpbsch` | not yet measured | Requires the relation-backed Longfellow/Ligero proving fixture. |
| `niwi_verify_rpbsch` | not yet measured | Requires a generated RPBSch `NIWI` proof with its checked `LZK0` body. |
| `npro_gamma_serialize` | not yet measured | Requires the observed proving fixture that supplies Gamma. |
| `niwi_extract_rpbsch` | not yet measured | Requires a valid RPBSch proof and matching observed Gamma. |
| `extracted_relation_revalidate` | not yet measured | Is internal to successful RPBSch extraction and cannot be separated without a new hook. |

## Pedersen H Caching Decision

No local Pedersen-H derivation cache is added at this stage. The current
`commitment_key` benchmark row is below the clock resolution (`0.002 us` per
iteration in the latest clean run), while CMT3 proving and verification dominate
the measured boundary. Adding cache state without a measurable benefit would
increase ownership and lifetime complexity without improving the paper flow.
