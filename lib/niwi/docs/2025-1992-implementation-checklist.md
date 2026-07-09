# 2025-1992 Implementation Checklist

This checklist maps the current implementation to the paper-level components
needed before claiming production, paper-exact RPBSch.

## NIWI Core

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Relation-backed proving | `lib/niwi/src/niwi.c`, `src/lua/crypto_niwi.lua` | `make -C lib/niwi test`, `test/lua/zkcc_niwi_smoke.lua` | Implemented for BIP340 and generic P256 zkcc relations |
| Native proof body | `LIG0` in `lib/niwi/src/niwi.c` | `lib/niwi/tests/test_abi.c` | Versioned, relation-bound, and carries tableau entries; still not yet a full paper NIWI/Ligero proof body |
| Tableau root and selected opening | `LIG0` in `lib/niwi/src/niwi.c` | `test_relation_checked_prove` | Native verifier recomputes the tableau root, Fiat-Shamir opening index, and selected opening digest; still not full Merkle path/Ligero response verification |
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
| Rejection behavior | SECP/zkcc BIP340 tests | `test/lua/zkcc_bip340.lua` | Covers invalid official vectors including odd-y R and infinity cases |

## PBSch Cmt

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Commitment key `ck` | `lib/niwi/src/pbsch_commitment.c` | `test/lua/pedersen.lua` | Deterministic Pedersen H derivation |
| `C` and `S` opening checks | `src/lua/crypto_pbsch.lua`, `src/lua/crypto_rpbsch.lua` | `test/lua/rpbsch_niwi.lua` | Checked in Lua adapter boundary |
| Straight-line extractable Cmt | `lib/niwi/docs/pbsch-cmt-profile.md` | Not implemented | Open. Current profile is binding Pedersen, not paper-exact Cmt |

## RPBSch Relation

| Paper component | Current code | Tests | Status |
| --- | --- | --- | --- |
| Statement `(X, X', R, c, C, phi, ck, S)` | `src/lua/crypto_pbsch.lua`, `src/lua/crypto_rpbsch.lua` | `test/lua/rpbsch_niwi.lua`, `test/lua/pbsch_end_to_end.lua` | Encoded and mutation-tested |
| Branch 1 relation | `src/lua/crypto_rpbsch.lua` | `test/lua/rpbsch_niwi.lua` | Prototype through BIP340 NIWI plus Lua C/S checks |
| Branch 2 relation | `src/lua/crypto_rpbsch.lua` | `test/lua/rpbsch_niwi.lua` | Prototype through BIP340 NIWI plus Lua C/S checks |
| Selector-composed relation | Not implemented | Not implemented | Open. Required before RPBSch matches paper shape |
| C/S opening checks inside relation | Lua only | `test/lua/rpbsch_niwi.lua` | Open for native/paper-exact relation |

## Claims And Limits

- Current NIWI proofs are relation-backed and versioned. Production
  verification/extraction read tableau entries from `LIG0`, and production
  observed leaves use `TBL1` to bind relation id and public statement digest
  into the extracted witness tableau. `LIG0` also carries a native tableau root
  and a Fiat-Shamir selected opening digest. The `LIG0` body is still not yet
  the full native NIWI/Ligero proof body described in the roadmap because it
  does not yet carry full Merkle paths or Ligero algebraic responses.
- Current extraction reconstructs the committed tableau-fragment profile and
  revalidates the relation before returning success. Full paper-level Ligero
  body extraction remains open.
- Current PBSch Cmt is a binding Pedersen profile. It is not the
  straight-line extractable Cmt required for final RPBSch proof claims.
- Current RPBSch has branch fixtures and statement binding, but not a
  selector-composed native relation.
- BIP340 is the strongest covered dependency: official vectors cover the SECP
  and zkcc paths, and valid official vectors now run through NIWI
  prove/verify/extract.

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
./zenroom test/lua/pedersen.lua
./zenroom test/lua/rpbsch_niwi.lua
./zenroom test/lua/pbsch_end_to_end.lua
```

Known warnings: `lib/niwi/src/pbsch_commitment.c` currently emits a
signedness warning in the local `sha256` helper and an unused-function warning.
