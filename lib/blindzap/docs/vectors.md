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

The NIWI papers (2025-1992, KLP22, Pass/NPRO) do not provide official test
vectors comparable to Bitcoin's BIP-340 CSV. All test evidence must be
generated reproducibly from the implementation itself.

## Vector directory layout

```
test/vectors/niwi/
├── README.md                  Generator commit, protocol version
├── encoding/                  Canonical encoding vectors
│   ├── empty.bin
│   ├── field_elements.bin
│   ├── arrays.bin
│   └── proof_sections.bin
├── commitments/               KLP22 and Pass/NPRO commitment vectors
│   ├── klp22_open_verify.bin
│   └── pass_leaf_merkle.bin
├── npro/                      Observable random oracle vectors
│   ├── query_log.bin
│   └── replay.bin
├── proofs/                    Honest proof vectors
│   ├── small_arith.niwi
│   └── or_circuit.niwi
├── extraction/                 Extraction fixtures
│   ├── honest_extract.bin
│   └── adversarial/           Gamma mutations
└── transcripts/               Fiat-Shamir transcript vectors
    └── challenge_schedule.bin
```

## Deterministic test profiles

| Profile | NPRO queries | Challenge derivation | Commitments | Randomness | Use |
|---------|-------------|---------------------|-------------|------------|-----|
| `test_deterministic` | Observed, replayable | From fixed seed | Fixed randomness | `NiwiTestRng` | Vector generation, regression |
| `production` | Not observed | From secure RNG | Fresh randomness | System CSPRNG | Normal proving |
| `extraction_test` | Observed, with cutoff | From fixed seed | Fixed randomness | `NiwiTestRng` | Extraction tests |

Production APIs reject `NiwiTestRng` unless compiled with a test flag.

## Vector generation

A generator binary or test target produces all vectors under
`test/vectors/niwi/`. The generator:

1. Uses `NiwiTestRng` with a fixed, documented seed
2. Produces vectors for every encoding, commitment, NPRO, proof, and extraction path
3. Self-checks that regenerated output matches committed vectors byte-for-byte

Running the generator twice must produce identical output (no hidden RNG,
no timestamps, no machine-dependent serialization).

## README format

Each `test/vectors/niwi/` directory must include a README with:

- Generator commit hash
- Protocol version (e.g., `niwi-v1`)
- Seed value
- Domain tags used
- Circuit description (for proof vectors)
- Expected output sizes and digests

## What is excluded

- BIP-340 vectors (part of Schnorr/SECP plan)
- RPBSch / PBSch vectors (milestone 2+)
- Bitcoin transaction serialization vectors
