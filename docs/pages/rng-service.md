# Zenroom RNG service decision

## Compatibility backend

Zenroom's default VM RNG remains the Milagro `csprng`.  Existing `rngseed`
inputs are passed to `AMCL_(RAND_seed)` unchanged and `zen_rng_fill` forwards
each requested byte directly to `RAND_byte`; it does not batch, prefetch, or
discard bytes.  This preserves the deterministic stream and consumption order
covered by the compatibility baseline.

The new public boundary is deliberately backend-neutral: callers use
`zen_rng_fill`, `zen_rng_reseed`, `zen_rng_clear`, and the
`zen_rng_callback_fill` callback/context adapter rather than Milagro types.
Each `zenroom_t` owns its generator; callers must provide synchronization when
sharing a context across threads.  Forked processes must initialize their own
context rather than sharing inherited generator state.

Contexts passed to `zen_rng_init` must be zero-initialized.  Initializing an
already initialized context fails without replacing or leaking its generator;
call `zen_rng_clear` before reinitializing, or use `zen_rng_reseed` to restart
the existing stream.

## Compatibility exceptions

Runtime consumers that only need bytes use the checked service.  A narrow set
of native Milagro calls still receives the opaque generator because its ABI
requires `csprng *`: `BIG_randomnum`, ECDH key generation and randomized
signing, and RSA key generation and OAEP encoding.  Reimplementing those
algorithms around byte buffers would alter their rejection sampling or seeded
stream consumption.  The source and relocation audit allowlists only these
call sites plus the RNG backend and VM lifecycle implementation.

## Entropy and backend selection

For a VM without an explicit seed, `zen_entropy_fill` obtains all 64 seed bytes
from the platform `randombytes` adapter.  Entropy failures fail initialization;
wall-clock bytes are not mixed into the seed.  The adapter is the only intended
OS-entropy entry point for runtime code.  Seed copies and generator state are
cleared during reseed failure and teardown.

`ARCH_CORTEX` retains its pre-existing zero-seed startup contract because the
current Cortex-M `randombytes` shim is a deterministic test stub, not a
validated entropy source.  Explicit seeds remain supported there.  A future
board-specific entropy adapter must return checked success/failure before this
runtime enables nondeterministic Cortex-M initialization.

No stronger default backend is selected in this change.  A replacement would
change seeded streams and must therefore be introduced as a separately named,
explicitly selected algorithm/version with published KATs on every supported
target.  The current tree has no such portable, maintained implementation
available without adding a new dependency, so retaining Milagro compatibility
mode is the deliberate engineering and security decision.

## API failure semantics

`zen_rng_fill(context, NULL, 0)` and `zen_entropy_fill(NULL, 0)` succeed.
Nonzero requests require a non-NULL buffer and initialized context; invalid
arguments and entropy failures return `-1`.  Reseeding rejects empty or
unrepresentable seed lengths and never modifies caller-owned seed material.
