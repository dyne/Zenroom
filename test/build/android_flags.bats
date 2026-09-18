#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
}

longfellow_flags() {
    make -C "$REPO_ROOT" -f build/android.mk -pn \
        ARCH="$1" \
        ANDROID_TARGET="$2" \
        ANDROID_PLATFORM=android21 2>/dev/null |
        sed -n 's/^longfellow_cflags = //p' |
        head -n 1
}

@test "Android builds preserve common Longfellow include flags" {
    for target in \
        x86_64:x86_64 \
        i686:i686 \
        aarch64:aarch64 \
        armv7a:armv7l; do
        flags="$(longfellow_flags "${target#*:}" "${target%%:*}")"

        [[ " $flags " == *" -I.. "* ]]
        [[ " $flags " == *" -I../zstd "* ]]
        [[ " $flags " == *" -fPIC "* ]]
        [[ " $flags " == *" -DLIBRARY "* ]]
    done
}

@test "Android builds select Longfellow architecture flags through ARCH" {
    [[ " $(longfellow_flags x86_64 x86_64) " == *" -mpclmul "* ]]
    [[ " $(longfellow_flags i686 i686) " == *" -mpclmul "* ]]
    [[ " $(longfellow_flags aarch64 aarch64) " == *" -march=armv8-a+crypto "* ]]

    armv7_flags="$(longfellow_flags armv7l armv7a)"
    [[ " $armv7_flags " == *" -march=armv7-a "* ]]
    [[ " $armv7_flags " == *" -mfpu=neon "* ]]
}
