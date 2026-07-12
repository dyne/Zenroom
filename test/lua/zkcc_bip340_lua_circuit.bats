load ../bats_setup

@test "Lua zkcc BIP340 Lua-authored circuit" {
    Z zkcc_bip340_lua_circuit.lua
}
