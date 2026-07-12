# 2025-1992 Coherence Review

## Review Scope

This review checks whether the current Zenroom branch coherently implements the
algorithmic flow used by `niwi-articles/2025-1992.pdf`, *Improved
Concurrent-Secure Blind Schnorr Signatures* by Pierpaolo Della Monica and Ivan
Visconti.

The implementation/profile name for this codebase is **BlindZap**.  BlindZap is
a pronounceable implementation profile for the paper's blind Schnorr + NIWI/zap
construction.  It does **not** rename the underlying primitives or wire-format
objects: `RPBSch`, `NIWI`, `CMT3`, `LIG0`, and `LZK0` remain protocol object
names.

This document is intentionally conservative.  A component is marked paper-exact
only when it can be traced to `2025-1992.pdf` or to a secondary article in
`niwi-articles/` that the primary paper relies on for omitted algorithmic
details.

## Source Corpus

Primary source:

| File | Role |
| --- | --- |
| `niwi-articles/2025-1992.pdf` | Primary Blind Schnorr / RPBSch / NIWI flow. |

Secondary sources for details omitted or delegated by the primary paper:

| File | Topic |
| --- | --- |
| `niwi-articles/2018-228.pdf` | Non-interactive zaps of knowledge / NIWI background. |
| `niwi-articles/73.pdf` | Non-interactive zaps and NIZK techniques. |
| `niwi-articles/Fischl05b.pdf` | Online extractors and non-interactive proofs of knowledge. |
| `niwi-articles/2022-767.pdf` | KLP22 non-malleable ZK context and Ligero-derived WI claims. |
| `niwi-articles/efficient_nizk.pdf` | Groth-Sahai efficient non-interactive proof systems. |
| `niwi-articles/WImoduleFull.pdf` | Full Groth-Sahai version. |
| `niwi-articles/niwi.lua` | Local prototype/reference, reviewed only as implementation context. |

## Primary Algorithm Flow

The paper defines the RPBSch relation immediately before Figure 4.  In the PDF
text extraction, the key relation appears around lines 701--723:

- `parR := (q, G, G, Hq)`
- `stm := (X, X', R, c, C, phi, ck, S)`
- `wtn := (m, alpha, beta, rho, sigma0, sigma1, nu_u, nu_u', nu_s, varrho)`
- `R' := R + alpha*G + beta*X`
- `vk'_Sch := ((q, G, G, Hq), X')`
- `m0 := (nu_s, nu_u)` and `m1 := (nu_s, nu_u')`
- accepted if either:
  1. `P(phi, m) = 1`, `m in M`, `c = Hq(R', X, m) + beta`, and
     `C = Cmt.Com(ck, (m, alpha, beta); rho)`, or
  2. `nu_u != nu_u'`, `S = Cmt.Com(ck, (sigma0, sigma1, nu_u, nu_u', nu_s); varrho)`,
     `m0, m1 in M`, and both Schnorr verifications under `vk'_Sch` accept.

Figure 4 then specifies the PBSch protocol using `Cmt` and `Niwi` for this
relation.

