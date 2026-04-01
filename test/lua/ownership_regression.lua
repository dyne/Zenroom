local hash = HASH.new("sha256")
local message = O.from_string("ownership")

for _ = 1, 200 do
    local digest = hash:process(message)
    assert(#digest == 32)
end

local point = ECP.generator()
for _ = 1, 200 do
    local encoded = point:to_zcash()
    local decoded = ECP.from_zcash(encoded)
    assert(decoded == point)
    assert(point:x() ~= nil)
end

local point2 = ECP2.generator()
for _ = 1, 200 do
    local encoded = point2:to_zcash()
    local decoded = ECP2.from_zcash(encoded)
    assert(decoded == point2)
    assert(point2:xr() ~= nil)
end
