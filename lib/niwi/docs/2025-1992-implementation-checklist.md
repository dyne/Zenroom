# 2025-1992 Implementation Checklist

This checklist maps the current implementation to the paper-level components
needed before claiming production, paper-exact RPBSch.

## NIWI Core

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Relation-backed proving | `lib/niwi/src/niwi.c`, `src/lua/crypto_niwi.lua` | `make -C lib/niwi test`, `test/lua/zkcc_niwi_smoke.lua` | Implemented for BIP340 and generic P256 zkcc relations |
| Native proof body | `LIG0` / `LZK0` in `lib/niwi/src/niwi.c` | `lib/niwi/tests/test_abi.c`, `lib/niwi/tests/test_bip340_relation.cc`, `lib/niwi/tests/test_ligero_bip340.cc` | Versioned, relation-bound, carries tableau entries and explicit `NRSP` response objects. BIP340 additionally carries a checked Longfellow/Ligero `ZkProof` body in `LZK0`; generic P256 and RPBSch still use the narrower scaffold body |
| Tableau root, response, and selected opening | `LIG0` in `lib/niwi/src/niwi.c` | `test_relation_checked_prove`, `test_relation_merkle_path_for_multi_leaf_tableau`, `test_native_ligero_profile_vectors` | Native verifier recomputes the Merkle root, parses and checks `NRSP`, recomputes the response digest, verifies tableau-digest row and column evaluations over the current square-ish bounded-row profile, recomputes the dimension-bound `param_id`, derives the Fiat-Shamir opening index, checks the selected `TBL1` leaf preimage, and verifies the selected Merkle path; remaining generalization is replacing this scaffold for non-BIP340 relations with checked Longfellow/Ligero bodies |
| Relation witness tableau leaves | `TBL1` in `lib/niwi/src/niwi.c` | `test_relation_observed_uses_bound_tableau_leaves` | Production observed leaves bind relation id and public statement digest; unchecked fixtures retain legacy `TBL0` |
| Unchecked envelope isolation | `src/lua/crypto_niwi.lua`, native `niwi` module | `test/lua/niwi_regression.lua` | Production Lua rejects raw unchecked envelopes |
| Native generic zkcc evaluation | `lib/niwi/src/relations/zkcc_p256_relation.cc` | `test/lua/zkcc_niwi_smoke.lua` | Direct circuit evaluation, no Lua or legacy proof object |

## Extraction

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Gamma observation | `lib/niwi/src/npro.c` | `lib/niwi/tests/test_npro.c` | Implemented |
| Tableau-fragment recovery | `lib/niwi/src/niwi.c`, `lib/niwi/src/extract.c` | `lib/niwi/tests/test_abi.c`, `lib/niwi/tests/test_extract.c` | Implemented for current tableau-leaf profile |
| Relation revalidation after extraction | `niwi_extract` in `lib/niwi/src/niwi.c` | `test_extract_validates_recovered_relation` | Implemented |
| Full Ligero tableau extraction | `lib/niwi/src/niwi.c` | Current tests cover fragments | Remaining paper-alignment work: replace compact tableau profile with full NIWI/Ligero body extraction |

## BIP340 Relation

| Paper dependency | Current code | Tests | Status |
| --- | --- | --- | --- |
| secp256k1/BIP340 native helper path | `src/lua/crypto_schnorr_signature.lua`, `src/lua/zenroom_secp.lua` | `test/lua/bip340_vectors.lua` | Covered by official vectors |
| Native NIWI BIP340 relation | `lib/niwi/src/relations/bip340_relation.cc` | `test/lua/bip340_niwi_native_relation.lua` | Covered by official valid vectors through prove/verify/extract |
| BIP340 Longfellow/Ligero proof body | `lib/niwi/src/relations/bip340_relation.cc`, `LZK0` in `lib/niwi/src/niwi.c` | `lib/niwi/tests/test_bip340_relation.cc`, `lib/niwi/tests/test_ligero_bip340.cc` | Native BIP340 proving embeds a serialized Longfellow `ZkProof<Fp256k1Base>`; production verification rebuilds the BIP340 circuit and verifies that body |
| Rejection behavior | SECP/zkcc BIP340 tests | `test/lua/zkcc_bip340.lua` | Covers invalid official vectors including odd-y R and infinity cases |

