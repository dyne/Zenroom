# Zenroom AGENTS Guide

## Purpose

This file is for LLMs and other contributors starting work on Zenroom's core runtime.
It focuses on the code under `src/` and `src/lua/`.
It intentionally omits build instructions.

Zenroom is a small deterministic crypto VM:

- C creates and fences the runtime.
- Lua bootstraps the VM and owns most Zencode behavior.
- Zencode itself is parsed into an AST and executed inside that Lua runtime.


## First Mental Model

There are two layers:

1. Native runtime in C
   - VM lifecycle, memory policy, config parsing, RNG setup, I/O shims, parser helpers, Lua module registration, native crypto userdata/types.
2. Embedded Lua runtime
   - Zencode parser/state machine, schema system, `Given/When/Then`, branching/foreach, scenario loading, JSON/data conversion, high-level crypto flows.

If a change is about:

- VM startup, buffers, config, sandboxing, RNG, stdout/stderr, or Lua registration: look in `src/*.c`.
- Zencode grammar, statement matching, schemas, ACK/CODEC handling, or scenario behavior: look in `src/lua/*.lua`.


## Execution Flow

The main execution path for Zencode is:

1. `zencode_exec()` in [`src/zenroom.c`](/home/jrml/devel/zenroom/src/zenroom.c)
2. `zen_init_extra()` / `zen_init()`
3. Lua state creation with custom allocators, RNG, IO and parser hooks
4. `zen_lua_init()` from [`src/lua_modules.c`](/home/jrml/devel/zenroom/src/lua_modules.c)
5. embedded [`src/lua/init.lua`](/home/jrml/devel/zenroom/src/lua/init.lua)
6. `ZEN:begin()`, `ZEN:parse()`, `ZEN:run()` from [`src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua)

Important consequence: most "language" behavior is not in C parser code. C only provides small parsing helpers. The actual Zencode parser and executor live in Lua.


## Runtime Ownership Map

### C side

- [`src/zenroom.h`](/home/jrml/devel/zenroom/src/zenroom.h)
  - Public API, `zenroom_t`, scopes, exit codes, buffer limits.
- [`src/zenroom.c`](/home/jrml/devel/zenroom/src/zenroom.c)
  - VM lifecycle, Lua initialization, RNG seeding, input globals, execution entry points, teardown.
- [`src/cli-zenroom.c`](/home/jrml/devel/zenroom/src/cli-zenroom.c)
  - CLI wrapper, file loading, interactive mode, validation/introspection entry points.
- [`src/zencode-exec.c`](/home/jrml/devel/zenroom/src/zencode-exec.c)
  - Binding-oriented stdin/base64 executor.
- [`src/zen_config.c`](/home/jrml/devel/zenroom/src/zen_config.c)
  - `conf` parser: `debug`, `scope`, `rngseed`, `logfmt`, memory/iteration limits.
- [`src/zen_memory.c`](/home/jrml/devel/zenroom/src/zen_memory.c)
  - Lua allocators, startup allocator vs pool allocator.
- [`src/zen_io.c`](/home/jrml/devel/zenroom/src/zen_io.c)
  - Replaces `print`, `io.write`, logging, buffer-backed stdout/stderr behavior.
- [`src/zen_parse.c`](/home/jrml/devel/zenroom/src/zen_parse.c)
  - Small parser helpers exposed to Lua: prefix parsing, trimming, statement normalization, JSON token extraction, scenario listing.
- [`src/lua_modules.c`](/home/jrml/devel/zenroom/src/lua_modules.c)
  - Restricted `require`, embedded extension loading, native module registration.
- [`src/lua_functions.c`](/home/jrml/devel/zenroom/src/lua_functions.c)
  - Lua global/table/class helpers.

### Embedded Lua side

- [`src/lua/init.lua`](/home/jrml/devel/zenroom/src/lua/init.lua)
  - Runtime bootstrap, globals, scenario preloads, `CONF`, aliases, memory spaces.
- [`src/lua/zenroom_common.lua`](/home/jrml/devel/zenroom/src/lua/zenroom_common.lua)
  - Core helpers: type override, deterministic iteration helpers, deep map/copy/compare, tokenization.
- [`src/lua/statemachine.lua`](/home/jrml/devel/zenroom/src/lua/statemachine.lua)
  - Small FSM used by the Zencode parser.
- [`src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua)
  - Core Zencode engine: statement registration, AST creation, rule handling, branching/foreach control, runtime execution.
