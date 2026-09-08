#!/usr/bin/env bash
set -Eeuo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
entropy_pattern='(randombytes|RAND_bytes|getrandom|arc4random)[[:space:]]*\('
backend_pattern='(RAND_byte|RAND_clean|OCT_rand|CREATE_CSPRNG|KILL_CSPRNG)[[:space:]]*\(|AMCL_\(RAND_seed\)[[:space:]]*\('
generator_pattern='(->|\.)[[:space:]]*random_generator'

# Runtime bridges must not retain relocations to a direct OS-RNG entry point or
# to a legacy vendor convenience API.  The vendor archives deliberately retain
# such APIs for upstream ABI compatibility; they are classified below and are
# not reachable from a registered Zenroom bridge.
runtime_forbidden='(randombytes|PQCLEAN_(DILITHIUM2|KYBER512|SNTRUP761)_CLEAN_crypto_(sign_keypair|kem_keypair)|mayo_sign_signature|run_mdoc_prover)([-+[:space:]]|$)'
runtime_objects=(
    src/zen_qp.o
    src/zen_mayo.o
    src/zen_longfellow.o
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
    local expression=$2
    if command -v rg >/dev/null 2>&1; then
        rg -n --glob '*.[ch]' --glob '*.cc' --glob '*.cpp' "$expression" "$path"
    else
        find "$path" -type f \( -name '*.c' -o -name '*.h' -o \
            -name '*.cc' -o -name '*.cpp' \) \
            -exec grep -EnH "$expression" {} +
    fi
}

audit_entropy_bypass() {
    local path=$1
    local hits
    hits=$(search_sources "$path" "$entropy_pattern" || true)
    while IFS= read -r hit; do
        [[ -z $hit ]] && continue
        case "$hit" in
            "$root/src/randombytes.c":*) ;;
            "$root/src/randombytes.h":*) ;;
            "$root/src/zen_random.c":*) ;;
            *) printf 'forbidden RNG bypass: %s\n' "$hit" >&2; return 1 ;;
        esac
    done <<< "$hits"
}

audit_backend_bypass() {
    local path=$1
    local hits hit
    hits=$(search_sources "$path" "$backend_pattern" || true)
    while IFS= read -r hit; do
        [[ -z $hit ]] && continue
        case "$hit" in
            # Sole compatibility-backend implementation.
            "$root/src/zen_random.c":*) ;;
            *) printf 'forbidden direct backend RNG access: %s\n' "$hit" >&2; return 1 ;;
        esac
    done <<< "$hits"
}

audit_generator_access() {
    local path=$1
    local allowed_root=${2:-}
    local hits hit source_file source_line
    local big_count=0 ecdh_count=0 rsa_count=0
    [[ -n $allowed_root ]] || allowed_root="$root/src"
    hits=$(search_sources "$path" "$generator_pattern" || true)
    while IFS= read -r hit; do
        [[ -z $hit ]] && continue
        source_file=${hit%%:*}
        source_line=${hit#*:}
        source_line=${source_line#*:}
        source_line=${source_line#"${source_line%%[![:space:]]*}"}
        source_line=${source_line%"${source_line##*[![:space:]]}"}
        case "$source_file" in
            # Backend implementation and VM lifecycle ownership.
            "$root/src/zen_random.c"|"$root/src/zenroom.c") ;;
            # Milagro APIs with an unavoidable csprng* ABI.  These are kept
            # expression- and count-specific so new consumers cannot silently
            # join the allowlist merely by living in an approved file.
            "$allowed_root/zen_big.c")
                case "$source_line" in
                    'BIG_randomnum(res->val,modulus->val,Z->random_generator);'|\
                    'BIG_randomnum(res->val,(chunk*)CURVE_Order,Z->random_generator);')
                        big_count=$((big_count + 1)) ;;
                    *) printf 'forbidden opaque RNG expression: %s\n' "$hit" >&2; return 1 ;;
                esac ;;
            "$allowed_root/zen_ecdh.c")
                case "$source_line" in
                    '(*ECDH.ECP__KEY_PAIR_GENERATE)(Z->random_generator,sk,pk);'|\
                    '(*ECDH.ECP__SP_DSA)( max_size, Z->random_generator, NULL,'|\
                    '((int)n, Z->random_generator, NULL,')
                        ecdh_count=$((ecdh_count + 1)) ;;
                    *) printf 'forbidden opaque RNG expression: %s\n' "$hit" >&2; return 1 ;;
                esac ;;
            "$allowed_root/zen_rsa.c")
                case "$source_line" in
                    'csprng *RNG = Z->random_generator;'|\
                    'csprng *RNG = Z-> random_generator;')
                        rsa_count=$((rsa_count + 1)) ;;
                    *) printf 'forbidden opaque RNG expression: %s\n' "$hit" >&2; return 1 ;;
                esac ;;
            *) printf 'forbidden opaque RNG generator access: %s\n' "$hit" >&2; return 1 ;;
        esac
    done <<< "$hits"
    if (( big_count != 3 || ecdh_count != 3 || rsa_count != 3 )); then
        printf 'unexpected opaque RNG access counts: zen_big=%d zen_ecdh=%d zen_rsa=%d (expected 3 each)\n' \
            "$big_count" "$ecdh_count" "$rsa_count" >&2
        return 1
    fi
}

