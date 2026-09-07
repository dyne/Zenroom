#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
python3 "$root/test/larkg/oracle_vectors.py"
python3 -m py_compile "$root/test/larkg/oracle_vectors.py"

# The boundary vector records a confirmed legacy defect: its sampler accepts an
# out-of-support current secret.  Keep the witness source-location explicit.
grep -Fq 'if (s > 3) return 0;' "$root/lib/pqclean/kyber512/kyber_larkg.c"
