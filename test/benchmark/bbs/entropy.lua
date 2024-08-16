print 'BBS+ entropy benchmarks'
print ''

TOTAL = 10
B3 = BBS.ciphersuite'shake256'

local kp = keygen(B3)



local msg = { OCTET.random(512) }
local idx = { 1 }

local signed = sign(B3, kp, msg)

print "Proof \t Rand"

local prev = create_proof(B3, kp.pk, signed, msg, idx)
local rlen = #prev
for i=1,TOTAL do
    local proof = create_proof(B3, kp.pk, signed, msg, idx)
    local ham = O.hamming(proof, prev)
    local rand = O.hamming(O.random(rlen), O.random(rlen))
    print(ham.." \t "..rand)
    prev = proof
end


print ("shannon "..prev:entropy())
