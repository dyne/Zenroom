<div align="center">

# Zenroom js bindings 🧰

###  Zenroom js bindings provides a javascript wrapper of <a href="https://github.com/dyne/Zenroom">Zenroom</a>, a secure and small virtual machine for crypto language processing.

</div>

<p align="center">
 <a href="https://dev.zenroom.org/">
    <img src="https://raw.githubusercontent.com/dyne/Zenroom/master/docs/_media/images/zenroom_logo.png" height="140" alt="Zenroom">
  </a>
</p>

<p align="center">
  <a href="https://badge.fury.io/js/zenroom">
    <img alt="npm" src="https://img.shields.io/npm/v/zenroom.svg">
  </a>
  <a href="https://dyne.org">
    <img src="https://img.shields.io/badge/%3C%2F%3E%20with%20%E2%9D%A4%20by-Dyne.org-blue.svg" alt="Dyne.org">
  </a>
</p>

---
<br><br>

## 💾 Install

Stable releases are published on https://www.npmjs.com/package/zenroom that
have a slow pace release schedule that you can install with

```bash
npm install zenroom
# or using yarn
yarn add zenroom
# or using pnpm
pnpm add zenroom
# or using bun
bun add zenroom
```

---

## 🎮 Usage

The bindings are composed of two main functions:

