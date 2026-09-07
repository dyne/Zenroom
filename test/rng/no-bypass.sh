#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
pattern='(randombytes|RAND_bytes|getrandom|arc4random)[[:space:]]*\('

audit() {
    local path=$1
    local hits
    hits=$(rg -n --glob '*.[ch]' -o "$pattern" "$path" || true)
    while IFS= read -r hit; do
        [[ -z $hit ]] && continue
        case "$hit" in
            "$root/src/randombytes.c":*) ;;
            "$root/src/randombytes.h":*) ;;
            "$root/src/zen_random.c":*:randombytes\(*) ;;
            "$root/src/api_sign.c":*:randombytes\(*) ;;
            "$root/src/zen_larkg.c":*:randombytes\(*) ;;
            *) printf 'forbidden RNG bypass: %s\n' "$hit" >&2; return 1 ;;
        esac
    done <<< "$hits"
}

if [[ ${1:-} == --self-test ]]; then
    scratch=$(mktemp -d)
    trap 'rm -rf "$scratch"' EXIT
    printf 'void example(void) { randombytes(0, 1); }\n' > "$scratch/forbidden.c"
    if audit "$scratch"; then
        printf '%s\n' 'RNG bypass self-test unexpectedly passed' >&2
        exit 1
    fi
    exit 0
fi

audit "$root/src"
if [[ -f $root/libzenroom.so ]] && nm -D --undefined-only "$root/libzenroom.so" | rg -q 'RAND_bytes|getrandom|arc4random'; then
    printf '%s\n' 'forbidden unresolved OS RNG symbol in libzenroom.so' >&2
    exit 1
fi
