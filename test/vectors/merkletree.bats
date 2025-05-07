load ../bats_setup

@test "FRIGO: merkletree" {
    ${ZENROOM_EXECUTABLE} $T/check_merkle_tree.lua
}