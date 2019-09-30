# Random quality measurements

Obviously, randomness is very important when doing cryptography.

Zenroom accepts a random seed when called or retrieves one
automatically from the host system.

**Zenroom is fully deterministic**: if the same random seed is
provided then all results of transformations will be exactly the same,
except for the sorting order of elements in its output, which must be
sorted by the caller with a constant algorithm.

If the random seed is not provided at call time, then Zenroom does its
best to gather a good quality random seed from the host system. This
works well on Windows, OSX, GNU/Linux as well Android and iOS; but
beware that **when running in Javascript random is very weak**.

## Pseudo-random generator

In order to generate key material, it is often needed to have a random
number generator (RNG). But generating good randomness (one which is
unpredictable to attackers) is very challenging for a variety of reasons.
An alternative to use RNG is to use Pseudo Random Generators (PRNG), which
pseudo random data is generated from a seed by a deterministic algorithm.
It is often the case as well that the seed for this PRNG is actual real
random data.

In the context of a cryptographic system, this pseudo random data should not
give information of any past nor future outputs from the PRNG. This is
difficult to prevent as an attacker at some point might be able to acquire
the internal state of a PRNG, which can lead to they being able to
follow all of the outputs of the internal state of the generator. Once
the PRNG internal state is compromised is difficult to recover it a
secure state again.

Cryptographic strength is added to any random seed by Zenroom's
pseudo-random generator (PRNG) which is an [old RSA
standard](ftp://ftp.rsasecurity.com/pub/pdfs/bull-1.pdf) basically
consisting of:

```txt
Unguessable seed -> SHA -> PRNG internal state -> SHA -> random numbers
```
-----

This is a rather old PRNG and will soon be substituted with [the
Fortuna PRNG](https://en.wikipedia.org/wiki/Fortuna_(PRNG)) in
forthcoming versions.

Fortuna was designed by Niels Ferguson and Bruce Schneier. There are
three parts to Fortuna. The generator takes a fixed-size seed and
generates arbitrary amounts of pseudorandom data. The accumulator that
collects and pools entropy from various sources and occasionally reseeds
the generator. The seed file control that ensures that the PRNG can
generate random data even when the computer has just booted.

We will describe the three parts:

1. The Generator: this is basically a block cipher in Counter Mode (CTR).
   It converts a fixed size state to arbitrary long outputs.
2. Accumulator: collects real random data from various sources and uses it
   to reseed the generator.
3. Seed file control: the PRNG keeps a separate file full of entropy,
   called the seed file, which is read and used as entropy to get into an
   unknown state.

## Hamming distance frequency

As a reference indicator of results here we provide a graph that shows
the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance)
measuring how many different bits are there between each new random
776 bit long octets. This benchmark was run on a PC gathering entropy
from system events:

![Hamming distance random benchmark](img/random_hamming_gnuplot.png)

Here are represented four different random generation methods which
are commonly used in cryptographic transformations. It is noticeable
that the most common average distance is **between 380 and 400 bits**
for all of them.

## Measure your system

To have a value estimation on the system you are currently running
Zenroom, run this simple lua script:

```lua
print( BENCH.random_hamming_freq() )
```

Then compare the number returned: if much lower than 350 then you
should worry about the quality of random on your current system.
