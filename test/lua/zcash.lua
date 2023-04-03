local g = ECP2.generator()
local g0 = ECP2.inf()

for i=1,10,1 do
    print(i)
    local g1 = ECP2.zcash_import(g0:zcash_export())

    assert(g1 == g0)

    g0 = g0 + g;
end
