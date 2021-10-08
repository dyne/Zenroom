local QP = require'qp'

local kp = QP.sigkeygen()

local msg = "I sign this great message"

local sig = QP.sign(kp.private, O.from_string(msg))

assert(QP.verify(kp.public, sig, O.from_string(msg)))
assert(not QP.verify(kp.public, sig, O.from_string("Another message")))

local sm = QP.signed_msg(kp.private, msg)

assert(QP.verified_msg(kp.public, sm):string() == msg)

local kp = QP.kemkeygen()

local alice = QP.enc(kp.public)
local bob_secret = QP.dec(kp.private, alice.cipher)

assert(alice.secret == bob_secret)
