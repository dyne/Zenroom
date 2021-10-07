PQ = require'pq'

kp = PQ.sigkeygen()

msg = "I sign this great message"

sig = PQ.sign(kp.private, O.from_string(msg))

assert(PQ.verify(kp.public, sig, O.from_string(msg)))
assert(not PQ.verify(kp.public, sig, O.from_string("Another message")))
