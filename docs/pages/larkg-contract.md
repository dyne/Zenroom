# LARKG cryptographic contract status

## Authoritative evidence

The primary source is Frymann *et al.*, *Asynchronous Remote Key Generation
for Post-Quantum Cryptosystems from Lattices*, IACR ePrint 2023/419
(<https://eprint.iacr.org/2023/419>).  Its
Kyber instantiation is Kyber1024 (level 5), with `n=256`, `k=4`, `q=3329`,
`eta1=eta2=2`, `du=11`, and `dv=5`.  It describes a Python implementation and
identifies `sccs/larkg` as its source repository.  That source was not publicly
retrievable during this review (GitHub returns an authentication challenge).

The paper's sKEM uses `s,e <- chi_eta^k`, `b = A*s + e`; encapsulator state
uses `r,e' <- chi_eta^k`, `u = A^T*r + e'`; and decapsulation recovers the
message from `v - s^T*u`.  Its LARKG-Kyber measurement uses a wider derived-key
distribution, with standard deviation `sigma_b = 5*sigma_a`, and states
`M=9` for the rejection envelope.  It has a separate relaxed correctness
parameter (`tau`), rather than an unbounded ratchet claim.

The in-tree implementation is not that parameterization: `params.h` selects
Kyber512 (`k=2`, `eta1=3`, `eta2=2`), while `kyber_larkg.c` uses `CBD(3)` for
both the current-secret and candidate weights and hard-codes `M=3`.  Thus the
paper does not justify enabling this construction as a supported default.

The exact-rational oracle duplicates only the published CBD probability table
and rejection equation; it neither imports nor executes production C code.
Its exhaustive single-coefficient checks are therefore independent of the
production bigint sampler.

## Required acceptance equation

For target density `f` and proposal density `g`, rejection sampling requires a
published finite envelope `M` such that `f(x) <= M*g(x)` over every candidate
in the support.  The exact acceptance probability is `f(x)/(M*g(x))`; it is
zero when `f(x)=0`, and a zero `g(x)` with nonzero `f(x)` is an invalid
parameterization, not a value to clip to one.  Secret and error distributions
require independent envelopes `M_S` and `M_E` whenever they differ.

The current code instead evaluates a product of CBD(3) weights as
`chi(K)/(3*chi(S))`.  It calls `K` out of support a rejection, but treats `S`
out of support as acceptance.  That behavior has no stated target/proposal
density or envelope proof and must not be assigned an LARKG security claim.

## Contract decision and availability gate

Until a reviewer accepts a parameterized distribution, domain labels,
authentication transcript, failure semantics, `M_S`/`M_E`, and a quantified
depth/correctness bound, Kyber512 LARKG is **experimental only**.  The current
public entry points are disabled by default through
`ZEN_ENABLE_EXPERIMENTAL_LARKG=0`.  The selector is shared by all build
platforms through `build/init.mk`: it removes `src/zen_larkg.o`, omits
`zencode_larkg.lua` from the embedded extension list, and leaves
`luaopen_larkg` unregistered.  `ZEN_ENABLE_EXPERIMENTAL_LARKG=1` is an
explicit evaluator opt-in; it restores exactly the legacy native module and
Zencode scenario without changing their algorithm or expected outputs.

The existing Zencode LARKG BATS suite is excluded from the default Meson test
set and remains an opt-in compatibility assertion.  Its source hash stays in
the manifest, so this availability boundary cannot silently weaken the legacy
assertions.  `test/larkg/experimental-gate.sh` checks the common selector in
the object, embedding, registration, and default test registration paths.

### Gate acceptance matrix

| Build mode | Required assertion |
| --- | --- |
| Default native | `nm` has no `luaopen_larkg` binding symbol; `require 'larkg'` fails; all non-LARKG baseline tests remain unchanged. |
| Explicit native opt-in | `ZEN_ENABLE_EXPERIMENTAL_LARKG=1` builds the binding; the existing LARKG BATS suite and native smoke test run unchanged, while the independent oracle remains the contract check. |
| Default WASM/platform builds | no LARKG module/object is linked unless the identical explicit opt-in is supported and selected for that platform. |
| Build registration | a source-level test checks that the object registration, native module registration, embedded Lua scenario, and default Meson registration are controlled by the same selector. |

This gate is an availability boundary only.  It makes no LARKG distribution,
acceptance, authentication, or ratchet-depth claim and does not alter the
legacy experimental implementation.

## Error growth and supported depth

The legacy implementation evolves a public key as

```
s_(t+1) = s_t + K_t
e_(t+1) = e_t + E_t
b_t     = A*s_t + e_t
```

where `K_t` is expanded from the recovered sKEM shared seed and `E_t` is
sampled independently.  In the current Kyber512 code both increments use
CBD(3), as do the initial `s_0` and `e_0`; therefore each centered
coefficient has support `[-3(t+1), 3(t+1)]` after `t` accepted derivations.
The
rejection rule only considers the secret-side `S_t`/`K_t` pair.  It supplies
neither a separate error-side `M_E` nor an error-growth acceptance mechanism,
so it cannot establish the paper's required independent `M_S` and `M_E`
envelopes when the two distributions differ.

For a deliberately conservative, representation-independent correctness
check, sKEM decapsulation has noise

```
e_t^T r - s_t^T e1 + e2.
```

With `k=2`, `n=256`, `eta(K_t)=eta(E_t)=eta(s_0)=eta(e_0)=3`,
`eta(r)=3`, and `eta(e1)=eta(e2)=2`, the coefficient-wise ring-product bound
is

```
B(t) = k*n*((3(t+1))*3 + (3(t+1))*2) + 2 = 7680(t+1) + 2.
```

Kyber512's decoding margin is `q/4 = 3329/4`; already `B(1)=15362` exceeds
that margin.  This is a conservative *non-proof of correctness*, not an
estimate of the actual failure probability.  It is sufficient to reject any
positive supported ratchet depth for the unreviewed legacy construction.

Accordingly, the explicit supported ratchet depth is **zero**.  The
experimental opt-in may exercise legacy derivations for compatibility and
research only; it has no deployed decryption-failure bound or LARKG security
claim.  A future supported parameterization must select independently
analysed `M_S` and `M_E`, a concrete failure target, and a versioned positive
depth before this limit can change.

`test/larkg/error_growth_oracle.py` independently freezes the parameters,
support recurrence, `q/4` margin, and depth-zero policy.  Any change to a
coefficient support, sKEM noise parameter, modulus, ring dimensions, or the
maximum supported depth fails the fixture until its accompanying bound and
review record are deliberately updated.

## Independent contract vectors

`test/larkg/oracle_vectors.py` and its checked-in
`test/larkg/oracle-vectors.json` are a standalone, compact algebraic oracle:
they model sKEM key generation, encapsulation/decapsulation, candidate-secret
recovery, authentication, rejection decisions, malformed credentials, and two
successive derivations.  The vector declares its deterministic transcript,
canonical coefficient representation, byte order, current Kyber key and
credential layouts, and the fact that the small reference model deliberately
uses no NTT or Montgomery encoding.  This makes representation conversion an
implementation obligation rather than an oracle dependency.

The `S=4,K=3` boundary vector expects an invalid zero-proposal parameter.  It
records the confirmed legacy defect: `larkg_rej_sampling` accepts an
out-of-support current-secret coefficient.  Thus this vector is intentionally
incompatible with the legacy experimental implementation while the supported
default build exposes no LARKG entry point.  The oracle imports neither
production C nor generated bindings, and hashes its fixed serialization, so a
production replacement cannot silently redefine its contract.
