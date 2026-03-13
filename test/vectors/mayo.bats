load ../bats_setup

@test "NIST qp: mayo" {
    ${ZENROOM_EXECUTABLE} -a $T/mayo5.rsp $T/check_mayo.lua
}