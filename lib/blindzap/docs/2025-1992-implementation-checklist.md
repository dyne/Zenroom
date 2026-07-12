# 2025-1992 Implementation Checklist

This checklist maps the current implementation to the paper-level components
needed before claiming production, paper-exact RPBSch.

## NIWI Core

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Relation-backed proving | `lib/blindzap/src/niwi.c`, `src/lua/crypto_niwi.lua` | `make -C lib/blindzap test`, `test/lua/zkcc_niwi_smoke.lua` | Implemented for BIP340 and generic P256 zkcc relations |
| Native proof body | `LIG0` / `LZK0` in `lib/blindzap/src/niwi.c` | `lib/blindzap/tests/test_abi.c`, `lib/blindzap/tests/test_zkcc_p256_relation.cc`, `lib/blindzap/tests/test_bip340_relation.cc`, `lib/blindzap/tests/test_ligero_bip340.cc`, `test/lua/rpbsch_niwi.lua` | Versioned, relation-bound, carries tableau entries and explicit `NRSP` response objects. BIP340, generic P-256 zkcc, and RPBSch production proofs carry checked Longfellow/Ligero `ZkProof` bodies in `LZK0` |
| Tableau root, response, and selected opening | `LIG0` in `lib/blindzap/src/niwi.c` | `test_relation_checked_prove`, `test_relation_merkle_path_for_multi_leaf_tableau`, `test_native_ligero_profile_vectors`, `test/lua/rpbsch_niwi.lua` | Native verifier recomputes the Merkle root, parses and checks `NRSP`, recomputes the response digest, verifies tableau-digest row and column evaluations over the current square-ish bounded-row profile, recomputes the dimension-bound `param_id`, derives the Fiat-Shamir opening index, checks the selected `TBL1` leaf preimage, and verifies the selected Merkle path. RPBSch now also requires the checked `LZK0` body |
| Relation witness tableau leaves | `TBL1` in `lib/blindzap/src/niwi.c` | `test_relation_observed_uses_bound_tableau_leaves` | Production observed leaves bind relation id and public statement digest; unchecked fixtures retain legacy `TBL0` |
| Unchecked envelope isolation | `src/lua/crypto_niwi.lua`, native `niwi` module | `test/lua/niwi_regression.lua` | Production Lua rejects raw unchecked envelopes |
| Native generic zkcc evaluation | `lib/blindzap/src/relations/zkcc_p256_relation.cc` | `test/lua/zkcc_niwi_smoke.lua`, `lib/blindzap/tests/test_zkcc_p256_relation.cc` | Direct circuit evaluation, no Lua or legacy proof object; production proofs carry checked Longfellow/Ligero `LZK0` bodies |

## Extraction

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Gamma observation | `lib/blindzap/src/npro.c` | `lib/blindzap/tests/test_npro.c` | Implemented |
| Tableau-fragment recovery | `lib/blindzap/src/niwi.c`, `lib/blindzap/src/extract.c` | `lib/blindzap/tests/test_abi.c`, `lib/blindzap/tests/test_extract.c` | Implemented for current tableau-leaf profile |
| Relation revalidation after extraction | `niwi_extract` in `lib/blindzap/src/niwi.c` | `test_extract_validates_recovered_relation` | Implemented |
| Full Ligero tableau extraction | `lib/blindzap/src/niwi.c` | Current tests cover fragments | Remaining paper-alignment work: replace compact tableau profile with full NIWI/Ligero body extraction |

## BIP340 Relation

| Paper dependency | Current code | Tests | Status |
| --- | --- | --- | --- |
| secp256k1/BIP340 native helper path | `src/lua/crypto_schnorr_signature.lua`, `src/lua/zenroom_secp.lua` | `test/lua/bip340_vectors.lua` | Covered by official vectors |
| Native NIWI BIP340 relation | `lib/blindzap/src/relations/bip340_relation.cc` | `test/lua/bip340_niwi_native_relation.lua` | Covered by official valid vectors through prove/verify/extract |
| BIP340 Longfellow/Ligero proof body | `lib/blindzap/src/relations/bip340_relation.cc`, `LZK0` in `lib/blindzap/src/niwi.c` | `lib/blindzap/tests/test_bip340_relation.cc`, `lib/blindzap/tests/test_ligero_bip340.cc` | Native BIP340 proving embeds a serialized Longfellow `ZkProof<Fp256k1Base>`; production verification rebuilds the BIP340 circuit and verifies that body |
| Rejection behavior | SECP/zkcc BIP340 tests | `test/lua/zkcc_bip340.lua` | Covers invalid official vectors including odd-y R and infinity cases |

