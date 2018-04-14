print '= ECDH TESTS'
octet = require'octet'

secret = [[
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
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

   ciphermsg = curve:encrypt(ses,secoctet)

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

secoctet = octet.new(#secret)
secoctet:string(secret)
ecdh = require'ecdh'
test_curve('ec25519')
test_curve('nist256')
-- TODO: check why goldilocks doesn't works
-- test_curve('goldilocks')
test_curve('bn254cx')
test_curve('fp256bn')
