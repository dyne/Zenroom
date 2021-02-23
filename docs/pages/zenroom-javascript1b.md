# Make 💏 with Zencode and Javascript: use Zenroom in node.js

This article is part of a series of tutorials about interacting with Zenroom VM inside the Javascript/Typescript messy world. This is the first entry and at the end of the article you should be able to implement your own encryption library with Elliptic-curve Diffie–Hellman.

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).

## 📑 Some RTFM and resources

So first things first, let’s start by where to look for good information about Zenroom (docs that are continuously under enhancement and update).

- [https://dev.zenroom.org](https://dev.zenroom.org) this is the main source of technical documentation
- [https://zenroom.org](https://zenroom.org) here you find more informative documentation and all the products related to the main project
- [https://apiroom.net](https://apiroom.net) a very useful playground to try online your scripts
- 
## 🌐 How a VM could live in a browser?

So basically Zenroom is a virtual machine that is mostly written in C and high-level languages and has no access to I/O and no access to networking, this is the reason that makes it so portable.


In the past years we got a huge effort from nice projects to transpile native code to Javascript, we are talking about projects like [emscripten](https://emscripten.org/), [WebAssembly](https://webassembly.org/) and [asm.js](http://asmjs.org/)


This is exactly what we used to create a WASM (WebAssembly) build by using the Emscripten toolkit, that behaves in a good manner with the JS world.

## 💻 Let’s get our hands dirty

So let’s start by our first hello world example in node.js I’m familiar with yarn so I’ll use that but if you prefer you can use `npm `


```bash
mkdir hello-world-zencode
cd !$
yarn init
yarn add zenroom
```


The previous commands create a folder and a js project and will add zenroom javascript wrapper as a dependency. The wrapper is a very simple utility around the pure emscripten build.


Next create a `index.js` with the following content

```javascript
const { zencode_exec } = require('zenroom')

const smartContract = `Given that I have a 'string' named 'hello'
                       Then print all data as 'string'`
const data = JSON.stringify({ hello: 'world!' })
const conf = 'memmanager=lw'

zencode_exec(smartContract, { data, conf }).then(({ result }) => {
  console.log(result) // {"hello":"world!"}
})
```

run it with: 

```bash
node index.js
```

Yay, 🥳 we just run our hello world in node.js

Let's go through lines; In first line we import the zencode_exec function from the zenroom package. Two major functions are exposed:

 - **zencode_exec** to execute Zencode (DSL for smart contracts that reads like English).
 - **zenroom_exec** to execute our special flavor of Lua enhanced with Zenroom’s [special effects](./lua).

Before you 🤬 on me for the underscore casing, this was a though decision but is on purpose to keep the naming consistent across all of our bindings.

**zencode_exec** is an asynchronous function, means return a Promise (more on promises [here](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises)) and accepts two parameters:

- the smart contract, mandatory, in form of string
- an optional object literal that can contain {data, keys, conf} in brief data and keys is how you pass data to your smart contract, and conf is a configuration string that changes the Zenroom VM behaviour. All of them should be passed in form of string… this means that even if you need to pass a JSON you need to JSON.stringify it before, as we did on line 5 of the previous snippet

**zencode_exec** resolves the promise with an object that contains two attributes:

- result this is the output of the execution of the smart contract in form of string
- logs the logs of the virtual machine… if there are some errors — warning they are printed here

In the previous snippet we just passed the *result* by using [Object destructuring](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#object_destructuring) on line 8


## 🔏 Let’s complicate it a bit! Let’s encrypt!
Now that we saw how the basics works, let’s proceed with some sophistication: let's encrypt a message with a password/secret with ECDH **(Elliptic-curve Diffie–Hellman)** on the elliptic curve SECP256K1 sounds complicated, isn't it?


```javascript
const { zencode_exec } = require('zenroom')

const smartContract = `Scenario 'ecdh': Encrypt a message with a password/secret 
                        Given that I have a 'string' named 'password' 
                          and that I have a 'string' named 'message' 
                        When I encrypt the secret message 'message' with 'password' 
                        Then print the 'secret message'`
const data = JSON.stringify({
  message: 'Dear Bob, your name is too short, goodbye - Alice.',
})
const keys = JSON.stringify({ password: 'myVerySecretPassword' })
const conf = 'memmanager=lw'

zencode_exec(smartContract, { data, keys, conf }).then(({ result }) => {
  console.log(result)
})
```

Et voila 🤯 as easy as the hello the world… if you run it you'll get something like:

```json
{
   "secret_message": {
      "checksum": "507cpFVzIjwFXhvieeXq/A==",
      "header": "QSB2ZXJ5IGltcG9ydGFudCBzZWNyZXQ=",
      "iv": "vd7/4KIb3ubXElbGRRTyM4qTVtROkcacnaOeN5Pa0Vo=",
      "text": "HGsZTlnigSv6zlDpc1bZs40QMWbJxYf9CgjYLEpYI+t62WA6j+bPhfoUxxbnWkYVjX4="
   }
}
```

## 🔏 Next step: decryption 

But being able to encrypt without having a decrypt function is useless, so  let's tidy up a bit and create our own encryption/decryption library with some javascript fun: 

```javascript
const { zencode_exec } = require("zenroom");

const conf = "memmanager=lw";

const encrypt = async (message, password) => {
  const keys = JSON.stringify({ password });
  const data = JSON.stringify({ message });
  const contract = `Scenario 'ecdh': Encrypt a message with a password/secret 
    Given that I have a 'string' named 'password' 
    and that I have a 'string' named 'message' 
    When I encrypt the secret message 'message' with 'password' 
    Then print the 'secret message'`;
  const { result } = await zencode_exec(contract, { data, keys, conf });
  return result;
};

const decrypt = async (encryptedMessage, password) => {
  const keys = JSON.stringify({ password });
  const data = encryptedMessage;
  const contract = `Scenario 'ecdh': Decrypt the message with the password 
    Given that I have a valid 'secret message' 
    Given that I have a 'string' named 'password' 
    When I decrypt the text of 'secret message' with 'password' 
    Then print the 'text' as 'string'`;
  const { result } = await zencode_exec(contract, { data, keys, conf });
  const decrypted = JSON.parse(result).text;
  return decrypted;
};

const message = "Dear Bob, your name is too short, goodbye - Alice.";
const password = 0xBADA55;
(async () => {
  // encrypt the message
  const encrypted = await encrypt(message, password);
  console.log(encrypted); // some crypto magic material
  const decrypted = await decrypt(encrypted, password);
  // let's verify that the original message is the same as the decrypted one
  if (message === decrypted) {
    console.log("🎉 🎉 🎉 ");
    console.log("Yeah! It works");
    console.log("🎉 🎉 🎉 ");
  }
})();
```

There you go encryption — decryption with password — secret over Elliptic-curve Diffie–Hellman on curve SECP256K1 in 30 super easy lines of code.

The code used in this article is available on [Github](https://github.com/dyne/blog-code-samples).