## PBSch Cmt

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Commitment key `ck` | `lib/blindzap/src/pbsch_commitment.c` | `test/lua/pedersen.lua` | Deterministic Pedersen H derivation |
| `C` and `S` opening checks | `lib/blindzap/src/circuits/rpbsch/rpbsch_relation_circuit.h`, `lib/blindzap/src/relations/rpbsch_ligero_relation.cc`, `src/lua/crypto_pbsch.lua` | `lib/blindzap/tests/test_rpbsch_commitment_circuit.cc`, `lib/blindzap/tests/test_rpbsch_branch_circuit.cc`, `test/lua/rpbsch_niwi.lua` | Checked in the native Longfellow RPBSch relation and still checked at the Lua/native adapter boundary |
| Public Cmt opening proof surface | `src/lua/crypto_pbsch.lua`, `src/lua/crypto_rpbsch.lua`, `lib/blindzap/docs/pbsch-cmt-profile.md` | `test/lua/pbsch_cmt.lua`, `test/lua/rpbsch_niwi.lua` | `CMT2` is a versioned public Fiat-Shamir Pedersen-opening proof. Lua RPBSch fixtures now carry and verify `C` and `S` CMT2 proofs before production proof generation |
| Straight-line extractable Cmt | `src/lua/crypto_pbsch.lua`, `lib/blindzap/src/pbsch_commitment.c`, `lib/blindzap/docs/pbsch-cmt-profile.md` | `test/lua/pbsch_cmt.lua`, `test/lua/pedersen.lua`, `test/lua/rpbsch_niwi.lua` | Still open for paper-exact claims: `CMT1` is private opened-proof extraction material and `CMT2` v1 is an ordinary Fiat-Shamir opening proof, not the final Fischlin/Pas-style straight-line extractable Cmt construction |

## RPBSch Relation

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Statement `(X, X', R, c, C, phi, ck, S)` | `src/lua/crypto_pbsch.lua`, `src/lua/crypto_rpbsch.lua` | `test/lua/rpbsch_niwi.lua`, `test/lua/pbsch_end_to_end.lua` | Encoded and mutation-tested |
| Branch 1 relation | `lib/blindzap/src/circuits/rpbsch/rpbsch_relation_circuit.h`, `lib/blindzap/src/relations/rpbsch_ligero_relation.cc` | `lib/blindzap/tests/test_rpbsch_branch_circuit.cc`, `test/lua/rpbsch_niwi.lua` | Native Longfellow branch relation validates statement, C/S openings, phi, final BIP340 challenge/signature, and rejects targeted mutations |
| Branch 2 relation | `lib/blindzap/src/circuits/rpbsch/rpbsch_relation_circuit.h`, `lib/blindzap/src/relations/rpbsch_ligero_relation.cc` | `lib/blindzap/tests/test_rpbsch_branch_circuit.cc`, `test/lua/rpbsch_niwi.lua` | Native Longfellow branch relation validates statement, C/S openings, phi, tuple-message hashes, and two BIP340 challenge/signature checks |
| Selector-composed relation | `lib/blindzap/src/circuits/rpbsch/rpbsch_relation_circuit.h`, `lib/blindzap/src/relations/rpbsch_ligero_relation.cc` | `lib/blindzap/tests/test_rpbsch_branch_circuit.cc`, `test/lua/rpbsch_niwi.lua` | Implemented as a fixed-shape private OR selector: selector is private/range-checked, selected branch constraints feed the audited SHA/BIP340/Pedersen gadgets, inactive branch-specific padding is not required to satisfy the unselected branch |
| C/S opening checks inside relation | `lib/blindzap/src/circuits/rpbsch/rpbsch_relation_circuit.h`, `lib/blindzap/src/relations/rpbsch_ligero_relation.cc` | `lib/blindzap/tests/test_rpbsch_commitment_circuit.cc`, `lib/blindzap/tests/test_rpbsch_branch_circuit.cc`, `test/lua/rpbsch_niwi.lua` | Native Longfellow relation validates C/S openings before NIWI proving/extraction succeeds |