- [`src/lua/zencode_data.lua`](/home/jrml/devel/zenroom/src/lua/zencode_data.lua)
  - Input/output encoding, schema conversion, `guess_conversion`, `new_codec`, serialization.
- [`src/lua/zencode_given.lua`](/home/jrml/devel/zenroom/src/lua/zencode_given.lua)
  - Import/validation path from `IN` to `ACK`.
- [`src/lua/zencode_when.lua`](/home/jrml/devel/zenroom/src/lua/zencode_when.lua)
  - Generic mutation/manipulation steps.
- [`src/lua/zencode_then.lua`](/home/jrml/devel/zenroom/src/lua/zencode_then.lua)
  - Output materialization from `ACK`/`CODEC` into `OUT`.
- [`src/lua/zencode_verify.lua`](/home/jrml/devel/zenroom/src/lua/zencode_verify.lua)
  - Generic `IfWhen("verify ...")` predicates.


## Build System Mental Model

The build system is make-first.

- The top-level entry point is [`Makefile`](/home/jrml/devel/zenroom/Makefile).
- Real build logic lives in `build/*.mk` plus helper scripts in `build/`.
- Meson does not build Zenroom itself. In this repository it is used to declare and run test suites after make has produced the needed executable or wrapper.

For contributors, think of it like this:

1. GNU make builds binaries, shared libraries, generated sources, and third-party static libs.
2. Meson/BATS run test suites against those artifacts.


## Build File Ownership

- [`Makefile`](/home/jrml/devel/zenroom/Makefile)
  - Public front door. Dispatches to platform-specific makefiles and test entry points.
- [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk)
  - Central defaults: version metadata, source lists, include paths, dependency list, toolchain defaults, library graph.
- [`build/plugins.mk`](/home/jrml/devel/zenroom/build/plugins.mk)
  - Compiler selection overlays: release/debug, profiling, `LIBRARY`, optional `CCACHE`.
- [`build/deps.mk`](/home/jrml/devel/zenroom/build/deps.mk)
  - Generated-source rules and third-party dependency builds.
- [`build/posix.mk`](/home/jrml/devel/zenroom/build/posix.mk)
  - Main POSIX/Linux/macOS build recipe for `zenroom`, `lua-exec`, `zencode-exec`, and shared libs.
- [`build/musl.mk`](/home/jrml/devel/zenroom/build/musl.mk)
  - Static musl build.
- [`build/win-exe.mk`](/home/jrml/devel/zenroom/build/win-exe.mk), [`build/win-dll.mk`](/home/jrml/devel/zenroom/build/win-dll.mk)
  - MinGW cross-builds for Windows.
- [`build/apple-ios.mk`](/home/jrml/devel/zenroom/build/apple-ios.mk)
  - iOS static library variants.
- [`build/android.mk`](/home/jrml/devel/zenroom/build/android.mk), [`build/android.sh`](/home/jrml/devel/zenroom/build/android.sh)
  - Android shared-library build and multi-ABI packaging script.
- [`build/wasm.mk`](/home/jrml/devel/zenroom/build/wasm.mk)
  - Emscripten/WASM build rules.
- [`build/embed-lualibs`](/home/jrml/devel/zenroom/build/embed-lualibs)
  - Generates embedded Lua source bundle `src/lualibs_detected.c`.
- [`build/meson.build`](/home/jrml/devel/zenroom/build/meson.build), [`build/meson.options`](/home/jrml/devel/zenroom/build/meson.options)
  - Test orchestration only.


## What Make Actually Governs

Make is responsible for:

- selecting toolchains and flags
- embedding build metadata (`VERSION`, `COMMIT`, `BRANCH`, `CURRENT_YEAR`) into compiled C objects
- generating source files such as:
  - `src/lualibs_detected.c`
  - `src/zen_ecdh_factory.c`
  - `src/zen_ecp_factory.c`
  - `src/zen_big_factory.c`
- building bundled third-party static libraries in `lib/`
- linking final binaries and shared libraries
- creating platform-specific wrappers for certain test modes

The main source/dependency inventory is defined in [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk):

- `ZEN_SOURCES` is the canonical native object list used for the main binaries.
- `BUILD_DEPS` is the default prerequisite chain:
  - `apply-patches`, `milagro`, `lua54`, `embed-lua`, `mlkem`, `quantum-proof`, `ed25519-donna`, `longfellow-zk`, `zk-circuit-lang`, `zstd`

