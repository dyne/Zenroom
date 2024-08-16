print 'BBS+ size benchmarks'
print ''

B3 = BBS.ciphersuite'shake256'
local T, start
start = os.clock()
local kp = keygen(B3)
print('TIME: '..os.clock()-start)
I.print(kp)
print''


local m = { OCTET.random(512) }
local i = { 1 }

start = os.clock()
local signed = sign(B3, kp, m)
print('TIME: '..os.clock()-start)
I.print({signature=signed})
print''

start = os.clock()
local proof = create_proof(B3, kp.pk, signed, m, i)
print('TIME: '..os.clock()-start)
I.print({proof=proof})
print''

print'verification'
disclosed = disclosed_messages(m, i)
start = os.clock()
assert( verify_proof(B3, kp.pk, proof, disclosed, i) )
print('TIME: '..os.clock()-start)
