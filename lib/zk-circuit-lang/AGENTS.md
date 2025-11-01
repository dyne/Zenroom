## Architecture & Core Components

### 1. Field Arithmetic & Cryptographic Foundations

**Field Types**:
- `Fp256Base` / `p256_base`: Prime field arithmetic over P-256 curve (256-bit)
- `Fp2<Fp256Base>`: Quadratic extension field (Fp² for enhanced security)
- `GF2_128` / `f_128`: Binary field GF(2^128) for MACs and certain proof components
- All fields use **Montgomery representation** for efficient modular arithmetic

**Core Algebra (`src/algebra/`):**
- `fp.h`, `fp_generic.h`: Generic finite field arithmetic with template-based design
- `fp_p256.h`: P-256 specific optimizations
- `nat.h`, `nat.cc`: Multi-precision natural number arithmetic (limbs)
- `fft.h`, `rfft.h`: Fast Fourier Transform for polynomial operations
- `reed_solomon.h`: Reed-Solomon codes for error correction in proofs
- `convolution.h`: Polynomial convolution using FFT

**Elliptic Curves (`src/ec/`):**
- `p256.h`, `p256.cc`: NIST P-256 curve implementation for ECDSA
- Used for both signature verification and as the base field for ZK proofs

### 2. Zero-Knowledge Proof System

**Proof Architecture** (Ligero-based with Sumcheck protocol):

```
Circuit Definition → Compilation → Witness Generation → Proving → Verification
     ↓                    ↓              ↓                  ↓           ↓
QuadCircuit         Optimizer      Dense Arrays      ZkProver    ZkVerifier
```

**ZK Core Components (`src/zk/`):**
- `zk_prover.h`: Main prover that commits to witness, runs sumcheck, produces Ligero proof
- `zk_verifier.h`: Verifier that checks commitments and validates proofs
- `zk_proof.h`: Proof data structure (commitment + Ligero proof)
- `zk_common.h`: Shared utilities for pad generation, constraint setup

**Ligero System (`src/ligero/`):**
- `ligero_prover.h`: Reed-Solomon based IOP (Interactive Oracle Proof) prover
- `ligero_verifier.h`: Verifier for Ligero commitments
- `ligero_param.h`: Parameters (rate=4, nreq=128 for 86+ bits security)
- `ligero_transcript.h`: Fiat-Shamir transform handling
- Uses **Merkle trees** (`src/merkle/`) for polynomial commitment

**Sumcheck Protocol (`src/sumcheck/`):**
- `circuit.h`: Circuit representation with layers, quad gates
- `prover_layers.h`: Layer-by-layer sumcheck proving
- `quad.h`: Quadratic gate representation (sum of products: Σ w_l * w_r * v)
- `transcript_sumcheck.h`: Fiat-Shamir transcript for sumcheck rounds

### 3. Circuit Compilation System

**Circuit Compiler (`src/circuits/compiler/`):**
- `compiler.h`: `QuadCircuit<Field>` class - DSL for building arithmetic circuits
- **Key Operations**: `input()`, `mul()`, `add()`, `assert0()`, `linear()`, `konst()`
- **Optimizations**:
  - Common Subexpression Elimination (CSE)
  - Constant propagation
  - Dead code elimination (tracking `nwires_not_needed_`)
  - Layer squashing (minimize depth)
- `schedule.h`: Wire scheduling and layer assignment
- `node.h`: Internal node representation (add/mul gates)
- `circuit_dump.h`: Debug utilities for circuit inspection

**Gate Types**:
- **Quad gates**: Most general form `Σ k_i * w_left[i] * w_right[i]`
- More efficient than traditional add/mul gates
- Compiled from high-level operations

### 4. mDoc-Specific Circuits

**mDoc Verification (`src/circuits/mdoc/`):**

The library implements ZK proofs for ISO 18013-5 mDoc credentials:

**Main C API** (`mdoc_zk.h` - note: uses `extern "C"` for FFI):
- `generate_circuit()`: Produces compressed circuit bytes (zstd-compressed)
- `run_mdoc_prover()`: Proves knowledge of valid mDoc with requested attributes
- `run_mdoc_verifier()`: Verifies the ZK proof