If a new C source file is part of the core binary, it usually needs to be added to `ZEN_SOURCES`.


## Generated Artifacts Contributors Must Remember

Two generated paths matter often:

- [`src/lualibs_detected.c`](/home/jrml/devel/zenroom/src/lualibs_detected.c)
  - Generated by `build/embed-lualibs` from all `src/lua/*.lua`.
  - If you add or rename embedded Lua modules, this file must be regenerated.
- `src/zen_*_factory.c`
  - Generated by the codegen scripts in `build/`.
  - These are curve-dependent factory files, not hand-maintained source.

This repo uses generated code as part of the normal make graph. Do not hand-edit those generated outputs unless you are intentionally debugging generation.


## Normal Build Paths

The top-level [`Makefile`](/home/jrml/devel/zenroom/Makefile) is intentionally thin and dispatches to specialized makefiles:

- `make posix-exe` -> `build/posix.mk`
- `make posix-lib` -> `build/posix.mk ... LIBRARY=1`
- `make linux-exe` / `make linux-lib`
- `make osx-exe` / `make osx-lib`
- `make musl`
- `make win-exe` / `make win-dll`
- `make ios-*`
- `make node-wasm`

Important practical point: the "real" POSIX build target is `build/posix.mk`, not the top-level file.


## Toolchain/Flag Model

Flag layering works roughly like this:

1. [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk) defines defaults, sources, includes, library graph.
2. Platform makefile adds platform-specific defines and linker flags.
3. [`build/plugins.mk`](/home/jrml/devel/zenroom/build/plugins.mk) overlays debug/release/profile/library/ccache behavior.
4. [`build/deps.mk`](/home/jrml/devel/zenroom/build/deps.mk) reuses those variables to build bundled dependencies consistently.

Notable conventions:

- non-`RELEASE` builds pick debug-ish flags by default
- `LIBRARY=1` adds shared-library-oriented flags
- `ASAN=1` switches the POSIX build into sanitizer mode
- some downstream libraries use the same compiler variables, so changing compiler selection in one place affects many sub-builds


## Meson’s Actual Role

Meson is used as a test manifest, not as the product build system.

The relevant files are:

- [`build/meson.build`](/home/jrml/devel/zenroom/build/meson.build)
- [`build/meson.options`](/home/jrml/devel/zenroom/build/meson.options)

Current behavior:

- `meson setup meson/ build/ ...` uses `build/` as the Meson source directory and `meson/` as the build directory.
- Meson discovers the already-built root `zenroom` binary with `find_program(root_dir+'zenroom')`.
- Most tests are BATS invocations over files under `test/`.
- Suite selection is controlled by the Meson `tests` array option.

This means:

- if `zenroom` or `zencode-exec` are missing, Meson test setup will fail
- make must run first for the relevant binary/wrapper path
- when a test mode swaps in a JS/Rust wrapper, make still owns that wrapper creation flow


## How Top-Level Test Targets Work

The top-level [`Makefile`](/home/jrml/devel/zenroom/Makefile) test targets are wrappers around Meson:

- `make check`
  - runs `meson setup meson/ build/ -D "tests=[...]"` and `ninja -C meson test`
- `make check-js`
  - first builds JS/WASM assets, creates a wrapper, then runs Meson-selected suites
- `make check-rs`
  - first builds the Rust wrapper binary, writes a local `zenroom` wrapper script, then runs Meson-selected suites
- `make check-osx`
  - same Meson/BATS model with a different test suite selection

So "tests are run using Meson" is true, but "Meson governs builds" is false here.


## Legacy/Secondary Test Logic

There is also [`build/tests.mk`](/home/jrml/devel/zenroom/build/tests.mk), which contains older direct-BATS test helpers and wrapper generation logic.

In the current top-level flow:

- the public `make check*` targets in [`Makefile`](/home/jrml/devel/zenroom/Makefile) use Meson
- `build/tests.mk` is still useful as reference for wrapper/test conventions and for understanding older/manual test flows

Do not assume `build/tests.mk` is the canonical entry point for normal CI-style testing unless you verify the caller.


## Embedded Lua Build Detail

Lua modules under `src/lua/` are not loaded from the filesystem at runtime in normal native builds.

Instead:

