# setup paths for BATS test units
setup() {
    bats_require_minimum_version 1.5.0
    T="$BATS_TEST_DIRNAME"
    TR=`cd "$T"/.. && pwd`
    R=`cd "$TR"/.. && pwd`
    TMP="$BATS_RUN_TMPDIR"
    load "$TR"/test_helper/bats-support/load
    SUBDOC=lua
    Z="$R/src/zenroom"
}

Z() {
    $R/src/zenroom $T/$1
}

@test "Lua himem tests" {
    Z sort.lua
    Z literals.lua
    Z pm.lua
    Z nextvar.lua
    Z gc.lua
    Z calls.lua
    Z constructs.lua
    Z json.lua
}

@test "Lua lowmem tests" {
    Z vararg.lua
    Z utf8.lua
    Z tpack.lua
    Z strings.lua
    Z math.lua
    Z goto.lua
    Z events.lua
    Z code.lua
    Z locals.lua
    Z zentypes.lua
}


@test "Lua crypto tests" {
    Z octet.lua
    Z octet_conversion.lua
    Z hash.lua
    Z ecdh.lua
    Z dh_session.lua
    Z ecp_generic.lua
    Z elgamal.lua
    Z bls_pairing.lua
    Z coconut_test.lua
    Z crypto_credential.lua
    Z mnemonic_encoding.lua
    Z qp.lua
}

