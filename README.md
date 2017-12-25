# Zenroom - DECODE project

[![software by Dyne.org](https://www.dyne.org/wp-content/uploads/2015/12/software_by_dyne.png)](http://www.dyne.org)

Restricted execution environment for a turing-incomplete language implementation to be used in untrusted distributed computing, i.e. for distributed ledger or blockchain smart contracts.


[![Build Status](https://travis-ci.org/DECODEproject/zenroom.svg?branch=master)](https://travis-ci.org/DECODEproject/zenroom)

This README documentation is operational. For more information on the purpose and design of this software see:

- The DECODE Project website: https://decodeproject.eu
- The Zenroom whitepaper and API documentation: https://decodeproject.github.io/zenroom

## Build instructions

The Zenroom compiles the same base sourcecode to 3 different POSIX
compatible ELF binary targets. They are:

1. Shared executable linked to a system-wide libc, libm and libpthread (mostly for debugging)
2. Fully static executable linked to musl-libc (to be operated on embedded platforms)
3. Javascript module to be operated from a browser or NodeJS (for web based operations)

If you have cloned this source code from git, then do:

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

For the Javascript module:

```
make js
```

## Crypto functionalities

The Zenroom language interpreter includes statically the following cryptographic primitives:

- **Norx** authenticated encryption with additional data (AEAD) - this is the default 64-4-1 variant (256-bit key and nonce, 4 rounds)
- **Blake2b** cryptographic hash function
- **Argon2i**, a modern key derivation function based on Blake2. Like 
scrypt, it is designed to be expensive in both CPU and memory.
- **Curve25519**-based key exchange and public key encryption,
- **Ed25519**-based signature function using Blake2b hash instead of sha512,

Legacy cryptographic functions include **md5**, and **rc4**.

Endoding and decoding functions are provided for **base64** and **base58** (for base58, the BitCoin encoding alphabet is used).

Compression functions based on **BriefLZ** are also included.

## Acknowledgements

Copyright (C) 2017-2018 by Dyne.org foundation, Amsterdam

Designed, written and maintained by Denis Roio <jaromil@dyne.org>

Includes code by:

- Mozilla foundation (lua_sandbox)
- Rich Felker, et al (musl-libc)
- Phil Leblanc (luazen)
- Joergen Ibsen (brieflz)
- Loup Vaillant (blake2b, argon2i, ed/x25519)
- Samuel Neves and Philipp Jovanovic (norx)
- Luiz Henrique de Figueiredo (base64)
- Luke Dashjr (base58)
- Cameron Rich (md5)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
