load ../bats_setup

@test "Lua zenroom primitives tests" {
    Z base45.lua
    Z big_decimal.lua
    Z big_shift.lua
    Z big_to_fixed_oct.lua
    Z export_float.lua
    Z msgpack.lua
    Z zenroom_msgpack.lua
    Z zenroom_strings.lua
}
