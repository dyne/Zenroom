#!/usr/bin/env bats

load ../bats_setup

@test "RNG service :: bypass audit and self-test" {
    run "$R/test/rng/no-bypass.sh"
    assert_success
    run "$R/test/rng/no-bypass.sh" --self-test
    assert_success
}

@test "RNG service :: Cortex-M initialization object remains buildable" {
    run cc ${CFLAGS:-} -std=c11 -DARCH_CORTEX -I"$R/src" \
        -I"$R/lib/lua54/src" -I"$R/lib/milagro-crypto-c/build/include" \
        -I"$R/lib/milagro-crypto-c/include" -c "$R/src/zen_random.c" \
        -o "$TMP/zen_random_cortex.o"
    assert_success
}
