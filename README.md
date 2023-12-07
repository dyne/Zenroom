<!--
SPDX-FileCopyrightText: 2017-2022 Dyne.org foundation

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Zenroom crypto VM

[![Zenroom logo](docs/_media/images/zenroom_logotype.png)](https://zenroom.org)

Zenroom is a **secure language interpreter** of the domain-specific Zencode, making it easy to execute fast cryptographic operations on any data structure.

The Zenroom VM is very small, has **no external dependency**, is fully deterministic and is ready to run **end-to-end encryption** on any platform: desktop, embedded mobile, cloud micro-services, and web browsers. Zenroom works inside applications written in Javascript, Python3, Rust or Golang.

Zencode has a **no-code** approach. It is a domain-specific language (DSL) **similar to human language**. One can process large data structures through complex cryptographic and logical transformations.

Zencode helps developers to **empower people** who know what to do with data: one can write and review business logic and data-sensitive operations **without learning to code**.


[![software by Dyne.org](https://files.dyne.org/software_by_dyne.png)](http://www.dyne.org)

## Timeline

- 2017 - Proof of Concept
- 2018 - Prototype and Alpha release series
- 2019 - Stable release series `v1` (now EOL)
- 2022 - Stable release series [v2](https://github.com/dyne/Zenroom/tree/v2) until LTS `v2.22.1`
- 2023 - Stable release series [v3](https://github.com/dyne/Zenroom/tree/v3) until LTS `v3.23.4`
- 2024 - Current stable `v4` (latest HEAD)

### [Read the full Changelog for more infos](https://github.com/dyne/Zenroom/blob/master/ChangeLog.md)

This software has zero dependencies. If you chose to use it in your
project be assured that we intend to support the same code to still
run in 20 years from now on any target platform.

## Links

Continue to the [developer website](https://dev.zenroom.org/)

or

Read the [Zencode whitepaper](https://files.dyne.org/zenroom/Zenroom_Whitepaper.pdf)

or

Visit the [product website](http://zenroom.org/) for a friendly
introduction to the love we put in craftsmanship.

For many quick running examples visit the
[ApiRoom](https://apiroom.net) online IDE powered by Zenroom.


**Zenroom is licensed as AGPLv3; we are [open to grant exceptions on a commercial basis](https://forkbomb.solutions).**

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

Designed and written by Denis "[Jaromil](https://jaromil.dyne.org)"
Roio with the help of [Puria](https://github.com/puria) Nafisi Azizi
and [Andrea](https://www.linkedin.com/in/andrea-d-intino/) D'Intino.

Includes code contributions by Alberto Lerda, Matteo Cristino, Danilo
Spinella, Luca Di Domenico and Rebecca Selvaggini.

Reviews and suggestions contributed by: Richard Stallman, Daniele
Lacamera, Enrico Zimuel, Sofía Celi, Sebastian Blichfeld, Adam Burns,
Thomas Fuerstner and Jürgen Eckel.

Zenroom [complies with the REUSE license specification](https://github.com/dyne/Zenroom/actions/workflows/reuse.yml) and redistributes:
- Lua 5.4 - Copyright © 1994–2023 Lua.org, PUC-Rio.
- Apache Milagro Crypto Library (AMCL)
- Various Lua libraries released under Apache/MIT license

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
