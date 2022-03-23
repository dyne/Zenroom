ECP = require('zenroom_ecp')
ECP2 = require('zenroom_ecp2')
BIG = require('zenroom_big')
MPACK = require'zenroom_msgpack'

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
	 pubkey = G * seckey
}

m = MPACK.encode(test)
print(m)
d = MPACK.decode(m)
I.print( d )
