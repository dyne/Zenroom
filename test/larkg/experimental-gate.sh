#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Verify that LARKG is unavailable unless the explicit experimental selector
# was used for the current build.  This script never changes test vectors.
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

static_gate() {
    grep -Fq 'ZEN_ENABLE_EXPERIMENTAL_LARKG ?= 0' "$root/build/init.mk" || fail 'missing default-off selector'
    grep -Fq 'ZEN_SOURCES := $(filter-out src/zen_larkg.o' "$root/build/init.mk" || fail 'ungated LARKG object'
    grep -Fq 'LUA_EMBED_EXCLUDES += zencode_larkg.lua' "$root/build/init.mk" || fail 'ungated LARKG scenario'
    grep -Fq 'src/lua_modules_cli_larkg.o' "$root/build/init.mk" || fail 'registration object is not mode-specific'
    grep -Fq 'src/lua_modules_cli_default.o' "$root/build/init.mk" || fail 'default registration object is not mode-specific'
    grep -Fq 'force-larkg-build-mode-link' "$root/build/posix.mk" || fail 'final link does not track build mode'
    grep -Fq '#ifdef ZEN_ENABLE_EXPERIMENTAL_LARKG' "$root/src/lua_modules.c" || fail 'ungated native registration'
    grep -Fq 'longfellow larkg' "$root/build/meson.build" || fail 'default Meson suite includes LARKG'
}

native_symbol() {
    # Do not use grep -q here: with pipefail it can close early and turn a
    # successful nm scan into SIGPIPE.
    nm -g "$1" 2>/dev/null | grep -E '[[:space:]]luaopen_larkg$' >/dev/null
}

default_gate() {
    static_gate
    test -x "$root/zenroom" || fail 'default gate needs zenroom'
    test -f "$root/libzenroom.so" || fail 'default gate needs libzenroom.so'
    ! native_symbol "$root/zenroom" || fail 'default executable exports luaopen_larkg'
    ! native_symbol "$root/libzenroom.so" || fail 'default library exports luaopen_larkg'
    # The CLI reports Lua failures on stderr but historically exits zero, so
    # assert the curated-loader diagnostic rather than its process status.
    output=$(printf "return require('larkg')\n" | "$root/zenroom" 2>&1)
    grep -Fq 'required extension not found: larkg' <<<"$output" || fail 'default executable loads larkg'
}

experimental_gate() {
    static_gate
    test -x "$root/zenroom" || fail 'experimental gate needs zenroom'
    test -f "$root/libzenroom.so" || fail 'experimental gate needs libzenroom.so'
    native_symbol "$root/zenroom" || fail 'experimental executable omits luaopen_larkg'
    native_symbol "$root/libzenroom.so" || fail 'experimental library omits luaopen_larkg'
    printf "return require('larkg')\n" | "$root/zenroom" >/dev/null
}

case "${1:-}" in
    --static) static_gate ;;
    --default) default_gate ;;
    --experimental) experimental_gate ;;
    *)
        printf '%s\n' "usage: $0 --static|--default|--experimental" >&2
        exit 64
        ;;
esac
