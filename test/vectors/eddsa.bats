load ../bats_setup

@test "NIST EdDSA: Ed25519" {
    ${ZENROOM_EXECUTABLE} -a $T/ed25519.rsp $T/check_eddsa.lua
}

@test "W3C Data Integrity EdDSA" {
    ${ZENROOM_EXECUTABLE} $T/check_w3c-vc-di-eddsa.lua
}
