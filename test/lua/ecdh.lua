print()
print '= ELLIPTIC CURVE DIFFIE-HELLMAN ALGORITHM TESTS'
print()

secret = O.from_str([[
Minim quis typewriter ut. Deep v ut man braid neutra culpa in officia consectetur tousled art party stumptown yuccie. Elit lo-fi pour-over woke venmo keffiyeh in normcore enim sunt labore williamsburg flexitarian. Tumblr distillery fanny pack, banjo tacos vaporware keffiyeh.
]])

alice = ECDH.keygen()
bob = ECDH.keygen()

-- AES-GCM encryption
iv = O.random(16)
-- iv = octet.hex('00000000000000000000000000000000')
ciphermsg = { header = O.from_string('This is the header!') }
session = ECDH.session(alice.private, bob.public)
I.print({ session = session,
		  iv = iv,
		  secret = secret,
		  header = ciphermsg.header })
ciphermsg.text, ciphermsg.checksum =
   AES.gcm_encrypt(session, secret, iv, ciphermsg.header)

-- I.print(ciphermsg)
-- print ('AES-GCM encrypt : '  .. ciphermsg.text:url64())
-- print ('AES-GCM checksum : ' .. ciphermsg.checksum:url64())

session = ECDH.session(bob.private, alice.public)
decode = { header = ciphermsg.header }
decode.text, decode.checksum =
   AES.gcm_decrypt(session, ciphermsg.text, iv, decode.header)

-- print ('AES-GCM checksum : ' .. ck2:base64())

assert(decode.checksum == ciphermsg.checksum,
	   "Checksum differs when de/coding")
assert(secret == decode.text, "Secret differs from de/coded text")
assert(ciphermsg.header == decode.header, "Header differs from de/coded text" )
print 'decipher message:'
print(decode.header:string())
print(decode.text:string())

print ''
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
local shorter = false
local tot = 0

while (tot<100) or (not shorter) do
	sig = ecdh.sign(alice.private, m)
	sig.r = INT.new(sig.r):octet()
	sig.s = INT.new(sig.s):octet()
	if #sig.r<32 or #sig.s<32 then
		shorter = true
	end
	assert(ecdh.verify(alice.public, m, sig), "ecdh verify failed")
	assert(not ecdh.verify(alice.public, sha256(m),sig), "ecdh verify failed")
	tot = tot+1
end

print 'iterate at least 100 tests of sign/verify pre-hashed'
print 'and at least 1 tests with r or s length lower than 32 bytes'
local function recovery_test(msg, sig, parity, pk)
	local recovered_pk, valid
	local parity = parity and 1 or 0

	local x = INT.new(sig.r)
	local p = ECDH.prime()
	local n = ECDH.order()
	local h = ECDH.cofactor() --h=1
	repeat
		recovered_pk, valid = ECDH.recovery(x:octet(), parity, msg, sig)
		if h > 0 then   -- do not add n last iteration
			x = (x + n) % p
		end
	   	h = h-1
	until (valid and recovered_pk==pk) or (h < 0)
	
	return (valid and recovered_pk==pk)
end

local hm = sha256(m)
local shorter = false
local tot = 0

while (tot<100) or (not shorter) do
	nohashsig, parity = ecdh.sign_hashed(alice.private, hm, #hm)
	nohashsig.r = INT.new(nohashsig.r):octet()
	nohashsig.s = INT.new(nohashsig.s):octet()
	if #nohashsig.r<32 or #nohashsig.s<32 then
		shorter = true
	end
	assert(ecdh.verify_hashed(alice.public, hm, nohashsig, #hm), "ecdh verify failed")
	assert(not ecdh.verify_hashed(alice.public, sha256(hm),nohashsig, #hm), "ecdh verify failed")
	assert(recovery_test(hm, nohashsig, parity, alice.public), "ecdh recovery failed")
	assert(not recovery_test(sha256(hm), nohashsig, parity, alice.public), "ecdh recovery failed")
	tot = tot+1
end

print "OK"
-- vk, sk = ecdh:keygen()
