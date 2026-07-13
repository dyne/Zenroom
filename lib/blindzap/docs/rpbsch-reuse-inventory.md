# This file is part of Zenroom (https://zenroom.dyne.org)
#
# Copyright (C) 2026 Dyne.org foundation
# designed, written and maintained by Denis Roio <jaromil@dyne.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# RPBSch Component Inventory

This document classifies every RPBSch subcomponent as **reuse**,
**adapt**, **new**, or **deferred**. It is the reference for
implementation ordering and serves as a check against accidental
modification of `lib/longfellow-zk`.

## Classification legend

| Tag       | Meaning                                              |
|-----------|------------------------------------------------------|
| **Reuse** | Use as-is from `lib/longfellow-zk`, no adaptation    |
| **Adapt** | Copy under `lib/blindzap` with provenance, no upstream changes |
| **New**   | Implement under `lib/blindzap` from scratch              |
| **Deferred** | Not in v1 profile                                |

---

## Field and curve infrastructure

| Component                     | Class     | Location                                      | Notes |
|-------------------------------|-----------|-----------------------------------------------|-------|
| `FpGeneric<W, ...>`           | **Reuse** | `lib/longfellow-zk/algebra/fp_generic.h`      | Generic field template |
| `Nat<W>`                      | **Reuse** | `lib/longfellow-zk/algebra/nat.h`             | Multi-precision nat type |
| `FpReduce`                    | **Reuse** | `lib/longfellow-zk/algebra/fp.h`              | Generic Montgomery reduction |
| `FpSecp256k1Base`             | **New**   | `lib/blindzap/src/secp256k1/secp256k1_field.*`    | secp256k1 base field instance |
| `FpSecp256k1Scalar`           | **New**   | `lib/blindzap/src/secp256k1/secp256k1_scalar.*`   | secp256k1 scalar field (mod n) |
| `EllipticCurve<F, W, kN>`     | **Reuse** | `lib/longfellow-zk/ec/elliptic_curve.h`       | Generic EC template |
| `Secp256k1` (curve instance)  | **New**   | `lib/blindzap/src/secp256k1/secp256k1_curve.*`    | secp256k1 curve instance |
| `P256` (P-256 curve)          | **Reuse** | Leave unchanged                                | Legacy zkcc continues using this |

## Proof system

| Component                       | Class     | Location                                      | Notes |
|---------------------------------|-----------|-----------------------------------------------|-------|
| `LigeroParam<F>`                | **Reuse** | `lib/longfellow-zk/ligero/ligero_param.h`     | Prover/verifier parameter layout |
| `LigeroProver<F, IF>`           | **Adapt** | `lib/blindzap/ligero/niwi_ligero_exposed.h`       | Already adapted in NIWI milestone |
| `LigeroVerifier<F, IF>`         | **Adapt** | `lib/blindzap/ligero/`                            | Already adapted |
| `LigeroTranscript<F>`           | **Adapt** | `lib/blindzap/ligero/`                            | Already adapted |
| `MerkleCommitment`, `MerkleTree`| **Adapt** | `lib/blindzap/ligero/`                            | Already adapted |
| `ZkProof<F>`                    | **Reuse** | `lib/longfellow-zk/zk/zk_common.h`            | Unified proof structure |
| `ZkProver<F, RSF>`              | **Reuse** | `lib/longfellow-zk/zk/zk_prover.h`            | Generic, templatized on Field |
| `ZkVerifier<F, RSF>`            | **Reuse** | `lib/longfellow-zk/zk/zk_verifier.h`          | Generic |
| `FFTExtConvolutionFactory<F, F2>`| **Reuse**| `lib/longfellow-zk/algebra/convolution.h`     | Generic over Field and Fp2 |
| `ReedSolomonFactory<F, FFT>`    | **Reuse** | `lib/longfellow-zk/algebra/reed_solomon.h`    | Generic |

## Circuit serialization

| Component                       | Class     | Location                                      | Notes |
|---------------------------------|-----------|-----------------------------------------------|-------|
| `FieldID::SECP_ID`              | **Reuse** | `lib/longfellow-zk/proto/circuit.h`           | Already exists (value 10) |
| `CircuitRep<F>`                 | **Reuse** | `lib/longfellow-zk/proto/circuit.h`           | Generic template |
| `Circuit<F>`                    | **Reuse** | `lib/longfellow-zk/sumcheck/circuit.h`        | Generic circuit structure |
| `Quad<F>`                       | **Reuse** | `lib/longfellow-zk/sumcheck/quad.h`           | Quadratic constraint |

## Circuit building blocks

| Component                       | Class     | Location                                      | Notes |
|---------------------------------|-----------|-----------------------------------------------|-------|
| `BitAdder`, `BitPlucker`        | **Reuse** | `lib/longfellow-zk/circuits/logic/`           | Bit-level gates |
| `memcmp`, routing helpers       | **Reuse** | `lib/longfellow-zk/circuits/logic/`           | Comparison, multiplexing |
| `Polynomial<Logic>`             | **Reuse** | `lib/longfellow-zk/circuits/logic/`           | Polynomial eval in circuits |
| `FlatSHA256Circuit`             | **Reuse** | `lib/longfellow-zk/circuits/sha/`             | SHA-256 circuit for tagged hash |
| `FlatSHA256Witness`             | **Reuse** | `lib/longfellow-zk/circuits/sha/`             | SHA-256 witness generation |

