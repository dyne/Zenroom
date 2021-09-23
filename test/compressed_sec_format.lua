local v = BIG.from_decimal('25')

local p = BIG.new(O.from_hex('fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f'))
local e = BIG.new(O.from_hex('3fffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffff0c'))
w = v:modpower(e, p)

assert(BIG.modmul(w,w,p) == v)

kp = ECDH.keygen()

BTC = require('crypto_bitcoin')

compressed = BTC.compress_public_key(kp.public)
newpublic = BTC.uncompress_public_key(compressed)

assert(kp.public == newpublic)
