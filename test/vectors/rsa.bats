load ../bats_setup

@test "NIST RSA 4096" {
    ${ZENROOM_EXECUTABLE} -a $T/rsa_4096.rsp $T/check_rsa.lua
}
