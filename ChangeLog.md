# Zenroom ChangeLog

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
