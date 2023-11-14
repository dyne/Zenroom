load ../bats_setup

@test "NIST ECDSA KeyGen" {
    ${ZENROOM_EXECUTABLE} -a $T/ecdsa_KeyPair.rsp $T/check_ecdsa_keygen.lua
}

@test "NIST ECDSA SigVerify" {
    ${ZENROOM_EXECUTABLE} -a $T/ecdsa_SigVer.rsp $T/check_ecdsa_verify.lua
}
