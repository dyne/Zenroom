local schnorr = require('crypto_schnorr_signature')

local function expect_error(label, expected, fn)
   local ok, err = pcall(fn)
   assert(not ok, label .. ': expected failure')
   local actual = tostring(err)
   assert(actual:find(expected, 1, true), label .. ': expected "' .. expected .. '" in "' .. actual .. '"')
end

expect_error('missing secret key', 'no secret key found', function()
   schnorr.pubgen(nil)
end)

expect_error('short secret key', 'invalid secret key: length is not of 32B', function()
   schnorr.pubgen(O.zero(31))
end)

expect_error('zero secret key', 'invalid secret key, is zero', function()
   schnorr.pubgen(O.zero(32))
end)

expect_error('overflow secret key', 'invalid secret key, overflow with curve order', function()
   schnorr.pubgen(ECP.order():octet():pad(32))
end)

print('schnorr invalid input regressions OK')
