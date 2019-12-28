# List of planned improvements

This is a draft TODO list for future directions in zenroom
development, to be vouched with priorities emerging from DECODE pilots
and their specific use-cases.

-faddress-sanitizers <- (check flags)

elements in multiplications that take ECP* and BIG should be checked
for position, for instance ECP multiplication needs to have the BIG
number always as second argument. Instead of returning error we should
check the type and reposition the arguments accordingly.

## XML encode/decode

- https://github.com/n1tehawk/LuaXML
- https://github.com/Cluain/Lua-Simple-XML-Parser
- https://github.com/Phrogz/SLAXML (also supports DOM)
- https://github.com/manoelcampos/xml2lua


## Table iteration

so far done in lua, could be optimized in C?

```c
lua_getglobal(L, "level");
lua_pushnil(L);

while(lua_next(L, -2)) {  // <== here is your mistake
    if(lua_isnumber(L, -1)) {
        int i = (int)lua_tonumber(L, -1);
        //use number
    }
    lua_pop(L, 1);
}
lua_pop(L, 1);
```

## Multi Part Computing

this is the best introduction into the mechanism of secure multi party
computing with split shares:

   [1]https://blog.trailofbits.com/2019/10/04/multi-party-computation-on-machine-learning/

   and this are interesting serious libraries for implementation:

   [2]https://github.com/lschoe/mpyc

   and everything that "unbound" does:

   [3]https://www.unboundtech.com/cryptocurrency-protection-mpc-threshold-signing/

   [4]https://github.com/unbound-tech/blockchain-crypto-mpc


     """
     multi-part computing, shamir secret sharing for signing

     shamir splits as multiplication factors on a curve point

     A mul a point with her share -> Am
     B mul Am with his share -> Secret

     secret never recomposed, fully distributed computation
     """


## post-DECODE

https://github.com/fnuecke/eris

https://github.com/trezor/trezor-firmware

lua orchestration

3 different crypto setups
- cloud
- hardware wallets
- blockchain -> crypto conditions

https://tools.ietf.org/html/draft-thomas-crypto-conditions-04

metadata + business logic (oracle)
https://github.com/pakozm/lua-faces


distributed computing
https://github.com/briansmith/ring
"traveling virtual machines and secure enclaves"
smart agent concept



x86 crypto core
https://github.com/herumi/mcl
wolfssl


zencode mod example
https://gist.github.com/jpopesculian/bcbe046cd77064085b5b27e2ddfc6a03

lisp
https://github.com/SquidDev/urn

## BLS Multi-signature

https://docs.rs/indy-crypto/0.4.1/indy_crypto/bls/struct.Bls.html

https://github.com/hyperledger/ursa/blob/master/libursa/src/signatures/bls.rs

https://crypto.stanford.edu/~dabo/pubs/papers/BLSmultisig.html

https://eprint.iacr.org/2018/483



## Review

IV fine - if key is always different IV is not needed
for reusal of the key then IV needs to be random (or a counter)


RNG -> fortuna

ECDH keylen 16<k>64

ecdh_aead_encrypt limit key size to 32 bytes (256 bit)
accepted values to aes: 128 192 256



https://github.com/DECODEproject/Zenroom/blob/master/lib/milagro-crypto-c/src/ecdh.c.in#L71

co-factor of a curve
instead of checking always if point is part of curve
multiple of co-factors


## Low-hanging

- memory locking with controls at switch Given (r/o) -> When (r/w) -> Then (w/o)
- variable wiping with content overwriting in GC
- DATA and KEYS wiping in Zencode
X adopt finite state machine in Zencode parser
- wipe previous memory block in Zencode
X load multiple scenarios, build `documentation` scenario with ZEN.callback

## Benchmarking

extend redroom for in-memory benchmarks

prime number discovery using crypto primitives:
https://github.com/pakozm/lua-happy-prime-numbers/blob/master/happy_primes.lua

using perf-tool:
```
perf record zenroom $*
perf report
```

### Optimizations

Take DATA inside Zencode without parsing from JSON
- fast detect if JSON: `[` or `{` as first char
- fast detect of type by 3 char prefix: `u64:` or `b64:`
X read into IN with name of prefix (data schema)
X insure that parsing to ACK implies only one memcpy to octet




## Add-ons

### threshold and BLS-SSS

https://github.com/dashpay/dips/blob/master/dip-0006/bls_m-of-n_threshold_scheme_and_dkg.md

https://blog.dash.org/secret-sharing-and-threshold-signatures-with-bls-954d1587b5f

### BLS12-381

https://github.com/apache/incubator-milagro-crypto-c/issues/16

https://github.com/ethereum/eth2.0-specs/blob/dev/specs/bls_signature.md

https://github.com/pairingwg/bls_standard

https://github.com/sigp/milagro_bls/

https://github.com/lovesh

### master/slave states for scripting isolation

https://github.com/keplerproject/rings/blob/master/src/rings.c

maybe also useful for redroom

### Symbolic Calculus

https://github.com/pakozm/SymLua

### RPI integration

https://github.com/pakozm/BrickPi_Lua

### Zencode spell correction

https://github.com/pakozm/lua-spell-correct

### Forward chaining expert system development tool

https://github.com/pakozm/lua-faces

### microservice server
https://github.com/raksoras/luaw

### socks5 client
see lua socks5 ngx

### nanomsg

https://github.com/pakozm/xemsg

### message passing interface standard (MPI)

