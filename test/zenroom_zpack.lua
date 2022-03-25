print''
print("TEST ZPACK (msgpack + ZSTD)")
print''
OCTET = require'zenroom_octet'
ECP = require('zenroom_ecp')
ECP2 = require('zenroom_ecp2')
BIG = require('zenroom_big')
MPACK = require'zenroom_msgpack'
ZPACK = require'zenroom_zpack'
ZEN = require'zencode'
HASH = require'zenroom_hash'

G = ECP.generator()
salt = ECP.hashtopoint("Constant random string")
message = INT.new(sha256("Message to be authenticated"))
r = BIG.random()
seckey = BIG.random()
test = { 
   r = r,
   G = G,
   O = ECP.order(),
   salt = salt,
   message = message,
   commitment = G * r + salt * message,
   seckey = seckey,
   pubkey = G * seckey,
   pub2 = ECP2.generator() * seckey
}

test_hash = sha256( ZEN.serialize(test) ):hex()
print( "ENC SHA256: ".. test_hash)
sm = MPACK.encode(test)
d = MPACK.decode(sm)
res_hash = sha256( ZEN.serialize(d) ):hex()
print( "DEC SHA256: ".. res_hash)
assert( res_hash == test_hash, "msgpack encoding and decoding mismatch")

zc = ZPACK.encode(test)
zd = ZPACK.decode(zc)
res_hash = sha256( ZEN.serialize(zd) ):hex()
print ("ZDEC SHA256:"..res_hash)
print("uncompressed size: "..#sm)
print("compressed size:   "..#zc)
print("compression ration: ".. (#zc / #sm))
assert( res_hash == test_hash, "zpack encoding and decoding mismatch")
print''
