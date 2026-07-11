# lib/niwi

`lib/niwi` contains the native NIWI and relation-backed proof code used by
Zenroom. The current production path is relation-backed: Lua builds typed
statements and witnesses, native code evaluates the selected relation, and
accepted proofs carry checked Ligero/Longfellow proof bodies where available.

## PBSch Cmt profiles

PBSch/RPBSch uses a Pedersen commitment over secp256k1:

```
C = m * G + rho * H
```

`G` is the secp256k1 generator. `H` is derived deterministically as the even-y
lift of `SHA-256("Zenroom/PBSch/PedersenH/v1" || iteration)`.

Lua PBSch/RPBSch code must treat secp256k1 scalar arithmetic as part of the
`SECP` API. Use `SECP.bip340_scalar_add`, `SECP.bip340_scalar_mul`,
`SECP.bip340_scalar_negate`, and `SECP.bip340_scalar_div` for scalar field
operations. Do not use Lua `BIG` for secp256k1 scalar algebra: in this runtime
`BIG` is a big-integer class tied to the BLS381 configuration, not the
secp256k1 field API.

The implementation keeps three versioned Cmt profiles:

| Profile | Status | Purpose | Default use |
| --- | --- | --- | --- |
| `CMT1` | compatibility/test | Private opening envelope `CMT1 || ck || message || rho`. It is straight-line extractable only from opened proof material already carried by the witness or test Gamma. | Unit tests and current native witness extraction internals. Not a paper-level public Cmt. |
| `CMT2` | compatibility/debug | Public Fiat-Shamir proof of a Pedersen opening, `CMT2 || ck || A || e || z_m || z_r`. It proves knowledge of an opening but is not the Fischlin/Pas straight-line extractable proof required by 2025-1992. | Debugging and regression tests. Do not use as the production RPBSch Cmt default once CMT3 is available. |
| `CMT3` | paper-level default | Pedersen commitment `c'` plus a Fischlin05 straight-line extractable proof of knowledge for the Pedersen opening. Initial parameters are `b=9`, `t=12`, `r=10`, `S=10`, matching the concrete profile discussed in `niwi/Fischl05b.pdf`. | Best paper-level default for PBSch/RPBSch production helpers. |

The active paper-level default should be `CMT3` whenever the API can carry a
public Cmt proof object. Keep `CMT1` and `CMT2` available for compatibility and
regression coverage, but do not claim paper-exact RPBSch for paths that only
use those profiles.

## How to switch profiles

Lua callers should use the profile-specific helpers in `src/lua/crypto_pbsch.lua`:

- `pbsch.cmt_commit`, `pbsch.cmt_verify`, and `pbsch.cmt_extract` operate on
  `CMT1` private openings.
- `pbsch.cmt2_prove`, `pbsch.cmt2_verify`, and `pbsch.cmt2_commit` operate on
  `CMT2` public Fiat-Shamir opening proofs.
- `pbsch.cmt3_prove`, `pbsch.cmt3_verify`, and `pbsch.cmt3_commit` operate on
  `CMT3` Fischlin05 opening proofs.

RPBSch production Lua helpers should validate the full Cmt proof object before
calling native NIWI proof generation. The native RPBSch Longfellow relation
continues to prove the algebraic Pedersen opening equations for the compressed
commitment points `C` and `S`.

The production RPBSch boundary is therefore the Lua relation-backed path, not
the low-level native C helpers by themselves. Lua must carry and validate the
`RPB2` envelope:

```
RPB2 || len(core_statement) || core_statement ||
        len(C_proof) || C_proof ||
        len(S_proof) || S_proof
```

before calling native relation proving or verification. Direct native calls are
building blocks for the relation and tests. The seeded native CMT3 prover is the
fast production-friendly generator for deterministic fixtures and future API
work; native CMT3 verification is currently only a fast accept path for native
seeded proofs, with Lua verification remaining the canonical verifier until
native verifier parity is proven against all Lua-generated CMT3 proofs.

Changing CMT3 parameters changes the proof system and must use a new profile id.
Do not silently change `b`, `t`, `r`, or `S` under
`pbsch-cmt-pedersen-fischlin05-v1`.

## Core relation entry points

- BIP340 relation: `lib/niwi/src/relations/bip340_relation.cc`
- Generic zkcc P-256 relation: `lib/niwi/src/relations/zkcc_p256_relation.cc`
- RPBSch relation: `lib/niwi/src/relations/rpbsch_relation.cc`
- RPBSch Longfellow proof body:
  `lib/niwi/src/relations/rpbsch_ligero_relation.cc`
- PBSch Pedersen primitive: `lib/niwi/src/pbsch_commitment.c`

## Main tests

Run focused Cmt/RPBSch checks with:

```sh
./zenroom test/lua/pbsch_cmt.lua
./zenroom test/lua/pedersen.lua
./zenroom test/lua/rpbsch_niwi.lua
make -C lib/niwi test
```