**Circuit Components**:
- `mdoc_hash.h`: SHA-256 verification of mDoc structure, CBOR parsing
- `mdoc_signature.h`: ECDSA signature verification circuit
- `mdoc_witness.h`: Witness generation from actual mDoc data
- `mdoc_examples.h`: Test vectors with real issuer public keys
- `mdoc_decompress.cc`: Zstd decompression of circuits

**What mDoc Circuits Prove**:
1. Valid ECDSA signature from issuer on mDoc
2. Valid SHA-256 hashes of disclosed attributes
3. CBOR structure parsing (nameSpace, elementIdentifier, elementValue)
4. Time validity: `validFrom <= now <= validUntil`
5. Specific attribute values match requested claims
6. All while keeping undisclosed attributes and signatures private

**ZkSpecStruct Versioning**:
- `kZkSpecs[]`: Array of 12 supported specification versions
- Each version has: system name, circuit_hash, num_attributes, version number
- Allows protocol evolution while maintaining backward compatibility

### 5. Supporting Circuits

**ECDSA Verification (`src/circuits/ecdsa/`):**
- `verify_circuit.h`: Triple scalar multiplication form: `identity = g*e + pk*r + R*(-s)`
- `verify_witness.h`: Witness generation for ECDSA verification
- Uses precomputed witness tables for efficiency

**SHA-256 (`src/circuits/sha/`):**
- `flatsha256_circuit.h`: Optimized SHA-256 circuit (bit-level operations)
- `flatsha256_witness.cc`: Witness generation from actual SHA computations
- Handles variable-length messages in blocks of 512 bits

**Logic Circuits (`src/circuits/logic/`):**
- `bit_plucker.h`: Extract bits from field elements efficiently
- `bit_adder.h`: Binary addition circuits
- `memcmp.h`: Constant-time comparison
- `routing.h`: Conditional routing based on selector bits
- `polynomial.h`: Polynomial evaluation circuits

**MAC Circuits (`src/circuits/mac/`):**
- `mac_circuit.h`, `mac_witness.h`: Message Authentication Codes
- Used to bind different circuit components securely
- Prevents malicious witness mixing

### 6. Cryptographic Primitives

**Custom Implementations (`src/util/`):**
- `crypto.h`, `crypto.cc`: Custom SHA-256 and AES-ECB (replacing OpenSSL)
- `sha256.h`, `sha256.cc`: Standalone SHA-256 implementation
- `aes_ecb.h`, `aes_ecb.cc`: AES in ECB mode for PRF
- `randombytes.h`: Secure random number generation
- **Reason**: Independence from OpenSSL, WASM compatibility

**Transcript & Randomness (`src/random/`):**
- `transcript.h`: Fiat-Shamir hashing with domain separation
- `secure_random_engine.h`: Cryptographically secure RNG
- `random.h`: Base RandomEngine interface

### 7. Data Structures

**Arrays (`src/arrays/`):**
- `dense.h`: Dense multi-dimensional arrays of field elements
- `affine.h`: Affine (multi-linear) function representations
- `eq.h`, `eqs.h`: Equality check evaluations

**DenseFiller Pattern**:
```cpp
DenseFiller<Field> filler(circuit, F);
filler.push_back(value);  // Sequentially fill witness
```

### 8. Binary Field Operations

**GF(2^k) Support (`src/gf2k/`):**
- `gf2_128.h`: GF(2^128) arithmetic with SIMD optimizations
- `lch14.h`: LCH14 algorithm for polynomial basis (Lin-Chung-Han 2014)
- `lch14_reed_solomon.h`: Reed-Solomon over binary fields
- Used for MACs and certain proof components

### 9. Build System

**Multi-Target Makefiles**:
- **Root Makefile**: Orchestrates wasm and x86 builds
- **WASM Target**: Uses wasi-sdk, produces `longfellow-zk.wasm`
  - Exports: `run_mdoc_prover`, `run_mdoc_verifier`
  - No exceptions, no RTTI (`-fno-exceptions -fno-rtti`)
  - SIMD support (`-msimd128`)
- **x86 Target**: Builds CLI tool with PCLMUL support (`-mpclmul`)
- **Dependencies**: zstd (vendored), no OpenSSL

