P256 = require('es256')

alice_sk = P256.keygen()
I.spy(alice_sk)
alice_pk = P256.pubgen(alice_sk)
I.spy(alice_pk)

print('  DSA SIGN/VERIFY')

local m = O.from_str([[
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.]])
print 'iterate at least 100 tests of sign/verify'
print 'and at least 1 tests with r or s length lower than 32 bytes'
local tot = 0

while (tot<100) do
	sig = P256.sign(alice_sk, m)
	assert(P256.verify(alice_pk, sig, m), "ecdh verify failed")
	assert(not P256.verify(alice_pk, sig, sha256(m)), "ecdh verify failed")
	tot = tot+1
end

print "OK"

