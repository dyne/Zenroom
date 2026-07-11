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

# PBSch Verification Matrix

This matrix tracks every known doubt / risk for the PBSch v1 profile.
No row should remain without an executable test, benchmark, or explicit
review gate before release.

## Blocker matrix

| # | Blocker | Required tests | Expected pass | Expected fail | Owner | Decision |
|---|---------|---------------|---------------|---------------|-------|----------|
| B1 | SECP proof-field viability | Fp2 root derivation, FFT verification, tiny circuit prove/verify over secp256k1_base | prover/verifier agree on SECP circuit | rejection under P256_ID | `lib/niwi` C++ test | ⬜ |
| B2 | Cmt proof-equivalence boundary | Valid C/S, wrong Pedersen point, wrong opening, changed tuple, missing proof bytes | valid openings accepted | partitioned openings rejected | `lib/niwi` C test + Lua mutation tests | ⬜ prototyped: Pedersen-only until Fischlin |
| B3 | BIP-340 circuit correctness | vendored CSV vectors, x-only lift, even-y, range checks, wrong msg/key/sig | positive vectors accepted | negative vectors rejected with correct reason | `lib/niwi` C++ circuit test | ⬜ |
| B4 | BIP-340 circuit cost | constraint count, proof size, witness gen time, prove time, verify time for 1 sig and 2 sigs | measured and recorded | N/A | benchmark | ⬜ |
| B5 | RPBSch branch 1 correctness | valid branch-1 proof, α/β/R/m/C mutations | honest witness accepted | mutated witness rejected | `lib/niwi` C++ circuit test | ✅ v1 |
| B6 | RPBSch branch 2 correctness | valid branch-2 proof, νᵤ=νᵤ', bad sig, bad S | trapdoor witness accepted | equal-νᵤ, bad sig, bad S rejected | `lib/niwi` C++ circuit test | ✅ v1 |
| B7 | Selector composition | valid fixed-shape witness, malformed selected slot, malformed inactive slot, selector non-boolean | selected valid branch accepted and inactive branch-specific padding ignored | selected branch mutation and non-bool selector rejected | `lib/niwi` C++ circuit test | ✅ private OR selector |
| B8 | PBSch end-to-end | full Figure 4 session, valid BIP-340 final sig, wrong state, replayed messages | valid session produces valid sig | out-of-order state rejected | Lua test | ⬜ |
| B9 | Deterministic vectors | byte-exact vectors for setup, keygen, all messages, final sig | vectors match across rebuilds | mutation changes output | Lua vector test | ⬜ |

## Test commands (to be run before release)

```bash
# Native circuit tests
cd lib/niwi && make test_bip340_circuit && ./test_bip340_circuit
cd lib/niwi && make test_rpbsch_circuit && ./test_rpbsch_circuit

# Lua integration tests  
./zenroom test/lua/pbsch_session.lua
./zenroom test/lua/pbsch_vectors.lua

# NIWI regression (must still pass)
./zenroom test/lua/niwi_regression.lua

# Legacy zkcc regression (must still pass)
cat test/lua/zkcc_small.lua | ./zenroom

# Benchmarks
cd lib/niwi && make bench

# Full lib/niwi test suite
cd lib/niwi && make test
```

## Release decision checklist

- [ ] All blocker rows resolved (pass or accepted-prototype)
- [ ] All CI tests green
- [ ] BIP-340 constraint count recorded and reviewed
- [ ] PBSch session produces BIP-340-valid final signature
- [ ] Deterministic vectors match across rebuilds
- [ ] Legacy zkcc prove_circuit / verify_circuit still pass
- [ ] Review document states: Cmt = Pedersen prototype (not Fischlin), P=true only, 32-byte msg only
