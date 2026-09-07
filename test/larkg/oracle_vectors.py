#!/usr/bin/env python3
"""Small independent, deterministic LARKG contract-vector oracle.

The arithmetic model is intentionally tiny and transparent.  It checks the
protocol relations and wire contract without importing Zenroom or PQClean, so
an implementation may be replaced without changing this oracle.
"""
import hashlib
import json
import sys
from fractions import Fraction
from pathlib import Path

Q = 17
HALF_Q = Q // 2
A = ((2, 1), (1, 3))
CBD3 = {-3: 1, -2: 6, -1: 15, 0: 20, 1: 15, 2: 6, 3: 1}


def mod(values):
    return [value % Q for value in values]


def mat_vec(matrix, vector):
    return mod([sum(row[i] * vector[i] for i in range(2)) for row in matrix])


def mat_t_vec(matrix, vector):
    return mod([sum(matrix[i][j] * vector[i] for i in range(2)) for j in range(2)])


def add(left, right):
    return mod([x + y for x, y in zip(left, right)])


def dot(left, right):
    return sum(x * y for x, y in zip(left, right)) % Q


def keygen(secret, error):
    return add(mat_vec(A, secret), error)


def encaps(public, r, e1, e2, message):
    u = add(mat_t_vec(A, r), e1)
    v = (dot(public, r) + e2 + message * HALF_Q) % Q
    return {"u": u, "v": v}


def decaps(secret, ciphertext):
    value = (ciphertext["v"] - dot(secret, ciphertext["u"])) % Q
    # The model's message alphabet is {0, 1}; nearest 0 or floor(q/2).
    distance_zero = min(value, Q - value)
    distance_one = min((value - HALF_Q) % Q, (HALF_Q - value) % Q)
    return 0 if distance_zero < distance_one else 1


def tag(candidate_secret, candidate_error, chain):
    raw = json.dumps(
        {"chain": chain, "candidate_error": candidate_error,
         "candidate_secret": candidate_secret},
        separators=(",", ":"), sort_keys=True,
    ).encode()
    return hashlib.sha256(raw).hexdigest()[:32]


def density(value):
    return Fraction(CBD3.get(value, 0), 64)


def decision(target, proposal, envelope):
    target_density, proposal_density = density(target), density(proposal)
    if not target_density:
        return "reject-zero-target"
    if not proposal_density:
        return "invalid-zero-proposal"
    probability = target_density / (envelope * proposal_density)
    if probability > 1:
        return "invalid-envelope"
    return f"accept-probability-{probability.numerator}/{probability.denominator}"


def chain_step(state, candidate_secret, candidate_error, chain):
    next_secret = add(state["secret"], candidate_secret)
    next_error = add(state["error"], candidate_error)
    return {
        "chain": chain,
        "candidate_secret": candidate_secret,
        "candidate_error": candidate_error,
        "authentication": tag(candidate_secret, candidate_error, chain),
        "next_secret": next_secret,
        "next_error": next_error,
        "next_public": keygen(next_secret, next_error),
    }


def vectors():
    initial = {"secret": [1, -1], "error": [0, 1]}
    initial_public = keygen(initial["secret"], initial["error"])
    cipher = encaps(initial_public, [1, 0], [0, 1], 0, 1)
    assert decaps(initial["secret"], cipher) == 1
    first = chain_step(initial, [0, 1], [-1, 0], 1)
    second = chain_step(
        {"secret": first["next_secret"], "error": first["next_error"]},
        [-1, 0], [1, -1], 2,
    )
    return {
        "format": "larkg-independent-oracle-v1",
        "model": {
            "ring": "Z_17^2 scalar reference; arithmetic is canonical coefficient domain",
            "matrix_row_major": [list(row) for row in A],
            "ntt_montgomery": "none: vectors deliberately avoid implementation representation",
            "rng_transcript": [
                "keygen:s=[1,-1],e=[0,1]", "encap:r=[1,0],e1=[0,1],e2=0,m=1",
                "chain1:K=[0,1],E=[-1,0]", "chain2:K=[-1,0],E=[1,-1]",
            ],
        },
        "wire_contract": {
            "byte_order": "toy values are signed JSON integers; production Kyber poly bytes are 12-bit little-endian packs",
            "public_key": "polyvec bytes || rho[32] (Kyber512: 768 || 32)",
            "secret_key": "NTT polyvec bytes || last k_seed[32] (Kyber512: 768 || 32)",
            "credential": "B_prime[768] || c[128] || mu[32], total 928 bytes",
        },
        "skem": {
            "keygen": {"secret": initial["secret"], "error": initial["error"],
                       "public": initial_public},
            "encapsulation": {"ciphertext": cipher, "recovered_message": 1},
        },
        "chains": [first, second],
        "acceptance": {
            "s3_k3": decision(3, 3, 3),
            "zero_target": decision(4, 3, 3),
            "zero_proposal": decision(3, 4, 3),
            "boundary_s4_k3": {
                "contract": decision(3, 4, 3),
                "legacy_review_failure": "legacy accepts an out-of-support S=4",
            },
        },
        "malformed": {
            "credential_length_927": "reject",
            "credential_length_929": "reject",
            "authentication_tag_mismatch": "reject",
            "rho_public_mismatch": "reject",
        },
    }


def encoded():
    return json.dumps(vectors(), indent=2, sort_keys=True) + "\n"


def main():
    if sys.argv[1:] == ["--emit"]:
        print(encoded(), end="")
        return
    expected = Path(__file__).with_name("oracle-vectors.json").read_text()
    # Parsing makes the checked-in JSON readable; the pinned digest still
    # detects every serialized-artifact change, including whitespace changes.
    assert json.loads(expected) == vectors(), "oracle semantics changed"
    assert hashlib.sha256(expected.encode()).hexdigest() == (
        "244c7e9ac35daf21825ab04ac40a4a7943c11c7bd7f619ba61076ca583aa9ee0"
    ), "checked-in oracle vectors changed"


if __name__ == "__main__":
    main()
