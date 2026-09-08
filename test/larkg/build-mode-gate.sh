#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Exercise mode changes without cleaning so stale conditional objects cannot
# retain or break the experimental LARKG registration.
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

build_and_check() {
    local mode=$1
    make -C "$root" linux-lib linux-exe CCACHE=1 \
        ZEN_ENABLE_EXPERIMENTAL_LARKG="$mode"
    if [[ $mode == 1 ]]; then
        "$root/test/larkg/experimental-gate.sh" --experimental
    else
        "$root/test/larkg/experimental-gate.sh" --default
    fi
}

build_and_check 0
build_and_check 1
build_and_check 0
