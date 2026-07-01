# NIWI Cryptographic Review Checklist

This checklist maps implementation invariants to the paper claims they
support.  Each item states the invariant, the paper requirement it
addresses, the file(s) that enforce it, and whether it is verified or
tracking.

## Domain Separation

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 1 | Every hash operation uses a 4-byte domain tag | KLP22, 2025-1992 Def. 12 | `src/hash.h`, `src/hash.c` | ✅ Verified |
| 2 | Domain tags are disjoint: protocol (NP01), statement (NS02), FS challenge (NC03), KLP22 commit (NK04), leaf (NL05), Merkle leaf (NM06), Merkle internal (NM07), proof ser (NP08), extractor replay (NE09) | KLP22 FS soundness | `src/hash.h` | ✅ Verified |
| 3 | Tag is fed as first 4 bytes into SHA-256, before any data | Domain separation | `src/hash.c:niwi_hash_create()` | ✅ Verified |
| 4 | No two protocol messages share a domain tag | Cross-protocol collision | `src/hash.h` enum | ✅ Verified |
| 5 | PBSch message domain tags are reserved but not used in milestone 1 | 2025-1992 Fig. 4 deferred | `src/hash.h` (reserve comment) | 🔶 Tracking |

## KLP22 Challenge-Share Commitments

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 6 | Commitment uses statistically hiding scheme | KLP22 WI lemma | `docs/klp22-commitment-profile.md` | 🔶 SHA-256 scaffold (computational only); Pedersen tracked |
| 7 | Commitment randomness is fresh per proof | KLP22 binding | `src/commitment.c:niwi_klp22_commit()` | ✅ Verified (scaffold: rand(), tracking CSPRNG) |
| 8 | Opening is 64 bytes (message[32] ‖ randomness[32]) | Canonical encoding | `src/commitment.h` | ✅ Verified |
| 9 | Commitment domain tag NK04 is fixed and never reused | Domain separation | `src/hash.h`, `src/commitment.c` | ✅ Verified |
| 10 | Verifier rejects opening with wrong message or randomness | Binding | `src/commitment.c:niwi_klp22_verify()` | ✅ Verified (tested) |

## Pass/NPRO Leaf Commitments & Extraction

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 11 | Leaf preimage is committed as domain-tagged NPRO query | Pass/NPRO, 2025-1992 Def. 13 | `src/commitment.c:niwi_leaf_commit()` | ✅ Verified |
| 12 | NPRO observation records domain, input, output, sequence number | Def. 13 extractor | `src/npro.c:niwi_npro_query()` | ✅ Verified |
| 13 | Gamma serialization includes query count, cutoff, and per-query data | Def. 13 extractor | `src/npro.c:niwi_npro_serialize_gamma()` | ✅ Verified |
| 14 | Extractor lookup enforces before-proof cutoff (seq < cutoff) | Def. 13 straight-line | `src/npro.c:niwi_npro_lookup()` | ✅ Verified (tested) |
| 15 | Production mode disables observation (Gamma is empty) | Production safety | `src/npro.c:niwi_npro_create(0)` | ✅ Verified (tested) |
| 16 | Deserialized Gamma is immutable (observation disabled) | Extractor integrity | `src/npro.c:niwi_npro_deserialize_gamma()` | ✅ Verified |

## Fiat-Shamir Challenge Schedule

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 17 | Challenge order: statement → commitment → challenge_1 → response → challenge_2 → openings | KLP22, Def. 12 | `ligero/niwi_phase_prover.h` | 🔶 Defined in header; C++ instantiation tracked |
| 18 | All prior messages are bound before deriving each challenge | FS soundness | `ligero/niwi_phase_prover.h::phase_challenge_1()` | 🔶 Design documented |
| 19 | Commitment to prover shares occurs BEFORE verifier challenge | KLP22 WI | `ligero/niwi_phase_prover.h::phase_commit()` | 🔶 Design documented |
| 20 | Challenge derivation rejects if required prior messages are missing | Protocol integrity | `ligero/niwi_phase_prover.h` | 🔶 Enforcement tracked |

