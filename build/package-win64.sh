#!/usr/bin/env bash

set -Eeuo pipefail

readonly source_dir="${1:-$PWD}"
readonly output_dir="${2:-$PWD}"
readonly mingw_cxx="${MINGW_CXX:-x86_64-w64-mingw32-g++}"
readonly package_name="zenroom-win64"
readonly package_dir="${output_dir}/${package_name}"
readonly archive="${output_dir}/${package_name}.zip"

readonly -a build_artifacts=(
    zenroom.exe
    zencode-exec.exe
    libzenroom_dll.lib
    zenroom.dll
)

readonly -a runtime_dlls=(
    libstdc++-6.dll
    libgcc_s_seh-1.dll
    libssp-0.dll
)

die() {
    printf 'package-win64: %s\n' "$*" >&2
    exit 1
}

command -v "$mingw_cxx" >/dev/null 2>&1 ||
    die "compiler not found: ${mingw_cxx}"
command -v zip >/dev/null 2>&1 || die "zip command not found"

for artifact in "${build_artifacts[@]}"; do
    [[ -f "${source_dir}/${artifact}" ]] ||
        die "build artifact not found: ${source_dir}/${artifact}"
done

rm -rf -- "$package_dir"
rm -f -- "$archive"
mkdir -p -- "$package_dir"

for artifact in "${build_artifacts[@]}"; do
    cp -- "${source_dir}/${artifact}" "$package_dir/"
done

for dll in "${runtime_dlls[@]}"; do
    runtime_path="$("$mingw_cxx" -print-file-name="$dll")"
    [[ "$runtime_path" != "$dll" && -f "$runtime_path" ]] ||
        die "MinGW runtime DLL not found: ${dll}"
    cp -- "$runtime_path" "$package_dir/"
done

(
    cd "$output_dir"
    zip -q -r "${package_name}.zip" "$package_name"
)

for file in "${build_artifacts[@]}" "${runtime_dlls[@]}"; do
    [[ -f "${package_dir}/${file}" ]] ||
        die "packaged file not found: ${file}"
done

printf 'Created %s\n' "$archive"