audit_backend_relocations() {
    local object hits
    for object in "$root"/src/*.o; do
        [[ -f $object ]] || continue
        [[ $object == "$root/src/zen_random.o" ]] && continue
        hits=$(nm -u "$object" | match_lines \
            '(RAND_byte|AMCL_RAND_seed|RAND_clean|OCT_rand)([-+[:space:]]|$)' || true)
        if [[ -n $hits ]]; then
            printf 'forbidden direct backend RNG relocation in %s:\n%s\n' \
                "$object" "$hits" >&2
            return 1
        fi
    done
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
    # - pqclean: SNTRUP system-RNG wrapper;
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
    if audit_entropy_bypass "$scratch"; then
        printf '%s\n' 'RNG bypass self-test unexpectedly passed' >&2
        exit 1
    fi
    printf '#include <amcl.h>\nvoid example(csprng *r) { (void)RAND_byte(r); }\n' \
        > "$scratch/forbidden-backend.c"
    if audit_backend_bypass "$scratch"; then
        printf '%s\n' 'Backend RNG bypass self-test unexpectedly passed' >&2
        exit 1
    fi
    printf '#include <zenroom.h>\nvoid example(zenroom_t *z) { (void)z->random_generator; }\n' \
        > "$scratch/forbidden-generator.c"
    if audit_generator_access "$scratch"; then
        printf '%s\n' 'Opaque generator access self-test unexpectedly passed' >&2
        exit 1
    fi
    mkdir "$scratch/allowlisted"
    printf '%s\n' \
        'BIG_randomnum(res->val,modulus->val,Z->random_generator);' \
        'BIG_randomnum(res->val,modulus->val,Z->random_generator);' \
        'BIG_randomnum(res->val,(chunk*)CURVE_Order,Z->random_generator);' \
        > "$scratch/allowlisted/zen_big.c"
    printf '%s\n' \
        '(*ECDH.ECP__KEY_PAIR_GENERATE)(Z->random_generator,sk,pk);' \
        '(*ECDH.ECP__SP_DSA)( max_size, Z->random_generator, NULL,' \
        '((int)n, Z->random_generator, NULL,' \
        > "$scratch/allowlisted/zen_ecdh.c"
    printf '%s\n' \
        'csprng *RNG = Z->random_generator;' \
        'csprng *RNG = Z->random_generator;' \
        'csprng *RNG = Z-> random_generator;' \
        > "$scratch/allowlisted/zen_rsa.c"
    if ! audit_generator_access "$scratch/allowlisted" "$scratch/allowlisted"; then
        printf '%s\n' 'Valid opaque generator fixture unexpectedly failed' >&2
        exit 1
    fi
    printf '%s\n' 'BIG_randomnum(res->val,modulus->val,Z->random_generator);' \
        >> "$scratch/allowlisted/zen_big.c"
    if audit_generator_access "$scratch/allowlisted" "$scratch/allowlisted"; then
        printf '%s\n' 'Opaque generator count self-test unexpectedly passed' >&2
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

audit_entropy_bypass "$root/src"
audit_backend_bypass "$root/src"
audit_generator_access "$root/src"
audit_backend_relocations
audit_runtime_relocations
audit_archive_residues
if [[ -f $root/libzenroom.so ]] &&
    nm -D --undefined-only "$root/libzenroom.so" |
        match_lines 'RAND_bytes|getrandom|arc4random' >/dev/null; then
    printf '%s\n' 'forbidden unresolved OS RNG symbol in libzenroom.so' >&2
    exit 1
fi
