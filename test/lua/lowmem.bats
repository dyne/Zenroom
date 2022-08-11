load ../bats_setup

@test "Lua lowmem tests" {
    Z vararg.lua
    Z utf8.lua
    Z tpack.lua
    Z strings.lua
    Z math.lua
    Z goto.lua
    Z events.lua
    Z code.lua
    Z locals.lua
    Z zentypes.lua
}

