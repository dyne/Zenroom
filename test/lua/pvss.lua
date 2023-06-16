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

    c, r = PVSS.create_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, {alpha, beta})
    assert(PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, c, r))
    assert( not (PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, BIG.new(5), {c, c})))
end

-- print('----------------------------------------------')
-- print("TEST generators")
-- I.spy(PVSS.create_generators(10, ECP.prime(), ECP.order()))

print('----------------------------------------------')
print("Create and verify shares")
print("Test case 1")
local participants = 10
local thr = 6
local secret = BIG.modrand(ECP.order())
local g, G = table.unpack(PVSS.create_generators(2, ECP.prime(), ECP.order()))
local public_keys = {}

for i=1,participants do
    public_keys[i] = PVSS.sk2pk(G, PVSS.keygen())
end

local commitments, encrypted_shares, challenge, responses = PVSS.create_shares(secret, g, public_keys, thr, participants)
assert(PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))

print("Test failure 1")
-- This fails because there is one wrong encrypted share.
local temp = encrypted_shares[1]
encrypted_shares[1] = encrypted_shares[2]
assert( not PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))
encrypted_shares[1] = temp

print("Test failure 2")
-- This fails because we pass the wrong generator point.
assert( not PVSS.verify_shares(G, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))

print("Test failure 3")
-- This fails because there is one wrong public key.
temp = public_keys[1]
public_keys[1] = public_keys[2]
assert( not PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))
public_keys[1] = temp

print("Test failure 4")
-- This fails because there is one wrong commitment.
temp = commitments[1]
commitments[1] = commitments[2]
assert( not PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))
commitments[1] = temp

print('----------------------------------------------')
