print()
print'MAYO ALGORITHMS TESTS'
print()

local mayo = require'mayo'

local kp = mayo.keygen()

local msg = [[
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Praesent vel velit non velit ullamcorper pulvinar. Curabitur 
non est in sem placerat fringilla. Sed non rutrum nunc, 
et consequat leo. Aenean at nisi in purus commodo porta convallis 
vitae nulla. Mauris magna ligula, hendrerit non augue eget, 
eleifend pellentesque nibh. Curabitur arcu mauris, iaculis 
convallis felis dapibus, luctus varius dui.]]

print'iterate 100 tests of sign/verify'

for i=1,100 do
   local sig = mayo.sign(kp.private, O.from_string(msg))
   assert(mayo.verify(kp.public, sig, O.from_string(msg)), "mayo verify failed")
   assert(not mayo.verify(kp.public, sig, O.to_string(sha256(m))), "mayo verify failed")
end

for i=1,100 do
   local sm = mayo.signed_msg(kp.private, msg)
   assert(mayo.verified_msg(kp.public, sm):string() == msg,"mayo verify message failed")
   assert(not mayo.verified_msg(kp.public, sig, O.to_string(sha256(m))), "mayo verify message failed")
end