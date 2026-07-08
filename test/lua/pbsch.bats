load ../bats_setup

@test "Lua PBSch tests" {
    Z pbsch_vectors.lua
}

@test "Lua RPBSch BIP340 NIWI fixture" {
    Z rpbsch_niwi.lua
}
