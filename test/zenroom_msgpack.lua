print''
print("TEST MSGPACK WITH ZENROOM TYPES")
print''
ECP = require('zenroom_ecp')
ECP2 = require('zenroom_ecp2')
BIG = require('zenroom_big')
MPACK = require'zenroom_msgpack'
ZEN = require'zencode'
HASH = require'zenroom_hash'

G = ECP.generator()
O = ECP.order()
salt = ECP.hashtopoint("Constant random string")
message = INT.new(sha256("Message to be authenticated"))
r = BIG.random()
seckey = BIG.random()
test = { 
   r = r,
   G = G,
   O = O,
   salt = salt,
   message = message,
   commitment = G * r + salt * message,
   seckey = seckey,
   pubkey = G * seckey,
   pub2 = ECP2.generator() * seckey
}

test_hash = sha256( ZEN.serialize(test) ):hex()
print( "ENC SHA256: ".. test_hash)
m = MPACK.encode(test)
d = MPACK.decode(m)
res_hash = sha256( ZEN.serialize(d) ):hex()
print( "DEC SHA256: ".. res_hash)
assert( res_hash == test_hash, "encoding and decoding mismatch")
print''