## Proof Serialization & Parsing

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 21 | NiwiProof header has magic "NIWI" (4 bytes) | Self-identification | `ligero/niwi_proof_serde.h` | ✅ Verified (tested) |
| 22 | Version is major.minor (u16 each) | Forward compatibility | `ligero/niwi_proof_serde.h` | ✅ Verified (tested) |
| 23 | All multi-byte integers are big-endian | Canonical encoding | `ligero/niwi_proof_serde.h`, `src/encoding.c` | ✅ Verified |
| 24 | Parser rejects trailing bytes after proof | Strict parsing | `ligero/niwi_proof_serde.h` | 🔶 Design documented; enforcement tracked |
| 25 | Parser rejects unsupported versions | Forward compatibility | `ligero/niwi_proof_serde.h` | ✅ Verified (tested) |
| 26 | Parser rejects non-canonical field encodings | Deterministic parsing | `ligero/niwi_proof_serde.h` | 🔶 Field serialization tracked |
| 27 | Legacy ZkProof is rejected by NIWI verification | Separation | `src/niwi.c`, `ligero/niwi_ligero_adapt.h` | 🔶 Different magic bytes; enforcement tracked |
| 28 | NIWI proof is rejected by legacy verification | Separation | Different magic "NIWI" vs legacy format | 🔶 Format differs; enforcement tracked |

## Statement Binding

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 29 | Circuit digest is included in proof header | Statement binding | `ligero/niwi_proof_serde.h` | ✅ Verified |
| 30 | Public inputs are hashed into statement_digest | Statement binding | `ligero/niwi_proof_serde.h`, `ligero/niwi_phase_prover.h` | 🔶 Hashing tracked |
| 31 | Verifier recomputes statement_digest and compares | Statement binding | `src/niwi_lua_bindings.c:lua_verify_circuit_niwi()` | 🔶 Comparison tracked |

## Randomness

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 32 | Production proving uses system CSPRNG, not rand() | Security | `src/commitment.c` | 🔶 Scaffold uses rand(); CSPRNG tracked |
| 33 | Test mode uses deterministic NiwiTestRng with fixed seed | Reproducibility | `docs/vectors.md` | 🔶 Generator tracked |
| 34 | Production APIs reject test-only RNG types | Safety | `docs/vectors.md` | 🔶 Gate tracked |

## Extraction

| # | Invariant | Paper | Files | Status |
|---|-----------|-------|-------|--------|
| 35 | Every committed leaf digest is recoverable from Gamma | Def. 13 | `src/extract.c:niwi_extract_recover_leaves()` | 🔶 Full recovery requires C++ Field types |
| 36 | Merkle root is rebuilt from recovered leaves | Def. 13 | `src/extract.c` | 🔶 Merkle rebuild tracked |
| 37 | Recovered witness is validated by re-evaluating the circuit | Def. 13 soundness | `src/extract.c:niwi_extract_witness()` | 🔶 Stub; full validation tracked |
| 38 | Missing leaf in Gamma causes extraction failure (not silent) | Def. 13 completeness | `src/extract.c`, `src/extract.h` | ✅ Error code NIWI_EXTRACT_ERR_MISSING_LEAF |
| 39 | Post-cutoff queries are ignored by extractor | Def. 13 straight-line | `src/npro.c:niwi_npro_lookup()` | ✅ Verified (tested) |
| 40 | Extractor is deterministic: same proof + Gamma → same witness | Def. 13 | `src/extract.c` | 🔶 Determinism tracked |

## Legend

- ✅ Verified: implemented and tested
- 🔶 Tracking: design documented, full implementation or integration tracked

## Unresolved protocol-composition blockers

1. **Pedersen commitment upgrade** (items 6, 32): SHA-256 scaffold is
   computationally hiding only. Must be replaced with Pedersen-over-BLS381
   before production use per klp22-commitment-profile.md.

2. **KLP22 challenge schedule C++ instantiation** (items 17-20): The NiwiPhaseProver
   template is defined in headers but not yet instantiated against a concrete
   Field type. Requires linking with Longfellow's Fp256Base and ReedSolomon
   factory.

3. **Full extraction witness recovery** (items 35-37): The extractor scaffold
   parses proofs and deserializes Gamma, but full tableau reconstruction and
   circuit re-evaluation require C++ Field types from Longfellow.

4. **CSPRNG integration** (item 32): Scaffold uses rand(). Must switch to
   Zenroom's random engine or system getrandom() for production.

5. **NiwiProof full wire format** (items 24, 26-28): Field element serialization
   is defined but the full Ligero proof body (y_ldt, y_dot, req, Merkle paths)
   serialization requires C++ Field::to_bytes integration.

None of these blockers prevent the current milestone from being reviewed;
they are explicitly tracked for the Ligero adaptation follow-up.
