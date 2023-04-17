local g = ECP2.generator()
local g0 = ECP2.inf()
--[[
for i=1,10,1 do
    print(i)
    local g1 = g0:zcash_export():zcash_topoint()

    assert(type(g1) == "zenroom.ecp2")
    assert(g1 == g0)

    g0 = g0 + g;
end
]]

local g = ECP.generator()
local g0 = ECP.inf()
for i=1,100,1 do
    print(i)
    local g1 = g0:zcash_export():zcash_topoint()

    assert(type(g1) == "zenroom.ecp")
    assert(g1 == g0)

    g0 = g0 + g;
end