| Step | Paper source | Inputs | Outputs | Security / semantic purpose | Implementation candidate |
| --- | --- | --- | --- | --- | --- |
| Schnorr/group setup | Fig. 1, RPBSch setup paragraph | security parameter, group/hash generation | `(q, G, G, Hq)`, signing keys | defines Schnorr environment and `parR` | Zenroom SECP/BIP340 helpers; `lib/blindzap/src/relations/bip340_relation.cc` |
| Commitment key setup | Fig. 4 / Cmt setup | security parameter | `ck` | public commitment key for `C` and `S` | `src/lua/crypto_pbsch.lua`; `lib/blindzap/src/pbsch_commitment.c` |
| User commitment `C` | RPBSch branch 1 | `(m, alpha, beta)`, opening `rho`, `ck` | `C` | binds message/blinding material | CMT3 helpers in `crypto_pbsch.lua` and native seeded prover |
| Extractor commitment `S` | RPBSch branch 2 | `(sigma0, sigma1, nu_u, nu_u', nu_s)`, opening `varrho`, `ck` | `S` | binds forking/extraction branch material | CMT3 helpers and native RPBSch relation |
| Public statement assembly | RPBSch definition | `X, X', R, c, C, phi, ck, S` | `stm` | fixed public relation statement | `crypto_pbsch.lua`; `pbsch_commitment.{c,h}` full statement parser |
| Witness assembly | RPBSch definition | branch-specific private values | `wtn` | private relation witness | Lua RPBSch helpers; `rpbsch_ligero_relation.cc` witness parser/filler |
| Branch 1 validation | RPBSch first disjunct | `stm`, `(m, alpha, beta, rho)` | accept/reject | prove well-formed real signing transcript | `rpbsch_relation.cc`; `rpbsch_ligero_relation.cc`; RPBSch branch circuit |
| Branch 2 validation | RPBSch second disjunct | `stm`, `(sigma0, sigma1, nu_u, nu_u', nu_s, varrho)` | accept/reject | prove extractor/forking consistency | same native RPBSch relation/circuit |
| Private OR composition | RPBSch disjunction | branch selector and branch witnesses | accept/reject | witness-indistinguishable choice of branch | fixed-shape private selector circuit in `rpbsch_ligero_relation.cc` |
| NIWI prove | Fig. 4, App. A.4 | relation parameters, statement, witness | proof | non-interactive WI argument for RPBSch | `niwi_prove*` and `niwi_rpbsch_ligero_prove` / `LZK0` body |
| NIWI verify | Fig. 4, App. A.4 | relation parameters, statement, proof | accept/reject | verifier checks relation proof | `niwi_verify*`, `niwi_rpbsch_ligero_verify` |
| NPRO/Gamma observation | App. A.4 / Def. 13 area | random-oracle queries | Gamma/transcript | straight-line extraction support | `lib/blindzap/src/npro.c` |
| Straight-line extraction | App. A.4 / Def. 13; Def. 17 for Cmt | accepted proof, NPRO transcript/Gamma | witness or failure | extract without rewinding | `niwi_extract`, `extract.c`, tableau fragments |
| Extracted relation revalidation | Argument of knowledge/extraction semantics | extracted witness, statement | accept/reject | reject malformed extraction artifacts | `niwi_extract` relation revalidation |
| Lua protocol surface | Fig. 4 integration | Zenroom heap objects | user-facing proof/signature data | production orchestration | `crypto_pbsch.lua`, `crypto_rpbsch.lua`, `crypto_niwi.lua` |

## Dependency Flow

| Dependency | Source paper | Paper role | Implementation candidate | Current review status |
| --- | --- | --- | --- | --- |
| NIWI / zap primitive | `2025-1992.pdf` App. A.4; `2018-228.pdf`; `73.pdf` | non-interactive witness indistinguishability without trusted setup | `lib/blindzap/src/niwi.c`, `LIG0`, `LZK0` | requires code trace |
| Ligero-style proof body | `2025-1992.pdf` discussion around KLP22/Ligero; `2022-767.pdf` | efficient WI proof body | Longfellow/Ligero integration in relation `.cc` files | requires code trace |
| Straight-line extraction in NPRO | `2025-1992.pdf` Def. 13 area; `Fischl05b.pdf`; Pass/Pas references | extract witness without rewinding | `npro.c`, `extract.c`, Gamma serialization | requires code trace |
| Straight-line extractable Cmt | `2025-1992.pdf` Def. 17 and commitment discussion | extract committed message/opening material | CMT3 profile in Lua/native helpers | likely profiled/substituted; requires careful non-claim text |
| Schnorr/BIP340 relation | Fig. 1 and RPBSch relation | signature verification inside relation | SECP/BIP340 native helpers and Longfellow BIP340 circuit | requires test trace |
| Predicate compiler `P(phi, m)` | RPBSch branch 1 | public message predicate | current profile-specific predicate handling | requires code trace |

