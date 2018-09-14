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

   kdf = alice:session(bob)

   -- AES-GCM encryption
   iv = rng:octet(16)
   -- iv = octet.hex('00000000000000000000000000000000')
   header = octet.string('This is the header!')

   ciphermsg, ck = ECDH.encrypt(kdf, secret, iv, header)

   print ('AES-GCM encrypt : ' .. ciphermsg:base64())
   print ('AES-GCM checksum : ' .. ck:base64())

   decipher, ck2 = ECDH.decrypt(kdf, ciphermsg, iv, header)

   print ('AES-GCM checksum : ' .. ck2:base64())

   assert(secret == decipher)
   print 'decipher message:'
   print(header:string())
   print(decipher:string())
   print (' AES-GCM on ' .. name .. ' OK')
end

test_curve('ed25519')
test_curve('bls383')
test_curve('goldilocks')
-- test_curve('bn254cx')
-- test_curve('fp256bn')
