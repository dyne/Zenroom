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

lib/blindzap is a **standalone library slice** that reuses Longfellow public headers
and types but does **not** edit any file under lib/longfellow-zk/. When Ligero
internals must be adapted to expose KLP22 phases, the minimal required code is
**copied** into lib/blindzap/ligero/ with provenance comments and compatibility tests.

## File layout

```
lib/blindzap/
├── include/
│   ├── niwi.h          C ABI (opaque handles, byte buffers, status codes)
│   └── niwi.hh         Thin C++ facade over C ABI (optional convenience)
├── src/
│   ├── niwi.cpp        Prove / verify entry points
│   ├── extract.cpp     Straight-line extractor (test-only entry)
│   ├── encoding/       Canonical length-prefixed encoders
│   ├── hash/           Domain-separated hashing
│   └── npro/           Observable random oracle
├── ligero/             Copied Longfellow Ligero code, split into NIWI phases
├── commitment/         KLP22 + Pass/NPRO commitment implementations
├── tests/              Native C++ tests
├── docs/               Design notes, source map, scope
└── GNUmakefile         Standalone build target
```

## Longfellow files: read-only vs. copied

### Read-only (link against, include headers)

| Longfellow file | Purpose |
|-----------------|---------|
| lib/longfellow-zk/algebra/ | Field arithmetic, polynomials |
| lib/longfellow-zk/circuits/ | Circuit types and tableau layout |
| lib/longfellow-zk/arrays/ | Array/vector helpers |
| lib/longfellow-zk/util/ | Utility functions |
| lib/longfellow-zk/merkle/ | **Read existing MerkleCommitment for reference only** |

### Copied into lib/blindzap/ligero/ (with provenance)

| Source file | Copied as | Adaptation |
|-------------|-----------|------------|
| lib/longfellow-zk/ligero/[phase files] | lib/blindzap/ligero/ | Split monolithic prover into witness-commit, first-challenge, algebraic-response, query-challenge, opening phases |

Each copied file must include at the top:

```
// Copied from lib/longfellow-zk/ligero/<path> at commit <hash>
// Adapted for NIWI KLP22 phase boundaries.
// Do not edit the original Longfellow file.
```

### New (native to lib/blindzap)

Everything else: KLP22 challenge schedule, NPRO, Pass commitments, canonical
encoding, C ABI, and the NIWI proof/verifier/extractor logic.

## API surface

### C ABI (niwi.h) — stable, exception-free

```c
// Opaque handles
typedef struct niwi_ctx niwi_ctx_t;

// Lifecycle
niwi_ctx_t* niwi_ctx_create(const uint8_t* circuit_artifact, size_t len);
void        niwi_ctx_free(niwi_ctx_t* ctx);

// Prove (production: secure randomness)
int niwi_prove(niwi_ctx_t* ctx,
               const uint8_t* public_inputs, size_t pub_len,
               const uint8_t* private_inputs, size_t priv_len,
               uint8_t** proof_out, size_t* proof_len);

// Prove with observation (test-only)
int niwi_prove_observed(niwi_ctx_t* ctx,
                        const uint8_t* public_inputs, size_t pub_len,
                        const uint8_t* private_inputs, size_t priv_len,
                        uint8_t** proof_out, size_t* proof_len,
                        uint8_t** gamma_out, size_t* gamma_len);

// Verify
int niwi_verify(niwi_ctx_t* ctx,
                const uint8_t* proof, size_t proof_len,
                const uint8_t* public_inputs, size_t pub_len);

// Extract (test-only)
int niwi_extract(niwi_ctx_t* ctx,
                 const uint8_t* proof, size_t proof_len,
                 const uint8_t* gamma, size_t gamma_len,
                 const uint8_t* public_inputs, size_t pub_len,
                 uint8_t** witness_out, size_t* witness_len);

// Free output buffers
void niwi_free_buffer(uint8_t* buf);

// Last error
const char* niwi_last_error(niwi_ctx_t* ctx);
```

### C++ facade (niwi.hh) — thin, optional

Wraps the C ABI with RAII, `std::span<const uint8_t>`, and
`std::expected<..., NiwiError>`. Does not expose Longfellow templates,
STL containers, or exceptions through the C boundary.

## Compatibility guarantee

Existing `prove_circuit` and `verify_circuit` (legacy zkcc path) must produce
byte-identical proofs before and after lib/blindzap is linked. A future
compatibility test runs legacy zkcc tests with lib/blindzap linked.
