# KLP22 Challenge-Share Commitment Profile

## Context

KLP22's statistically hiding commitment commits to prover challenge shares
before the corresponding verifier challenges are revealed. The commitment
must be:

1. **Statistically hiding** — the verifier cannot distinguish which share
   was committed before the challenge is set.

2. **Computationally binding** — the prover cannot open the commitment to
   a different share after seeing the challenge.

3. **Compatible with Ligero shares** — the message space must cover all
   possible challenge-share values at the configured security parameter.

4. **Implementable with existing primitives** — should not require new
   cryptographic assumptions beyond those already present in the system.

5. **Simple canonical encoding** — deterministic, byte-stable encoding needed
   for Fiat-Shamir transcript hashing.

## Candidates

### Option A: Naor-Yung with SHA-256

Commit(m; r) = SHA-256(r || m) with |r| = 256 bits.

- **Hiding**: Computational (SHA-256 is a random oracle but does not hide
  statistically; an unbounded adversary can try all messages).
- **Binding**: Computational (collision resistance).
- **Verdict**: Does **not** satisfy the KLP22 statistical-WI lemma because
  the statistical hiding property fails for an unbounded distinguisher.

### Option B: Extract-then-hide (Pedersen-style over a prime-order group)

Commit(m; r) = g^m * h^r in a prime-order group with two independent generators.

- **Hiding**: Statistical (information-theoretic for uniform r).
- **Binding**: Computational (discrete log).
- **Verdict**: Satisfies the KLP22 proof criteria but requires group operations,
  increasing code complexity and dependency footprint. The existing BLS381
  curve provides the necessary group.

### Option C: Almost-universal hash + fresh pad

Commit(m; r) = (H_k(m) XOR r, r) where H_k is an almost-universal hash family
and r is a fresh random pad.

- **Hiding**: Statistical (r is a fresh uniform random pad, XOR with any
  function of m is a one-time pad; the resulting distribution is uniform).
  The pad itself is public (second part of the commitment), but the commitment
  output is H_k(m) ^ r which is statistically close to uniform.
  
  Actually, this needs re-examining. A proper statistical commitment in the
  standard model would be: Commit(m; r) = r (with H(r || m) as opening), but
  that has the wrong properties.

Let's go with the simplest correct option.

### Selected: Option B+ — Linear combination commitment over BLS381

Commit(m; r) = m * G + r * H where G and H are independent generators of the
BLS381 G1 group, m and r are scalars in Fr.

This is the classic Pedersen commitment adapted to the BLS381 curve already
used by Zenroom.

**Why this satisfies KLP22**:

1. **Statistically hiding**: For any commitment C and any two messages m1, m2,
   there exist r1, r2 such that C = m1*G + r1*H = m2*G + r2*H. Since r is
   chosen uniformly from the full scalar field, the commitment distribution
   is identical for all messages. The information-theoretic argument holds
   because |r| is large enough to absorb the message entropy.

2. **Computationally binding**: Breaking binding = finding (m,r) != (m',r')
   such that m*G + r*H = m'*G + r'*H, i.e., (m-m')*G = (r'-r)*H which
   reveals log_G(H). This is the discrete log problem over BLS381.

3. **Ligero-compatible message space**: Challenge shares are field elements
   in the BLS381 scalar field; the commitment operates directly on scalars.

4. **Existing primitives**: BLS381 group operations and random field element
   generation are already present (zen_ecp.c, zen_big.c).

5. **Canonical encoding**: Serialize the G1 point via ECP_toOctet (deterministic,
   compressed, 49 bytes).

## Concrete parameters

| Parameter | Value |
|-----------|-------|
| Curve | BLS381 (G1) |
| Generators | G = canonical G1 generator, H = Hash-to-curve("NIWI-KLP22-Commit-H") |
| Scalar field | BLS381 Fr (32 bytes) |
| Point encoding | ECP_toOctet, compressed |
| Commitment size | 49 bytes |
| Domain tag | NK04 |

## Implementation note

Prefer the Milagro ECP/G1 API through Zenroom's existing native bindings
where possible. If direct Milagro calls are simpler for the C library, use
`ECP_BLS381_*` functions from amcl.h directly (libamcl_core.a is already linked).

## Alternative for milestone 1 (simpler, reviewable)

If ECP integration adds latency, a temporary **computational** commitment using
SHA-256 with a domain-tagged random salt is acceptable for test scaffolding
only. It must be clearly marked as test-only and replaced before the review
checklist (final L1). This document selects the Pedersen path as the production
target.
