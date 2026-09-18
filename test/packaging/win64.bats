#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
    SOURCE_DIR="${BATS_TEST_TMPDIR}/source"
    OUTPUT_DIR="${BATS_TEST_TMPDIR}/output"
    RUNTIME_DIR="${BATS_TEST_TMPDIR}/runtime"
    FAKE_COMPILER="${BATS_TEST_TMPDIR}/x86_64-w64-mingw32-g++"

    mkdir -p "$SOURCE_DIR" "$OUTPUT_DIR" "$RUNTIME_DIR"
    touch \
        "${SOURCE_DIR}/zenroom.exe" \
        "${SOURCE_DIR}/zencode-exec.exe" \
        "${SOURCE_DIR}/libzenroom_dll.lib" \
        "${SOURCE_DIR}/zenroom.dll" \
        "${RUNTIME_DIR}/libstdc++-6.dll" \
        "${RUNTIME_DIR}/libgcc_s_seh-1.dll" \
        "${RUNTIME_DIR}/libssp-0.dll"

    # Variables in these single-quoted lines belong to the generated fixture.
    # shellcheck disable=SC2016
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -euo pipefail' \
        'dll="${1#-print-file-name=}"' \
        'if [[ -f "${FAKE_RUNTIME_DIR}/${dll}" ]]; then' \
        '    printf "%s\\n" "${FAKE_RUNTIME_DIR}/${dll}"' \
        'else' \
        '    printf "%s\\n" "$dll"' \
        'fi' > "$FAKE_COMPILER"
    chmod +x "$FAKE_COMPILER"
}

@test "Win64 package includes MinGW runtime DLLs" {
    run env \
        MINGW_CXX="$FAKE_COMPILER" \
        FAKE_RUNTIME_DIR="$RUNTIME_DIR" \
        "${REPO_ROOT}/build/package-win64.sh" "$SOURCE_DIR" "$OUTPUT_DIR"

    [ "$status" -eq 0 ]

    run unzip -Z1 "${OUTPUT_DIR}/zenroom-win64.zip"
    [ "$status" -eq 0 ]

    for file in \
        zenroom.exe \
        zencode-exec.exe \
        libzenroom_dll.lib \
        zenroom.dll \
        libstdc++-6.dll \
        libgcc_s_seh-1.dll \
        libssp-0.dll; do
        [ -f "${OUTPUT_DIR}/zenroom-win64/${file}" ]
        [[ "$output" == *"zenroom-win64/${file}"* ]]
    done
}

@test "Win64 packaging fails when a runtime DLL cannot be resolved" {
    rm "${RUNTIME_DIR}/libssp-0.dll"

    run env \
        MINGW_CXX="$FAKE_COMPILER" \
        FAKE_RUNTIME_DIR="$RUNTIME_DIR" \
        "${REPO_ROOT}/build/package-win64.sh" "$SOURCE_DIR" "$OUTPUT_DIR"

    [ "$status" -ne 0 ]
    [[ "$output" == *"MinGW runtime DLL not found: libssp-0.dll"* ]]
}
