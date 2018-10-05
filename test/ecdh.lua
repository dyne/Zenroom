print()
print '= ELLIPTIC CURVE DIFFIE-HELLMAN ALGORITHM TESTS'
print()

secret = str([[
Minim quis typewriter ut. Deep v ut man braid neutra culpa in officia consectetur tousled art party stumptown yuccie. Elit lo-fi pour-over woke venmo keffiyeh in normcore enim sunt labore williamsburg flexitarian. Tumblr distillery fanny pack, banjo tacos vaporware keffiyeh.
]])

rng = RNG.new()

function test_curve (name)
   print ('  ' .. name)
   alice = ECDH.new(name)
   apk,ask = alice:keygen()
   bob = ECDH.new(name)
   bpk,bsk = bob:keygen()

   assert(ask:hex() == alice:private():hex()) -- compare strings
   assert(ask == alice:private()) -- compare octects

   -- AES-GCM encryption
   iv = rng:octet(16)
   -- iv = octet.hex('00000000000000000000000000000000')
   header = octet.string('This is the header!')

   ciphermsg = ECDH.encrypt(alice, bob, secret, header)

   print ('AES-GCM encrypt : '  .. ciphermsg.text:base64())
   print ('AES-GCM checksum : ' .. ciphermsg.checksum:base64())

   decipher = ECDH.decrypt(alice, bob, ciphermsg)

   -- print ('AES-GCM checksum : ' .. ck2:base64())

   assert(secret == decipher.text)
   assert(header == decipher.header)
   print 'decipher message:'
   print(decipher.header:string())
   print(decipher.text:string())
   print (' AES-GCM on ' .. name .. ' OK')
end

test_curve('ed25519')
test_curve('bls383')
test_curve('goldilocks')
-- test_curve('bn254cx')
-- test_curve('fp256bn')
