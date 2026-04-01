# Zenroom AGENTS

## Scope

This guide is for work on the core runtime in `src/` and `src/lua/`.
Goal: minimal context, enough to edit safely.

Zenroom is a deterministic crypto VM:

- C owns VM lifecycle, config, RNG, memory, IO shims, native crypto bindings.
- Lua owns bootstrap, Zencode parsing, schemas, `Given/When/Then`, scenarios.
- Zencode is not parsed by a big C parser. It is mostly parsed and executed in Lua.


## Fast Mental Model

If the change is about:

- startup, buffers, config, RNG, allocators, logging, `require`, native userdata: edit `src/*.c`
- statement wording, schemas, import/export, heap objects, crypto scenarios, parser behavior: edit `src/lua/*.lua`

Default execution path:

1. [`zencode_exec` in `src/zenroom.c`](/home/jrml/devel/zenroom/src/zenroom.c)
2. `zen_init_extra()` / `zen_init()`
3. Lua state + IO/parser/random hooks
4. [`zen_lua_init` in `src/lua_modules.c`](/home/jrml/devel/zenroom/src/lua_modules.c)
5. [`src/lua/init.lua`](/home/jrml/devel/zenroom/src/lua/init.lua)
6. [`ZEN:begin()`, `ZEN:parse()`, `ZEN:run()` in `src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua)


## Core Files

Native runtime:

- [`src/zenroom.h`](/home/jrml/devel/zenroom/src/zenroom.h): public API, `zenroom_t`, limits, scopes, exit codes
- [`src/zenroom.c`](/home/jrml/devel/zenroom/src/zenroom.c): init/exec/teardown
- [`src/cli-zenroom.c`](/home/jrml/devel/zenroom/src/cli-zenroom.c): CLI, file loading, validation/introspection entry points
- [`src/zencode-exec.c`](/home/jrml/devel/zenroom/src/zencode-exec.c): binding-oriented base64/stdin executor
- [`src/zen_config.c`](/home/jrml/devel/zenroom/src/zen_config.c): `conf` parsing
- [`src/zen_memory.c`](/home/jrml/devel/zenroom/src/zen_memory.c): allocators
- [`src/zen_io.c`](/home/jrml/devel/zenroom/src/zen_io.c): `print`, `io.write`, stderr/stdout handling
- [`src/zen_parse.c`](/home/jrml/devel/zenroom/src/zen_parse.c): Lua-visible parsing helpers
- [`src/lua_modules.c`](/home/jrml/devel/zenroom/src/lua_modules.c): restricted `require`, embedded Lua loading, native module registration

Lua runtime:

- [`src/lua/init.lua`](/home/jrml/devel/zenroom/src/lua/init.lua): bootstrap, globals, scenario preload, `CONF`
- [`src/lua/zenroom_common.lua`](/home/jrml/devel/zenroom/src/lua/zenroom_common.lua): type/deepmap/deterministic helpers
- [`src/lua/statemachine.lua`](/home/jrml/devel/zenroom/src/lua/statemachine.lua): parser FSM
- [`src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua): parser, AST, runtime executor
- [`src/lua/zencode_data.lua`](/home/jrml/devel/zenroom/src/lua/zencode_data.lua): encodings, schemas, `guess_conversion`, `new_codec`
- [`src/lua/zencode_given.lua`](/home/jrml/devel/zenroom/src/lua/zencode_given.lua): import/validation
- [`src/lua/zencode_when.lua`](/home/jrml/devel/zenroom/src/lua/zencode_when.lua): generic mutation steps
- [`src/lua/zencode_then.lua`](/home/jrml/devel/zenroom/src/lua/zencode_then.lua): output materialization
- [`src/lua/zencode_verify.lua`](/home/jrml/devel/zenroom/src/lua/zencode_verify.lua): generic `verify ...` predicates


## Heap And Data Invariants

Main Lua globals:

- `AST`: parsed statements
- `IN`: merged input from `EXTRA`, `DATA`, `KEYS`
- `TMP`: staging area during `Given`
- `ACK`: validated working heap
- `OUT`: output heap
- `CODEC`: metadata for objects in `ACK` / `OUT`
- `CACHE`: internal scratch cache
- `WHO`: active identity

Rules to preserve:

- `Given` moves validated data from `IN` to `ACK`
- `CODEC` must stay aligned with `ACK`
- new `ACK` objects usually need `new_codec(...)`
- `IN` is cleared when leaving `Given`
- object names are normalized by replacing spaces with underscores

