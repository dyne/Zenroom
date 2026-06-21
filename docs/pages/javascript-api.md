# JavaScript API – Direct Calls

The `zenroom` npm package exposes fast cryptographic primitives
that work without writing Lua or Zencode scripts.  Import the
functions you need:

```js
import { hashHex, signKeygenHex, merkleRootHex } from "zenroom";
```

Every function returns a `Promise<{ result: string, logs: string }>`.
On success, `result` contains the output.  On failure the promise
rejects with the same shape — inspect `logs` for error details.

---

## Hash

### One-shot hex hash

Hash a hex-encoded message in one call.  The digest is lowercase hex.

```js
import { hashHex, utf8ToHex } from "zenroom";

const { result } = await hashHex("sha256", utf8ToHex("hello"));
console.log(result);
// => 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

`hashHex(algorithm, messageHex)`

| arg | type | note |
|---|---|---|
| `algorithm` | `string` | one of: `sha256` `sha384` `sha512` `sha3_256` `sha3_512` `shake256` `keccak256` `ripemd160` |
| `messageHex` | `string` | lowercase hex (even length) |

### PBKDF2 key derivation

```js
import { pbkdf2Hex, utf8ToHex } from "zenroom";

const { result: key } = await pbkdf2Hex(
  "sha256",
  utf8ToHex("password"),
  utf8ToHex("salt"),
  4096,   // iterations
  32      // output length in bytes
);
// key is a 64-char hex string (32 bytes)
```

`pbkdf2Hex(algorithm, passwordHex, saltHex, iterations, keylen)`

| arg | type | note |
|---|---|---|
| `algorithm` | `string` | `sha256` or `sha512` |
| `passwordHex` | `string` | lowercase hex |
| `saltHex` | `string` | lowercase hex |
| `iterations` | `number` | > 0 |
| `keylen` | `number` | output bytes, > 0 |

### Streaming hash (legacy)

For large inputs or compatibility with existing code:

```js
import { zenroom_hash } from "zenroom";

const { result: b64 } = await zenroom_hash("sha256", "hello world");
// result is base64-encoded (legacy format)
```

---

## Signatures

All signature functions share the same interface.  The first argument
is the algorithm name, followed by hex-encoded keys, messages, and
signatures.

| algorithm | curve / standard | key (hex) | pk (hex) | sig (hex) |
|---|---|---|---|---|
| `eddsa` | Ed25519 | 64 chars | 64 chars | 128 chars |
| `p256` | P-256 / secp256r1 ECDSA | 64 chars | 128 chars | 128 chars |
| `mldsa44` | ML-DSA-44 FIPS 204 | 5120 chars | 2624 chars | 4840 chars |

### Key generation

```js
import { signKeygenHex } from "zenroom";

// Without seed (uses internal PRNG)
const { result: sk } = await signKeygenHex("eddsa");

// With a deterministic hex seed (must be 64 bytes = 128 hex chars)
const { result: sk2 } = await signKeygenHex("eddsa", "0".repeat(128));
```

`signKeygenHex(algorithm, rngseed?)`

| arg | type | note |
|---|---|---|
| `algorithm` | `string` | `eddsa` `p256` `mldsa44` |
| `rngseed` | `string?` | optional 128-char hex seed for deterministic keygen |

### Public key derivation

```js
const { result: pk } = await signPubgenHex("eddsa", sk);
```

`signPubgenHex(algorithm, secretKeyHex)`

### Sign

```js
const msgHex = utf8ToHex("hello");
const { result: sig } = await signCreateHex("eddsa", sk, msgHex);
```

`signCreateHex(algorithm, secretKeyHex, messageHex)`

### Verify

```js
const { result: ok } = await signVerifyHex("eddsa", pk, msgHex, sig);
console.log(ok); // "1" (valid) or "0" (invalid)
```

`signVerifyHex(algorithm, publicKeyHex, messageHex, signatureHex)`

### Full EdDSA example

```js
import { signKeygenHex, signPubgenHex, signCreateHex, signVerifyHex, utf8ToHex } from "zenroom";

const { result: sk } = await signKeygenHex("eddsa");
const { result: pk } = await signPubgenHex("eddsa", sk);
const { result: sig } = await signCreateHex("eddsa", sk, utf8ToHex("sign this"));
const { result: ok } = await signVerifyHex("eddsa", pk, utf8ToHex("sign this"), sig);
console.log(ok); // "1"
```

---

## Merkle Trees

Merkle operations are Lua-backed and don't require writing scripts.

### Root

```js
import { merkleRootHex } from "zenroom";

const { result: root } = await merkleRootHex(
  ["0101010101010101010101010101010101010101010101010101010101010101",
   "0202020202020202020202020202020202020202020202020202020202020202"],
  "sha256"   // optional, defaults to "sha256"
);
// root is a 64-char hex string
```

### Proof verification

```js
import { merkleProofVerifyHex } from "zenroom";

const { result: ok } = await merkleProofVerifyHex(
  proofHexArray,    // sibling hashes
  0,                // leaf position
  rootHex,          // trusted root
  4,                // total leaf count
  "sha256"          // optional
);
console.log(ok); // "1" or "0"
```

---

## Named Recipes

Run higher-level Lua-backed operations via a short recipe name with
JSON input.  Every binary value inside the JSON must be hex.

```js
import { recipeExec } from "zenroom";

const { result } = await recipeExec("merkle.root", JSON.stringify({
  hash: "sha256",
  leaves: [
    "0101010101010101010101010101010101010101010101010101010101010101",
    "0202020202020202020202020202020202020202020202020202020202020202",
  ],
}));
const { root } = JSON.parse(result);
```

Available recipes: `"merkle.root"`, `"merkle.verify_proof"`.

---

## Encoding Helpers

Small utilities to convert between hex, UTF-8, and `Uint8Array` —
no WASM call needed.

```js
import { bytesToHex, hexToBytes, utf8ToHex, hexToUtf8 } from "zenroom";

utf8ToHex("hello");          // "68656c6c6f"
hexToUtf8("68656c6c6f");     // "hello"

hexToBytes("deadbeef");      // Uint8Array [0xde, 0xad, 0xbe, 0xef]
bytesToHex(new Uint8Array([0xde, 0xad, 0xbe, 0xef])); // "deadbeef"
```

---

## Executing Zencode and Lua Scripts

For full VM-backed workflows use the same functions documented in
[Embedding Zenroom](how-to-embed.md):

```js
import { zencode_exec, zenroom_exec } from "zenroom";

const { result } = await zencode_exec(`
  Given nothing
  When I create the random array with '4' elements each of '32' bits
  Then print all data
`);

// The legacy introspection helper:
import { introspect } from "zenroom";
const codec = await introspect(`Given I have a 'string' named 'msg'`);
```

---

## Error Handling

All functions throw on failure.  The error object has `result` and
`logs` properties just like the success response:

```js
try {
  await hashHex("unknown", "aa");
} catch ({ logs }) {
  console.error(logs);
}
```
