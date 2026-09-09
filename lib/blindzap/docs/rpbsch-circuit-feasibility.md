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

# RPBSch Circuit Feasibility Audit

This document audits exactly what the `SECP_ID = 10` stub in Longfellow
covers and what must be built under `lib/blindzap` to use native secp256k1
field arithmetic for RPBSch circuits.

## What SECP_ID already provides

In `lib/longfellow-zk/proto/circuit.h`:

```cpp
enum FieldID {
  // ...
  SECP_ID = 10,
};
```

This reserves a field identifier for secp256k1 circuit serialization.
`CircuitRep<Field>` uses `field_id_` to:

1. **Serialize** the field ID as a 3-byte header in circuit bytecode
2. **Validate** during deserialization that `fid_as_size_t ==
   static_cast<size_t>(field_id_)`

That is the *only* function of `SECP_ID`. It is a serialization label.
It does NOT provide:

- A secp256k1 Field type (FpSecp256k1Base)
- A secp256k1 EllipticCurve instance
- FFT/Reed-Solomon root constants
- Witness conversion helpers
- Any circuit templates

## What must be built under lib/blindzap

### Field type: `FpSecp256k1Base`

The secp256k1 prime `p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F` 
is a 256-bit prime. Using the generic `FpGeneric<4, true, FpReduce>` path:

```cpp
namespace niwi {
using FpSecp256k1Base = proofs::Fp<4, true>;
extern const FpSecp256k1Base secp256k1_base;
}
```

In `.cc`:
```cpp
const FpSecp256k1Base secp256k1_base(
    "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f");
```

The generic `FpReduce` handles any odd 256-bit modulus fitting in 4
limbs. No specialized reduction is needed for the first profile.

**Feasibility**: ✓ Straightforward. The generic Fp<4> constructor
accepts any odd 256-bit prime. No changes to `lib/longfellow-zk`.

### Scalar field: `FpSecp256k1Scalar`

The curve order `n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141`
fits in 4 limbs. Define a second field instance:

```cpp
using FpSecp256k1Scalar = proofs::Fp<4, true>;
extern const FpSecp256k1Scalar secp256k1_scalar;
```

**Feasibility**: ✓ Same generic path. The scalar field is used only
for modular arithmetic mod `n` in BIP-340 signature verification.

### EllipticCurve instance: `Secp256k1`

Following the pattern of `ec/p256.h`:

```cpp
namespace niwi {
using Secp256k1 = proofs::EllipticCurve<FpSecp256k1Base, 4, 256>;
extern const Secp256k1 secp256k1;
}
```

In `.cc`:
```cpp
const Secp256k1 secp256k1(
    secp256k1_base.of_string("0"),     // a = 0
    secp256k1_base.of_string("7"),     // b = 7
    secp256k1_base.of_string(          // G_x
        "0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"),
    secp256k1_base.of_string(          // G_y
        "0x483ada7726a3c4655da4fb0fc1108a8fd17b448a68554199c47d08ffb10d4b8"),
    secp256k1_base);
```

**Feasibility**: ✓ The `EllipticCurve<Field, W, kN>` template is generic.
Since `a = 0`, the curve will detect `is_zero_a_` and use the
optimized addition formulas. No changes to `lib/longfellow-zk`.

### Reed-Solomon FFT root derivation

The FFT-based Reed-Solomon encoding used by Ligero requires a
primitive root of unity `ω` in an extension field such that `ω^N = 1`
for `N` a large power of 2.

For a prime field `Fp`, the maximum power-of-2 subgroup size in the
multiplicative group is `v2(p-1)` where `v2` counts factors of 2.

For secp256k1: `p - 1 = 2^6 * 3 * 2459565876494606882130114647029886100129345462086340953827996439880923`
So `v2(p-1) = 6`.

This means the **base field only supports FFT sizes up to 2^6 = 64**,
which is insufficient for any practical circuit.

Therefore we must use the quadratic extension `Fp2<FpSecp256k1Base>`.
Since -1 is a quadratic non-residue mod p (verified: `p ≡ 3 mod 4`),
we can use `Fp2<FpSecp256k1Base, true>` with the "complex" fast path.

The extension field order is `p^2 ≈ 2^512`. The maximum power-of-2
subgroup in `Fp2*` depends on `p^2 - 1` factorization, but for our
purposes we only need a root of order `N = 2^k` where `k ≥ 20`
(supporting circuits up to 2^20 ≈ 1M constraints).

**Derivation strategy**:

1. Find `g`, a generator of `Fp2*`
2. Let `t = (p^2 - 1) / N`
3. `ω = g^t` is a primitive N-th root of unity

The root constants `(kRootX, kRootY)` will be computed numerically
(using Python/GMP or a small C program) and hardcoded, then verified
by circuit tests.

**Feasibility**: ✓ Same approach as P-256 in `lfzk_bindings.cc` which
hardcodes `kRootX`/`kRootY`. The secp256k1 Fp2 will have a different
ω but the derivation and usage pattern is identical.

### Reed-Solomon factory

Following the pattern in `lfzk_bindings.cc`'s `lua_prove_circuit`:

```cpp
using Field = FpSecp256k1Base;
const Field& F = secp256k1_base;
Fp2<Field> F2(F);
auto omega = F2.of_string(kRootX, kRootY);
FFTExtConvolutionFactory<Field, Fp2<Field>> fft(F, F2, omega, 1ull << 31);
ReedSolomonFactory<Field, FFTExtConvolutionFactory<Field, Fp2<Field>>> rsf(fft, F);
```

