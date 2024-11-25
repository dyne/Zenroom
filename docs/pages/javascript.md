# Use Zenroom in JavaScript

<p align="center">
 <a href="https://dev.zenroom.org/">
    <img src="https://raw.githubusercontent.com/DECODEproject/Zenroom/master/docs/_media/images/zenroom_logo.png" height="140" alt="Zenroom">
  </a>
</p>

<h1 align="center">
  Zenroom js bindings 🧰</br>
  <sub>Zenroom js bindings provides a javascript wrapper of <a href="https://github.com/dyne/Zenroom">Zenroom</a>, a secure and small virtual machine for crypto language processing.</sub>
</h1>

<p align="center">
  <a href="https://badge.fury.io/js/zenroom">
    <img alt="npm" src="https://img.shields.io/npm/v/zenroom.svg">
  </a>
  <a href="https://dyne.org">
    <img src="https://img.shields.io/badge/%3C%2F%3E%20with%20%E2%9D%A4%20by-Dyne.org-blue.svg" alt="Dyne.org">
  </a>
</p>

<br><br>


## 💾 Install

Stable releases are published on https://www.npmjs.com/package/zenroom that
have a slow pace release schedule that you can install with

<!-- tabs:start -->

### ** npm **

```bash
npm install zenroom
```

### ** yarn **

```bash
yarn add zenroom
```

### ** pnpm **

```bash
pnpm add zenroom
```

<!-- tabs:end -->

* * *

## 🎮 Usage

The binding consists of two main functions:

- **zencode_exec** to execute [Zencode](https://dev.zenroom.org/#/pages/zencode-intro?id=smart-contracts-in-human-language). To learn more about zencode syntax look [here](https://dev.zenroom.org/#/pages/zencode-cookbook-intro)
- **zenroom_exec** to execute our special flavor of Lua enhanced with Zenroom's [special effects](https://dev.zenroom.org/#/pages/lua)

This function accepts a mandatory **SCRIPT** to be executed and some optional parameters:
  * DATA
  * KEYS
  * [CONF](https://dev.zenroom.org/#/pages/zenroom-config)
All in form of strings.

These functions return a [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

To start using the zenroom vm just do:

```js
import { zenroom_exec, zencode_exec, introspection } from "zenroom";
// or if you don't use >ES6
// const { zenroom_exec, zencode_exec } = require('zenroom')


// Zencode: generate a random array. This script takes no extra input

const zencodeRandom = `
  Given nothing
  When I create the array of '16' random objects of '32' bits
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
  When I encrypt the secret message 'message' with 'password'
  Then print the 'secret message'
`;

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

zencode_exec(zencode, {
  data: zenData,
  keys: zenKeys,
  conf:`debug=1`
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
  const result = await zenroom_exec(`print(DATA)`, {
    data: "Some data",
    keys: "Some other data",
    conf: `debug=0`,
  });
  console.log(result); // => Some data
} catch (e) {
  console.error(e);
}

```

Other APIs are:
* **zenroom_hash** that takes in input the hash type ("sha256" or "sha512") and an ArrayBuffer
containing the data to be hashed
* **introspect** that takes in input a zencode contract and return the data that should be present in input
to that contract
* **zencode_valid_code** that takes in input a zencode contract and throw an error in case invalid statements
are found in the contract.

## 📖 Tutorials

Here we wrote some tutorials on how to use Zenroom in the JS world
  * [Node.js](/pages/zenroom-javascript1b)
  * [Browser](/pages/zenroom-javascript2b)
  * [React](/pages/zenroom-javascript3)

For more information also see the [🌐Javascript NPM package](https://www.npmjs.com/package/zenroom).
