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
| Schnorr/group setup | Fig. 1, RPBSch setup paragraph | security parameter, group/hash generation | `(q, G, G, Hq)`, signing keys | defines Schnorr environment and `parR` | Zenroom SECP/BIP340 helpers; `lib/niwi/src/relations/bip340_relation.cc` |
| Commitment key setup | Fig. 4 / Cmt setup | security parameter | `ck` | public commitment key for `C` and `S` | `src/lua/crypto_pbsch.lua`; `lib/niwi/src/pbsch_commitment.c` |
| User commitment `C` | RPBSch branch 1 | `(m, alpha, beta)`, opening `rho`, `ck` | `C` | binds message/blinding material | CMT3 helpers in `crypto_pbsch.lua` and native seeded prover |
| Extractor commitment `S` | RPBSch branch 2 | `(sigma0, sigma1, nu_u, nu_u', nu_s)`, opening `varrho`, `ck` | `S` | binds forking/extraction branch material | CMT3 helpers and native RPBSch relation |
| Public statement assembly | RPBSch definition | `X, X', R, c, C, phi, ck, S` | `stm` | fixed public relation statement | `crypto_pbsch.lua`; `pbsch_commitment.{c,h}` full statement parser |
| Witness assembly | RPBSch definition | branch-specific private values | `wtn` | private relation witness | Lua RPBSch helpers; `rpbsch_ligero_relation.cc` witness parser/filler |
| Branch 1 validation | RPBSch first disjunct | `stm`, `(m, alpha, beta, rho)` | accept/reject | prove well-formed real signing transcript | `rpbsch_relation.cc`; `rpbsch_ligero_relation.cc`; RPBSch branch circuit |
| Branch 2 validation | RPBSch second disjunct | `stm`, `(sigma0, sigma1, nu_u, nu_u', nu_s, varrho)` | accept/reject | prove extractor/forking consistency | same native RPBSch relation/circuit |
| Private OR composition | RPBSch disjunction | branch selector and branch witnesses | accept/reject | witness-indistinguishable choice of branch | fixed-shape private selector circuit in `rpbsch_ligero_relation.cc` |
| NIWI prove | Fig. 4, App. A.4 | relation parameters, statement, witness | proof | non-interactive WI argument for RPBSch | `niwi_prove*` and `niwi_rpbsch_ligero_prove` / `LZK0` body |
| NIWI verify | Fig. 4, App. A.4 | relation parameters, statement, proof | accept/reject | verifier checks relation proof | `niwi_verify*`, `niwi_rpbsch_ligero_verify` |
| NPRO/Gamma observation | App. A.4 / Def. 13 area | random-oracle queries | Gamma/transcript | straight-line extraction support | `lib/niwi/src/npro.c` |
| Straight-line extraction | App. A.4 / Def. 13; Def. 17 for Cmt | accepted proof, NPRO transcript/Gamma | witness or failure | extract without rewinding | `niwi_extract`, `extract.c`, tableau fragments |
| Extracted relation revalidation | Argument of knowledge/extraction semantics | extracted witness, statement | accept/reject | reject malformed extraction artifacts | `niwi_extract` relation revalidation |
| Lua protocol surface | Fig. 4 integration | Zenroom heap objects | user-facing proof/signature data | production orchestration | `crypto_pbsch.lua`, `crypto_rpbsch.lua`, `crypto_niwi.lua` |

## Dependency Flow

| Dependency | Source paper | Paper role | Implementation candidate | Current review status |
| --- | --- | --- | --- | --- |
| NIWI / zap primitive | `2025-1992.pdf` App. A.4; `2018-228.pdf`; `73.pdf` | non-interactive witness indistinguishability without trusted setup | `lib/niwi/src/niwi.c`, `LIG0`, `LZK0` | requires code trace |
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
   microbenchmarks only.  The existing `lib/niwi/tests/test_bench.c` is useful
   but does not yet report the full Figure 4 / RPBSch path with input/output
   sizes.

## Gaps / Non-claims To Resolve

| Area | Current risk | Required review action |
| --- | --- | --- |
| Cmt straight-line extractability | Current CMT3 may be profile-specific rather than paper-exact | trace to Def. 17 / secondary sources and document status |
| Full Ligero extraction | Existing docs mention compact tableau/fragments | verify if current `LIG0`/`LZK0` extraction matches paper-level claim or remains profiled |
| Predicate compiler | Paper allows generic `P(phi, m)` | document current supported predicate/profile |
| Naming | `lib/niwi` describes primitive, not full implementation profile | rename implementation profile to BlindZap while preserving primitive names |

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

## Next Review Steps

1. Fill the trace matrix with exact functions, tests, and statuses.
2. Update the existing implementation checklist with paper-step statuses.
3. Run focused coherence tests.
4. Only after coherence is established, review simplification/optimization and
   add the full-flow benchmark.
