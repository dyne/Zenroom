load ../bats_setup

@test "Lua native tests" {
Z native/gengc.lua
Z native/gc.lua
Z native/events.lua
Z native/constructs.lua
Z native/code.lua
Z native/closure.lua
Z native/bwcoercion.lua
Z native/api.lua
Z native/vararg.lua
Z native/utf8.lua
Z native/tracegc.lua
Z native/tpack.lua
Z native/strings.lua
Z native/sort.lua
Z native/pm.lua
Z native/math.lua
Z native/literals.lua
Z native/heavy.lua
Z native/goto.lua
}