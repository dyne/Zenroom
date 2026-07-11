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

# RPBSch Implementation Profile

This document defines the first PBSch/RPBSch profile supported by
this implementation. It maps every byte of the statement and witness
to concrete secp256k1/BIP-340 encodings so developers can derive
inputs without consulting ambiguous paper notation.

## Protocol version

| Field           | Value                     |
|-----------------|---------------------------|
| Profile name    | `pbsch-v1-secp256k1`      |
| Based on        | 2025-1992 Figures 4 (PBSch) and 10 (RPBSch) |
| Curve           | secp256k1                 |
| Schnorr variant | BIP-340 (x-only, even-y)  |
| Predicate       | `P(phi, m) = 1` (always true) |
| Message format  | Fixed 32 bytes            |
| Cmt             | Prototype Pedersen (see limitations) |

## Cryptographic parameters

### Curve constants (secp256k1)

```
p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
G = (0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,
     0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8)
a = 0
b = 7
```

### Generators for Pedersen commitments

Two independent generators are needed: `G` (curve generator, used for
BIP-340) and `H` (an unrelated generator for Pedersen hiding).

`H` is derived deterministically via:

```
H = lift_x(sha256("Zenroom/PBSch/PedersenH/v1"))
```

where `lift_x` attempts to find the even-y point. If the hash output
is not a valid x-coordinate, the hash is re-hashed iteratively until a
valid x-coordinate is found.

Protocol parameters defined here must match exactly between prover and verifier.

## Statement encoding

The RPBSch public statement consists of:

