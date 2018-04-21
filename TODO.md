# List of planned improvements

This is a draft TODO list for future directions in zenroom
development, to be vouched with priorities emerging from DECODE pilots
and their specific use-cases.


## Generic improvements

- add brieflz2 compression

- add a new 8bit memory manager to test
  https://github.com/8devices/MemoryManager perhaps also build a
  memory paging system to use 8bit mm over larger portions of memory

- add more memory tracking / fencing facilities also for script
  testing/profiling
	  https://github.com/kallisti5/ElectricFence
	  https://github.com/Ryandev/MemoryTracker


- add tracking of single lua command/operations executions

- in/out to MSGPACK in addition to JSON for compact messaging easy using
  Antirez' extension see https://github.com/antirez/lua-cmsgpack

- add some more functions from stdlib's string and utils
  https://github.com/lua-stdlib/lua-stdlib

- Include libs from penlight
  http://stevedonovan.github.io/Penlight/api/index.html stringx, lexer

- erlang style pattern matching on data structures
  https://github.com/silentbicycle/tamale

- date and time module
  https://github.com/Tieske/date

V if event based callback framework needed, try including libev
  https://github.com/brimworks/lua-ev
  http://software.schmorp.de/pkg/libev.html

V pick extensions from here
  http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/

X compile extensions and load them from strings using the lua load()
  function directly with callbacks
  http://www.lua.org/manual/5.1/manual.html#lua_load

X provide a finite state machine programming interface
  https://github.com/kyleconroy/lua-state-machine
  https://github.com/airstruck/knife/blob/master/readme/behavior.md

X functional programming facility
  https://github.com/Yonaba/Moses

X use static memory pool in place of malloc from host
  https://github.com/dcshi/ncx_mempool
  implemented using umm_malloc

## Developer experience

- on error print out code at line where it has been detected
  the line number is already included between semicolons
  just need to go to script buffer and extract line

- !! make a Jupyter kernel for zenroom (-> Puria)
  - http://jupyter-client.readthedocs.io/en/latest/kernels.html
  - https://github.com/neomantra/lua_ipython_kernel

- graphviz representation of complex data structures
  http://siffiejoe.github.io/lua-microscope/

- add superior testing and profiling facility with lust
  https://github.com/bjornbytes/lust

- enhance debug module stacktrace
  https://github.com/ignacio/StackTracePlus

- introspection
  https://github.com/leegao/see.lua

V self documentation
  https://github.com/rgieseke/locco
  (also includes interesting modules as luabalanced)

X add list of functions and keywords for completion in ace
  the js editor used for the example. last review of way
  to include extensions (with prefix. or?)

## Performance

- Benchmark suite to measure capacity to de/code large amounts of
  streaming data in chunks.

V Investigate adoption of LuaJit in place of Lua5.1
  (should be easy as it seems the C api is pretty much the same)

## Security

- maybe support Linux kernel keystore feature for loaded keys
  (see cryptsetup 2.0)

X adopt a declarative approach to data schemes accepted in scripts
  supporting i.e. https://github.com/sschoener/lua-schema
  code analysis to report on bad constructs
  DONE - just write documentation, examples and tests

## Documentation

- Start sketching an high-level API based on experience in DECODE

- Provide cross-language examples for most basic operations

V Make it easy to integrate with BLOCKLY to generate simple
  cryptographic functions.

X Build a simple example webpage that runs only in javascript and
  compiles Zenroom scripts providing results

X Document api with luadoc http://keplerproject.github.io/luadoc/
  or other means http://lua-users.org/wiki/DocumentingLuaCode

## Crypto

- Build a usable ABC implementation (maybe compatible with coconut
  and/or IRMA?)

- Reproduce tor's new onion address scheme
  (see tor-dam/pkg/damlib/crypto_25519.go)

- Consider adding GOST from https://github.com/aprelev/libgost15

- Investigate inclusion of primitives from libsodium

- Investigate inclusion of primitives from libgcrypt

- Investigate strategies to build compatibility with ssh

- Investigate strategies to build compatibility with gnupg

X Integrate the new secret-sharing library by dsprenkels

- Include salsa20 (and its dependency bit32)

X Finish integrating Milagro in the LUA script

## Parser

This section lists hypotethical developments and may lead to a
completely new release of Zenroom or a derivate, while keeping the LUA
one still maintained

? Substitute cjson with a langsec hammer parser (tutorial lesson13)

? After extensive documentation of use-cases, substitute the LUA
  syntax parser with a limited DSL also written in langsec hammer

- Add SMT analysis as a backend to most sensitive operations
