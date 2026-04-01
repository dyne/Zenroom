local g = ECP2.generator()
local g0 = ECP2.inf()

local function expect_failure(fn, expected)
    local ok, err = pcall(fn)
    assert(not ok)
    assert(string.find(err, expected, 1, true))
end

for i=1,100,1 do
    print(i)
    local g1 = ECP2.from_zcash(g0:to_zcash())

    assert(type(g1) == "zenroom.ecp2")
    assert(g1 == g0)

    g0 = g0 + g;
end


local h = ECP.generator()
local h0 = ECP.inf()
for i=1,100,1 do
    print(i)
    local g1 = ECP.from_zcash(h0:to_zcash())

    assert(type(g1) == "zenroom.ecp")
    assert(g1 == h0)

    h0 = h0 + h;
end

expect_failure(function()
    ECP.from_zcash(O.new())
end, "Invalid octet length")

expect_failure(function()
    ECP2.from_zcash(O.new())
end, "Invalid octet length")

expect_failure(function()
    local valid = ECP.generator():to_zcash():hex()
    local invalid = O.from_hex("00" .. valid:sub(3))
    ECP.from_zcash(invalid)
end, "Invalid octet header")

expect_failure(function()
    local valid = ECP2.generator():to_zcash():hex()
    local invalid = O.from_hex("00" .. valid:sub(3))
    ECP2.from_zcash(invalid)
end, "Invalid octet header")
