print()
print '= ELLIPTIC CURVE DIFFIE-HELLMAN ALGORITHM TESTS'
print()

secret = str([[
Minim quis typewriter ut. Deep v ut man braid neutra culpa in officia consectetur tousled art party stumptown yuccie. Elit lo-fi pour-over woke venmo keffiyeh in normcore enim sunt labore williamsburg flexitarian. Tumblr distillery fanny pack, banjo tacos vaporware keffiyeh.
]])

alice = ECDH.keygen()
bob = ECDH.keygen()

-- AES-GCM encryption
iv = O.random(16)
-- iv = octet.hex('00000000000000000000000000000000')
ciphermsg = { header = octet.string('This is the header!') }
session = ECDH.session(alice.private, bob.public)
ciphermsg.text, ciphermsg.checksum =
   ECDH.aead_encrypt(session, secret, iv, ciphermsg.header)

print ('AES-GCM encrypt : '  .. ciphermsg.text:url64())
print ('AES-GCM checksum : ' .. ciphermsg.checksum:url64())

session = ECDH.session(bob.private, alice.public)
decode = { header = ciphermsg.header }
decode.text, decode.checksum =
   ECDH.aead_decrypt(session, ciphermsg.text, iv, decode.header)

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

local m = str([[
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.]])
sig = ECDH.sign(alice.private, m)
assert(ECDH.verify(alice.public, m, sig), "ECDH verify failed")
assert(not ECDH.verify(alice.public, m..str("bug"),sig), "ECDH verify failed")

print "OK"
-- vk, sk = ecdh:keygen()
