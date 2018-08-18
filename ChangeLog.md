# Zenroom ChangeLog

## 0.7.1
### August 2018

Fixes to all Javascript builds.

## 0.7.0
### August 2018

Adopted AES-GCM as default encryption method, downgraded CBC as weak.
Fixes to the exposed API for complete usage in Zenroom-studio.  Added
seccomp kernel-level protection and insured unikernel functionality
with provable isolation from network and filesystem access. Added
language bindings, a Python module is now provided.

Switched to BLS383 curve for ECP operations and upgraded Milagro to
version 4.12.0. Implemented arithmetic operations on BIG numbers and
improved the language design around ECP, ECDH and OCTET. Exposed and
improved objects for HASH and RNG. Added curves GOLDILOCKS and
SECP256K1 for use in ECDH and Base58 for OCTET. Added support for
MSGPACK binary serialization format.

Updated tests and examples, added new simple implementation for
ElGamal with ZKP using ECP primitives. Started ECP2 twisted curve
implementation. Improved build system; added python, java and esp32
targets. Updated API documentation.

## 0.6.0
### June 2018

Implemented arithmetic operations on elliptic curve points (ECP)
as cryptographic primitives to implement new schemes.

Modularised ECDH class/factory implementation to support multiple
curve types.

Support for multiple memory managers (still not fully reentrant),
improved use of memory (and reflexivity), better constructors in
scripts.

Further progress on syntax in relation to use-cases (DECODE D3.5).

Abstract Syntax Tree parsing of smart rules and rendering to
JSON (based on lpeglabels and lua-parser).

Exposed more public calls on zenroom.h for usage as a library
(stdout/stderr to memory).

Added contributed scripts for iOS, Android and Go shared builds.


## 0.5.0
### April 2018

Fully adopted Milagro-crypto-C as underlying crypto library,
abandoning luazen at least for now. Refactored the API and language
approach to adopt a more object-oriented posture towards first-class
citizen data objects (octets) and keyrings. Full ECDH implementation
with support for multiple curve types.

Direct-syntax interpreter upgraded to Lua 5.3; dropped dependency from
lua_sandbox effectively cleaning up large portions of code.

Improved support for javascript; implemented a cryptographically
secure random generator linked to different RNG functions provided by
native platforms. Added build targets for Android and iOS, improved JS
support both for NodeJS and WASM targets.

Adopted an embedded memory-manager (umm) optionally enabled at
runtime, achieving significant speed improvements, reduction of
resources used and full control on memory allocation; adopted a
function pointer mechanism to easily include different memory managers
in the future.

Updated documentation accordingly with more examples and
tests. Half-baked RSA implementation may be abandoned in the future
unless use-cases arise.


## 0.4 (ALPHA)
### March 2018

Major improvements to standard Lua direct-syntax compatibility, port
to emscripten, osx and win targets. Documentation using LDoc and
website. Support for cjson and other embedded extensions. First
binary release, enters ALPHA stage.


## 0.3 (Prototype)
### February 2018

Build fixes for various architecture targets. Milagro integration,
test suites, continuous integration setup.

## 0.2
### December 2017

Whitepaper and improved Lua support.
Adopted luazen in place of luanacha.

## 0.1 (POC)
### November 2017

Proof of concept based on lua_sandbox
