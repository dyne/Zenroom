print()
print'=SCHNORR SIGNATURE ALGORITHM TEST'
print()

local SCH = require("crypto_schnorr_signature")

print()
print'SCHNORR SIGN/VERIFY TEST'
local sk = SCH.keygen()

local m = OCTET.random(32)
print'ietrate 100 tests of pubgen, sign, verify and some checks'
for i=1,100 do
   local pk = SCH.pubgen(sk)
   assert(SCH.pubcheck(pk), "schnorr pubchek failed")
   assert(SCH.seccheck(sk), "schnorr seccheck failed")
   local sig = SCH.sign(sk, m)
   assert(SCH.sigcheck(sig), "schnorr sigcheck failed")
   assert(SCH.verify(pk, m, sig), "schnorr verify failed")
end
