# Build instructions

This section is optional for those who want to build this software from source. The following build instructions contain generic information meant for an expert audience.

The Zenroom compiles the same sourcecode to run on Linux in the form of 2 different POSIX compatible ELF binary formats using GCC (linking shared libraries) or musl-libc (fully static) targeting both X86 and ARM architectures. It also compiles to a Windows 64-bit native and fully static executable. At last, it compiles to Javascript/Webassembly using the LLVM based emscripten SDK. To recapitulate some Makefile targets:

1. `make shared` its the simpliest, builds a shared executable linked to a system-wide libc, libm and libpthread (mostly for debugging)
2. `make static` builds a fully static executable linked to musl-libc (to be operated on embedded platforms)
3. `make javascript-node`, `make javascript-wasm` (need EMSDK env) builds different flavors of Javascript modules to be operated from a browser or NodeJS (for client side operations)
4. `make win` builds a Windows 64bit executable with no DLL dependancy, containing the LUA interpreter and all crypto functions (for client side operations on windows desktops)
5. `make javascript-demo` creates in the `docs/demo` folder a simple web page with a REPL and some boilerplate code to show how to use the WebAssembly binary (visible online [here](https://zenroom.dyne.org/demo))

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
make javascript-node
make javascript-wasm
make javascript-demo
```
NB. for the `javascript-demo` target the generated files should be served by a http server and not directly opened in a browser eg.
```
$ make javascript-demo
$ cd docs/demo
$ python3 -m http.server
```

# Build instructions for Mobile libraries

### iOS

You need to have install `Xcode` with the `commandline-tools`

There are 3 different targets `ios-sim` `ios-armv7` `ios-arm64` these targets creates an static library with the correct architecture (x86_64, ARMV7, ARM64).

Finally once done all the libraries there is a final target `ios-fat` that put them together creating a fat-binary that you can include into your app. 

Or you can just use the `build-ios.sh` that does all the steps for you!

For using the library just copy `zenroom.a` somewhere in your project and include the zenroom.h file.

### Android

You need to have installed `android-sdk` (if you have Android Studio installed is already there) and set the `ANDROID_HOME` variable.

Also you need to install NDK inside the android-sdk using the Android Studio -> Tools -> Android -> SDK Manager

Finally use the `builld-android.sh` script (be sure that the ANDROID_HOME environment var is set) and you will have at the end `libzenroom-arm.so` and libzenroom-x86.so

To use it in your project just drop `src/Zenroom.java` inside your codebase and the put the `*.so` as following:

```
src/
    main/
         java/
         jniLibs/
                 x86/ 
                      libzenroom.so
                 armeabi/ 
                      libzenroom.so
```




