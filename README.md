<!--
SPDX-FileCopyrightText: 2017-2022 Dyne.org foundation

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Zenroom crypto VM

[![Zenroom logo](https://files.dyne.org/zenroom/logos/zenroom_logotype.png)](https://dev.zenroom.org)

Zenroom is a **secure language interpreter** of both Lua and its own
secure domain specific language (DSL) to execute fast cryptographic
operations using elliptic curve arithmetics.

The Zenroom VM is very small, has **no external dependency**, is fully
deterministic and ready to run **end-to-end encryption** on any
platform: desktop, embedded, mobile, cloud micro-services, web
browsers. It can be embedded inside applications written in
Javascript, Python3, Rust or Golang.

**Zencode** is the name of the DSL executed by Zenroom: it is similar
to human language and can process large data structures while
operating cryptographic transformations and basic logical operations
on them.

[![software by Dyne.org](https://files.dyne.org/software_by_dyne.png)](http://www.dyne.org)

## Timeline

- 2017 - Development started
- 2019 - Released version 1.0.0
- 2022 - Released version 2.0.0 (long term support)
- 2022 - Started development of 3.0.0

This software has zero dependencies. If you chose to use it in your
project be assured that we intend to support the same code to still
run in 20 years from now.

Version 3 development started with the implementation of Quantum Resistant encryption and signatures.

## Links

Continue to the [developer website](https://dev.zenroom.org/)

or

Read the [Zencode whitepaper](https://files.dyne.org/zenroom/Zenroom_Whitepaper.pdf)

or

Visit the [product website](http://zenroom.org/) for a friendly
introduction to the love we put in craftsmanship.

For many quick running examples visit the
[ApiRoom](https://apiroom.net) online IDE powered by Zenroom.


**Zenroom is licensed as AGPLv3; we are [open to grant exceptions on a commercial basis](https://forkbomb.eu).**

## Applications

Many applications already include Zenroom and use the Zencode language.

- [W3C compatible Distributed Identity did:dyne](https://did.dyne.org)
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
- [Planetmint by the IPDB foundation](https://ipdb.io)

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

### Tutorials

- [Bitcoin secure off-line wallet](https://medium.com/think-do-tank/bitcoin-secure-off-line-wallet-be50a57a8474)
- [Easy Ethereum (and ERC20) transactions](https://medium.com/think-do-tank/easy-ethereum-transactions-with-zenroom-ac911a0bfdc0)
- [Quantum Proof Crypto](https://medium.com/think-do-tank/quantum-proof-cryptography-e23b165b3bbd)

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

Practical build scripts for GNU/Linux are provided using Meson + Ninja

```
make meson
```

Will produce a `zenroom` executable and a `libzenroom` shared lib in `zenroom/build`.

## License

Copyright (C) 2017-2023 Dyne.org foundation

Designed and written by Denis "[Jaromil](https://jaromil.dyne.org)" Roio with the help of [Puria](https://github.com/puria) Nafisi Azizi and [Andrea](https://github.com/andrea-dintino) D'Intino.

Includes code contributions by Alberto Lerda, Matteo Cristino, Danilo Spinella, Luca Di Domenico and Rebecca Selvaggini.

Reviews and suggestions contributed by: Richard Stallman, Daniele
Lacamera, Enrico Zimuel, Sofía Celi, Sebastian Blichfeld, Danilo
Spinella, Adam Burns, Thomas Fuerstner and Jürgen Eckel.

Zenroom [complies with the REUSE license specification](https://github.com/dyne/Zenroom/actions/workflows/reuse.yml) and redistributes:
- Lua 5.3 - Copyright © 1994–2019 Lua.org, PUC-Rio.
- Apache Milagro Crypto Library (AMCL)
- Various Lua libraries released under MIT license

Special thanks to our colleagues in the [DECODE
project](https://decodeproject.eu) whose research has inspired the
birth of this project: Francesca Bria, George Danezis, Ola Bini, Mark
de Villiers, Ivan Jelincic, Alberto Sonnino, Jim Barritt, Christian
Espinoza, Samuel Mulube and Nina Boelsums.

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
