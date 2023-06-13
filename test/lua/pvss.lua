local PVSS = require'crypto_pvss'

print('----------------- TEST PVSS ------------------')
print('----------------------------------------------')
print("TEST: DLEQ")

-- TODO: use secp256k1 somehow
local g1 = ECP.generator()
local g2 = g1 * (BIG.modrand(ECP.order()))
local g3 = g1 * (BIG.modrand(ECP.order()))
local g4 = g1 * (BIG.modrand(ECP.order()))

local alpha, h1, h2, h3, h4, c, r
for i=1,10 do
    print("Test case ".. i)
    alpha = BIG.modrand(ECP.order())
    h1 = g1 * alpha
    h2 = g2 * alpha
    beta = BIG.modrand(ECP.order())
    h3 = g3 * beta
    h4 = g4 * beta

    c, r = PVSS.create_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, {alpha, beta}, {hash = sha256})
    assert(PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, c, r, {hash = sha256}))
    assert( not (PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, BIG.new(5), {c, c}, {hash = sha256})))
end

print('----------------------------------------------')
