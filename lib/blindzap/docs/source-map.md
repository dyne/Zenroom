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

Each module below names its source paper, repository dependency, and security role.

## Active modules (milestone 1)

| Module | Paper / Source | Repository dependency | Security role |
|--------|---------------|----------------------|---------------|
| NIWI prover | 2025-1992 Def. 12 | lib/blindzap/src/, lib/blindzap/ligero/ | Statistical WI via KLP22 |
| NIWI verifier | 2025-1992 Def. 12 | lib/blindzap/src/, lib/blindzap/ligero/ | Accepts only valid proofs |
| Straight-line extractor | 2025-1992 Def. 13, Pass/NPRO | lib/blindzap/src/, NPRO query log | Recovers witness from Gamma without rewinding |
| KLP22 challenge-share commitments | KLP22 §4, statistically hiding commitment | lib/blindzap/commitment/ | Hides challenge shares before verifier challenge |
| Pass/NPRO leaf commitments | Pass/NPRO, 2025-1992 §5 | lib/blindzap/commitment/, Merkle | Commit leaf preimages as observable NPRO queries |
| Ligero adaptation | Longfellow Ligero | lib/blindzap/ligero/ (copied from lib/longfellow-zk/ligero/) | Exposes commit/challenge/response/query phases |
| Canonical encoding | 2025-1992, KLP22 | lib/blindzap/src/encoding/ | Byte-exact deterministic serialization |
| Domain separation | 2025-1992, KLP22 | lib/blindzap/src/hash/ | Separate protocol, statement, challenge, Merkle hashing |
| Observable NPRO | Pass/NPRO, 2025-1992 Def. 13 | lib/blindzap/src/npro/ | Records random oracle queries for extraction |
| C ABI | lib/blindzap | lib/blindzap/include/niwi.h | Narrow C interface for Zenroom Lua binding |
| Lua binding | lib/blindzap | src/lua/ (plain Lua C API, no sol++) | expose prove_circuit_niwi, verify_circuit_niwi, niwi_profile |
| 2025/1992 flow benchmark | 2025-1992 Fig. 4 / RPBSch profile | `lib/blindzap/tests/test_2025_1992_flow_bench.c` | Measures native CMT3/RPB2 public-boundary operations with stable `BENCH paper_flow` rows |

## Deferred modules (milestone 2+)

| Module | Paper / Source | Repository dependency | Security role |
|--------|---------------|----------------------|---------------|
| PBSch (Blind Schnorr) | 2025-1992 Fig. 4 | lib/blindzap/src/pbsch/ | Composes NIWI + BIP-340 + commitments |
| RPBSch relation | 2025-1992 Fig. 4 | zkcc circuit | The relation proved under NIWI in PBSch |
| Outer Cmt (extractable) | 2025-1992 Fig. 4, Pedersen/Fischlin | lib/blindzap/commitment/ | Extractable commitment for PBSch message flow |
| BIP-340 Schnorr | BIP-340 | src/lua/crypto_secp.lua | 64-byte signatures, 32-byte x-only keys |
| PBSch end-to-end fixture | 2025-1992 Fig. 4 | test/ | Full Figure 4 message flow test |

## Dependency graph

```
lib/blindzap
├── lib/blindzap/ligero/          (copied from lib/longfellow-zk/ligero/)
├── lib/blindzap/commitment/      (KLP22 + Pass/NPRO)
├── lib/blindzap/src/encoding/    (canonical byte-level)
├── lib/blindzap/src/hash/        (domain-separated SHA-256)
├── lib/blindzap/src/npro/        (observable random oracle)
├── lib/blindzap/include/niwi.h   (C ABI)
├── lib/blindzap/tests/           (unit, relation, and benchmark coverage)
├── lib/longfellow-zk/        (read-only: circuit types, algebra, RS)
├── SHA-256                   (from zenroom C runtime)
└── src/lua/                  (Lua bindings via plain C API)
```
