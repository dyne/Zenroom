print()
print '= ELLIPTIC CURVE DIFFIE-HELLMAN ALGORITHM TESTS'
print()

ECDH = require'zenroom_ecdh'
ECP = require'zenroom_ecp'

secret = str([[
Minim quis typewriter ut. Deep v ut man braid neutra culpa in officia consectetur tousled art party stumptown yuccie. Elit lo-fi pour-over woke venmo keffiyeh in normcore enim sunt labore williamsburg flexitarian. Tumblr distillery fanny pack, banjo tacos vaporware keffiyeh.
]])

function test_curve (name)
   print ('  ' .. name)
   alice = ECDH.new(name)
   apk,ask = alice:keygen()
   bob = ECDH.new(name)
   bpk,bsk = bob:keygen()

   assert(ask:hex() == alice:private():hex()) -- compare strings
   assert(ask == alice:private()) -- compare octects

   -- AES-GCM encryption
   iv = O.random(16)
   -- iv = octet.hex('00000000000000000000000000000000')
   ciphermsg = { header = octet.string('This is the header!') }
   session = alice:session(bob)
   ciphermsg.text, ciphermsg.checksum =
	  ECDH.aead_encrypt(session, secret, iv, ciphermsg.header)

   print ('AES-GCM encrypt : '  .. ciphermsg.text:url64())
   print ('AES-GCM checksum : ' .. ciphermsg.checksum:url64())

   session = bob:session(alice)
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
   print (' AES-GCM on ' .. name .. ' OK')
end

test_curve('ed25519')
test_curve('bls383')
test_curve('goldilocks')
test_curve('secp256k1')
-- test_curve('bn254cx')
-- test_curve('fp256bn')

print ''
print('  DSA SIGN/VERIFY')

G = ECP.generator()
modulo = ECP.order()
local skey = OCTET.random(32)
I.print({ octlen = #skey})
I.print({ intlen = #INT.new(skey)})
local pkey = INT.new(skey):mod(ECP.order()) * G

ecdh = ECDH.new('bls383')
ecdh:private(skey)
I.print({ ECP = skey,
		  ECDH = ecdh:private()})
assert(#ecdh:private() == #skey, "ECDH and ECP private key lenghts differ")
assert(ecdh:private() == skey, "ECDH and ECP private key import reports incongruence")
I.print({ p__ECP = pkey:octet(),
		  ECDH = ecdh:public() })
assert(ecdh:public() == pkey, "ECDH and ECP public key calculation gives different results")
local m = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
c, d = ecdh:sign(m)
print(c)
print(d)
ecdh2 = ECDH.new()
ecdh2:public(skey*G)
assert(ecdh2:verify(m,c,d), "ECDH verify failed")
print "OK"
-- vk, sk = ecdh:keygen()
