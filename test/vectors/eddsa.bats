load ../bats_setup

@test "NIST EdDSA: Ed25519" {
    ${ZENROOM_EXECUTABLE} -a $T/ed25519.rsp $T/check_eddsa.lua
}