| Field     | Bytes | Description                                    |
|-----------|-------|------------------------------------------------|
| X         | 32    | Signer public key (x-only, even-y)             |
| X'        | 32    | Auxiliary signer public key (x-only, even-y)   |
| C         | 33    | Pedersen commitment to (m, ρ)                  |
| S         | 33    | Pedersen commitment to (σ₀, σ₁, νᵤ, νᵤ', νₛ)  |

### Statement serialization

The 130-byte statement is the concatenation:

```
statement = X || X' || C || S
```

### Field details

**X (32 bytes)**: x-only BIP-340 public key. If `x >= p`, the statement
is rejected before circuit evaluation.

**X' (32 bytes)**: x-only BIP-340 public key for the auxiliary key
pair. Same validity rules as X.

**C (33 bytes)**: Pedersen commitment `C = m·G + ρ·H` as a compressed
secp256k1 point (0x02/0x03 || x). No auxiliary hash proof is embedded;
the Pedersen point IS the commitment. Opening verification is
recomputing C from the claimed `(m, ρ)`.

**S (33 bytes)**: Same format as C. The tuple `(sig0, sig1, νᵤ, νᵤ', νₛ)`
is serialized and hashed to a 32-byte scalar `m'`, then S commits to
`m'` under randomness `ρ`.

### Cmt prototype limitations

This prototype Cmt is NOT paper-level extractable Cmt. The Fischlin-style
opening proof is deferred. The Pedersen point alone does not provide
straight-line extractability. See `pbsch-verification-matrix.md` for the
security implications.

### Cmt proof-equivalence boundary

The paper states `C = Cmt.Com(pp, (m, α, β); ρ)` where `Cmt` is
straight-line extractable. In this prototype:

1. **Outside the circuit**: The protocol parser verifies that `C` is a
   valid compressed secp256k1 point. If `C_x >= p` or the point is not
   on the curve, the statement is rejected.
2. **Inside the circuit**: The RPBSch circuit checks the Pedersen
   equation `C = m·G + ρ·H` for the claimed opening `(m, ρ)`.

This decomposition is **weaker** than paper-level `Cmt`. An adversary
who can create a Pedersen commitment that passes point-validity checks
but has a different opening structure could potentially break
extractability. The upgrade path is replacing the point-only
verification with a Fischlin-style opening proof.

## Witness encoding

### Branch 1 witness (honest user)

| Field | Range        | Description                              |
|-------|-------------|------------------------------------------|
| R     | 32-byte x   | Signer nonce (x-only, even-y)            |
| R'_x  | 32-byte x   | Blinded nonce x-coordinate               |
| R'_y_parity | 1 bit   | Even-y parity of R'                      |
| α     | [0, n)      | Blinding scalar                          |
| β     | [0, n)      | Blinding scalar                          |
| ρ     | 32 bytes    | Cmt.Challenge randomness                 |
| c     | [0, n)      | Auxiliary Schnorr challenge              |
| m     | 32 bytes    | Message                                  |

### Branch 2 witness (trapdoor)

| Field  | Range        | Description                              |
|--------|-------------|------------------------------------------|
| σ₀     | 64 bytes    | BIP-340 signature (Rₓ || s)              |
| σ₁     | 64 bytes    | BIP-340 signature (Rₓ || s)              |
| νᵤ     | 32 bytes    | Nonce for σ₀ (challenge-binding)         |
| νᵤ'    | 32 bytes    | Nonce for σ₁ (must differ from νᵤ)       |
| νₛ     | 32 bytes    | Message for both signatures              |

### Witness serialization

Witnesses are serialized by the RPBSch witness generator as a dense
array of 32-byte field elements. Each scalar is padded to 32 bytes
big-endian. Points use x-only encoding (32 bytes).

## BIP-340 details

### x-only public key

A BIP-340 public key is a 32-byte x-coordinate `x` such that:
- `x < p` (the field size) 
- The point `(x, y)` is on the curve with `y` even

`lift_x(x)` returns the unique even-y point, or fails if `x >= p` or
the point is not on the curve. The even-y convention means the public
key byte string represents the unique point with even y-coordinate.

### Signature equation

The BIP-340 verification equation (with implicit `y` even):

```
s·G = R  +  e·P
```

Where:
- `R` is the nonce point (even y, x-coordinate from signature)
- `P` is the public key (even y)
- `e = int(sha256(sha256("BIP0340/challenge") || sha256("BIP0340/challenge") || R_x || P_x || msg)) mod n`
- `s` is the signature scalar

### Signature format

| Offset | Size | Field     |
|--------|------|-----------|
| 0      | 32   | R_x       |
| 32     | 32   | s (scalar)|

## PBSch protocol messages

Protocol message format between User and Signer. All messages are
serialized as concatenated byte fields.

### Sign0 → User0: R

```
R = R_x (32 bytes)
```

Where `R = r·G` with fresh random `r`, and `R_x` is the x-only
serialization with even y.

### User1 → Sign1: R'

```
R' = R_x' (32 bytes)
```

Where `R' = R + α·G + β·X`, and `R_x'` is x-only with even y. If `R'`
happens to have odd y, the User retries with new `α`.

### Sign2 → User2: c

```
c = c_scalar (32 bytes)
```

Where `c = Hq(R'_x, X_x, m) + β mod n`, with `Hq(x, pk, msg)` being
the BIP-340 challenge hash.

### User3: Output signature

```
σ = R_x (32 bytes) || s (32 bytes)
```

Where `s = c + α mod n`. This is a valid BIP-340 signature under `X`
on message `m`.

## Verification (native)

The native verification path (outside the circuit) checks:

1. `σ` is a valid BIP-340 signature under key `X` on message `m`
2. `R = r·G` implies `s·G = R + c·G = ...` the BIP-340 equation holds

## Circuit verification (RPBSch)

The RPBSch circuit proves knowledge of either:

**Branch 1** (honest): `(R, α, β, ρ, m)` such that:
- `R' = R + α·G + β·X`
- R' has even y
- `c = Hq(R'_x, X_x, m) + β mod n`
- C opens to (m, α, β) under ρ

**Branch 2** (trapdoor): `(σ₀, σ₁, νᵤ, νᵤ', νₛ)` such that:
- `νᵤ ≠ νᵤ'`
- S opens to (σ₀, σ₁, νᵤ, νᵤ', νₛ)
- σ₀ is a valid BIP-340 signature under X' on message (νₛ, νᵤ)
- σ₁ is a valid BIP-340 signature under X' on message (νₛ, νᵤ')

The current native v1 composition uses a private selector and a fixed two-slot
proof shape. The circuit muxes the selected branch values into the audited
SHA/BIP340/Pedersen gadgets, so inactive branch-specific padding is present for
constant shape but is not required to satisfy the unselected branch relation.

## Limitations (prototype)

This v1 profile has the following known limitations:

1. **Cmt is a prototype**: The commitment uses a simple hash-based
   opening proof instead of a Fischlin-style extractable commitment.
   See `pbsch-verification-matrix.md` for the security implications.

2. **P(φ, m) = 1 only**: No custom predicates are supported.

3. **Fixed 32-byte messages**: Messages shorter than 32 bytes must be
   zero-padded; longer messages are not supported.

4. **No Bitcoin transaction binding**: This profile does not include
   Bitcoin sighash or transaction serialization.

5. **Fischlin deferred**: The full Fischlin extractable-Cmt is
   deferred to a future profile (`pbsch-v2`).

6. **Cmt is not paper-exact yet**: The checked RPBSch `LZK0` body now uses a
   private OR selector, but the commitment profile is still Pedersen-backed
   `CMT1`, not the final straight-line extractable Cmt profile.