## NIWI backend

| Component                       | Class     | Location                                      | Notes |
|---------------------------------|-----------|-----------------------------------------------|-------|
| `niwi_ctx_t`                    | **Reuse** | `lib/blindzap/include/niwi.h`                     | Already built |
| `niwi_prove` / `niwi_verify`    | **Reuse** | `lib/blindzap/src/niwi.c`                         | Already built |
| `niwi_klp22_commit` / `_verify` | **Reuse** | `lib/blindzap/src/commitment.c`                   | Already built |
| `niwi_leaf_commit` / `_verify`  | **Reuse** | `lib/blindzap/src/commitment.c`                   | Already built |
| `niwi_npro_t`                   | **Reuse** | `lib/blindzap/src/npro.c`                         | Already built (test-only) |
| `niwi_prove_observed`           | **Reuse** | `lib/blindzap/src/niwi.c`                         | Already built (test-only) |
| `niwi_extract`                  | **Reuse** | `lib/blindzap/src/extract.c`                      | Already built (test-only) |

## RPBSch-specific: New components

| Component                       | Class     | Location                                      | Notes |
|---------------------------------|-----------|-----------------------------------------------|-------|
| BIP-340 verification circuit    | **New**   | `lib/blindzap/src/circuits/bip340_circuit.*`      | Standalone reusable circuit |
| BIP-340 witness generator       | **New**   | `lib/blindzap/src/circuits/bip340_witness.*`      | Witness from byte-level BIP-340 sigs |
| Pedersen commitment circuit     | **New**   | `lib/blindzap/src/circuits/pedersen_circuit.*`    | Cmt equation in-circuit |
| RPBSch branch-1 circuit         | **New**   | `lib/blindzap/src/circuits/rpbsch_circuit.*`      | Honest-user branch |
| RPBSch branch-2 circuit         | **New**   | `lib/blindzap/src/circuits/rpbsch_circuit.*`      | Trapdoor branch (same file) |
| RPBSch OR composition           | **New**   | `lib/blindzap/src/circuits/rpbsch_circuit.*`      | Private selector |
| RPBSch witness/stmt builder     | **New**   | `lib/blindzap/src/rpbsch_witness.*`               | Construct witnesses from scalars |
| RPBSch statement serializer     | **New**   | `lib/blindzap/src/rpbsch_stmt.*`                  | Byte-level statement encoding |
| PBSch protocol state machine    | **New**   | `lib/blindzap/src/pbsch.*`                        | Figure 4 protocol steps |
| PBSch Cmt (prototype)           | **New**   | `lib/blindzap/src/pbsch_commitment.*`             | Pedersen + hash opening proof |
| PBSch Lua bindings              | **New**   | `lib/blindzap/src/pbsch_lua_bindings.c`           | Thin Lua wrappers |

## RPBSch-specific: Deferred components

| Component                       | Class       | Notes                                         |
|---------------------------------|-------------|-----------------------------------------------|
| Fischlin opening proof (full)   | **Deferred**| Cmt prototype uses hash-based proof            |
| Bitcoin tx serialization        | **Deferred**| Not in v1                                      |
| Custom predicates P(φ, m)       | **Deferred**| Only P=1 supported in v1                       |
| Variable-length messages        | **Deferred**| Fixed 32-byte messages                         |
| PBSch/RPBSch over P-256         | **Deferred**| If non-native path is needed later             |

## What must NOT be changed

The following files are **off-limits**. If a piece appears to require
editing one of these, it must be escalated before proceeding:

- `lib/longfellow-zk/**` (all files under this directory)
- `lib/zk-circuit-lang/**` (witness bindings, Lua integration)
- `src/lua/crypto_zkcc.lua` (legacy zkcc Lua interface)
- `src/lua/crypto_niwi.lua` (unless adding PBSch wrappers later)
- `lib/blindzap/ligero/` (adaptation is frozen as-is)

## Implementation order

Given the classification above, the build order is:

1. **[#A]** `secp256k1_field.*`, `secp256k1_scalar.*`, `secp256k1_curve.*` (foundation)
2. **[#A]** `secp256k1_witness.*` (conversion helpers)
3. **[#A]** FFT root derivation + constant validation
4. **[#A]** `pbsch_commitment.*` (prototype Cmt)
5. **[#A]** `bip340_circuit.*`, `bip340_witness.*` (standalone BIP-340)
6. **[#A]** `rpbsch_circuit.*`, `rpbsch_witness.*`, `rpbsch_stmt.*` (RPBSch relation)
7. **[#A]** `pbsch.*` (protocol state machine)
8. **[#B]** `pbsch_lua_bindings.c` (Lua wrappers)
