# List of planned improvements

This is a draft TODO list for future directions in zenroom
development, to be vouched with priorities emerging from DECODE pilots
and their specific use-cases.


## Generic improvements

- in/out to MSGPACK in addition to JSON for compact messaging easy using
  Antirez' extension see https://github.com/antirez/lua-cmsgpack

- compile extensions and load them from strings using the lua load()
  function directly with callbacks
  http://www.lua.org/manual/5.1/manual.html#lua_load

- if event based callback framework needed, try including libev
  https://github.com/brimworks/lua-ev
  http://software.schmorp.de/pkg/libev.html

- add some more functions from stdlib's string and utils
  https://github.com/lua-stdlib/lua-stdlib

X provide a finite state machine programming interface
  https://github.com/kyleconroy/lua-state-machine
  https://github.com/airstruck/knife/blob/master/readme/behavior.md

- erlang style pattern matching on data structures
  https://github.com/silentbicycle/tamale

X functional programming facility
  https://github.com/Yonaba/Moses

- date and time module
  https://github.com/Tieske/date

- pick extensions from here
  http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/

## Developer experience

- !! make a Jupyter kernel for zenroom
  - http://jupyter-client.readthedocs.io/en/latest/kernels.html
  - https://github.com/neomantra/lua_ipython_kernel

- add list of functions and keywords for completion in ace
  the js editor used for the example. last review of way
  to include extensions (with prefix. or?)

- add superior testing and profiling facility with lust
  https://github.com/bjornbytes/lust

- enhance debug module stacktrace
  https://github.com/ignacio/StackTracePlus

- introspection
  https://github.com/leegao/see.lua

- self documentation
  https://github.com/rgieseke/locco
  (also includes interesting modules as luabalanced)

- graphviz representation of complex data structures
  http://siffiejoe.github.io/lua-microscope/

## Performance

- Benchmark suite to measure capacity to de/code large amounts of
  streaming data in chunks.

- Investigate adoption of LuaJit in place of Lua5.1
  (should be easy as it seems the C api is pretty much the same)

## Security

X adopt a declarative approach to data schemes accepted in scripts
  supporting i.e. https://github.com/sschoener/lua-schema
  code analysis to report on bad constructs
  DONE - just write documentation, examples and tests

- maybe support Linux kernel keystore feature for loaded keys
  (see cryptsetup 2.0)

- new ad-hoc memory manager with boundary control,
  inspiration from lsb:
```c
/**
* Implementation of the memory allocator for the Lua state.
*
* See: http://www.lua.org/manual/5.1/manual.html#lua_Alloc
*
* @param ud Pointer to the lsb_lua_sandbox
* @param ptr Pointer to the memory block being allocated/reallocated/freed.
* @param osize The original size of the memory block.
* @param nsize The new size of the memory block.
*
* @return void* A pointer to the memory block.
*/
// TODO: fix to work with lua 5.3 and implement simple memory fence
void* memory_manager(void *ud, void *ptr, size_t osize, size_t nsize)
{
  lsb_lua_sandbox *lsb = (lsb_lua_sandbox *)ud;

  void *nptr = NULL;
  if (nsize == 0) {
    free(ptr);
    lsb->mem_usage -= osize;
  } else {
    size_t new_state_memory =
        lsb->mem_usage + nsize - osize;
    if (0 == lsb->mem_max
        || new_state_memory
        <= lsb->mem_max) {
      nptr = realloc(ptr, nsize);
      if (nptr != NULL) {
        lsb->mem_usage = new_state_memory;
        if (lsb->mem_usage > lsb->mem_max) {
          lsb->mem_max = lsb->mem_usage;
        }
      }
    }
  }
  return nptr;
}
```

## Documentation

- Provide cross-language examples for most basic operations

- Start sketching an high-level API based on experience in DECODE

- Build a simple example webpage that runs only in javascript and
  compiles Zenroom scripts providing results

- Make it easy to integrate with BLOCKLY to generate simple
  cryptographic functions.

X Document api with luadoc http://keplerproject.github.io/luadoc/
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

? Substitute cjson with a langsec hammer parser (tutorial lesson13)

? After extensive documentation of use-cases, substitute the LUA
  syntax parser with a limited DSL also written in langsec hammer

- Add SMT analysis as a backend to most sensitive operations

## LUA Sandbox

- provide cryptographic proof random sources

V make a secure include directive

X Find a way to load native LUA extensions at compile time

- Remove all additional cruft coming in from heka and eventually turn
  the implementation to use only non-dynamic memory

- take configuration parameters from a json struct

X provide a REPL and perhaps a LISP interpreter

- Include libs from penlight
  http://stevedonovan.github.io/Penlight/api/index.html stringx, lexer

- Include libs for lispy operations on data