- `build/embed-lualibs` collects every `src/lua/*.lua`
- optional bytecode compilation can happen via `luac54`
- the script emits `src/lualibs_detected.c`
- [`src/lua_modules.c`](/home/jrml/devel/zenroom/src/lua_modules.c) loads those embedded modules via the generated `zen_extensions[]`

Consequence: if an agent edits or adds `src/lua/*.lua`, a rebuild may require regenerating the embed output before the runtime sees the change.


## Build-System Pitfalls

- Forgetting that `src/lualibs_detected.c` is generated from `src/lua/`.
- Adding a new core C file but not updating `ZEN_SOURCES` in [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk).
- Treating Meson as the source of truth for compilation flags or dependencies; it is not.
- Editing generated factory files instead of their generators.
- Assuming docs describe the exact current flow; the source makefiles are more authoritative than prose docs.
- Forgetting that some test modes rely on a wrapper named exactly `./zenroom` in the repo root.


## Vendorized Dependencies In `lib/`

The `lib/` tree is vendorized source, not a loose collection of optional packages.
Several of these libraries are in the default make dependency graph and are statically linked into Zenroom.

The main build-integrated vendor dirs are:

- [`lib/lua54`](/home/jrml/devel/zenroom/lib/lua54)
  - Vendored Lua 5.4 runtime, built as `liblua.a`.
  - Zenroom embeds and restricts this runtime rather than depending on a system Lua.
- [`lib/milagro-crypto-c`](/home/jrml/devel/zenroom/lib/milagro-crypto-c)
  - Apache Milagro Crypto Library (AMCL).
  - This is the main upstream native crypto substrate for Zenroom’s classic ECC/pairing/RSA/hash/random support.
- [`lib/ed25519-donna`](/home/jrml/devel/zenroom/lib/ed25519-donna)
  - Dedicated Ed25519 implementation used for EDDSA support.
- [`lib/pqclean`](/home/jrml/devel/zenroom/lib/pqclean)
  - Bundled post-quantum implementations used to build `libqpz.a`.
  - Includes Kyber/Dilithium-style families plus project-specific PQ entries.
- [`lib/mlkem`](/home/jrml/devel/zenroom/lib/mlkem)
  - Separate ML-KEM implementation built into static libs and linked by Zenroom for ML-KEM support.
- [`lib/longfellow-zk`](/home/jrml/devel/zenroom/lib/longfellow-zk)
  - ZK backend used by the Longfellow integration.
- [`lib/zk-circuit-lang`](/home/jrml/devel/zenroom/lib/zk-circuit-lang)
  - C++/Lua-facing circuit-language bindings layered on top of the Longfellow work.
- [`lib/zstd`](/home/jrml/devel/zenroom/lib/zstd)
  - Compression library built as a static dependency.

There are also directories present that are not part of the normal default build path documented in `BUILD_DEPS`, such as `mimalloc`, `openssl`, and `tinycc`. Do not assume every subtree in `lib/` participates in the shipping build.


## Milagro’s Role And Integration

Milagro is the most important third-party native dependency in this repository.

At a high level, Zenroom uses Milagro for:

- core cryptographic primitives and support types from `amcl.h`
- RNG/CSPRNG support
- elliptic-curve arithmetic
- pairing-friendly curve support
- ECDH/ECDSA support code
- RSA support
- X.509 helpers
- some hash/HMAC/AES support paths

You can see this directly in the codebase:

- many native sources include `amcl.h`, for example [`src/zen_random.c`](/home/jrml/devel/zenroom/src/zen_random.c), [`src/zen_octet.c`](/home/jrml/devel/zenroom/src/zen_octet.c), [`src/zen_big.c`](/home/jrml/devel/zenroom/src/zen_big.c), [`src/zen_hash.c`](/home/jrml/devel/zenroom/src/zen_hash.c), [`src/zen_ecdh.c`](/home/jrml/devel/zenroom/src/zen_ecdh.c), [`src/zen_rsa.c`](/home/jrml/devel/zenroom/src/zen_rsa.c)
- include paths for generated Milagro headers are injected from [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk)
- Milagro static libraries are linked explicitly from `lib/milagro-crypto-c/build/lib`

The normal integration path is:

