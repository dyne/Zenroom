load ../bats_setup

@test "Lua PBSch tests" {
    Z pbsch_vectors.lua
}

@test "Lua PBSch commitment profiles" {
    Z pbsch_cmt.lua
}

@test "Lua RPBSch CMT3 boundary" {
    Z rpbsch_cmt3_smoke.lua
}

@test "Lua RPBSch BIP340 NIWI fixture" {
    Z rpbsch_niwi.lua
}

@test "Lua PBSch end-to-end smoke" {
    Z pbsch_end_to_end.lua
}