**Source Organization**:
- `sources.mk`: Lists compilation units
- Selective compilation: Only needed `.cc` files are compiled
- Header-only templates dominate the codebase

### 10. CLI Tool (`src/cli/`)

**Command-Line Interface** (`main.cc`):

Modern C++17/20 design using CLI11 library:

**Commands**:
1. `circuit_gen`: Generate and save circuit bytes
   - `--zkspec <latest|list|0-11>`: Select ZK specification
   - `-c, --circuit <file>`: Output circuit file

2. `mdoc_prove`: Generate ZK proof from mDoc
   - `-c, --circuit`: Circuit file
   - `-p, --proof`: Output proof file
   - `--pk, --public-key`: Issuer public key
   - `-s, --transcript`: Session transcript
   - `-t, --time`: ISO 8601 timestamp
   - `-d, --doc-type`: Document type

3. `mdoc_verify`: Verify ZK proof
   - Same parameters as prove (except proof is input)

4. `mdoc_example`: Show example mDoc data

**C++ Features Used**:
- RAII (`FileReader` class for automatic resource management)
- `std::unique_ptr` for memory safety
- `constexpr` lambdas for compile-time validation
- `magic_enum` for enum-to-string conversion
- `std::filesystem` for path handling

## Important Patterns & Conventions

### Template-Based Design

Almost everything is templated on `Field`:
```cpp
template <class Field>
class ZkProver { ... }
```

**Reason**: Same code works with Fp256, Fp2, GF2_128, etc.

### Field Element Lifecycle

```cpp
using Elt = typename Field::Elt;  // Field element type
const Field& F;                    // Field instance reference
Elt x = F.zero();                 // Create zero
Elt y = F.addf(x, F.one());       // Field addition
```

**Critical**: Field instance must outlive all Elt objects!

### Namespace Organization

All library code in `namespace proofs { ... }`

**Exception**: C API in `mdoc_zk.h` uses `extern "C"` for FFI compatibility

### Error Handling

- `check(condition, "error message")` macro (from `util/panic.h`)
- Aborts on failure (suitable for cryptographic code)
- C API returns error codes (enums like `MdocProverErrorCode`)

### Memory Management

**C++ Internal**: RAII, std::unique_ptr, std::vector
**C API Boundary**: Manual malloc/free
- `generate_circuit()` allocates with malloc, caller must free
- `run_mdoc_prover()` allocates proof, caller must free

### Circuit Wire Indexing

- Wire 0 is always `F.one()` (constant 1)
- Wire indices increase as circuit is built
- Public inputs come first, private inputs follow at `c_.npub_in`

## Vendor Dependencies

1. **Google Longfellow-ZK** (`vendor/longfellow-zk/`):
   - Upstream source (Apache 2.0 license)
   - Imported selectively via `scripts/import_upstream.sh`
   - Headers copied to `src/`, implementation files to `src/circuits/mdoc/`

2. **Zstd** (`vendor/zstd/`):
   - Facebook's Zstandard compression
   - Used for circuit compression (circuits are large, ~150MB uncompressed)
   - Built from source with minimal features

## Key Differences from Upstream

1. **License**: AGPL v3 (vs Apache 2.0)
2. **Crypto Primitives**: Custom SHA-256/AES instead of OpenSSL
3. **Build System**: GNU Make instead of CMake
4. **CLI Tool**: Custom implementation with modern C++ features
5. **WASM Support**: Primary target alongside x86

## Performance Characteristics

- **Circuit Size**: ~150MB uncompressed, ~5-10MB compressed
- **Proof Size**: Varies with attributes, typically 100-500KB
- **Prover Time**: Seconds to minutes depending on circuit complexity
- **Verifier Time**: Much faster than prover (seconds)
- **Security**: 128-bit security level (Ligero rate=4, nreq=128)

## Common Development Tasks

### Adding a New Attribute Type

1. Modify `mdoc_witness.h` to parse new CBOR type
2. Update `mdoc_hash.h` circuit to verify new type
3. Increment ZK spec version in `zk_spec.cc`
4. Regenerate circuits with new version

### Debugging Circuit Issues