- **zencode_exec** to execute [Zencode](https://dev.zenroom.org/#/pages/zencode-intro?id=smart-contracts-in-human-language). To learn more about zencode syntax look [here](https://dev.zenroom.org/#/pages/zencode-cookbook-intro)
- **zenroom_exec** to execute our special flavor of Lua enhanced with Zenroom's [special effects](https://dev.zenroom.org/#/pages/lua)

Both of this functions accepts a mandatory **SCRIPT** to be executed and some optional parameters:

- DATA
- KEYS
- EXTRA
- CONTEXT
- [CONF](https://dev.zenroom.org/#/pages/zenroom-config)

**All in form of strings.** This means that if you want to pass a JSON you have to `JSON.stringify` it before.

Both functions return a [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

To start using the zenroom vm just

```js
import { zenroom_exec, zencode_exec, introspection } from "zenroom";
// or if you don't use >ES6
// const { zenroom_exec, zencode_exec } = require('zenroom')

// Zencode: generate a random array. This script takes no extra input

const zencodeRandom = `
  Given nothing
  When I create the random array with '16' elements each of '32' bits
  Then print all data
`;

zencode_exec(zencodeRandom)
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });

// Zencode: encrypt a message.
// This script takes the options' object as the second parameter: you can include data and/or keys as input.
// The "config" parameter is also optional.

const zencodeEncrypt = `
  Scenario 'ecdh': Encrypt a message with the password
  Given that I have a 'string' named 'password'
  Given that I have a 'string' named 'message'
  Given that I have a 'string' named 'extra'
  When I append 'extra' to 'message'
  When I encrypt the secret message 'message' with 'password'
  Then print the 'secret message'`;

const zenKeys = `
  {
    "password": "myVerySecretPassword"
  }
`;

const zenData = `
  {
      "message": "HELLO WORLD"
  }
`;

const zenExtra = `
  {
      "extra": "!!!"
  }
`;

zencode_exec(zencodeEncrypt, {
  data: zenData,
  keys: zenKeys,
  extra: zenExtra,
  conf: `debug=1`,
})
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });

// Lua Hello World!

const lua = `print("Hello World!")`;
zenroom_exec(lua)
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });

// to pass the optional parameters you pass an object literal eg.

try {
  const result = await zenroom_exec(`print(DATA..KEYS..EXTRA..CONTEXT)`, {
    data: "Hello ",
    keys: "from ",
    extra: "Zenroom ",
    context: "developers",
    conf: `debug=1`,
  });
  console.log(result); // => Hello from Zenroom developers
} catch (e) {
  console.error(e);
}

// code inspection is done via the `zencode_valid_input` primitive function or by a utility `introspect`

const introspection = await introspection(
  `Given I have a 'string' named 'missing'
  Then print the codec`
);
console.log(introspection); // => an object described as https://dev.zenroom.org/#/pages/how-to-embed?id=input-validation
```

## 🔐 Direct primitives (hex API)

Zenroom also exports direct cryptographic primitives that work
without writing Lua or Zencode scripts.  All binary inputs and
outputs use lowercase hex strings.

### One-shot hash

```js
import { hashHex, utf8ToHex } from "zenroom";

const { result: sha256 } = await hashHex("sha256", utf8ToHex("hello"));
console.log(sha256);
// => 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

Supported algorithms: `sha256`, `sha384`, `sha512`, `sha3_256`,
`sha3_512`, `shake256`, `keccak256`, `ripemd160`.

### PBKDF2 key derivation

```js
import { pbkdf2Hex } from "zenroom";

const { result: key } = await pbkdf2Hex(
  "sha256",
  utf8ToHex("password"),
  utf8ToHex("salt"),
  4096,
  32
);
// key is a 64-char hex string (32 bytes)
```

### EdDSA signatures

```js
import { signKeygenHex, signPubgenHex, signCreateHex, signVerifyHex } from "zenroom";

// Generate a secret key (optionally pass a hex rngseed)
const { result: sk } = await signKeygenHex("eddsa");

// Derive the public key
const { result: pk } = await signPubgenHex("eddsa", sk);

// Sign a hex-encoded message
const { result: sig } = await signCreateHex("eddsa", sk, utf8ToHex("hello"));

// Verify the signature
const { result: ok } = await signVerifyHex("eddsa", pk, utf8ToHex("hello"), sig);
console.log(ok); // => 1
```

### Merkle tree recipes (Lua-backed)

```js
import { merkleRootHex } from "zenroom";

const { result: root } = await merkleRootHex(
  ["0101010101010101010101010101010101010101010101010101010101010101",
   "0202020202020202020202020202020202020202020202020202020202020202"],
  "sha256"
);
console.log(root); // hex-encoded merkle root
```

### Named recipes

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

### Encoding helpers

```js
import { bytesToHex, hexToBytes, utf8ToHex, hexToUtf8 } from "zenroom";

const hex = utf8ToHex("hello");          // "68656c6c6f"
const str = hexToUtf8("68656c6c6f");     // "hello"

const bytes = hexToBytes("deadbeef");    // Uint8Array [0xde, 0xad, 0xbe, 0xef]
const back  = bytesToHex(bytes);         // "deadbeef"
```

### Streaming hash (legacy API)

```js
import { zenroom_hash } from "zenroom";

const { result: digest } = await zenroom_hash("sha256", "hello world");
// digest is base64-encoded (legacy format)
```

For large inputs or one-shot hashing with hex output, prefer
`hashHex` which handles chunking internally and returns lowercase hex.
```

## 😍 Acknowledgements

Copyright (C) 2018-2026 by [Dyne.org](https://www.dyne.org) foundation, Amsterdam

Designed, written and maintained by Puria Nafisi Azizi.

<img src="https://upload.wikimedia.org/wikipedia/commons/8/84/European_Commission.svg" class="pic" alt="Project funded by the European Commission">

This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

---

## 👤 Contributing

Please first take a look at the [Dyne.org - Contributor License Agreement](CONTRIBUTING.md) then

1.  [FORK IT](https://github.com/puria/zenroomjs/fork)
2.  Create your feature branch `git checkout -b feature/branch`
3.  Commit your changes `git commit -am 'Add some fooBar'`
4.  Push to the branch `git push origin feature/branch`
5.  Create a new Pull Request
6.  Thank you

---

## 💼 License

      Zenroom js - a javascript wrapper of zenroom
      Copyright (c) 2018-2026 Dyne.org foundation, Amsterdam

      This program is free software: you can redistribute it and/or modify
      it under the terms of the GNU Affero General Public License as
      published by the Free Software Foundation, either version 3 of the
      License, or (at your option) any later version.

      This program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU Affero General Public License for more details.

      You should have received a copy of the GNU Affero General Public License
      along with this program.  If not, see <http://www.gnu.org/licenses/>.
