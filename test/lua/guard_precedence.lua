local BTC = require'crypto_bitcoin'
local ECDHCompat = require'zenroom_ecdh'

local function expect_error(fn, needle)
    local ok, err = pcall(fn)
    assert(not ok, "expected failure containing: "..needle)
    assert(string.find(err, needle, 1, true), err)
end

local valid_sk = O.from_hex(string.rep('01', 32))
local sk = BTC.wif_to_sk(BTC.sk_to_wif(valid_sk, 'bitcoin'))
assert(sk == valid_sk, "bitcoin WIF should round-trip to the original secret key")

expect_error(function()
    BTC.wif_to_sk(42)
end, 'invalid bitcoin key type, not an octet: number')

local kp = ECDH.keygen()
local pubc = ECDHCompat.sk_to_pubc(kp.private)
assert(#pubc == 33, "compressed ECDH public keys must be 33 bytes")

expect_error(function()
    ECDHCompat.sk_to_pubc(O.zero(31))
end, 'Invalid ecdh private key size: 31')

local digest = O.from_hex('c24463f5e352da20cb79a43f97436cce57344911e1d0ec0008cbedb5fabcca33')
local multihash = ZEN.schemas.multihash_sha256.export(digest)
local imported, meta = ZEN.schemas.multihash_sha256.import(multihash:base64())
assert(imported == digest, "multihash import should recover the original digest")
assert(meta.schema == 'multihash_sha256', "multihash import should preserve schema metadata")

expect_error(function()
    ZEN.schemas.multihash_sha256.import(42)
end, 'Multihash invalid input: number')

print('guard precedence regressions OK')
