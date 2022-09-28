load ../bats_setup

@test "NIST qp: dilithium2" {
    ${ZENROOM_EXECUTABLE} -a $T/dilithium2.rsp $T/check_dilithium.lua
}

@test "NIST qp: kyber512" {
    ${ZENROOM_EXECUTABLE} -a $T/kyber512.rsp $T/check_kyber.lua
}

@test "NIST qp: sntrup761" {
    ${ZENROOM_EXECUTABLE} -a $T/sntrup761.rsp $T/check_sntrup.lua
}