1. Enable logging: Set log level in `util/log.h`
2. Use `dump_info()` and `dump_q()` from `circuit_dump.h`
3. Check circuit metrics: depth, wires, overhead
4. Verify CSE elimination is working (`nwires_cse_eliminated_`)

### Understanding a Proof Failure

1. Check return codes (enum values have descriptive names via magic_enum)
2. Verify circuit hash matches between prover/verifier
3. Ensure ZK spec version matches
4. Check transcript consistency (must be identical)
5. Validate public inputs (time, attributes, public keys)

## Testing Strategy

- **Unit Tests**: Not present in this fork (present in upstream)
- **Integration Tests**: CLI commands with example data
- **Example Data**: `mdoc_examples.h` contains real test vectors
- **Benchmarks**: Upstream has extensive benchmarks (not imported)

## Code Style & Conventions

- **C++ Standard**: C++17 (some C++20 features in CLI)
- **Naming**:
  - `snake_case` for functions, variables
  - `PascalCase` for classes, structs
  - `kConstantCase` for constants
  - `UPPER_CASE` for macros
- **Comments**: Doxygen-style not strictly enforced
- **Header Guards**: `#ifndef PRIVACY_PROOFS_ZK_LIB_...`
- **Line Length**: No strict limit, typically <80-100 chars

## Critical Security Considerations

1. **Constant-Time Operations**: MAC comparisons must be constant-time
2. **Randomness Quality**: Proofs use cryptographic RNG for blinding
3. **Circuit ID Verification**: Disabled by default in this codebase (see `enforce_circuit_id_in_*`)
4. **Subfield Boundary**: Carefully tracked for optimization and soundness
5. **Fiat-Shamir Transform**: Transcript must be properly domain-separated

## Useful Entry Points for Code Reading

1. **Start with CLI**: `src/cli/main.cc` shows high-level usage
2. **Follow a Proof**: Trace `run_mdoc_prover()` in `mdoc_zk.cc`
3. **Understand Fields**: Read `algebra/fp_generic.h` for template pattern
4. **Circuit Building**: Study `QuadCircuit` in `circuits/compiler/compiler.h`
5. **Sumcheck Protocol**: Read `sumcheck/circuit.h` and `zk/zk_prover.h`

## Common Pitfalls

1. **Field Lifetime**: Don't create `Elt` objects that outlive their `Field`
2. **Template Instantiation**: Missing template specializations cause linker errors
3. **Memory Leaks**: C API allocations must be manually freed
4. **WASM Limitations**: No exceptions, no threads, no filesystem
5. **Circuit Versioning**: Mismatched versions cause verification failures

## 11. Lua DSL Implementation (`lib/zk-circuit-lang/`)

**Overview**: A high-level Domain Specific Language (DSL) built on top of Longfellow-ZK primitives, providing Lua bindings for circuit construction through Zenroom.

### Architecture

**Three API Levels**:
1. **Low-level**: `QuadCircuit` - Direct arithmetic circuit building
2. **Mid-level**: `Logic` - Boolean logic with field elements  
3. **High-level**: Bit vectors and SHA-256 primitives

**Core Components**:
- `lfzk_bindings.h/.cc`: Sol2-based Lua bindings for C++ classes
- `custom_backend.h`: Workaround for missing `wire_id` method in QuadCircuit
- `test_completeness.lua`: Automated verification of binding completeness
- `examples/`: Working circuit examples demonstrating DSL usage

**Template-Based Design**:
- All operations templated on `Field` (Fp256Base, GF2_128)
- Same code works with multiple field types
- Modern C++17/20 with efficient template specialization

### Current Implementation Status

**Overall: 105/120 methods (87% complete)**

**✅ Fully Implemented (100%):**
- Field arithmetic (Fp256Base, GF2_128)
- GF128 field arithmetic (zero, one, addf, mulf)
- EltW operations (field element wires)
- BitW operations (boolean wires)
- GF128 logic operations (add, mul, konst, eltw_input, output, assert_eq_elt)
- SHA-256 specific primitives (lCh, lMaj, lxor3)
- BitVec<32> operations
- Conversion operations (BitW ↔ EltW)
- Linear algebra operations (ax, axpy, apy, axy)

