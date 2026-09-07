#!/usr/bin/env bats

load ../bats_setup

@test "RNG service :: checked and request-order compatible" {
    local ldadd="-L$R -lzenroom"
    local cflags="${CFLAGS:-} -I$R/src"
    if strings "$R/libzenroom.so" | grep -q "__asan_init"; then
        ldadd="$ldadd -fsanitize=address,undefined"
        cflags="$cflags -fsanitize=address,undefined"
    fi
    cc $cflags -ggdb -o rng_service "$T/rng_service.c" $ldadd
    run env LD_LIBRARY_PATH="$R" ./rng_service
    assert_success
}
