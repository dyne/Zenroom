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


## License

Copyright (C) 2017-2020 Dyne.org foundation

Designed and written by Denis Roio with the help of Puria Nafisi Azizi

documentation and testing by Andrea D'Intino

seccomp isolation and microkernel port by Daniele Lacamera

reviews and suggestions contributed by: Richard Stallman, Enrico
Zimuel and Sofía Celi

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
