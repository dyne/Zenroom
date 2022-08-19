print "TEST ELGAMAL HOMOMORPHIC ADDITIVE CLASS"

E = require'crypto_elgamal'
kp = E.keygen()
local r1 = random8()
local r2 = random8()
a = E.new(kp.public, BIG.new(r1))
b = E.new(kp.public, BIG.new(r2))
acc = E.add(kp.public, a, b.value)
tally = E.tally(kp.public, kp.private, acc)
res = E.count(tally, acc, 512) -- 256(8b) *2
assert(r1+r2 == res, "ECDHA homomorphic sum fails")
print("SUM OK")

local r1 = 100
local r2 = 40
a = E.new(kp.public, BIG.new(r1))
b = E.new(kp.public, BIG.new(r2))
acc = E.sub(kp.public, a, b.value)
tally = E.tally(kp.public, kp.private, acc)
res = E.count(tally, acc, 512) -- 256(8b) *2
assert(r1-r2 == res, "ECDHA homomorphic subtraction fails")
print("SUBTRACTION OK")