1. [`build/deps.mk`](/home/jrml/devel/zenroom/build/deps.mk) target `milagro` configures `lib/milagro-crypto-c` with CMake
2. configuration is driven by `milagro_cmake_flags` from [`build/init.mk`](/home/jrml/devel/zenroom/build/init.mk)
3. that configuration selects curves, RSA levels, naming prefix, word size, and disables upstream features Zenroom does not want
4. Zenroom links the resulting static archives, notably:
   - `libamcl_core.a`
   - `libamcl_curve_${ecdh_curve}.a`
   - `libamcl_curve_${ecp_curve}.a`
   - `libamcl_pairing_${ecp_curve}.a`
   - `libamcl_rsa_2048.a`
   - `libamcl_rsa_4096.a`
   - `libamcl_x509.a`

Important local choices:

- Zenroom builds Milagro as static libraries, not shared libs.
- Zenroom requests only selected curves, not the full upstream matrix.
- Zenroom uses the `AMCL_` exported-function prefix.
- Zenroom enables X.509 support but disables several upstream Milagro features that are not part of the normal Zenroom build.

For agents, the practical rule is:

- if a bug is in high-level statement behavior, stay in Zenroom Lua/native wrapper code
- if a bug is in low-level curve math, RNG internals, or AMCL API expectations, inspect the Milagro integration and possibly upstream-generated headers/libs too
- do not casually change `milagro_cmake_flags` unless you understand the downstream impact on generated headers, linked library names, and wrapper code


## Other Important Vendor Roles

- [`lib/lua54`](/home/jrml/devel/zenroom/lib/lua54)
  - Provides the embedded interpreter Zenroom wraps and restricts. This is foundational, but Zenroom’s language/security behavior is mostly imposed in `src/` and `src/lua/`, not by patching Lua itself at runtime.
- [`lib/pqclean`](/home/jrml/devel/zenroom/lib/pqclean) and [`lib/mlkem`](/home/jrml/devel/zenroom/lib/mlkem)
  - Supply the post-quantum algorithms consumed by [`src/zen_qp.c`](/home/jrml/devel/zenroom/src/zen_qp.c) and the corresponding Lua scenario files.
- [`lib/ed25519-donna`](/home/jrml/devel/zenroom/lib/ed25519-donna)
  - Supplies Ed25519 primitives for [`src/zen_ed.c`](/home/jrml/devel/zenroom/src/zen_ed.c). Its build is configured to use Zenroom/Milagro-compatible custom hash integration.
- [`lib/longfellow-zk`](/home/jrml/devel/zenroom/lib/longfellow-zk) and [`lib/zk-circuit-lang`](/home/jrml/devel/zenroom/lib/zk-circuit-lang)
  - Back the Longfellow/ZK functionality exposed through [`src/zen_longfellow.c`](/home/jrml/devel/zenroom/src/zen_longfellow.c), [`src/lua/crypto_longfellow.lua`](/home/jrml/devel/zenroom/src/lua/crypto_longfellow.lua), and [`src/lua/crypto_zkcc.lua`](/home/jrml/devel/zenroom/src/lua/crypto_zkcc.lua).
- [`lib/zstd`](/home/jrml/devel/zenroom/lib/zstd)
  - Compression support statically linked into the final binary and also used by the ZK-related dependencies.


## Native Crypto Layer

The native userdata/types are exposed from `src/zen_*.c`. The main ones are:

- [`src/zen_octet.c`](/home/jrml/devel/zenroom/src/zen_octet.c): fundamental byte-array type, encodings, conversions.
- [`src/zen_big.c`](/home/jrml/devel/zenroom/src/zen_big.c): big integers.
- [`src/zen_hash.c`](/home/jrml/devel/zenroom/src/zen_hash.c): hashing/HMAC/multihash helpers.
- [`src/zen_ecp.c`](/home/jrml/devel/zenroom/src/zen_ecp.c) and [`src/zen_ecp2.c`](/home/jrml/devel/zenroom/src/zen_ecp2.c): elliptic-curve and pairing primitives.
- [`src/zen_ecdh.c`](/home/jrml/devel/zenroom/src/zen_ecdh.c), [`src/zen_ed.c`](/home/jrml/devel/zenroom/src/zen_ed.c), [`src/zen_p256.c`](/home/jrml/devel/zenroom/src/zen_p256.c), [`src/zen_rsa.c`](/home/jrml/devel/zenroom/src/zen_rsa.c), [`src/zen_bbs.c`](/home/jrml/devel/zenroom/src/zen_bbs.c), [`src/zen_qp.c`](/home/jrml/devel/zenroom/src/zen_qp.c), [`src/zen_x509.c`](/home/jrml/devel/zenroom/src/zen_x509.c), [`src/zen_longfellow.c`](/home/jrml/devel/zenroom/src/zen_longfellow.c): algorithm-specific bindings.

