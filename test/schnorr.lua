print()
print'=SCHNORR SIGNATURE ALGORITHM TEST'
print()

local SCH = require("crypto_schnorr_signature")

print()
print'SCHNORR SIGN/VERIFY TEST'
local kp = SCH.keygen()

local m = OCTET.random(32)
print'ietrate 100 tests of sign/verify and some checks'
for i=1,100 do
   assert(SCH.pubgen(kp.private) == kp.public, "schnorr pubgen failed")
   assert(SCH.pubcheck(kp.public), "schnorr pubchek failed")
   assert(SCH.seccheck(kp.private), "schnorr seccheck failed")
   local sig = SCH.sign(kp.private, m)
   assert(SCH.sigcheck(sig), "schnorr sigcheck failed")
   assert(SCH.verify(kp.public, m, sig), "schnorr verify failed")
end
