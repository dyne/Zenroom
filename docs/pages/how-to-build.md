# Build instructions

This section is optional for those who want to build this software from source. The following build instructions contain generic information meant for an expert audience.

!> After cloning this source code from git, one should do:
```bash
git submodule update --init --recursive
```

The Zenroom compiles the same sourcecode to run on Linux in the form of 2 different POSIX compatible ELF binary formats using GCC (linking shared libraries) or musl-libc (fully static) targeting both X86 and ARM architectures.
It also compiles to a Windows 64-bit native and fully static executable. At last, it compiles to Javascript/Webassembly using the LLVM based emscripten SDK. To recapitulate some Makefile targets:

## Prerequisites

<!-- tabs:start -->
#### **Devuan / Debian / Ubuntu**
```bash
apt-get install -y git build-essential cmake zsh xxd
```
<!-- tabs:end -->

## Shared builds
The simpliest, builds a shared executable linked to a system-wide libc, libm and libpthread (mostly for debugging)
Then first build the shared executable for your platform:

<!-- tabs:start -->

#### ** Linux **

```bash
make linux
```

#### ** macOS **

```bash
make osx
```

#### ** Windows **

```bash
make win # builds a Windows 64bit executable with no DLL dependancy, containing the LUA interpreter and all crypto functions (for client side operations on windows desktops)
```

#### ** BSD **
```bash
make bsd
```

<!-- tabs:end -->


To run tests:

<!-- tabs:start -->

#### ** Functional **

```bash
make check-osx
make check-linux
```

#### ** Integration **

```bash
make check-js
make check-py
```

#### **Crypto**
```bash
make check-crypto
make check-crypto-lw
```

<!-- tabs:end -->

## Static builds
Builds a fully static executable linked to musl-libc (to be operated on embedded platforms).

As a prerequisite you need the `musl-gcc` binary installed on your machine.

**eg.** on [Devuan](https://devuan.org) you can just
```bash
  apt install musl-tools
```

To build the static environment with musl installed system wide run:

```bash
make musl-system
```

There are also two other targets that looks for the `libc` in other places.

For `/usr/local/musl/lib/libc.a` run
```bash
make musl-local
```

For `/usr/lib/${ARCH}-linux-musl/libc.a`
```bash
make musl
```

## Javascript builds

For the Javascript and WebAssembly modules the Zenroom provides various targets provided by emscripten which must be installed and loaded in the environment according to the emsdk's instructions and linked inside the `build` directory of zenroom sources:

!> (need EMSDK env) builds different flavors of Javascript modules to be operated from a browser or NodeJS

```bash
make javascript-wasm # For the webassembly build node/web
make javascript-rn   # For react native
```

There is another target to create the [`playground`](https://dev.zenroom.org/demo/)
locally a simple web page with a REPL and some boilerplate code to show how to
use the WebAssembly binary.

!> for the `javascript-demo` target the generated files should be served by a http server

```bash
make javascript-demo
cd docs
make preview
```

then point your browser to http://localhost:3000/demo

## Build instructions for Mobile libraries

### iOS

You need to have install `Xcode` with the `commandline-tools`

There are 3 different targets `ios-sim` `ios-armv7` `ios-arm64` these targets creates an static library with the correct architecture (x86_64, ARMV7, ARM64).

Finally once done all the libraries there is a final target `ios-fat` that put them together creating a fat-binary that you can include into your app. 

Or you can just use the `build-ios.sh` that does all the steps for you!

For using the library just copy `zenroom.a` somewhere in your project and include the zenroom.h file.

### Android

You need to have installed `android-sdk` (if you have Android Studio installed, it is already there) and set the `ANDROID_HOME` variable.

Also you need to install NDK inside the android-sdk using the Android Studio -> Tools -> Android -> SDK Manager. If you have installed the NDK somewhere else, just set the environment variable NDK_HOME to reflect this.

Finally use the `build/build-android.sh` script (if neither `ANDROID_HOME` nor `NDK_HOME` is set, the script will try default install paths of `ANDROID_HOME=~/Android/Sdk` and `NDK_HOME=${ANDROID_HOME}/ndk-bundle`). This will place the Android target libraries in `build/target`

```
build/target/
└── android
    └── jniLibs
        ├── arm64-v8a
        │   └── libzenroom.so
        ├── armeabi-v7a
        │   └── libzenroom.so
        └── x86
            └── libzenroom.so
```

To use it in your project just drop `src/Zenroom.java` inside your codebase and the put `jniLibs` and its contents directly into your Android project under `src/main`

```
src/main/jniLibs/
├── arm64-v8a
│   └── libzenroom.so
├── armeabi-v7a
│   └── libzenroom.so
└── x86
    └── libzenroom.so
```