## PBSch Cmt

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Commitment key `ck` | `lib/niwi/src/pbsch_commitment.c` | `test/lua/pedersen.lua` | Deterministic Pedersen H derivation |
| `C` and `S` opening checks | `src/lua/crypto_pbsch.lua`, `src/lua/crypto_rpbsch.lua` | `test/lua/rpbsch_niwi.lua` | Checked in Lua adapter boundary; still open inside RPBSch relation |
| Straight-line extractable Cmt | `src/lua/crypto_pbsch.lua`, `lib/niwi/src/pbsch_commitment.c`, `lib/niwi/docs/pbsch-cmt-profile.md` | `test/lua/pbsch_cmt.lua`, `test/lua/pedersen.lua` | Implemented as Pedersen-backed `CMT1` opening envelope; RPBSch remains non-paper-exact until branch/selector relations verify openings |

## RPBSch Relation

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Statement `(X, X', R, c, C, phi, ck, S)` | `src/lua/crypto_pbsch.lua`, `src/lua/crypto_rpbsch.lua` | `test/lua/rpbsch_niwi.lua`, `test/lua/pbsch_end_to_end.lua` | Encoded and mutation-tested |
| Branch 1 relation | `src/lua/crypto_rpbsch.lua`, `lib/niwi/src/relations/rpbsch_relation.cc` | `test/lua/rpbsch_niwi.lua` | Native branch relation validates statement, C/S openings, and embedded BIP340 witness |
| Branch 2 relation | `src/lua/crypto_rpbsch.lua`, `lib/niwi/src/relations/rpbsch_relation.cc` | `test/lua/rpbsch_niwi.lua` | Native branch relation validates statement, C/S openings, and two embedded BIP340 witnesses |
| Selector-composed relation | `src/lua/crypto_rpbsch.lua`, `lib/niwi/src/relations/rpbsch_relation.cc` | `test/lua/rpbsch_niwi.lua` | Implemented as a native fixed two-slot private selector relation; not a zkcc-authored selector circuit |
| C/S opening checks inside relation | `lib/niwi/src/relations/rpbsch_relation.cc` | `test/lua/rpbsch_niwi.lua` | Native relation validates C/S openings before NIWI proving/extraction succeeds |

## Claims And Limits

- Current NIWI proofs are relation-backed and versioned. Production
  verification/extraction read tableau entries from `LIG0`, and production
  observed leaves use `TBL1` to bind relation id and public statement digest
  into the extracted witness tableau. `LIG0` carries a native tableau Merkle
  root, dimension-bound `param_id`, explicit `NRSP` row/column response object,
  verifier-recomputed response digest, minimal tableau-digest row and column evaluations, Fiat-Shamir selected opening path,
  selected `TBL1` leaf preimage, and KLP22 challenge schedule binding. For
  BIP340, `LZK0` now carries a checked Longfellow/Ligero proof body with
  low-degree, dot, quadratic, requested-column, and Merkle checks. The remaining
  NIWI core generalization is adding equivalent checked Longfellow bodies for
  generic P256 and RPBSch, then retiring their local scaffold profile.
- Current extraction reconstructs the committed tableau-fragment profile,
  recomputes the accepted `NRSP` row and column evaluations over
  Gamma-recovered leaves,
  and revalidates the relation before returning success. Full paper-level
  Ligero body extraction remains open only for the broader parameterized layout
  above.
- Current PBSch Cmt is a Pedersen-backed `CMT1` profile with straight-line
  extraction from opened commitments. Final RPBSch proof claims still require
  branch/selector relations to verify `C` and `S` openings natively.
- Current RPBSch has native branch relations, statement binding, and a fixed
  two-slot private selector relation. It is still not a zkcc-authored selector
  circuit, and final paper claims remain gated by the full NIWI/Ligero proof
  body work above.
- BIP340 is the strongest covered dependency: official vectors cover the SECP
  and zkcc paths, valid official vectors run through NIWI prove/verify/extract,
  and production BIP340 proofs now verify an embedded Longfellow/Ligero proof
  body.

## Review Command Set

Run these commands before making or reviewing a paper-level claim:

Last run locally on 2026-07-09 against implementation commit `2d21d7d2`
plus this checklist documentation.

```sh
make -C lib/niwi test
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
