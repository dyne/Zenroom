load ../bats_setup

@test "FRIGO: merkletree" {
    ${ZENROOM_EXECUTABLE} $T/check_merkle_tree.lua
}

@test "OpenZeppelin v1.0.8: merkletree parity" {
    ${ZENROOM_EXECUTABLE} $T/check_openzeppelin_merkle_tree.lua
}
