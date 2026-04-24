load ../bats_setup

@test "Lua zkcc tests" {
    Z zkcc_small.lua
    Z zkcc_horner_expr.lua
    Z zkcc_sha256.lua
    Z zkcc_arith_progression.lua
    Z zkcc_flatsha256_proof.lua
}
