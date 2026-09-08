#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
pattern='(randombytes|RAND_bytes|getrandom|arc4random)[[:space:]]*\('

# Runtime bridges must not retain relocations to a direct OS-RNG entry point or
# to a legacy vendor convenience API.  The vendor archives deliberately retain
# such APIs for upstream ABI compatibility; they are classified below and are
# not reachable from a registered Zenroom bridge.
runtime_forbidden='(randombytes|PQCLEAN_(DILITHIUM2|KYBER512|SNTRUP761)_CLEAN_crypto_(sign_keypair|kem_keypair)|mayo_sign_signature|run_mdoc_prover)([-+[:space:]]|$)'
runtime_objects=(
    src/zen_qp.o
    src/zen_mayo.o
    src/zen_longfellow.o
	 src/zen_larkg.o
)

match_lines() {
    local expression=$1
    if command -v rg >/dev/null 2>&1; then
        rg "$expression"
    else
        grep -E "$expression"
    fi
}

search_sources() {
    local path=$1
    if command -v rg >/dev/null 2>&1; then
        rg -n --glob '*.[ch]' -o "$pattern" "$path"
    else
        find "$path" -type f \( -name '*.c' -o -name '*.h' \) \
            -exec grep -EnH -o "$pattern" {} +
    fi
}

audit() {
    local path=$1
    local hits
    hits=$(search_sources "$path" || true)
    while IFS= read -r hit; do
        [[ -z $hit ]] && continue
        case "$hit" in
            "$root/src/randombytes.c":*) ;;
            "$root/src/randombytes.h":*) ;;
            "$root/src/zen_random.c":*:randombytes\(*) ;;
            "$root/src/api_sign.c":*:randombytes\(*) ;;
            *) printf 'forbidden RNG bypass: %s\n' "$hit" >&2; return 1 ;;
        esac
    done <<< "$hits"
}

audit_runtime_object() {
    local object=$1
    local hits
    hits=$(objdump -r "$object" | match_lines "$runtime_forbidden" || true)
    if [[ -n $hits ]]; then
        printf 'forbidden reachable RNG relocation in %s:\n%s\n' "$object" "$hits" >&2
        return 1
    fi
}

audit_runtime_relocations() {
    local object
    for object in "${runtime_objects[@]}"; do
        # Source-only runs have no build products. CI invokes this gate after
        # building, where every registered bridge must be present.
        [[ -f $root/$object ]] || continue
        audit_runtime_object "$root/$object"
    done
}

audit_archive_residues() {
    # Classified, unregistered upstream compatibility residues:
    # - pqclean: SNTRUP system-RNG wrapper, sKEM and experimental LARKG;
    # - MAYO: legacy no-randomizer signing/keygen wrappers;
    # - Longfellow: SecureRandomEngine used only by the legacy C ABI wrapper.
    #   The old generator-backed BATS fixture is intentionally disabled, so it
    #   is not a compatibility gate; CallbackRandomEngine has fixture-free
    #   ASan replay/different-seed/failure coverage in test/api/rng.bats.
    # The relocation audit above is the reachability authority for Zenroom.
    local hits hit
    hits=$(nm -A "$root/lib/pqclean/libqpz.a" "$root/lib/mayo/libmayo.a" \
        "$root/lib/longfellow-zk/liblongfellow-zk.a" 2>/dev/null |
        awk '$2 == "U" && $3 == "randombytes" { print $1 }' || true)
    while IFS= read -r hit; do
        [[ -z $hit ]] && continue
        case "$hit" in
            "$root/lib/pqclean/libqpz.a":kem.o:|\
            "$root/lib/pqclean/libqpz.a":skem.o:|\
            "$root/lib/pqclean/libqpz.a":kyber_larkg.o:|\
            "$root/lib/mayo/libmayo.a":mayo.o:|\
            "$root/lib/longfellow-zk/liblongfellow-zk.a":crypto.cc.o:) ;;
            *) printf 'unclassified archive RNG residue: %s\n' "$hit" >&2; return 1 ;;
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
    printf 'extern int randombytes(void *, unsigned long); void example(void) { randombytes(0, 1); }\n' > "$scratch/forbidden-relocation.c"
    ${CC:-cc} -c "$scratch/forbidden-relocation.c" -o "$scratch/forbidden-relocation.o"
    if audit_runtime_object "$scratch/forbidden-relocation.o"; then
        printf '%s\n' 'RNG relocation self-test unexpectedly passed' >&2
        exit 1
    fi
    exit 0
fi

audit "$root/src"
audit_runtime_relocations
audit_archive_residues
if [[ -f $root/libzenroom.so ]] &&
    nm -D --undefined-only "$root/libzenroom.so" |
        match_lines 'RAND_bytes|getrandom|arc4random' >/dev/null; then
    printf '%s\n' 'forbidden unresolved OS RNG symbol in libzenroom.so' >&2
    exit 1
fi
