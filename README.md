# Zenroom - DECODE project

[![software by Dyne.org](https://www.dyne.org/wp-content/uploads/2015/12/software_by_dyne.png)](http://www.dyne.org)

[![Build Status](https://travis-ci.org/DECODEproject/zenroom.svg?branch=master)](https://travis-ci.org/DECODEproject/zenroom)

Zenroom is a small and portable virtual machine for cryptographic operations running on Windows, OSX, GNU/Linux, BSD as well Javascript and Webassembly inside modern browsers.

Its binaries are smaller than 1MB and ready to use on many platforms. Latest experimental test builds:
- [Javascript](https://sdk.dyne.org:4443/job/zenroom-js/lastSuccessfulBuild/artifact/src/zenroom.js)
- [X86-64bit](https://sdk.dyne.org:4443/job/zenroom-static-amd64/lastSuccessfulBuild/artifact/src/zenroom-static)
- [ARM-HF](https://sdk.dyne.org:4443/job/zenroom-static-armhf/lastSuccessfulBuild/artifact/src/zenroom-static)

Quick links:
- [Zenroom API documentation](https://zenroom.dyne.org/api) (work in progress)
- [Zenroom Cryptolang Whitepaper](https://zenroom.dyne.org/whitepaper)
- [Zenroom script examples](https://github.com/DECODEproject/zenroom/tree/master/examples) (work in progress)
- [Zenroom development on github](https://github.com/DECODEproject/zenroom)
- Online demo (work in progress)

Zenroom is software in **ALPHA stage** and is part of the [DECODE project](https://decodeproject.eu) about data-ownership and technological sovereignty. This software aims to make it easy and less error-prone to write **portable** scripts using **end-to-end encryption** inside isolated environments that can be easily made **interoperable**. Basic crypto functions provided include primitives from AES and soon CAESAR competition winners to manage **a/symmetric keys, key derivation, hashing and signing functionalities**. The [API documentation](https://zenroom.dyne.org/api) is a work in progress subject to slight changes.

Zenroom's **restricted execution environment** is a sort of [sandbox](https://en.wikipedia.org/wiki/Sandbox_%28computer_security%29) that executes cryptographic operations in a **Turing-incomplete language** without any access to the calling process, underlying operating system or filesystem. Zenroom's parser is based on LUA's [syntax-direct translation](https://en.wikipedia.org/wiki/Syntax-directed_translation) engine, has coarse-grained control of computations and memory.

Zenroom is software inspired by [langsec.org](language-theoretical security) and it is designed to brittle and exit execution returning a meaningful error on any error occurred. Zenroom's documentation and examples are being written to encourage a [declarative](https://en.wikipedia.org/wiki/Declarative_programming) approach to scripting, treating even complex data structures as [first-class citizens](https://en.wikipedia.org/wiki/First-class_citizen).

The main use case for Zenroom is that of **distributed computing** of untrusted code where advanced cryptographic functions are required, for instance it can be used as a distributed ledger implementation (also known as **blockchain smart contracts**).

For a larger picture describing the purpose and design of this software in the field of **data-ownership** and **secure distributed computing**, see:
- [The DECODE Project website](https://decodeproject.eu)
- [The DECODE Project Whitepaper](https://decodeproject.github.io/whitepaper)
- [The Zenroom Whitepaper](https://zenroom.dyne.org/whitepaper)

![Horizon 2020](https://zenroom.dyne.org/img/ec_logo.png)

This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

## Build instructions

This section is optional for those who want to build this software from source. The following build instructions contain generic information meant for an expert audience.

The Zenroom compiles the same sourcecode to run on Linux in the form of 2 different POSIX compatible ELF binary formats using GCC (linking shared libraries) or musl-libc (fully static) targeting both X86 and ARM architectures. It also compiles to a Windows 64-bit native and fully static executable. At last, it compiles to Javascript/Webassembly using the LLVM based emscripten SDK. To recapitulate some Makefile targets:

1. `make shared` its the simpliest, builds a shared executable linked to a system-wide libc, libm and libpthread (mostly for debugging)
2. `make static` builds a fully static executable linked to musl-libc (to be operated on embedded platforms)
3. `make js` or `make wasm` builds different flavors of Javascript modules to be operated from a browser or NodeJS (for client side operations)
4. `make win` builds a Windows 64bit executable with no DLL dependancy, containing the LUA interpreter and all crypto functions (for client side operations on windows desktops)

Remember that if after cloning this source code from git, one should do:
```
git submodule update --init --recursive
```

Then first build the shared executable environment:

```
make shared
```
To run tests:

```
make check-shared
```

To build the static environment:

```
make bootstrap
make static
make check-static
```

For the Javascript and WebAssembly modules the Zenroom provides various targets provided by emscripten which must be installed and loaded in the environment according to the emsdk's instructions :

```
make js
make wasm
make html
```

## Operating instructions

This software is work in progress and this section will be extended in
the near future. Scripts found in the test/ directory provide good
examples to start from.

From **command-line** the Zenroom is operated passing files as
arguments:

```
Usage: zenroom [-c config] [-k KEYS] [-a DATA] SCRIPT.lua
```

From **javascript** the function `zenroom_exec()` is exposed with four
arguments: four strings and one number from 1 to 3 indicating the
verbosity of output on the console:

```
int zenroom_exec(char *SCRIPT, char *config, char *KEYS, char *DATA, int verbosity)
```

The contents of the three strings cannot exceed 100k in size and are of different types:

- `script` is a parsable LUA script, for example:
```lua
t = "The quick brown fox jumps over the lazy dog"
pk, sk = keygen_sign_ed25519() -- signature keypair
sig = sign_ed25519(sk, pk, t)
assert(#sig == 64)
assert(check_ed25519(sig, pk, t))
```

- `config` is also a parsable LUA script declaring variables, for example:
```lua
memory_limit = 100000
instruction_limit = 696969
output_limit = 64*1024
log_level = 7
remove_entries = {
	[''] = {'dofile','load', 'loadfile','newproxy'},
	os = {'getenv','execute','exit','remove','rename',
		  'setlocale','tmpname'},
    math = {'random', 'randomseed'}
 }
disable_modules = {io = 1}
```

- `arguments` is a simple string, but can be also a json map used to
  pass multiple arguments

For example create a json file containing a map (this can be a string
passed from javascript)

```json
{
	"secret": "zen and the art of programming",
	"salt": "OU9Qxl3xfClMeiCz"
}
```

Then run `zenroon -a arguments.json` and pass the following script as
final argument, or pipe from stdin or passed as a string argument to
`zenroom_exec()` from javascript:

```lua
i = inspect()
json = cjson()
args = json.decode(DATA)
-- args is now a lua table containing values for each args.argname
i.print(args)
```

All strings parsed are in the `arguments` global variable available
inside the script. This allows separation of public code and private
data to be passed via separate channels.

So for instance if we want to encrypt a secret message for multiple
recipients who have provided us with their public keys, one would load
this example keyfile:

```json
{
    "keyring": {
        "public":"GoTdVYbTWEoZ4KtCeMghV7UcpJyhvny1QjVPf8K4oi1i",
        "secret":"9PSbkNgsbgPnX3hM19MHVMpp2mzvmHcXCcz6iV8r7RyZ"
    },
    "recipients": {
        "jaromil": "A1g6CwFobiMEq6uj4kPxfouLw1Vxk4utZ2W5z17dnNkv",
        "francesca": "CQ9DE4E5Ag2e71dUW2STYbwseLLnmY1F9pR85gLWkEC6",
        "jimb": "FNUdjaPchQsxSjzSbPsMNVPA2v1XUhNPazStSRmVcTwu",
        "mark": "9zxrLG7kwheF3FMa852r3bZ4NEmowYhxdTj3kVfoipPV",
        "paulus": "2LbUdFSu9mkvtVE6GuvtJxiFnUWBWdYjK2Snq4VhnzpB",
        "mayo": "5LrSGTwmnBFvm3MekxSxE9KWVENdSPtcmx3RZbktRiXc"
    }
}
```

And then with this code:

```lua
secret="this is a secret that noone knows"
-- this should be a random string every time
nonce="eishai7Queequot7pooc3eiC7Ohthoh1"

json = cjson()
keys = json.decode(KEYS)

res = {}

for name,pubkey in pairs(keys.recipients) do
   k = exchange_session_x25519(
	  decode_b58(keys.keyring.secret),
	  decode_b58(pubkey))
   enc = encrypt_norx(k,nonce,secret)
   -- insert in results
   res[name]=encode_b58(enc)
end
print(json.encode(res))
```

Zenroom can be executed as `zenroom -k keys.json code.lua` and will print out the encrypted message for each recipient reorganised in a similar json structure:

```json
{
   "jaromil" : "Ha8185xZoiMiJhfquKRHvtT6vZPWifGaXmD4gxjyfHV9ASNaJF2Xq85NCmeyy4hWLGns4MTbPsRmZ2H7uJh9vEuWt",
   "mark" : "13nhCBWKbPAYyhJXD7aeHtiFKb89fycBnoKy2nosJdSqfS2vhhHqBvVKb2oasiga9P3UyaEJZQdyYRfiBBKEswdmQ",
   "francesca" : "7ro9u2ViXjp3AaLzvve4E4ebZNoBPLtxAja8wd8YNn51TD9LjMXNGsRvm85UQ2vmhdTeJuvcmBvz5WuFkdgh3kQxH",
   "mayo" : "FAjQSYXZdZz3KRuw1MX4aLSjky6kbpRdXdAzhx1YeQxu3JiGDD7GUFK2rhbUfD3i5cEc3tU1RBpoK5NCoWbf2reZc",
   "jimb" : "7gb5SLYieoFsP4jYfaPM46Vm4XUP2jbCUnkFRQfwNrnJfqaew5VpwqjbNbLJrqGsgJJ995bP2867nYLcn96wuMDMw",
   "paulus" : "8SGBpRjZ21pgYZhXmy7uWGNEEN7wnHkrWtHEKeh7uCJgsDKtoGZHPk29itCV6oRxPbbiWEuN9Sm83jeZ1vinwQyXM"
}
```


## Acknowledgements

Copyright (C) 2017-2018 by Dyne.org foundation, Amsterdam

Designed, written and maintained by Denis "Jaromil" Roio

Includes code by:

- Mozilla foundation (lua_sandbox)
- Rich Felker, et al (musl-libc)
- Mike Scott and Kealan McCusker (milagro)
- Phil Leblanc (luazen)
- Joergen Ibsen (brieflz)
- Loup Vaillant (blake2b, argon2i, ed/x25519)
- Samuel Neves and Philipp Jovanovic (norx)
- Luiz Henrique de Figueiredo (base64)
- Luke Dashjr (base58)
- Cameron Rich (md5)
- Mark Pulford (lua-cjson)
- Daan Sprenkels (randombytes)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
