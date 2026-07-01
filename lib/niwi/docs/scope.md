# lib/niwi Milestone 1 Scope

## What milestone 1 implements

A **generic NIWI backend** for existing zkcc circuits with:

- `prove_circuit_niwi` — produce a NIWI proof for a compiled circuit
- `verify_circuit_niwi` — verify a NIWI proof against circuit and public inputs
- `niwi_profile` — query supported protocol id and version
- **Straight-line extraction** (test-only) — recover witness from Gamma (NPRO query log)
- Deterministic vector-generation tools for all encodings, commitments, and proofs

The implementation follows:

- **2025-1992** Definition 12 (NIWI) and Definition 13 (straight-line extractable NIWI)
- **KLP22** challenge-share commitments and Fiat-Shamir challenge schedule
- **Pass/NPRO** leaf commitments and straight-line extractability
- **Longfellow Ligero** as the underlying proof system, adapted under lib/niwi/ligero/

## What is deferred (milestone 2+)

The following are **explicitly not part of milestone 1**:

- **PBSch** (Blind Schnorr) — the full protocol of 2025-1992 Figure 4
- **RPBSch** — the relation for PBSch
- **Outer Cmt** — the extractable commitment used by PBSch outside the NIWI proof
- **BIP-340 composition** — composing NIWI proofs with BIP-340 Schnorr signatures
- **BIP-341 / Bitcoin transaction serialization**

## Public Lua surface

Production builds expose only:

| Name                    | Role                                          |
|-------------------------|-----------------------------------------------|
| `prove_circuit_niwi`    | Prove private inputs satisfy a zkcc circuit   |
| `verify_circuit_niwi`   | Verify a NIWI proof against public statement  |
| `niwi_profile`          | Query supported protocol id and version       |

Test-only (not registered in production):

| Name                         | Role                                      |
|------------------------------|-------------------------------------------|
| `prove_with_observation_test`| Prove with Gamma collection enabled       |
| `extract_from_gamma_test`    | Extract witness from Gamma + proof        |

Gamma, KLP22 commitments, Pass leaf commitments, NPRO query construction,
challenge shares, and extractor internals are **not exposed** as production
Lua primitives. If PBSch needs Lua-level helpers later, they will be
PBSch-specific wrappers, not raw NIWI internals.

## Non-goals

- Replacing the existing `prove_circuit` / `verify_circuit` legacy path
- Refactoring lib/longfellow-zk/ligero/ in place
- A silent mode switch on existing functions
- Exposing NIWI internals as a user-facing API
