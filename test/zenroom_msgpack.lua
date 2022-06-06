print''
print("TEST MSGPACK WITH ZENROOM TYPES")
print''
OCTET = require'zenroom_octet'
ECP = require('zenroom_ecp')
ECP2 = require('zenroom_ecp2')
BIG = require('zenroom_big')
MPACK = require'zenroom_msgpack'
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
print( sm )
local ssm = OCTET.from_rawlen(sm, #sm)
local b64 = ssm:base64()

d = MPACK.decode(OCTET.from_base64(b64):string())
res_hash = sha256( ZEN.serialize(d) ):hex()
print( "DEC SHA256: ".. res_hash)
assert( res_hash == test_hash, "encoding and decoding mismatch")
print''

