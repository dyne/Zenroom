# Zenroom crypto VM

[![Zenroom logo](https://files.dyne.org/zenroom/logos/zenroom_logotype.png)](https://dev.zenroom.org)

Zenroom is a **secure language interpreter** of both Lua and its own
secure domain specific language (DSL) to execute fast cryptographic
operations using elliptic curve arithmetics.

The Zenroom VM is very small, has **no external dependency**, is fully
deterministic and ready to run **end-to-end encryption** on any platform:
desktop, embedded, mobile, cloud and even web browsers.

**Zencode** is the name of the DSL executed by Zenroom: it is similar
to human language and can process large data structures while
operating cryptographic transformations and basic logical operations
on them.

[![software by Dyne.org](https://files.dyne.org/software_by_dyne.png)](http://www.dyne.org)

Continue to the [developer website](https://dev.zenroom.org/)

or

Read the [Zencode whitepaper](https://files.dyne.org/zenroom/Zenroom_Whitepaper.pdf)

or

Visit the [product website](http://zenroom.org/) for a friendly
introduction to the love we put in craftsmanship.

**Zenroom is licensed as AGPLv3; we are open to grant exceptions on a commercial basis.**

## Applications

Many applications already include Zenroom and use the Zencode language.

- [Global Passport Project](https://globalpassportproject.org)
- [Keypairoom mnemonic deterministic and private keypairs](https://github.com/LedgerProject/keypairoom)
- [Simple Android app to show how to use Zenroom libs](https://github.com/dyne/Zenroom-Android-app)
- [Zexec safe remote execution of signed commands](https://github.com/dyne/zexec)
- [Micro-service to produce ECDSA signed unix timestamps](https://github.com/dyne/zenstamp)
- [Sawroom Transaction Processor for Hyperledger Sawtooth](https://github.com/dyne/sawroom)
- [RedRoom Crypto module for Redis](https://github.com/dyne/redroom)
- [Lotionroom Tendermint / Cosmos proof of concept with Zenroom](https://github.com/dyne/lotionroom)
- [ZenSchnorr API for Schnorr signatures](https://github.com/wires/zenschnorr)
- [Great Dane DNSSEC as a AV store for Zenroom](https://github.com/dyne/great-dane)
- [Zen-Web-Ext Web extensions encapsulating Zenroom functionality](https://github.com/LedgerProject/zen-web-ext)

## Getting Started

To quickly try out Zenroom using the Zencode language with some
examples navigate to [ApiRoom](https://apiroom.net) and start typing
into the browser.

The Zenroom VM runs locally in your browser (needs WASM) and
[ApiRoom](https://apiroom.net) provides various examples to show
operational crypto flows.

[ApiRoom](https://apiroom.net) is also an IDE (Integrated Development
Environment) and by signing in with a username and password you can
save your contracts and download them as a Dockerfile micro-service
ready to deploy.

## Build

Dependencies: makefile, cmake, zsh, gcc

Optional: musl-libc, emscripten for wasm builds

Use this command sequence:

```
git clone https://github.com/dyne/zenroom
cd zenroom
make linux
```

to create the CLI executable in `src/zenroom`

```
make linux-lib
```

to create the shared library in `src/libzenroom-x86_64.so`

```
make
```

to list more available targets

### Meson + Ninja

Practical build scripts for release are provided using Meson + Ninja

```
meson builddir meson
ninja -C builddir
```

Will produce a `zenroom` executable and a `libzenroom` shared lib in `builddir`.

## License

Copyright (C) 2017-2021 Dyne.org foundation

Designed and written by Denis Roio with the help of Puria Nafisi Azizi and Andrea D'Intino.

Reviews and suggestions contributed by: Richard Stallman, Daniele
Lacamera, Enrico Zimuel, Sofía Celi, Sebastian Blichfeld, Danilo
Spinella, Adam Burns and Thomas Fuerstner.

Zenroom redistributes:
- Lua 5.3 - Copyright © 1994–2019 Lua.org, PUC-Rio.
- Apache Milagro Crypto Library (AMCL)
- Various Lua libraries released under MIT license

Special thanks to our colleagues in the DECODE project Francesca
Bria, George Danezis, Ola Bini, Mark de Villiers, Ivan Jelincic,
Alberto Sonnino, Jim Barritt, Christian Espinoza, Samuel Mulube and
Nina Boelsums.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.
 
This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.
