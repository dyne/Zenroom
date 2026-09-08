#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Frozen compatibility gate for the pre-contract LARKG surface.
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
manifest=test/larkg/compatibility-manifest.sha256
bats="$root/test/bats/bin/bats"

verify_manifest() {
    (cd "$root" && sha256sum --check --status "$manifest")
}

case "${1:-}" in
    --verify-manifest)
        verify_manifest
        exit 0
        ;;
    --self-test)
        temp_manifest=$(mktemp)
        trap 'rm -f "$temp_manifest"' EXIT
        sed '0,/^[[:xdigit:]]\{64\}  /s/^[[:xdigit:]]\{4\}/0000/' "$root/$manifest" > "$temp_manifest"
        if (cd "$root" && sha256sum --check --status "$temp_manifest"); then
            printf '%s\n' 'compatibility manifest mutation was not detected' >&2
            exit 1
        fi
        exit 0
        ;;
    '')
        ;;
    *)
        printf '%s\n' "usage: $0 [--verify-manifest|--self-test]" >&2
        exit 64
        ;;
esac

verify_manifest
test -x "$root/zenroom"
test -f "$root/libzenroom.so"

# Run existing non-LARKG tests verbatim.  The LARKG suite is deliberately
# behavioural: its experimental path bypasses VM RNG, so no seeded transcript
# is claimed here.  It remains frozen in the manifest and runs unchanged only
# when the build explicitly enables the experimental entry points.
"$bats" "$root/test/determinism"
"$bats" "$root/test/vectors/qp.bats"
"$bats" "$root/test/zencode/kyber.bats"
"$bats" "$root/test/api/sign.bats"

case "${ZEN_ENABLE_EXPERIMENTAL_LARKG:-0}" in
    0)
        "$root/test/larkg/experimental-gate.sh" --default
        ;;
    1)
        "$root/test/larkg/experimental-gate.sh" --experimental
        "$bats" "$root/test/zencode/larkg.bats"
        ;;
    *)
        printf '%s\n' 'ZEN_ENABLE_EXPERIMENTAL_LARKG must be 0 or 1' >&2
        exit 64
        ;;
esac
