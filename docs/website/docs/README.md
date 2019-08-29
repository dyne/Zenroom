# The Zenroom VM ...

[![software by Dyne.org](https://zenroom.dyne.org/img/software_by_dyne.png)](http://www.dyne.org)

Zenroom is a secure-isolated interpreter of both Lua and its own
Zencode DSL languages to execute fast cryptographic operations on
Elliptic Curves.

The Zenroom VM is very small, has no external dependencies and is
ready to run on any platform: desktop, embedded, mobile, cloud and
even web browsers.

Zencode is the name of the language executed by Zenroom: it is simple
to understand and can process large data structures while operating
cryptographic transformations on them.

![Credential example](img/coconut_credential-en.jpg)

This website is intended for a technical audience; more documentation is
available on:

<span class="mdi mdi-home"></span> Website: [Zenroom.org](https://zenroom.org)

<span class="mdi mdi-school"></span> Whitepaper: [Zencode by Denis Roio (Ph.D)](https://files.dyne.org/zenroom/Zenroom_Whitepaper.pdf)

<span class="mdi mdi-hand"></span> Blog post: [Why Zenroom? Algorithmic Sovereignty](https://decodeproject.eu/blog/algorithmic-sovereignty-decode)

<span class="mdi mdi-vote"></span> Blog post: [Zenroom does what? Smart contracts for the English speaker](https://decodeproject.eu/blog/smart-contracts-english-speaker)

<span class="mdi mdi-puzzle"></span> Blog post: [Cryptographic data integrity in a multiplatform environment](https://decodeproject.eu/blog/cryptographic-data-integrity-multiplatform-environment)

## Download

<span class="mdi mdi-target"></span>
Available targets: Portable source code (C99), **Javascript** (WebAssembly), **Linux** (Android, ARM and x86), **Windows** (EXE and DLL), **Apple** (OSX and iOS)

<span class="mdi mdi-download"></span>
Download from [files.dyne.org/zenroom](https://files.dyne.org/zenroom)

<span class="mdi mdi-history"></span>
Read the [history of changes](https://files.dyne.org/zenroom/ChangeLog.txt)

Anyone planning to use Zenroom to store and access secrets should not
use the latest development version in Git, but use instead the stable
releases on files.dyne.org.

Before releasing we make sure Zenroom works as expected by running
various tests, plus we note down all changes in the log above.

The development version in Git should only be used by contributors to
report bugs, test new features and develop patches.

## Documentation

### Programming

<span class="mdi mdi-flag"></span>
[Zencode: programming smart contracts in human language](zencode)

<span class="mdi mdi-code-braces"></span>
[Zenroom scripting in Lua: reference documentation](lua)

### Usage

<span class="mdi mdi-run"></span>
[How to execute scripts with Zenroom](wiki/how-to-exec)

<span class="mdi mdi-package"></span>
[How to embed Zenroom in your application](wiki/how-to-embed)

<span class="mdi mdi-cogs"></span>
[How to build Zenroom from the source code](wiki/how-to-build)


## Playground

### Online

<span class="mdi mdi-hand-pointing-right"></span>
[Online interactive demo](https://zenroom.dyne.org/demo)

<span class="mdi mdi-web"></span>
[Web encryption demonstration and benchmark](encrypt)

### Apps

<span class="mdi mdi-network"></span>
[Redroom: fast execution of Zencode in Redis](https://redroom.dyne.org)

<span class="mdi mdi-eye"></span>
[Sawroom: blockchain integration with Sawtooth](https://redroom.dyne.org)

### Docker

<span class="mdi mdi-docker"></span>
[Docker build files](https://github.com/dyne/docker-dyne-software/tree/master/zenroom)
(dyne/zenroom:latest)


## Bindings

Zenroom is designed to be embedded inside host applications and used from its very simple interface to execute code on an input and return an output of the transformation. The embedding API is:

```c
int zenroom_exec(char *script, char *conf, char *keys,
                 char *data, int verbosity);
```

This API can be called in similar ways from a variety of languages and in particular four wrappers already facilitate its usage:

<ul class="center">
<li><a href="https://www.npmjs.com/package/zenroom">Javascript NPM package</a></li>
<li><a href="https://github.com/DECODEproject/zenroom-py">Python language bindings</a></li>
<li><a href="https://github.com/DECODEproject/zenroom-go">Go language bindings</a></li>
<li><b>Redis</b> module implementation for in-memory database encryption</li>
</ul>


## Mission

Zenroom is software in **BETA stage** and is part of the [DECODE project](https://decodeproject.eu) about data commons and [technological sovereignty](https://www.youtube.com/watch?v=RvBRbwBm_nQ). Our effort is that of improving people's awareness of how their data is processed by algorithms, as well facilitate the work of developers to create along [privacy by design principles](https://decodeproject.eu/publications/privacy-design-strategies-decode-architecture).

[![DECODE project](img/decode.svg)](https://decodeproject.eu)

This software aims to make it easy and less error-prone to write **portable** scripts using **end-to-end encryption** inside isolated environments that can be easily made **interoperable**. Basic crypto functions provided include primitives to manage **a/symmetric keys, key derivation, hashing and signing functionalities**.

Zenroom is software inspired by the [language-theoretical security](http://langsec.org) research, it allows to expresses cryptographic operations in a readable scripting language that has no access to the calling process, underlying operating system or filesystem.

[![No more Turing Completion!](img/InputLanguages.jpg)](http://langsec.org/occupy/)

Zenroom's **restricted execution environment** is a sort of [sandbox](https://en.wikipedia.org/wiki/Sandbox_%28computer_security%29) whose parser is based on LUA's [syntax-direct translation](https://en.wikipedia.org/wiki/Syntax-directed_translation) and has coarse-grained control of computations and memory. The Zenroom VM is designed to "brittle" and exit execution returning a meaningful message on any error.

Zenroom's documentation and examples are being written to encourage a [declarative](https://en.wikipedia.org/wiki/Declarative_programming) approach to scripting, providing functional tools to manipulate efficiently even complex data structures.

[![Full Recognition Before Processing!](img/FullRecognition.jpg)](http://langsec.org/occupy/)

The main use case for Zenroom is that of **distributed computing** of untrusted code where advanced cryptographic functions are required, for instance it can be used as a distributed ledger implementation (also known as **blockchain smart contracts**).

![Project funded by the European Commission](img/ec_logo.png)

This project is receiving funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement nr. 732546 (DECODE).


## Acknowledgements

Copyright (C) 2017-2019 by Dyne.org foundation, Amsterdam

Designed, written and maintained by Denis Roio <jaromil@dyne.org>

With contributions by Puria Nafisi Azizi and Daniele Lacamera.

Go bindings by Christian Espinoza and Samuel Mulube.

JS bindings by Jordi Coscolla and Puria.

Special thanks to Francesca Bria for leading the DECODE project and to
George Danezis, Ola Bini, Mark de Villiers, Ivan J., Alberto Sonnino,
Richard Stallman, Enrico Zimuel, Jim Barritt and Andrea D'Intino for
their expert reviews.

This software includes software components by: R. Ierusalimschy,
W. Celes and L.H. de Figueiredo (lua), Mike Scott and Kealan McCusker
(milagro-crypto-c), Ralph Hempel (umm_malloc), Mark Pulford
(lua-cjson), Daan Sprenkels (randombytes), Salvatore Sanfilippo
(cmsgpack)

Some Lua extensions included are written by: Kyle Conroy
(statemachine), Enrique García Cota (inspect and semver).

Zenroom is Licensed under the terms of the Affero GNU Public License as
published by the Free Software Foundation; either version 3 of the
License, or (at your option) any later version.

Software contained include Lua 5.3, Copyright (C) 1994-2017 Lua.org,
PUC-Rio licensed with an MIT style license. Also included Milagro,
Copyright 2016 MIRACL UK Ltd licensed with the Apache License, Version
2.0 (the "License").

<!-- We are committed to contribute our code to communities and societies -->
<!-- adopting it as free and open source, according to the Free Software -->
<!-- Foundation guidelines and GNU artisanal traditions. Here is our -->
<!-- [Contributor License Agreement](Agreement.md). -->

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See [the License](LICENSE.txt).