https://en.wikipedia.org/wiki/Message_Passing_Interface

https://github.com/jzrake/lua-mpi


## Deterministic Random in the Checker

take an external rng buffer filled with random by the caller

provide zencode with random from this pool and move the index forward

return an error when the random is exhausted and more is needed


## Coconut notes

useful to have a functio that does PAIR:ate and PAIR:fexp on the same ECP2
also ate() can be called miller_loop and miller() and loop()
FP12 = pair(ECP1, ECP2)
then FP12 equals is the only thing needed


```
require'ecp'
mypoint = ecp.hash_to_point(octet)
mynewbig = big.hash_to_big(13123,123123213,2334)
mypoint = ecp.hash(octet)
mynewbig = big.hash(1213123213,1221232141,123213324)
!! hash_to_big has variadic arguments !!

```
hash_to_point:
function that takes any octet string
hashes it with any hashing algorithm
does a mapit to place it on the curve

hash_to_big:
very useful to have
a hash function that takes a series of big numbers
and outputs a big number
the big number series can be simply concatenated
and then hashed as a series of bytes


expose G1 as fixed ECP point
expose G2 as fixed ECP2 point
i.e.
/* Generator point on G1 */
extern const BIG_384_29 CURVE_Gx_BLS383; /**< x-coordinate of generator point in group G1  */
extern const BIG_384_29 CURVE_Gy_BLS383; /**< y-coordinate of generator point in group G1  */
should become a const ECP

about DBIG: no need to expose
they result from big multiplications between big numbers
but there is never a real use, because all useful multiplications have a modulus applied

every FP is also a BIG
but not every BIG is also an FP
exporting in BIG is more interesting since it can be of any size
and can be reduced to FP to match the curve

each curve has a different infinity point

TODO: do all ecp2 (new namespace)

TODO: pair.h
extern void PAIR_ZZZ_fexp(FP12_YYY *x);
extern void PAIR_ZZZ_ate(FP12_YYY *r,ECP2_ZZZ *P,ECP_ZZZ *Q);
possibly extern int PAIR_ZZZ_GTmember(FP12_YYY *x);
!!!!
FP12_YYY is exactly twice as big of the FP1 of the curve
so its made of two BIGs and can be a tuple

TODO: big numbers operations
	in particular BIG_XXX_mod*

DONE:
infinity production for "EC generator"
test:
O = infinity point
P + O = P
(-P) + P = O
DONE:
to expose the order of the curve:
like in rom_curve_XXX:
const BIG_256_29 CURVE_Order_ED25519= {0x1CF5D3ED,0x9318D2,0x1DE73596,0x1DF3BD45,0x14D,0x0,0x0,0x0,0x100000};
test:
multiply group order by the generetor should give the point at infinity

## Generic improvements


^ add tracking of single lua command/operations executions

- erlang style pattern matching on data structures
  https://github.com/silentbicycle/tamale

- add brieflz2 compression

- add more memory tracking / fencing facilities also for script
  testing/profiling
	  https://github.com/kallisti5/ElectricFence
	  https://github.com/Ryandev/MemoryTracker

- parse lib/milagro-crypto-c/cmake/AMCLParameters.cmake for info about
  curves: size of BIG, names and pairing-friendliness

- add some more functions from stdlib's string and utils
  https://github.com/lua-stdlib/lua-stdlib

- Include libs from penlight
  http://stevedonovan.github.io/Penlight/api/index.html stringx, lexer

- date and time module
  https://github.com/Tieske/date

X in/out to MSGPACK in addition to JSON for compact messaging easy using
  Antirez' extension see https://github.com/antirez/lua-cmsgpack

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

V add a new 8bit memory manager to test
  https://github.com/8devices/MemoryManager perhaps also build a
  memory paging system to use 8bit mm over larger portions of memory

## Developer experience

^ on error print out code at line where it has been detected
  the line number is already included between semicolons
  just need to go to script buffer and extract line

- improve Jupyter kernel for zenroom
  - http://jupyter-client.readthedocs.io/en/latest/kernels.html
  - https://github.com/neomantra/lua_ipython_kernel

- language server in lua (lsp branch) followup

- graphviz representation of complex data structures
  http://siffiejoe.github.io/lua-microscope/

- add superior testing and profiling facility with lust
  https://github.com/bjornbytes/lust

- enhance debug module stacktrace
  https://github.com/ignacio/StackTracePlus

V introspection (now made with AST output)
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

## Security

- maybe support Linux kernel keystore feature for loaded keys
  (see cryptsetup 2.0)

X adopt a declarative approach to data schemes accepted in scripts
  supporting i.e. https://github.com/sschoener/lua-schema
  code analysis to report on bad constructs
  DONE - just write documentation, examples and tests

## Documentation

^ Start sketching an high-level API based on experience in DECODE

^ Provide cross-language examples for most basic operations

V Make it easy to integrate with BLOCKLY to generate simple
  cryptographic functions.

X Build a simple example webpage that runs only in javascript and
  compiles Zenroom scripts providing results

X Document api with luadoc http://keplerproject.github.io/luadoc/
  or other means http://lua-users.org/wiki/DocumentingLuaCode

## Crypto

^ Build a usable ABC implementation (maybe compatible with coconut
  and/or IRMA?)

- see if ECDAA is any useful https://github.com/xaptum/ecdaa
  has Direct Anonymous Attestation (DAA) and Schnorr sigs

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
