local HDW = require('hdwallet')

local function expect_error(label, expected, fn)
   local ok, err = pcall(fn)
   assert(not ok, label .. ': expected failure')
   local actual = tostring(err)
   assert(actual:find(expected, 1, true), label .. ': expected "' .. expected .. '" in "' .. actual .. '"')
end

local xpub = 'xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8'
local xprv = 'xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi'
local mpk = HDW.parse_extkey(xpub)
local msk = HDW.parse_extkey(xprv)

expect_error('bad checksum', 'Wrong input key', function()
   HDW.parse_extkey(xpub:sub(1, #xpub - 1) .. '1')
end)

expect_error('private format from public key', 'From a public key it is not possible to print a private key', function()
   HDW.format_extkey(mpk, HDW.MAINSK)
end)

expect_error('private derivation from public key', 'Cannot derive a private key from a public key', function()
   HDW.ckd_priv(mpk, INT.new(0))
end)

expect_error('private derivation invalid index', 'Invalid index', function()
   HDW.ckd_priv(msk, BIG.from_decimal('4294967296'))
end)

expect_error('public derivation hardened index', 'Public key derivation is only defined for non-hardened child keys', function()
   HDW.ckd_pub(mpk, BIG.new(O.from_hex('80000000')))
end)

expect_error('standard child invalid child index', 'Invalid child index', function()
   HDW.standard_child(msk, BIG.new(O.from_hex('80000000')))
end)

expect_error('standard child invalid wallet index', 'Invalid wallet index', function()
   HDW.standard_child(msk, INT.new(0), BIG.new(O.from_hex('80000000')))
end)

print('hdwallet invalid input regressions OK')
