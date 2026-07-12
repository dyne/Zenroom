load ../bats_setup

@test "Lua zkcc FlatSHA256 proof" {
    Z zkcc_flatsha256_proof.lua
}