**✅ Mostly Implemented (83%):**
- BitVec<8> operations (missing output/assertion methods)

**❌ Missing (0%):**
- Aggregate operations (functional programming constructs)
- Array operations (bulk operations on arrays)

### Key Features Available

**Field Arithmetic**:
```lua
local F = create_fp256_field()
local zero = F:zero()
local one = F:one()
local five = F:of_scalar(5)
local sum = F:addf(five, one)
```

**Logic Circuit Building**:
```lua
local L = create_logic()
local a = L:input()
local b = L:input()
local c = L:land(a, b)
L:assert1(c)
```

**Bit Vector Operations**:
```lua
local vec8 = L:vinput8()
local vec32 = L:vinput32()
local sum = L:vadd8(vec8, L:vbit8(5))
local eq = L:veq8(vec8, L:vbit8(10))
```

**SHA-256 Primitives**:
```lua
local ch = L:lCh(x, y, z)      -- Choose function
local maj = L:lMaj(x, y, z)    -- Majority function
local xor3 = L:lxor3(a, b, c)  -- 3-way XOR
```

### Integration with Zenroom

**Module Loading**:
```lua
ZK = require'longfellow'
```

**Built-in Support**:
- Integrated via `luaopen_longfellow()` in `src/zen_longfellow.c`
- Automatically available in Zenroom Lua environment
- No external dependencies required

### Example Usage Patterns

**Simple Arithmetic Circuit**:
```lua
local Q = create_quad_circuit()
local a = Q:input_wire()
local b = Q:input_wire()
local c = Q:add(a, b)
Q:assert0(c)
Q:mkcircuit(1)
```

**Range Proof**:
```lua
local L = create_logic()
local age = L:vinput8()
local min_age = L:vbit8(18)
local is_adult = L:vleq8(min_age, age)
L:assert1(is_adult)
```

### Development Workflow

**Testing**:
```bash
./zenroom lib/zk-circuit-lang/test_completeness.lua
./zenroom lib/zk-circuit-lang/examples/01_simple_arithmetic.lua
```

**Building**:
- Uses GNU Make with custom backend
- Compiles to `libzk-circuit-lang.a`
- Integrated into Zenroom build system

### Performance Characteristics

**Circuit Building**:
- Lua bindings add minimal overhead
- Most operations compile to direct C++ calls
- Template specialization ensures efficiency

**Memory Usage**:
- Lua objects wrap C++ objects via Sol2
- Automatic memory management via RAII
- No manual memory management required

### Known Issues & Limitations

1. **Circuit Property Access**: Circuit metrics (depth, wires) not properly exposed
2. **Missing Functional Constructs**: Aggregate and array operations not implemented
3. **Limited Error Handling**: Some C++ exceptions not properly caught in Lua

### Future Development Directions

**Short-term (High Priority)**:
- Implement missing aggregate operations
- Add array operations for bulk processing
- Fix circuit property access

**Medium-term**:
- Add support for ECDSA verification circuits
- Implement SHA-256 full circuit
- Add mDoc-specific circuit building

**Long-term**:
- Support for alternative proof systems
- Mobile platform optimization
- Enhanced debugging and profiling

Based on upstream work:
- Support for more credential types (JWT, W3C VC)
- Batch verification optimization
- Improved circuit compilation (better CSE)
- Alternative proof systems (Plonk, etc.)
- Mobile platform integration

## Resources & References

- **Upstream Repo**: https://github.com/google/longfellow-zk
- **IETF Draft**: draft-google-cfrg-libzk
- **ISO mDoc Standard**: ISO/IEC 18013-5:2021
- **Academic Paper**: https://eprint.iacr.org/2024/2010
- **Lua DSL Documentation**: `lib/zk-circuit-lang/README.md`
- **Completeness Test**: `lib/zk-circuit-lang/test_completeness.lua`
- **Examples**: `lib/zk-circuit-lang/examples/`

---

**Last Updated**: November 2025  
**Maintainer**: Denis Roio (jaromil@dyne.org)  
**Lua DSL Status**: 87% Complete (105/120 methods)  
**License**: GNU Affero General Public License v3.0
