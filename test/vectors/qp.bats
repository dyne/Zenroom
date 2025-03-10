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

@test "NIST qp: ml_dsa44" {
    ${ZENROOM_EXECUTABLE} -a $T/ml_dsa44.rsp -c rngseed=hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 $T/check_ml_dsa44.lua
}

@test "NIST qp: ml_kem512" {
    ${ZENROOM_EXECUTABLE} -a $T/ml_kem512.rsp  $T/check_ml_kem512.lua
}

@test "NIST qp: ml_kem768" {
    ${ZENROOM_EXECUTABLE} -a $T/ml_kem768.rsp  $T/check_ml_kem768.lua
}

@test "NIST qp: ml_kem1024" {
    ${ZENROOM_EXECUTABLE} -a $T/ml_kem1024.rsp  $T/check_ml_kem1024.lua
}