Pattern to preserve:

- Each native module exports `luaopen_*`.
- Registration happens through [`src/lua_modules.c`](/home/jrml/devel/zenroom/src/lua_modules.c).
- Most native classes are attached with `zen_add_class(...)`.
- Lua-side code depends on stable userdata names and octet conversion methods.


## Lua Scenario Layer

Files named `zencode_*.lua` are scenario/statement modules.

Typical responsibilities:

- register statements with `Given(...)`, `When(...)`, `Then(...)`, `IfWhen(...)`, `Foreach(...)`
- register schemas with `ZEN:add_schema(...)`
- use helpers such as `have`, `mayhave`, `empty`, `new_codec`, `initkeyring`, `havekey`

Representative families:

- generic data flow: `zencode_data`, `zencode_given`, `zencode_when`, `zencode_then`, `zencode_verify`, `zencode_foreach`, `zencode_table`, `zencode_array`
- utility/data transforms: `zencode_hash`, `zencode_random`, `zencode_time`, `zencode_pack`, `zencode_dictionary`, `zencode_http`, `zencode_math`
- crypto scenarios: `zencode_ecdh`, `zencode_eddsa`, `zencode_es256`, `zencode_rsa`, `zencode_bbs`, `zencode_qp`, `zencode_bitcoin`, `zencode_ethereum`, `zencode_schnorr`, `zencode_pvss`, `zencode_secshare`
- credential/document flows: `zencode_credential`, `zencode_w3c`, `zencode_vc`, `zencode_jwk`, `zencode_jws`, `zencode_jwt`, `zencode_sd_jwt`, `zencode_dcql_query`, `zencode_did`, `zencode_fsp`, `zencode_reflow`, `zencode_longfellow`

Files named `crypto_*.lua` are lower-level helpers used by scenarios, not the parser itself.


## Core Memory Model

The important Lua globals are created in [`src/lua/init.lua`](/home/jrml/devel/zenroom/src/lua/init.lua):

- `AST`: parsed Zencode statements
- `IN`: merged input data from `EXTRA`, `DATA`, `KEYS`
- `TMP`: staging area used mostly by `Given`
- `ACK`: working heap for validated/imported objects
- `OUT`: output heap
- `CODEC`: metadata describing objects in `ACK`/`OUT`
- `CACHE`: internal scratch/cache invisible to Zencode scripts
- `WHO`: active identity

Treat these as invariants:

- `Given` imports from `IN` into `ACK`; raw input should not leak around validation.
- `CODEC` must stay consistent with `ACK`.
- When a statement creates a new object in `ACK`, it usually also needs a `new_codec(...)`.
- `IN` is cleared when execution leaves `Given`.
- Object names are normalized with spaces converted to underscores.

If you mutate `ACK` without maintaining `CODEC`, you will usually create subtle runtime failures later in `Then`, verification, or heap guarding.


## Parser Model

