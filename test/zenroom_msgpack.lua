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
}

I.print(test)
print( "SHA256: ".. sha256( ZEN.serialize(test) ):hex() )
m = MPACK.encode(test)
d = MPACK.decode(m)
print( "SHA256: ".. sha256( ZEN.serialize(d) ):hex())
I.print( d )
