print()
print'=QUANTUM PROOF ALGORITHMS TESTS'
print()

local QP = require'qp'

print()
print' DILITHIUM SIGN/VERIFY TEST'
local kp = QP.sigkeygen()

local msg = [[
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Praesent vel velit non velit ullamcorper pulvinar. Curabitur 
non est in sem placerat fringilla. Sed non rutrum nunc, 
et consequat leo. Aenean at nisi in purus commodo porta convallis 
vitae nulla. Mauris magna ligula, hendrerit non augue eget, 
eleifend pellentesque nibh. Curabitur arcu mauris, iaculis 
convallis felis dapibus, luctus varius dui.]]
print'ietrate 100 tests of sign/verify'
for i=1,100 do
   local sig = QP.sign(kp.private, O.from_string(msg))
   assert(QP.verify(kp.public, sig, O.from_string(msg)), "dilithium verify failed")
   assert(not QP.verify(kp.public, sig, O.to_string(sha256(m))), "dilithium verify failed")
end

for i=1,100 do
   local sm = QP.signed_msg(kp.private, msg)
   assert(QP.verified_msg(kp.public, sm):string() == msg,"dilithium verify message failed")
   assert(not QP.verified_msg(kp.public, sig, O.to_string(sha256(m))), "dilithium verify message failed")
end


print()
print' KYBER ENC/DEC TEST'
print'iterate 100 tests of enc/dec'
local kp  = QP.kemkeygen()
for i=1,100 do
   local alice = QP.enc(kp.public)   
   local bob_secret = QP.dec(kp.private, alice.cipher)
   assert(alice.secret == bob_secret, "kyber decpription failed")
end

print()
print' SNTRUP ENC/DEC TEST'
print'iterate 100 tests of enc/dec'
local kp  = QP.ntrup_keygen()
for i=1,100 do
   local alice = QP.ntrup_enc(kp.public) 
   local bob_secret = QP.ntrup_dec(kp.private, alice.cipher)
   assert(alice.secret == bob_secret, "ntrup decpription failed")
end
