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

@test "RNG service :: SNTRUP callback failure is closed" {
    local ldadd="-L$R -lzenroom"
    local cflags="${CFLAGS:-} -I$R/src -I$R/lib/pqclean/sntrup761"
    if strings "$R/libzenroom.so" | grep -q "__asan_init"; then
        ldadd="$ldadd -fsanitize=address,undefined"
        cflags="$cflags -fsanitize=address,undefined"
    fi
    cc $cflags -ggdb -o sntrup_rng_failure "$T/sntrup_rng_failure.c" $ldadd
    run env LD_LIBRARY_PATH="$R" ./sntrup_rng_failure
    assert_success
}

@test "RNG service :: Longfellow callback adapter is deterministic and closed" {
    local cflags="${CXXFLAGS:-} -I$R/lib -I$R/lib/longfellow-zk"
    if strings "$R/libzenroom.so" | grep -q "__asan_init"; then
        cflags="$cflags -fsanitize=address,undefined"
    fi
    c++ $cflags -std=c++17 -ggdb -o longfellow_rng_failure "$T/longfellow_rng_failure.cc"
    run ./longfellow_rng_failure
    assert_success
}
