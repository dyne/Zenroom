print()
print '= ELLIPTIC CURVE DIFFIE-HELLMAN ALGORITHM TESTS'
print()

secret = octet.string([[
Minim quis typewriter ut. Deep v ut man braid neutra culpa in officia consectetur tousled art party stumptown yuccie. Elit lo-fi pour-over woke venmo keffiyeh in normcore enim sunt labore williamsburg flexitarian. Tumblr distillery fanny pack, banjo tacos vaporware keffiyeh.
]])

function test_curve (name)
   print ('  ' .. name)
   alice = ecdh.new(name)
   apk,ask = alice:keygen()
   bob = ecdh.new(name)
   bpk,bsk = bob:keygen()
   -- print  'test both ways of obtaining keys'
   -- print 'public:'
   -- print(pk:hex())
   -- print(alice:public():hex())
   -- print 'secret:'
   -- print(sk:hex())
   -- print(alice:private():hex())
   assert(ask:hex() == alice:private():hex()) -- compare strings
   assert(ask == alice:private()) -- compare octects

   kdf = alice:session(bob)
   -- print(ses)
   -- print(#ses)
   -- ciphermsg = alice:encrypt(ses,octet.from_string(secret))

   -- print 'secret:'
   -- print(secoctet:string())

   -- print 'cipher message:'
   -- print(#ciphermsg)

--    decipher = alice:decrypt(ses,ciphermsg)

--    assert(secret == decipher:string())
   -- print 'decipher message:'
   -- print(decipher:string())
   -- print(#decipher)
   -- print ('         OK')

   -- AES-GCM encryption
   iv = alice:random(16)
   -- iv = octet.hex('00000000000000000000000000000000')
   header = octet.string('This is the header!')

   ciphermsg, tag = alice:encrypt(kdf, secret, iv, header)

   print ('AES-GCM encrypt : ' .. ciphermsg:base64())
   print ('AES-GCM tag : ' .. tag:base64())

   decipher = alice:decrypt(kdf, ciphermsg, iv, header, tag)

   assert(secret == decipher)
   print 'decipher message:'
   print(decipher:string())
   print(#decipher)
   print (' AES-GCM on ' .. name .. ' OK')
end

test_curve('ed25519')
test_curve('bls383')
test_curve('goldilocks')
-- test_curve('bn254cx')
-- test_curve('fp256bn')
