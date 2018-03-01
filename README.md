# Zenroom - DECODE project

[![software by Dyne.org](https://www.dyne.org/wp-content/uploads/2015/12/software_by_dyne.png)](http://www.dyne.org)

[![Build Status](https://travis-ci.org/DECODEproject/zenroom.svg?branch=master)](https://travis-ci.org/DECODEproject/zenroom)

Zenroom is a brand new, small and portable virtual machine for cryptographic operations: smaller than 500KB and ready to use on many platforms.

Latest stable executables:
<ul>

<li class="fab fa-node-js"><a href="https://files.dyne.org/zenroom/zenroom-0.4-js.zip">NodeJS</a></li>

<li class="fab fa-linux"><a href="https://files.dyne.org/zenroom/zenroom-0.4-x86_64_linux.zip">Linux x86 64bit</a></li>

<li class="fab fa-android"><a href="https://files.dyne.org/zenroom/zenroom-0.4-armhf.zip">ARM hard-float</a></li>

<li class="fab fa-windows"><a href="https://files.dyne.org/zenroom/zenroom-0.4-win64.zip">MS/Windows 64bit</li>

<li class="fab fa-apple"><a href="https://files.dyne.org/zenroom/zenroom-0.4-osx.zip">Apple/OSX</li>

<li class="fab fa-github"><a href="https://github.com/decodeproject/zenroom">Source Code</a></li>
</ul>

Quick links:
- [Zenroom API documentation](https://zenroom.dyne.org/api) (work in progress)
- [Zenroom Cryptolang Whitepaper](https://zenroom.dyne.org/whitepaper)
- [Zenroom script examples](https://github.com/DECODEproject/zenroom/tree/master/examples) (work in progress)
- [Zenroom development on github](https://github.com/DECODEproject/zenroom)
- Online demo (work in progress)
- [Build instructions](https://github.com/DECODEproject/zenroom/wiki)

Zenroom is software in **ALPHA stage** and is part of the [DECODE project](https://decodeproject.eu) about data-ownership and [technological sovereignty](https://www.youtube.com/watch?v=RvBRbwBm_nQ). This software aims to make it easy and less error-prone to write **portable** scripts using **end-to-end encryption** inside isolated environments that can be easily made **interoperable**. Basic crypto functions provided include primitives to manage **a/symmetric keys, key derivation, hashing and signing functionalities**. The [API documentation](https://zenroom.dyne.org/api) is a work in progress subject to slight changes.
<a href="https://decodeproject.eu">
<img src="https://zenroom.dyne.org/img/decode.svg" width="36%"
	alt="DECODE project"></a>

Zenroom's **restricted execution environment** is a sort of [sandbox](https://en.wikipedia.org/wiki/Sandbox_%28computer_security%29) that executes cryptographic operations in a **Turing-incomplete language** without any access to the calling process, underlying operating system or filesystem. Zenroom's parser is based on LUA's [syntax-direct translation](https://en.wikipedia.org/wiki/Syntax-directed_translation) engine, has coarse-grained control of computations and memory.

Zenroom is software inspired by [langsec.org](language-theoretical security) and it is designed to brittle and exit execution returning a meaningful error on any error occurred. Zenroom's documentation and examples are being written to encourage a [declarative](https://en.wikipedia.org/wiki/Declarative_programming) approach to scripting, treating even complex data structures as [first-class citizens](https://en.wikipedia.org/wiki/First-class_citizen).

The main use case for Zenroom is that of **distributed computing** of untrusted code where advanced cryptographic functions are required, for instance it can be used as a distributed ledger implementation (also known as **blockchain smart contracts**).

For a larger picture describing the purpose and design of this software in the field of **data-ownership** and **secure distributed computing**, see:
- [The DECODE Project website](https://decodeproject.eu)
- [The DECODE Project Whitepaper](https://decodeproject.github.io/whitepaper)
- [The Zenroom Whitepaper](https://zenroom.dyne.org/whitepaper)

![Horizon 2020](https://zenroom.dyne.org/img/ec_logo.png)

This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).

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
