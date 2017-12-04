# LUA Zenroom - DECODE project

Restricted execution environment for LUA based blockchain language
implementation. For more information see [docs](docs).

The binary produced is fully static and designed to be executed as a new process for each new script.

## Build instructions

If you have cloned this source code from git, then do:

```
git submodule update --init --recursive
```

Then first build the static build environment (musl-libc): this needs to be done only once at the beginning of new builds:

```
make bootstrap
```

Then at last run the build command:

```
make
```

To run tests:

```
make check
```

## Crypto functionalities

This interpreter includes statically the following cryptographic
primitives, extracted from the NaCl library and included via the
luazen implementation:

- Authenticated encryption with Chacha20 stream encryption (more precisely Xchacha20, ie. Chacha with a 24-byte nonce) and Poly1305 MAC, 
- Curve25519-based key exchange and public key encryption,
- Blake2b hash function,
- Ed25519-based signature function using Blake2b hash instead of sha512,
- Argon2i, a modern key derivation function based on Blake2b. Like scrypt, it is designed to be expensive in both CPU and memory.

## Acknowledgements

Copyright (C) 2017 by Dyne.org foundation, Amsterdam

Designed, written and maintained by Denis Roio <jaromil@dyne.org>

Includes code by:

- Mozilla foundation (lua_sandbox)
- Rich Felker, et al (musl-libc)
- IETF Trust (blake2b)
- Daniel J. Bernstein, Tanja Lange and Peter Schwabe (NaCl)
- Phil Leblanc (luazen)

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
