load ../bats_setup

@test "Lua zkcc fast tests" {
    Z zkcc_small.lua
    Z zkcc_niwi_smoke.lua
    Z zkcc_horner_expr.lua
    Z zkcc_sha256.lua
    Z zkcc_arith_progression.lua
}
