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

```bash
yarn add zenroom
# or if you use npm
npm install zenroom
```


For more cutting edge functionalities there is a pre-release aligned with
the last zenroom commit, automatically published, that you can install with

```bash
yarn add zenroom@next
# or if you use npm
npm install zenroom@next
```

* * *

## 🎮 Usage

The bindings are composed of two main functions:

 * **zencode_exec** to execute [Zencode](https://dev.zenroom.org/#/pages/zencode-intro?id=smart-contracts-in-human-language). To learn more about zencode syntax look [here](https://dev.zenroom.org/#/pages/zencode-cookbook-intro)
  * **zenroom_exec** to execute our special flavor of Lua enhanced with Zenroom's [special effects](https://dev.zenroom.org/#/pages/lua) 


Both of this functions accepts a mandatory **SCRIPT** to be executed and some optional parameters:
  * DATA
  * KEYS
  * [CONF](https://dev.zenroom.org/#/pages/zenroom-config)
All in form of strings.

Both functions return a [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

To start using the zenroom vm just

```js
import { zenroom_exec, zencode_exec } from 'zenroom'
// or if you don't use >ES6
// const { zenroom_exec, zencode_exec } = require('zenroom')


// Zencode: generate a random array. This script takes no extra input

const zencodeRandom = `
	Given nothing
	When I create the array of '16' random objects of '32' bits
    	Then print all data`
	
zencode_exec(zencodeRandom)
	.then((result) => {
		console.log(result);
	})
	.catch((error) => {
		throw new Error(error);
	});


// Zencode: encrypt a message. 
// This script takes the options' object as the second parameter: you can include data and/or keys as input.
// The "config" parameter is also optional.

const zencodeEncrypt = `
	Scenario 'ecdh': Encrypt a message with the password 
	Given that I have a 'string' named 'password' 
	Given that I have a 'string' named 'message' 
	When I encrypt the secret message 'message' with 'password' 
	Then print the 'secret message'`
	
const zenKeys = `
	{
		"password": "myVerySecretPassword"
	}
`

const zenData = `
	{
			"message": "HELLO WORLD"
	}
`
	
zencode_exec(zencode, {data: zenData, keys: zenKeys, conf:`color=0, debug=0`})
	.then((result) => {
		console.log(result);
	})
	.catch((error) => {
		throw new Error(error);
	});



// Lua Hello World!

const lua = `print("Hello World!")`
zenroom_exec(lua)
	.then((result) => {
		console.log(result);
	})
	.catch((error) => {
		throw new Error(error);
	});	



// to pass the optional parameters you pass an object literal eg.


try {
  const result = await zenroom_exec(`print(DATA)`, {data: "Some data", keys: "Some other data", conf:`color=0, debug=0`});
  console.log(result); // => Some data
} catch (e) {
  throw new Error(e)
}


```


## 😍 Acknowledgements

Copyright (C) 2018-2020 by [Dyne.org](https://www.dyne.org) foundation, Amsterdam

Designed, written and maintained by Puria Nafisi Azizi.

<img src="https://upload.wikimedia.org/wikipedia/commons/8/84/European_Commission.svg" class="pic" alt="Project funded by the European Commission">

This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

* * *

## 👤 Contributing

Please first take a look at the [Dyne.org - Contributor License Agreement](CONTRIBUTING.md) then

1.  [FORK IT](https://github.com/puria/zenroomjs/fork)
2.  Create your feature branch `git checkout -b feature/branch`
3.  Commit your changes `git commit -am 'Add some fooBar'`
4.  Push to the branch `git push origin feature/branch`
5.  Create a new Pull Request
6.  Thank you

* * *

## 💼 License

      Zenroom js - a javascript wrapper of zenroom
      Copyright (c) 2018-2020 Dyne.org foundation, Amsterdam

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