## Coherence Status Legend

| Status | Meaning |
| --- | --- |
| `exact` | Directly implements the paper behavior. |
| `profiled` | Intentionally profile-specific but semantically justified and documented. |
| `substituted` | Differs from paper, backed by a named secondary source or implementation decision. |
| `gap` | Not yet paper-coherent; do not claim paper-exact implementation. |
| `non-claim` | Implemented and useful, but should not be represented as paper-exact. |

## Initial Coherence Findings

1. The code surface is already structured around the paper's decomposition:
   Cmt/PBSch helpers in Lua/native C, relation validators/circuits in C++, and
   NIWI/Ligero proof bodies in the native library.
2. The RPBSch statement tuple and witness tuple from the paper are explicit
   enough to support a direct code trace.
3. The paper delegates important details for practical NIWI/Ligero and
   straight-line extraction to prior work.  These must be reviewed against the
   secondary papers before making final claims.
4. The Cmt construction is the highest-risk coherence area.  The current branch
   has CMT2/CMT3 evolution and docs already warn about transitional profiles;
   the final review must explicitly classify what is paper-exact versus a
   production engineering profile.
5. The benchmark unit should measure the paper flow rather than isolated helper
   microbenchmarks only.  The existing `lib/blindzap/tests/test_bench.c` is useful
   but does not yet report the full Figure 4 / RPBSch path with input/output
   sizes.

## Paper-To-Code Trace Matrix

