load ../bats_setup

@test "Lua himem tests" {
    Z sort.lua
    Z literals.lua
    Z pm.lua
    Z nextvar.lua
    Z gc.lua
    Z calls.lua
    Z constructs.lua
    Z json.lua
    Z coroutine.lua
    Z closure.lua
}
