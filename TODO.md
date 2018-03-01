# List of planned improvements

This is a draft TODO list for future directions in zenroom
development, to be vouched with priorities emerging from DECODE pilots
and their specific use-cases.


## Generic improvements

- Multiline REPL using a linkedlist FIFO of commands, easy using libhl
  from Xant

- in/out to MSGPACK in addition to JSON for compact messaging easy using
  Antirez' extension see https://github.com/antirez/lua-cmsgpack

## Performance

- Benchmark suite to measure capacity to de/code large amounts of
  streaming data in chunks.

## Security

- adopt a declarative approach to data schemes accepted in scripts
  supporting i.e. https://github.com/sschoener/lua-schema
  code analysis to report on bad constructs

- maybe support Linux kernel keystore feature for loaded keys (see
  cryptsetup 2.0)

## Documentation

- Provide cross-language examples for most basic operations

- Start sketching an high-level API based on experience in DECODE

- Build a simple example webpage that runs only in javascript and
  compiles Zenroom scripts providing results

- Make it easy to integrate with BLOCKLY to generate simple
  cryptographic functions.

- Document api with luadoc http://keplerproject.github.io/luadoc/
  or other means http://lua-users.org/wiki/DocumentingLuaCode

## Crypto

- Finish integrating Milagro in the LUA script

- Build a usable ABC implementation (maybe compatible with coconut
  and/or IRMA?)
  
- Reproduce tor's new onion address scheme
  (see tor-dam/pkg/damlib/crypto_25519.go)

- Consider adding GOST from https://github.com/aprelev/libgost15
  
- Investigate inclusion of primitives from libsodium

- Investigate inclusion of primitives from libgcrypt

- Investigate strategies to build compatibility with ssh

- Investigate strategies to build compatibility with gnupg

- Integrate the new secret-sharing library by dsprenkels

- Include salsa20 (and its dependency bit32)

## Parser

This section lists hypotethical developments and may lead to a
completely new release of Zenroom or a derivate, while keeping the LUA
one still maintained

- Substitute cjson with a langsec hammer parser (tutorial lesson13)

- After extensive documentation of use-cases, substitute the LUA
  syntax parser with a limited DSL also written in langsec hammer

- Add SMT analysis as a backend to most sensitive operations

## LUA Sandbox

- provide cryptographic proof random sources

- make a secure include directive

- Find a way to load native LUA extensions at compile time

- Remove all additional cruft coming in from heka and eventually turn
  the implementation to use only non-dynamic memory

- take configuration parameters from a json struct

- provide a REPL and perhaps a LISP interpreter

- Include libs from penlight
  http://stevedonovan.github.io/Penlight/api/index.html stringx, lexer