| Paper step | Implementation function(s) | Tests / fixtures | Status | Notes |
| --- | --- | --- | --- | --- |
| Schnorr/group setup and BIP340 checks | `src/lua/crypto_pbsch.lua` BIP340 helpers; `niwi_bip340_relation_validate`; `niwi_bip340_ligero_prove`; `niwi_bip340_ligero_verify` | `test/lua/zkcc_bip340.lua`; `lib/blindzap/tests/test_bip340_relation.cc`; `lib/blindzap/tests/test_ligero_bip340.cc` | `profiled` | Paper uses Schnorr over generated groups; implementation profiles this as BIP340/secp256k1 with x-only/even-y checks. |
| Commitment key `ck` | `niwi_pbsch_pedersen_h`; Lua `pbsch.commitment_key()` | `test/lua/pedersen.lua`; `test/lua/pbsch_cmt.lua` | `profiled` | Deterministic Pedersen H derivation is an implementation profile for `ck`. |
| C commitment `(m, alpha, beta)` | Lua CMT helpers in `crypto_pbsch.lua`; native `niwi_pbsch_cmt3_prove_seeded`; `niwi_pbsch_cmt3_verify` | `test/lua/pbsch_cmt.lua`; `test/lua/rpbsch_cmt3_smoke.lua` | `profiled` | Current CMT3 is the production profile; paper-exact straight-line Cmt claim remains under review. |
| S commitment `(sigma0, sigma1, nu_u, nu_u', nu_s)` | same CMT3 native/Lua helpers plus RPBSch full statement envelope | `test/lua/rpbsch_cmt3_smoke.lua`; RPBSch relation tests | `profiled` | Native relation verifies C/S openings in checked LZK body. |
| Public statement `(X, X', R, c, C, phi, ck, S)` | `niwi_rpbsch_parse_full_statement`; `niwi_rpbsch_validate_full_statement`; Lua `pbsch.parse_full_statement`; `pbsch.validate_full_statement` | `test/lua/rpbsch_cmt3_smoke.lua`; `test/lua/rpbsch_niwi.lua` | `exact/profiled` | Tuple matches the paper; byte encoding is implementation-specific and versioned. |
| Witness tuple | `rpbsch_ligero_relation.cc` parse/fill helpers; Lua `rpbsch.branch_relation_witness` | `lib/blindzap/tests/test_rpbsch_adapter.cc`; `test/lua/rpbsch_niwi.lua` | `profiled` | Witness fields map to paper tuple; circuit layout is fixed-shape implementation profile. |
| Branch 1 relation | `niwi_rpbsch_relation_validate`; RPBSch branch circuit in `rpbsch_relation_circuit.h`; `niwi_rpbsch_ligero_prove` | `lib/blindzap/tests/test_rpbsch_branch_circuit.cc`; `test/lua/rpbsch_niwi.lua` | `profiled` | Checks predicate/message, challenge equation, and C opening under the BIP340/CMT3 profile. |
| Branch 2 relation | same native RPBSch relation and branch circuit | `lib/blindzap/tests/test_rpbsch_branch_circuit.cc` | `profiled` | Checks distinct tuple messages, S opening, and two BIP340 verifications. |
| Private OR selector | `rpbsch_ligero_relation.cc`; `rpbsch_relation_circuit.h` | `lib/blindzap/tests/test_rpbsch_branch_circuit.cc` | `profiled` | Implements paper disjunction as fixed-shape private selector relation. |
| NIWI prove | `niwi_prove`; `niwi_prove_observed`; `niwi_rpbsch_ligero_prove` | `test/lua/zkcc_niwi_smoke.lua`; `test/lua/rpbsch_niwi.lua`; `lib/blindzap/tests/test_ligero_bip340.cc` | `profiled` | Production RPBSch proofs carry checked Longfellow/Ligero `LZK0` bodies. |
| NIWI verify | `niwi_verify`; `niwi_rpbsch_ligero_verify` | same proof tests plus mutation tests | `profiled` | Verifier checks relation-backed proof body, native envelope, and relation binding. |
| NPRO/Gamma observation | `niwi_prove_observed`; `niwi_npro_*` in `npro.c` | `lib/blindzap/tests/test_npro.c`; `lib/blindzap/tests/test_extract.c` | `profiled` | Implements observable random-oracle transcript used by extraction. |
| Straight-line extraction | `niwi_extract`; `niwi_envelope_extract_unchecked`; `extract.c` | `lib/blindzap/tests/test_extract.c`; adversarial Gamma tests | `profiled/non-claim` | Extracts current tableau-fragment profile and revalidates relation. Full paper-level Cmt/Ligero extraction claim remains guarded. |
| Extracted relation revalidation | `niwi_extract` plus relation validators | `lib/blindzap/tests/test_extract.c` | `profiled` | Prevents accepting Gamma fragments that do not reconstruct a valid relation witness. |
| Lua-facing PBSch/RPBSch flow | `crypto_pbsch.lua`; `crypto_rpbsch.lua`; `crypto_niwi.lua`; native Lua bindings | `test/lua/pbsch_end_to_end.lua`; `test/lua/rpbsch_cmt3_smoke.lua`; `test/lua/rpbsch_niwi.lua` | `profiled` | Production helper flow aligns to Fig. 4 but uses the BIP340/CMT3/Longfellow implementation profile. |

## Serialization And Domain-Separation Trace

| Object / tag | Implementation | Paper role | Status |
| --- | --- | --- | --- |
| `CMT3` | `crypto_pbsch.lua`; `pbsch_commitment.c` | Cmt proof/opening profile for `C` and `S` | `profiled` |
| `LIG0` | `lib/blindzap/src/niwi.c` native proof body | NIWI native envelope, tableau/response metadata | `profiled` |
| `LZK0` | `lib/blindzap/src/niwi.c`; relation `.cc` files | checked Longfellow/Ligero proof body | `profiled` |
| `NRSP` | `lib/blindzap/src/niwi.c` | native response object for extracted/checkable Ligero fragments | `profiled` |
| `TBL0` | `lib/blindzap/src/niwi.c` | legacy/unchecked tableau leaf | `non-claim` |
| `TBL1` | `lib/blindzap/src/niwi.c` | relation-bound tableau leaf | `profiled` |
| `NIWI_TAG_*` | `lib/blindzap/src/hash.h` | domain separation for protocol, statement, challenge, leaves | `profiled` |
| Full statement envelope | `pbsch_commitment.{c,h}` and Lua parser | public statement serialization | `profiled` |

