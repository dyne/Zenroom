# LARKG compatibility baseline

This document freezes the compatibility evidence present at branch baseline
`e9f31e67`.  It is a regression boundary, not an endorsement of the current
LARKG construction.  In particular, it does **not** characterize or create
vectors for the current LARKG proposal/acceptance distribution.

Run the mandatory gate after a native build with:

```sh
make compatibility-larkg
```

The gate first verifies `test/larkg/compatibility-manifest.sha256`, then runs
the listed non-LARKG tests unchanged.  The LARKG behavioural BATS suite is
also run unchanged when the binary was built with
`ZEN_ENABLE_EXPERIMENTAL_LARKG=1`; normal builds instead assert that its public
entry points are absent.  `make check` depends on the same gate.  The
manifest is deliberately small and only hashes files that contain existing
expected bytes or assertions relevant to the Kyber/LARKG/RNG boundary.
`test/larkg/compatibility.sh --self-test` proves that changing a protected
expected artifact is detected before any test is executed.

| Surface | Existing command | Existing asserted artifact/contract | RNG classification |
| --- | --- | --- | --- |
| VM seeded determinism | `test/determinism` | same explicit `rngseed` produces the same VM output; different seeds diverge | VM RNG consumer |
| Kyber/PQ KATs | `test/vectors/qp.bats` | `kyber512.rsp`, ML-KEM, ML-DSA and Dilithium response files | Kyber convenience paths use `randombytes()`; KAT verification itself is deterministic |
| Zencode Kyber | `test/zencode/kyber.bats` | fixed public-key and end-to-end success assertions | registered QP operations mix VM-backed explicit coins with vendor bypasses; preserve asserted output only |
| LARKG Zencode (explicit experimental build only) | `test/zencode/larkg.bats` | schema lengths, rho binding, authentication failure, and successful two-step ratchet | **confirmed bypass:** `src/zen_larkg.c`, `skem.c`, and `kyber_larkg.c` call `randombytes()`; no prior seeded-stream contract |
| Native LARKG smoke test | `make -C lib/pqclean/kyber512 test_larkg && ./lib/pqclean/kyber512/test_larkg` | three-round recovery and corrupted-tag rejection; manual target | **confirmed bypass:** test and implementation call `randombytes()` |
| C signing API | `test/api/sign.bats` | fixed EdDSA key, public-key, signature and boolean results for the all-zero external seed | standalone Milagro RNG context; explicit seed is a public deterministic contract |
| JavaScript/WASM binding | `yarn --cwd bindings/javascript test` after `make node-wasm` | binding unit assertions; no LARKG entry point is exposed | available WASM lane; not a LARKG vector source |

The protected test source hashes make weakening an existing assertion visible.
They do not prevent approved future changes to a test: any such change must
first be reviewed as a compatibility decision and update this manifest with a
documented reason.  The normal contract work must instead add independent,
reviewed oracle vectors for LARKG.

## Required execution matrix

For a release-quality baseline, execute twice from clean build directories:

```sh
make clean && make linux-lib linux-exe CCACHE=1 && make compatibility-larkg
make clean && make linux-lib linux-exe CCACHE=1 && make compatibility-larkg
make clean && make linux-lib linux-exe CCACHE=1 COMPILER=clang COMPILER_CXX=clang++
make compatibility-larkg
make clean && make linux-lib linux-exe CCACHE=1 ZEN_ENABLE_EXPERIMENTAL_LARKG=1
ZEN_ENABLE_EXPERIMENTAL_LARKG=1 make compatibility-larkg
make node-wasm && yarn --cwd bindings/javascript test
```

The GCC and Clang native lanes are mandatory where those compilers are
installed; the WASM lane is mandatory where the repository's Emscripten/Yarn
toolchain is available.  Keep the resulting command exit statuses with the
L1 review evidence.  No LARKG generated artifact belongs in this baseline.

### ML-KEM multilevel build note

Do not substitute `make -B` for the clean-build commands above.  The vendored
ML-KEM aggregate archive is deliberately assembled after separate 512, 768,
and 1024 object builds.  A forced rebuild of only the aggregate target applies
its final (`mlkem1024`) namespace flag to every object and produces an archive
without the 512/768 symbols required by `src/zen_qp.c`.  A normal rebuild after
`make clean` (or `make -C lib/mlkem clean` before rebuilding that dependency)
preserves the intended ordered three-level build.  This was verified by
checking `mlkem512_keypair_derand` and `mlkem768_keypair_derand` in the rebuilt
archive before linking the GCC and Clang core lanes.
