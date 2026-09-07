#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Bind the independent depth fixture to the legacy source parameter choices.
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
params="$root/lib/pqclean/kyber512/params.h"
skem="$root/lib/pqclean/kyber512/skem.c"
larkg="$root/lib/pqclean/kyber512/kyber_larkg.c"

expect() {
    grep -Fq "$1" "$2" || {
        printf 'error-growth fixture no longer matches %s: %s\n' "$2" "$1" >&2
        exit 1
    }
}

expect '#define KYBER_N 256' "$params"
expect '#define KYBER_Q 3329' "$params"
expect '#define KYBER_K 2' "$params"
expect '#define KYBER_ETA1 3' "$params"
expect '#define KYBER_ETA2 2' "$params"
expect 'poly_getnoise_eta1(&E_prime_poly.vec[i]' "$larkg"
expect 'poly_getnoise_eta1(&K_poly.vec[i]' "$larkg"
expect 'poly_getnoise_eta1(&skpv.vec[i]' "$skem"
expect 'poly_getnoise_eta1(&e.vec[i]' "$skem"
expect 'poly_getnoise_eta1(&r.vec[i]' "$skem"
expect 'poly_getnoise_eta2(&e1.vec[i]' "$skem"
expect 'poly_getnoise_eta2(&e2, coins' "$skem"

python3 "$root/test/larkg/error_growth_oracle.py"