## Gaps / Non-claims To Resolve

| Area | Current risk | Required review action |
| --- | --- | --- |
| Cmt straight-line extractability | Current CMT3 is a production profile, not yet documented as paper-exact | trace to Def. 17 / secondary sources and keep claims scoped |
| Full Ligero extraction | Current extraction reconstructs checked fragments/body profile | verify if sufficient for the paper-level claim or keep as profiled implementation |
| Predicate compiler | Paper allows generic `P(phi, m)` | document current supported predicate/profile |
| Naming | `lib/blindzap` describes primitive, not full implementation profile | rename implementation profile to BlindZap while preserving primitive names |

## Naming Decision

Accepted implementation/profile name: **BlindZap**.

Rationale:

- pronounceable;
- captures blind Schnorr plus NIWI/zap lineage;
- avoids overloading `NIWI`, which is only one primitive in the construction;
- keeps room for stable wire-format names (`RPBSch`, `NIWI`, `CMT3`, `LIG0`,
  `LZK0`).

Rejected or secondary candidates:

| Candidate | Reason not chosen |
| --- | --- |
| `SchnorrZap` | too tightly tied to the signature scheme rather than the full profile |
| `ZapSchnorr` | reads like a construction family rather than an implementation |
| `Niwisign` | pronounceable but hides the blind-signature context |
| `RPB-Zap` | closest to RPBSch but not comfortably pronounceable |

## Test Coverage Trace

Last focused verification: 2026-07-12 on branch `niwi-lib` after a clean native build.

Commands run:

```sh
make clean
make linux-exe linux-lib CCACHE=1
./zenroom test/lua/rpbsch_cmt3_smoke.lua
./zenroom test/lua/zkcc_niwi_smoke.lua
make -C lib/blindzap test_rpbsch_adapter test_rpbsch_branch_circuit \
  test_rpbsch_commitment_circuit test_extract test_bip340_relation
cd lib/blindzap
./test_rpbsch_adapter
./test_rpbsch_branch_circuit
./test_rpbsch_commitment_circuit
./test_extract
./test_bip340_relation
```

All commands passed.

| Paper step | Positive test | Negative / mutation test | Remaining coverage note |
| --- | --- | --- | --- |
| RPBSch statement tuple | `rpbsch_cmt3_smoke.lua`; `test_rpbsch_adapter` | statement hash/preimage matching tests | byte-level format is implementation profile |
| C/S commitment opening checks | `test_rpbsch_commitment_circuit`; `rpbsch_cmt3_smoke.lua` | bad statement/opening field mutations in branch tests | CMT3 straight-line claim still documented as profiled |
| Branch 1 relation | `test_rpbsch_branch_circuit` | negative statement fields | BIP340/profile-specific |
| Branch 2 relation | `test_rpbsch_branch_circuit` | bad slots / selector rejection | BIP340/profile-specific |
| Private OR selector | `test_rpbsch_branch_circuit` | selector rejects bad slots | fixed-shape implementation profile |
| NIWI prove/verify/extract smoke | `zkcc_niwi_smoke.lua` | extraction requires tableau / invalid gamma tests | generic zkcc smoke plus native extraction tests |
| NPRO/Gamma extraction | `test_extract` | wrong domain, missing digest, ambiguous digest, post-cutoff leaves | current tableau-fragment extraction profile |
| BIP340 relation body | `test_bip340_relation` | official invalid vector coverage in Lua zkcc tests | native tests prove/verify/extract valid vectors |

## Next Review Steps

1. Review simplification opportunities without changing protocol claims.
2. Review optimization opportunities and map each to a benchmark row.
3. Rename the implementation profile directory to `lib/blindzap`.
4. Add the full-flow benchmark and README diagrams.