## Claims And Limits

- Current NIWI proofs are relation-backed and versioned. Production
  verification/extraction read tableau entries from `LIG0`, and production
  observed leaves use `TBL1` to bind relation id and public statement digest
  into the extracted witness tableau. `LIG0` carries a native tableau Merkle
  root, dimension-bound `param_id`, explicit `NRSP` row/column response object,
  verifier-recomputed response digest, minimal tableau-digest row and column evaluations, Fiat-Shamir selected opening path,
  selected `TBL1` leaf preimage, and KLP22 challenge schedule binding. For
  BIP340 and RPBSch, `LZK0` now carries a checked Longfellow/Ligero proof body
  with low-degree, dot, quadratic, requested-column, and Merkle checks.
- Current extraction reconstructs the committed tableau-fragment profile,
  recomputes the accepted `NRSP` row and column evaluations over
  Gamma-recovered leaves,
  and revalidates the relation before returning success. Full paper-level
  Ligero body extraction remains open only for the broader parameterized layout
  above.
- Current PBSch Cmt has a Pedersen-backed historical `CMT1` private opening
  envelope, a deprecated `CMT2` public Fiat-Shamir opening proof, and the
  production `CMT3` Fischlin-style profile used by RPBSch helpers. Lua RPBSch
  production helpers require valid `C` and `S` CMT3 proofs, and the native
  RPBSch relation verifies the underlying `C` and `S` openings. The Cmt
  construction remains a profiled implementation until its straight-line
  extractability is fully traced to `2025-1992.pdf` Def. 17 and secondary
  sources.
- Current RPBSch has native branch relations, statement binding, a private
  OR selector relation, and checked `LZK0`. Final paper-exact claims remain
  gated by the coherence review in `2025-1992-coherence-review.md`.
- BIP340 is the strongest covered dependency: official vectors cover the SECP
  and zkcc paths, valid official vectors run through NIWI prove/verify/extract,
  and production BIP340 proofs now verify an embedded Longfellow/Ligero proof
  body.
- Generic P-256 zkcc proofs now also verify embedded Longfellow/Ligero proof
  bodies for compiled artifacts, using Longfellow's deterministic parameter
  search for each circuit.

## 2026-07-12 Trace Status Update

| Paper component | Current implementation status | Claim level |
| --- | --- | --- |
| RPBSch statement `(X, X', R, c, C, phi, ck, S)` | Native parser/validator and Lua fallback are present | `profiled`, tuple-aligned |
| RPBSch witness/disjunction | Native branch relation and private OR selector are present | `profiled` |
| C/S commitment checks | CMT3 production helpers and native relation checks are present | `profiled`, not yet paper-exact Cmt claim |
| NIWI proof body | `LIG0` native envelope and checked `LZK0` Longfellow body are present | `profiled` |
| NPRO/Gamma extraction | Observable query log, tableau fragments, and relation revalidation are present | `profiled` |
| BlindZap naming | Accepted for implementation/profile naming | directory rename pending |

See `2025-1992-coherence-review.md` for the detailed paper-to-code matrix.

## Review Command Set

Run these commands before making or reviewing a paper-level claim:

Last run locally on 2026-07-09 against implementation commit `2d21d7d2`
plus this checklist documentation.

```sh
make -C lib/blindzap test
make -f build/posix.mk
./zenroom test/lua/niwi_regression.lua
./zenroom test/lua/zkcc_niwi_smoke.lua
./zenroom test/lua/bip340_vectors.lua
./zenroom test/lua/zkcc_bip340.lua
./zenroom test/lua/bip340_niwi_native_relation.lua
./zenroom test/lua/pbsch_cmt.lua
./zenroom test/lua/pedersen.lua
./zenroom test/lua/rpbsch_niwi.lua
./zenroom test/lua/pbsch_end_to_end.lua
```