The Zencode parser is stateful and mostly implemented in [`src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua).

Important facts:

- It uses a small finite-state machine from [`src/lua/statemachine.lua`](/home/jrml/devel/zenroom/src/lua/statemachine.lua).
- Statement matching is normalized, not literal. Hot normalization is in C via `normalize_zencode_statement(...)` from [`src/zen_parse.c`](/home/jrml/devel/zenroom/src/zen_parse.c).
- Branching and looping are represented in AST metadata, then enforced at runtime by `manage_branching` and `manage_foreach`.
- `scope=given` is special: parsing stops before `When`/`Then`, and missing input becomes non-fatal for CODEC discovery.

Do not casually change statement normalization rules. Small text changes can break many existing scenarios.


## Key Abstractions To Reuse

Prefer these helpers over ad-hoc logic:

- `guess_conversion(...)` and `operate_conversion(...)` for import logic
- `new_codec(...)` for metadata
- `have(...)`, `mayhave(...)`, `empty(...)` for heap access discipline
- `initkeyring()` / `havekey(...)` for key material
- `schema_get(...)` for schema import functions
- `CRYPTO.load(...)` from [`src/lua/crypto_loader.lua`](/home/jrml/devel/zenroom/src/lua/crypto_loader.lua) for algorithm lookup and normalized signing/verification/pubgen access

If you need a new algorithm-specific scenario, study:

- [`src/lua/zencode_ecdh.lua`](/home/jrml/devel/zenroom/src/lua/zencode_ecdh.lua)
- [`src/lua/zencode_keyring.lua`](/home/jrml/devel/zenroom/src/lua/zencode_keyring.lua)
- [`src/lua/crypto_loader.lua`](/home/jrml/devel/zenroom/src/lua/crypto_loader.lua)


## Determinism And Safety

Zenroom strongly prefers deterministic behavior.

Preserve these properties:

- no filesystem assumptions from embedded Lua
- no dynamic external module loading beyond the controlled `require`
- deterministic table traversal where the runtime already enforces it
- no hidden host-dependent behavior in scenario logic unless the feature is explicitly about time or randomness

Also preserve the isolation model:

- Lua `require` is overridden and curated in C
- stdout/stderr are intercepted
- inputs arrive through explicit globals (`KEYS`, `DATA`, `EXTRA`, `CONTEXT`)


## How To Choose Where To Edit

Use the narrowest layer that solves the problem:

- New statement wording or business behavior for an existing domain: edit the relevant `zencode_*.lua` scenario file.
- New import/export encoding or schema behavior: edit [`src/lua/zencode_data.lua`](/home/jrml/devel/zenroom/src/lua/zencode_data.lua) or the scenario schema registration.
- New generic `Given/When/Then` primitive: edit the base scenario files, not the parser.
- New native cryptographic primitive or userdata method: edit the matching `src/zen_*.c` file and its Lua registration path.
- Parser/state-machine change only when the syntax itself must change.

Challenge the first idea: many changes that look like "parser work" are really scenario/schema work.


## Common Pitfalls

- Forgetting `new_codec(...)` after creating a new `ACK` object.
- Writing a scenario that bypasses `schema_get`, `guess_conversion`, or keyring helpers and silently diverges from existing encoding conventions.
- Breaking statement normalization by changing human-readable wording without considering normalized lookup keys.
- Introducing duplicate statement registrations; the runtime explicitly rejects conflicting `Given/When/Then/IfWhen/Foreach` patterns.
- Treating Zenroom userdata as plain Lua strings/numbers. Most crypto values are userdata and should round-trip through `:octet()` or schema helpers.
- Ignoring the `scope=given` path; validation/introspection must still work.


## Tests Worth Reading

When you need behavior examples, start here:

- [`test/zencode/`](/home/jrml/devel/zenroom/test/zencode) for language/scenario behavior
- [`test/api/`](/home/jrml/devel/zenroom/test/api) for C API usage
- [`test/bats_zencode`](/home/jrml/devel/zenroom/test/bats_zencode) for the main BATS helpers

Useful details:

- `zexe` injects a fixed zero RNG seed by default, so many tests expect deterministic outputs.
- Successful BATS scenario runs also refresh cookbook example assets under `docs/examples/zencode_cookbook/...`.


## Suggested Reading Order For New Agents

1. [`src/zenroom.h`](/home/jrml/devel/zenroom/src/zenroom.h)
2. [`src/zenroom.c`](/home/jrml/devel/zenroom/src/zenroom.c)
3. [`src/lua/init.lua`](/home/jrml/devel/zenroom/src/lua/init.lua)
4. [`src/lua/zencode.lua`](/home/jrml/devel/zenroom/src/lua/zencode.lua)
5. [`src/lua/zencode_data.lua`](/home/jrml/devel/zenroom/src/lua/zencode_data.lua)
6. [`src/lua/zencode_given.lua`](/home/jrml/devel/zenroom/src/lua/zencode_given.lua)
7. [`src/lua/zencode_when.lua`](/home/jrml/devel/zenroom/src/lua/zencode_when.lua)
8. [`src/lua/zencode_then.lua`](/home/jrml/devel/zenroom/src/lua/zencode_then.lua)
9. the specific scenario file you need to touch


## Working Rule Of Thumb

Prefer minimal, local edits.

- Extend an existing scenario before inventing a new abstraction.
- Reuse schema and keyring conventions before adding special cases.
- Keep parser changes rare.
- Keep `ACK` and `CODEC` in lockstep.
- Preserve deterministic behavior unless the feature explicitly exists to model randomness or current time.
