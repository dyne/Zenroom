#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
python3 "$root/test/larkg/oracle_vectors.py"
python3 -m py_compile "$root/test/larkg/oracle_vectors.py"

# Every out-of-support coefficient is rejected before density arithmetic; the
# legacy branch accepted an out-of-support current secret as probability one.
grep -Fq 'uint32_t out_of_support = magnitude > 3;' "$root/lib/pqclean/kyber512/kyber_larkg.c"
grep -Fq 'invalid != 0 || found == 0' "$root/lib/pqclean/kyber512/kyber_larkg.c"
grep -Fq 'Zenroom/LARKG/v1/auth' "$root/lib/pqclean/kyber512/kyber_larkg.c"
grep -Fq 'randombytes(coins, KYBER_SYMBYTES) != 0' "$root/lib/pqclean/kyber512/skem.c"
grep -Fq 'randombytes(buf, KYBER_SSBYTES) != 0' "$root/lib/pqclean/kyber512/skem.c"
grep -Fq 'LARKG_ENTROPY_FAILURE' "$root/lib/pqclean/kyber512/kyber_larkg.c"
