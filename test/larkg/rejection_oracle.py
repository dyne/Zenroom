#!/usr/bin/env python3
"""Independent exact-rational checks for the proposed CBD(3) sampler."""
from fractions import Fraction

CBD3 = {-3: 1, -2: 6, -1: 15, 0: 20, 1: 15, 2: 6, 3: 1}


def probability(value: int) -> Fraction:
    return Fraction(CBD3.get(value, 0), 64)


def acceptance(target: int, proposal: int, envelope: int) -> Fraction:
    """Return f/(M*g), rejecting zero target and rejecting invalid envelopes."""
    f, g = probability(target), probability(proposal)
    if not f:
        return Fraction(0)
    if not g:
        raise ValueError("target has support where proposal is zero")
    value = f / (envelope * g)
    if value > 1:
        raise ValueError("invalid rejection envelope")
    return value


def main() -> None:
    # Full support, including both signs, makes the CBD(3) weights auditable.
    assert sum(CBD3.values()) == 64
    assert CBD3 == {-3: 1, -2: 6, -1: 15, 0: 20, 1: 15, 2: 6, 3: 1}

    # f=g has minimal envelope M=1; M=3 is valid but adds avoidable rejection.
    for target in range(-3, 4):
        for proposal in range(-3, 4):
            ratio = probability(target) / probability(proposal)
            if ratio <= 1:
                assert acceptance(target, proposal, 1) == ratio
            else:
                try:
                    acceptance(target, proposal, 1)
                except ValueError:
                    pass
                else:
                    raise AssertionError("oracle failed to reject an invalid envelope")
            assert acceptance(target, proposal, 20) == ratio / 20

    # Required support edge cases: K=3, S=3 and zero-probability inputs.
    assert acceptance(3, 3, 3) == Fraction(1, 3)
    assert acceptance(0, 0, 3) == Fraction(1, 3)
    assert acceptance(4, 3, 3) == 0
    try:
        acceptance(3, 4, 3)
    except ValueError:
        pass
    else:
        raise AssertionError("zero proposal probability must not be clipped")


if __name__ == "__main__":
    main()