If you mutate `ACK` without updating `CODEC`, later `Then`, verification, and heap guards will fail in non-obvious ways.


## Parser Rules

The parser is in [`src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua), not in a big native parser.

Important facts:

- it uses the FSM in [`src/lua/statemachine.lua`](/home/jrml/devel/zenroom/src/lua/statemachine.lua)
- statement matching is normalized, not literal
- hot normalization lives in C: `normalize_zencode_statement(...)` in [`src/zen_parse.c`](/home/jrml/devel/zenroom/src/zen_parse.c)
- branching and foreach become AST metadata, then runtime control via `manage_branching` / `manage_foreach`
- `scope=given` stops parsing before `When` / `Then` and is used for input validation / CODEC discovery

Do not change normalization casually. Tiny wording changes can break many scenarios.


## Reuse These Helpers

Prefer existing helpers over custom logic:

- `guess_conversion(...)`, `operate_conversion(...)`
- `new_codec(...)`
- `have(...)`, `mayhave(...)`, `empty(...)`
- `schema_get(...)`
- `initkeyring()`, `havekey(...)`
- `CRYPTO.load(...)` from [`src/lua/crypto_loader.lua`](/home/jrml/devel/zenroom/src/lua/crypto_loader.lua)

If adding a new crypto scenario, study:

- [`src/lua/zencode_ecdh.lua`](/home/jrml/devel/zenroom/src/lua/zencode_ecdh.lua)
- [`src/lua/zencode_keyring.lua`](/home/jrml/devel/zenroom/src/lua/zencode_keyring.lua)
- [`src/lua/crypto_loader.lua`](/home/jrml/devel/zenroom/src/lua/crypto_loader.lua)


## Native Crypto Layer

Main native userdata modules:

- [`src/zen_octet.c`](/home/jrml/devel/zenroom/src/zen_octet.c)
- [`src/zen_big.c`](/home/jrml/devel/zenroom/src/zen_big.c)
- [`src/zen_hash.c`](/home/jrml/devel/zenroom/src/zen_hash.c)
- [`src/zen_ecp.c`](/home/jrml/devel/zenroom/src/zen_ecp.c)
- [`src/zen_ecp2.c`](/home/jrml/devel/zenroom/src/zen_ecp2.c)
- [`src/zen_ecdh.c`](/home/jrml/devel/zenroom/src/zen_ecdh.c)
- [`src/zen_ed.c`](/home/jrml/devel/zenroom/src/zen_ed.c)
- [`src/zen_p256.c`](/home/jrml/devel/zenroom/src/zen_p256.c)
- [`src/zen_rsa.c`](/home/jrml/devel/zenroom/src/zen_rsa.c)
- [`src/zen_bbs.c`](/home/jrml/devel/zenroom/src/zen_bbs.c)
- [`src/zen_qp.c`](/home/jrml/devel/zenroom/src/zen_qp.c)
- [`src/zen_x509.c`](/home/jrml/devel/zenroom/src/zen_x509.c)
- [`src/zen_longfellow.c`](/home/jrml/devel/zenroom/src/zen_longfellow.c)

Preserve:

- `luaopen_*` exports
- registration through [`src/lua_modules.c`](/home/jrml/devel/zenroom/src/lua_modules.c)
- stable userdata names and octet conversion behavior


## Scenario Layer

`src/lua/zencode_*.lua` files are scenario modules. They:

- register `Given(...)`, `When(...)`, `Then(...)`, `IfWhen(...)`, `Foreach(...)`
- register schemas with `ZEN:add_schema(...)`
- define domain behavior on top of the shared heap/helpers

`src/lua/crypto_*.lua` files are lower-level Lua crypto helpers used by scenarios.

Typical edit choice:

- new statement wording / business flow: scenario file
- new import/export encoding or schema: `zencode_data.lua` or scenario schema
- new generic data primitive: base `zencode_*` file
- new native crypto primitive: `src/zen_*.c`
- parser/state-machine change: only if syntax must actually change


## Build And Test Model

Build system is make-first:

- top-level entry: [`Makefile`](/home/jrml/devel/zenroom/Makefile)
- real build logic: `build/*.mk` and `build/*` scripts
- test orchestration: Meson + BATS

Use these files as build truth:

- [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk): `ZEN_SOURCES`, include paths, linked libs, `BUILD_DEPS`
- [`build/plugins.mk`](/home/jrml/devel/zenroom/build/plugins.mk): debug/release/library/ccache flag overlay
- [`build/deps.mk`](/home/jrml/devel/zenroom/build/deps.mk): generated files and bundled dependency builds
- [`build/posix.mk`](/home/jrml/devel/zenroom/build/posix.mk): normal POSIX build
- [`build/meson.build`](/home/jrml/devel/zenroom/build/meson.build): test manifest only

Critical build facts:

- Meson does not build Zenroom itself; it runs tests against already-built binaries or wrappers
- generated files include:
  - `src/lualibs_detected.c`
  - `src/zen_ecdh_factory.c`
  - `src/zen_ecp_factory.c`
  - `src/zen_big_factory.c`
- if you add a new core C file, update `ZEN_SOURCES`
- if you add or rename `src/lua/*.lua`, regenerate the embedded Lua bundle

Useful test entry points:

- [`test/zencode/`](/home/jrml/devel/zenroom/test/zencode)
- [`test/api/`](/home/jrml/devel/zenroom/test/api)
- [`test/bats_zencode`](/home/jrml/devel/zenroom/test/bats_zencode)

Important test detail:

- `zexe` injects a fixed zero RNG seed, so many tests expect deterministic outputs


## Vendorized Dependencies

Main build-integrated vendors:

- [`lib/lua54`](/home/jrml/devel/zenroom/lib/lua54): vendored Lua runtime
- [`lib/milagro-crypto-c`](/home/jrml/devel/zenroom/lib/milagro-crypto-c): main upstream crypto substrate
- [`lib/ed25519-donna`](/home/jrml/devel/zenroom/lib/ed25519-donna): Ed25519 implementation
- [`lib/pqclean`](/home/jrml/devel/zenroom/lib/pqclean): PQ algorithms used for `libqpz.a`
- [`lib/mlkem`](/home/jrml/devel/zenroom/lib/mlkem): ML-KEM static libs
- [`lib/longfellow-zk`](/home/jrml/devel/zenroom/lib/longfellow-zk): ZK backend
- [`lib/zk-circuit-lang`](/home/jrml/devel/zenroom/lib/zk-circuit-lang): circuit-language bindings
- [`lib/zstd`](/home/jrml/devel/zenroom/lib/zstd): compression

Milagro specifics:

- configured in [`build/deps.mk`](/home/jrml/devel/zenroom/build/deps.mk) using flags from [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk)
- built as static libs, not shared libs
- Zenroom links `libamcl_core`, selected `libamcl_curve_*`, `libamcl_pairing_*`, RSA libs, and `libamcl_x509`
- many core native files include `amcl.h`

Do not change `milagro_cmake_flags` casually. It affects generated headers, available curves, library names, and wrapper assumptions.


## Determinism And Safety

Preserve:

- deterministic behavior unless the feature is explicitly about randomness or time
- no filesystem assumptions from embedded Lua
- no unrestricted external module loading
- the curated `require`
- intercepted stdout/stderr
- explicit input globals: `KEYS`, `DATA`, `EXTRA`, `CONTEXT`


## Common Failure Modes

- creating `ACK` objects without `new_codec(...)`
- bypassing `schema_get`, `guess_conversion`, or keyring helpers
- changing statement wording without considering normalized lookup
- duplicate statement registrations
- treating userdata as plain strings/numbers instead of using `:octet()` or schema helpers
- ignoring `scope=given`
- editing generated files instead of generators
- treating Meson as the build source of truth


## Reading Order

1. [`src/zenroom.h`](/home/jrml/devel/zenroom/src/zenroom.h)
2. [`src/zenroom.c`](/home/jrml/devel/zenroom/src/zenroom.c)
3. [`src/lua/init.lua`](/home/jrml/devel/zenroom/src/lua/init.lua)
4. [`src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua)
5. [`src/lua/zencode_data.lua`](/home/jrml/devel/zenroom/src/lua/zencode_data.lua)
6. [`src/lua/zencode_given.lua`](/home/jrml/devel/zenroom/src/lua/zencode_given.lua)
7. [`src/lua/zencode_when.lua`](/home/jrml/devel/zenroom/src/lua/zencode_when.lua)
8. [`src/lua/zencode_then.lua`](/home/jrml/devel/zenroom/src/lua/zencode_then.lua)
9. then the specific scenario or native module you need


## Rule Of Thumb

Prefer minimal, local edits.

- extend existing scenarios before inventing abstractions
- keep parser changes rare
- keep `ACK` and `CODEC` in lockstep
- use makefiles as build truth
- use the narrowest layer that solves the problem