**Feasibility**: ✓ The template is fully generic. Only the `omega`
constant changes for the secp256k1 field.

### Circuit serialization

`CircuitRep<FpSecp256k1Base>(secp256k1_base, proofs::SECP_ID)` will
serialize circuits with `SECP_ID = 10`. Deserialization will validate
the field ID matches.

**Feasibility**: ✓ The `SECP_ID` enum value already exists. The
`CircuitRep` template is generic over `Field`. No changes needed.

### Witness conversion helpers

Need functions to convert 32-byte OCTET buffers to secp256k1 field
elements (base field and scalar field):

```cpp
// Convert 32-byte big-endian byte array to FpSecp256k1Base::Elt
FpSecp256k1Base::Elt octet_to_secp256k1_base(const uint8_t bytes[32]);

// Convert 32-byte big-endian byte array to FpSecp256k1Scalar::Elt
FpSecp256k1Scalar::Elt octet_to_secp256k1_scalar(const uint8_t bytes[32]);
```

These follow the pattern of `nat_from_octet<Fp256Nat>(...)` in
`witness_bindings.cc` but with explicit types to prevent confusion
with P-256 conversions.

**Feasibility**: ✓ Simple byte-to-Nat conversion plus Montgomery
encoding. The `Nat` type supports construction from packed byte
arrays.

## Comparison: Native SECP vs Non-Native P-256

| Criterion                    | Native SECP                    | Non-native over P-256           |
|------------------------------|--------------------------------|---------------------------------|
| Field modulus matches curve  | ✓ (same p)                     | ✗ (P-256 p ≠ secp256k1 p)      |
| Point ops are native         | ✓                              | ✗ (must emulate mod p in Fp256) |
| Scalar arithmetic            | ✓ (use FpSecp256k1Scalar)      | ✗ (must emulate mod n in Fp256) |
| Circuit size (constraints)   | Smaller (native ops)           | Much larger (non-native emu)    |
| Requires Longfellow changes  | No                             | No                              |
| Requires new FFT roots       | Yes (derived once)             | No (reuse P-256 roots)           |
| SECP_ID usage                | Natural                        | Requires separate circuit ID    |
| Verification cost            | Lower                          | Higher                          |

**Conclusion**: Native SECP is clearly the correct path. It requires
no changes to `lib/longfellow-zk`, only new field/curve definition
files under `lib/blindzap` and one set of hardcoded FFT root constants.

## Build integration

New files under `lib/blindzap/src/secp256k1/`:

```
lib/blindzap/src/secp256k1/
├── secp256k1_field.h        # FpSecp256k1Base, secp256k1_base
├── secp256k1_field.cc
├── secp256k1_curve.h        # Secp256k1 typedef, secp256k1 instance  
├── secp256k1_curve.cc
├── secp256k1_scalar.h       # FpSecp256k1Scalar, secp256k1_scalar
├── secp256k1_scalar.cc
├── secp256k1_witness.h      # octet_to_secp256k1_* helpers
└── secp256k1_witness.cc
```

Added to `lib/blindzap/sources.mk` and compiled by the existing `lib/blindzap/GNUmakefile`.
No changes to `lib/longfellow-zk/sources.mk` or `build/deps.mk`.

## Blocker resolution

The three known doubts from the plan:

| Doubt                          | Resolution                                           |
|--------------------------------|------------------------------------------------------|
| SECP proof-field viability     | Feasible: Fp<4> generic path, SECP_ID stub, Fp2 FFT  |
| Cmt proof equivalence          | Accepted: prototype Cmt, Fischlin deferred           |
| BIP-340 circuit correctness    | Design pattern: separate circuit module, CSV vectors |

## Risk: Fp2 quadratic non-residue verification

We must verify that -1 is a quadratic non-residue mod p = secp256k1
prime. Since `p ≡ 3 (mod 4)`, this is true by Euler's criterion:
`(-1)^((p-1)/2) ≡ -1 (mod p)` when `(p-1)/2` is odd. For secp256k1:
`(p-1)/2 = 2^5 * 3 * ...` which is even, so we need to verify -1 is
not a square.

Quick check: The Legendre symbol `(-1/p) = (-1)^((p-1)/2)`. Since
`p ≡ 3 (mod 4)`, `(p-1)/2` is odd, so `(-1/p) = -1`, meaning -1 is a
non-residue. ✓ Confirmed.

Actually: `p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F`.
`p mod 4 = 0x2F mod 4 = 3`. Since `p ≡ 3 (mod 4)` and `p > 3`, `-1`
is indeed a quadratic non-residue. The `Fp2<FpSecp256k1Base, true>`
optimized path applies.

## Risk: FFT root existence in Fp2

The extension field `Fp2` has order `p^2`. The maximum power-of-2
dividing `p^2 - 1 = (p-1)(p+1)`. Since `v2(p-1) = 6` and `v2(p+1)` is
at least 1, `v2(p^2-1) = 6 + v2(p+1)`.

`p + 1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC30`.
This is divisible by 2^? We'll compute this precisely during root
derivation. The absolute minimum needed is v2 ≥ 20 for meaningful
circuit sizes. This should be generous for `p+1` which is large.

**TODO during implementation**: Derive exact root constants and verify
v2(p^2-1) ≥ 20.
