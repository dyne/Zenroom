#!/usr/bin/env python3
"""Independent conservative error-growth bound for legacy experimental LARKG.

This fixture deliberately imports no production code.  Its constants are the
published/current Kyber512 parameters that must be reviewed together with any
positive LARKG ratchet-depth claim.
"""
from fractions import Fraction

KYBER_K = 2
KYBER_N = 256
KYBER_Q = 3329
ETA_INITIAL_SECRET = 3
ETA_INITIAL_ERROR = 3
ETA_SECRET_INCREMENT = 3
ETA_ERROR_INCREMENT = 3
ETA_ENCAPSULATOR_SECRET = 3  # r
ETA_ENCAPSULATOR_ERROR = 2  # e1
ETA_CIPHERTEXT_ERROR = 2  # e2
MAX_SUPPORTED_DEPTH = 0


def accumulated_support(initial: int, increment: int, depth: int) -> int:
    """Maximum centered coefficient magnitude after ``depth`` derivations."""
    if depth < 0:
        raise ValueError("depth must not be negative")
    return initial + depth * increment


def decapsulation_noise_bound(depth: int) -> int:
    """L-infinity bound for e_t^T r - s_t^T e1 + e2 in R_q."""
    secret = accumulated_support(
        ETA_INITIAL_SECRET, ETA_SECRET_INCREMENT, depth
    )
    error = accumulated_support(ETA_INITIAL_ERROR, ETA_ERROR_INCREMENT, depth)
    return (
        KYBER_K
        * KYBER_N
        * (error * ETA_ENCAPSULATOR_SECRET + secret * ETA_ENCAPSULATOR_ERROR)
        + ETA_CIPHERTEXT_ERROR
    )


def main() -> None:
    # CBD(3) support applies to the initial values and each legacy increment.
    assert accumulated_support(ETA_INITIAL_SECRET, ETA_SECRET_INCREMENT, 0) == 3
    assert accumulated_support(ETA_INITIAL_SECRET, ETA_SECRET_INCREMENT, 1) == 6
    assert accumulated_support(ETA_INITIAL_ERROR, ETA_ERROR_INCREMENT, 1) == 6

    decoding_margin = Fraction(KYBER_Q, 4)
    assert decapsulation_noise_bound(0) == 7682
    assert decapsulation_noise_bound(1) == 15362
    assert decapsulation_noise_bound(1) > decoding_margin

    # No positive depth has an analysed correctness/security claim.  This is
    # intentionally a depth-zero policy, not a claim about empirical success.
    assert MAX_SUPPORTED_DEPTH == 0
    assert decapsulation_noise_bound(MAX_SUPPORTED_DEPTH + 1) > decoding_margin


if __name__ == "__main__":
    main()
