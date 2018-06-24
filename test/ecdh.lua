print()
print '= ELLIPTIC CURVE DIFFIE-HELLMAN ALGORITHM TESTS'
print()

secret = [[
Minim quis typewriter ut. Deep v ut man braid neutra culpa in officia consectetur tousled art party stumptown yuccie. Elit lo-fi pour-over woke venmo keffiyeh in normcore enim sunt labore williamsburg flexitarian. Tumblr distillery fanny pack, banjo tacos vaporware keffiyeh.
]]

function test_curve (name)
   print ('  ' .. name)
   curve = ecdh.new(name)
   pk,sk = curve:keygen()
   -- print  'test both ways of obtaining keys'
   -- print 'public:'
   -- print(pk:hex())
   -- print(curve:public():hex())
   assert(curve:checkpub(pk))
   assert(curve:checkpub(curve:public()))
   -- print 'secret:'
   -- print(sk:hex())
   -- print(curve:private():hex())
   assert(sk:hex() == curve:private():hex())

   ses = curve:session(pk,sk)
   -- print 'session:'
   -- print(ses:hex())

   ciphermsg = curve:encrypt(ses,octet.from_string(secret))

   -- print 'secret:'
   -- print(secoctet:string())

   -- print 'cipher message:'
   -- print(#ciphermsg)

   decipher = curve:decrypt(ses,ciphermsg)

   assert(secret == decipher:string())
   -- print 'decipher message:'
   -- print(decipher:string())
   -- print(#decipher)
   print ('         OK')
end

test_curve('ed25519')
test_curve('nist256')
-- TODO: check why goldilocks doesn't works
-- test_curve('goldilocks')
test_curve('bn254cx')
test_curve('fp256bn')
