# lib/niwi Source Map

Each module below names its source paper, repository dependency, and security role.

## Active modules (milestone 1)

| Module | Paper / Source | Repository dependency | Security role |
|--------|---------------|----------------------|---------------|
| NIWI prover | 2025-1992 Def. 12 | lib/niwi/src/, lib/niwi/ligero/ | Statistical WI via KLP22 |
| NIWI verifier | 2025-1992 Def. 12 | lib/niwi/src/, lib/niwi/ligero/ | Accepts only valid proofs |
| Straight-line extractor | 2025-1992 Def. 13, Pass/NPRO | lib/niwi/src/, NPRO query log | Recovers witness from Gamma without rewinding |
| KLP22 challenge-share commitments | KLP22 §4, statistically hiding commitment | lib/niwi/commitment/ | Hides challenge shares before verifier challenge |
| Pass/NPRO leaf commitments | Pass/NPRO, 2025-1992 §5 | lib/niwi/commitment/, Merkle | Commit leaf preimages as observable NPRO queries |
| Ligero adaptation | Longfellow Ligero | lib/niwi/ligero/ (copied from lib/longfellow-zk/ligero/) | Exposes commit/challenge/response/query phases |
| Canonical encoding | 2025-1992, KLP22 | lib/niwi/src/encoding/ | Byte-exact deterministic serialization |
| Domain separation | 2025-1992, KLP22 | lib/niwi/src/hash/ | Separate protocol, statement, challenge, Merkle hashing |
| Observable NPRO | Pass/NPRO, 2025-1992 Def. 13 | lib/niwi/src/npro/ | Records random oracle queries for extraction |
| C ABI | lib/niwi | lib/niwi/include/niwi.h | Narrow C interface for Zenroom Lua binding |
| Lua binding | lib/niwi | src/lua/ (plain Lua C API, no sol++) | expose prove_circuit_niwi, verify_circuit_niwi, niwi_profile |

## Deferred modules (milestone 2+)

| Module | Paper / Source | Repository dependency | Security role |
|--------|---------------|----------------------|---------------|
| PBSch (Blind Schnorr) | 2025-1992 Fig. 4 | lib/niwi/src/pbsch/ | Composes NIWI + BIP-340 + commitments |
| RPBSch relation | 2025-1992 Fig. 4 | zkcc circuit | The relation proved under NIWI in PBSch |
| Outer Cmt (extractable) | 2025-1992 Fig. 4, Pedersen/Fischlin | lib/niwi/commitment/ | Extractable commitment for PBSch message flow |
| BIP-340 Schnorr | BIP-340 | src/lua/crypto_secp.lua | 64-byte signatures, 32-byte x-only keys |
| PBSch end-to-end fixture | 2025-1992 Fig. 4 | test/ | Full Figure 4 message flow test |

## Dependency graph

```
lib/niwi
├── lib/niwi/ligero/          (copied from lib/longfellow-zk/ligero/)
├── lib/niwi/commitment/      (KLP22 + Pass/NPRO)
├── lib/niwi/src/encoding/    (canonical byte-level)
├── lib/niwi/src/hash/        (domain-separated SHA-256)
├── lib/niwi/src/npro/        (observable random oracle)
├── lib/niwi/include/niwi.h   (C ABI)
├── lib/longfellow-zk/        (read-only: circuit types, algebra, RS)
├── SHA-256                   (from zenroom C runtime)
└── src/lua/                  (Lua bindings via plain C API)
```
