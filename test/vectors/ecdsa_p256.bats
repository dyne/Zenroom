load ../bats_setup

@test "NIST ECDSA KeyGen" {
    ${ZENROOM_EXECUTABLE} -a $T/ecdsa_p256_KeyPair.rsp $T/check_ecdsa_p256_keygen.lua
}

@test "NIST ECDSA SigVerify" {
    ${ZENROOM_EXECUTABLE} -a $T/ecdsa_p256_SigVer.rsp $T/check_ecdsa_p256_verify.lua
}

@test "NIST ECDSA SigGen" {
    ${ZENROOM_EXECUTABLE} -a $T/ecdsa_p256_SigGen.txt $T/check_ecdsa_p256_sign.lua
}
