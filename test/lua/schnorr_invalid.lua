local schnorr = require('crypto_schnorr_signature')
local O = OCTET

local function expect_error(label, expected, fn)
   local ok, err = pcall(fn)
   assert(not ok, label .. ': expected failure')
   local actual = tostring(err)
   assert(actual:find(expected, 1, true), label .. ': expected "' .. expected .. '" in "' .. actual .. '"')
end

-- nil sk: Lua error "attempt to get length of a nil value"
expect_error('nil secret key', 'attempt to get length of a nil value', function()
   schnorr.pubgen(nil)
end)

-- empty octet (len=0) is too short
expect_error('empty octet', 'secret key must be 32 bytes', function()
   schnorr.pubgen(O.new(32))
end)

-- zero secret key: 32 bytes of zeros, rejected by bip340_seckey_valid
expect_error('zero secret key', 'invalid secret key for pubgen', function()
   local sk = O.random(32)
   -- O.random returns filled octet; we want 32 zeros
   -- Use explicit 32-byte zero hex
   local zero = O.from_hex("0000000000000000000000000000000000000000000000000000000000000000")
   schnorr.pubgen(zero)
end)

-- overflow secret key: sk >= n
expect_error('overflow secret key', 'invalid secret key for pubgen', function()
   local sk = O.from_hex("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")
   schnorr.pubgen(sk)
end)

io.write('schnorr invalid input regressions OK\n')
