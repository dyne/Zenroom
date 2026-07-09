# Native Ligero Profile

This document defines the current Zenroom NIWI native proof body profile. It is
the local `LIG0` profile implemented in `lib/niwi`; it does not modify
`lib/longfellow-zk`.

The profile is intentionally minimal. It binds a relation-backed witness
tableau, a Merkle commitment to its leaves, a KLP22 Fiat-Shamir challenge
schedule, an explicit verifier-parsed `NRSP` response object, and one selected
opening leaf. Later work replaces the minimal row/query response with
polynomial Ligero response values.

## Tableau

The private witness byte string is split into 32-byte chunks. Empty witnesses
still produce one chunk. The current profile has one witness row.

Each relation-backed leaf is serialized as:

```text
TBL1 ||
  version: u32_be ||
  relation_id: u32_be ||
  statement_digest: 32 bytes ||
  row: u32_be ||
  offset: u32_be ||
  total_witness_len: u32_be ||
  chunk: 0..32 bytes
```

The `statement_digest` is `H_STMT(public_inputs)`. `relation_id` must match the
native relation selected by the `niwi_ctx_t`. The leaf digest is
`H_LEAF(serialized_leaf)`.

The proof body also carries one tableau entry for each leaf:

```text
index: u32_be ||
row: u32_be ||
offset: u32_be ||
leaf_len: u32_be ||
leaf_digest: 32 bytes
```

The `tableau_digest` is `H_EXTR(count || entries...)`, where each entry uses the
canonical serialization above.

## LIG0 Body

The native body is:

```text
LIG0 ||
  payload_size: u32_be ||
  version: u32_be ||
  protocol_id: u32_be ||
  param_id: u32_be ||
  rows: u32_be ||
  chunk_size: u32_be ||
  tableau_count: u32_be ||
  relation_id: u32_be ||
  opening_index: u32_be ||
  path_len: u32_be ||
  opening_leaf_len: u32_be ||
  tableau_digest: 32 bytes ||
  tableau_root: 32 bytes ||
  relation_digest: 32 bytes ||
  challenge1: 32 bytes ||
  response_object: 100 bytes ||
  response_digest: 32 bytes ||
  challenge2: 32 bytes ||
  opening_digest: 32 bytes ||
  final_digest: 32 bytes ||
  merkle_path: path_len * 32 bytes ||
  tableau_entries: tableau_count * 48 bytes ||
  opening_leaf: opening_leaf_len bytes
```

The current fixed values are:

```text
version = 0x00010000
protocol_id = 0
param_id = 1
rows = 1
chunk_size = 32
```

The fixed `LIG0` payload prefix is 396 bytes: ten `u32_be` words, eight 32-byte
digests, and one 100-byte `NRSP` response object. A one-leaf relation proof
therefore has payload `396 + 48 + opening_leaf_len`; a two-leaf proof has
`396 + 32 + (2 * 48) + opening_leaf_len` because the Merkle path has one digest.

## Challenges And Responses

The KLP22 schedule is:

```text
init(version=1, security=0, protocol_id=0)
bind share commitment
bind circuit_digest, statement_digest, tableau_root
derive challenge1
open share
bind response_digest
derive challenge2
```

`relation_digest` is:

```text
H_PROOF(relation_id || circuit_digest || statement_digest || tableau_digest)
```

The current `NRSP` response object is:

```text
NRSP ||
  response_version: u32_be ||
  response_count: u32_be ||
  query_count: u32_be ||
  row_count: u32_be ||
  chunk_size: u32_be ||
  query_index: u32_be ||
  row: u32_be ||
  offset: u32_be ||
  leaf_len: u32_be ||
  leaf_digest: 32 bytes ||
  eval_row: u32_be ||
  eval_start: u32_be ||
  eval_count: u32_be ||
  eval_point: u64_be ||
  eval_value: u64_be
```

The current fixed values are:

```text
response_version = 0x00010000
response_count = 1
query_count = 1
row_count = 1
chunk_size = 32
```

`query_index` is derived from `challenge1` as
`first_u32_be(challenge1) mod tableau_count`. The verifier checks that the
serialized query entry equals the corresponding tableau entry.

The minimal arithmetic field is the local prime field
`Fp`, where `p = 2^64 - 59`. A tableau coefficient is the first eight bytes of a
leaf digest interpreted as `u64_be` and reduced modulo `p`. `eval_point` is the
same reduction applied to `challenge1`. `eval_value` is the Horner evaluation of
the one-row tableau digest polynomial at `eval_point`, covering entries
`eval_start .. eval_start + eval_count - 1`. In the current profile
`eval_row = 0`, `eval_start = 0`, and `eval_count = tableau_count`.

The `response_digest` is:

```text
H_NRSP(
  relation_digest ||
  tableau_digest ||
  tableau_root ||
  challenge1 ||
  response_object
)
```

This section is still narrower than full paper Ligero. The next profile step
must generalize this local tableau-digest polynomial check to the paper's full
Ligero row/column polynomial response layout.

## Query And Opening

The selected `opening_index` is derived from `challenge2`:

```text
opening_index = first_u32_be(challenge2) mod tableau_count
```

The verifier checks all of the following:

- `relation_id` matches the active native relation.
- `relation_digest`, `challenge1`, `challenge2`, and `final_digest` recompute.
- `tableau_digest` recomputes from all tableau entries.
- the `NRSP` response object parses with non-zero `response_count` and
  `query_count`.
- `response_digest` recomputes from the parsed `NRSP` object.
- the parsed `NRSP` query entry matches the `challenge1`-derived tableau entry.
- `eval_point`, `eval_value`, and the covered range recompute from the public
  tableau leaf digests.
- `opening_index` matches the Fiat-Shamir query.
- `opening_digest` matches the selected tableau entry.
- `opening_leaf` hashes to `opening_digest`.
- `opening_leaf` decodes as `TBL1` with the same `relation_id`,
  `statement_digest`, row, offset, and length.
- the Merkle path opens `opening_digest` to `tableau_root`.

## Extraction Inputs

Extraction consumes the proof, public inputs, and observed Gamma queries. For
relation-backed proofs, production extraction must recover `TBL1` leaves by
their committed digests, reconstruct the witness bytes in row/offset order, and
run native relation evaluation before returning success.

Unchecked `TBL0` fixtures are retained only for serialization and parser tests.
They are not production proof claims.

## Longfellow Decision

No Longfellow change is needed for the current minimal native Ligero profile.
`lib/niwi/src/niwi.c` implements the local helpers
`ligero_field_add`, `ligero_field_mul`, `ligero_digest_to_field`, and
`evaluate_tableau_digest_row` over the `2^64 - 59` field. A Longfellow adapter
should only be introduced when the profile moves from this tableau-digest
polynomial check to the paper's full row/column polynomial response layout.
