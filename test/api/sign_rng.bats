#!/usr/bin/env bats

load ../bats_setup

@test "SIGN API :: absent entropy fails closed while explicit seed is stable" {
    local ldadd="-L$R -lzenroom"
    local cflags="${CFLAGS:-} -I$R/src"
    if strings "$R/libzenroom.so" | grep -q "__asan_init"; then
        ldadd="$ldadd -fsanitize=address,undefined"
        cflags="$cflags -fsanitize=address,undefined"
    fi
    cc $cflags -ggdb -Wl,--export-dynamic -o sign_entropy_failure \
        "$T/sign_entropy_failure.c" $ldadd
    run env LD_LIBRARY_PATH="$R" ./sign_entropy_failure
    assert_success
}
