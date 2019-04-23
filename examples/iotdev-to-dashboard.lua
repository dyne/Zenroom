-- one iot device encrypts its data and ID to a community dashboard
-- defines data validation shcemas that can be used on both ends
-- complementary to other script for reception

-- curve used
curve = 'ed25519'

-- import and validate keys 
keys = JSON.decode(KEYS)

-- generate a new device keypair every time
-- this could be optimised by creating keys onetime at first run
-- or temporarily, i.e: every day or every hour
devkey = ECDH.keygen(curve)

-- compute the session key using private/public keys
-- it may change to use random, but then we need a session channel

-- payload is a nested json structure to be encrypted
payload = {}
payload['device_id'] = keys['device_id']
payload['data']      = DATA

-- The device's public key, the 'community_id' and the encryption
-- curve type are transmitted in clear inside the header, which is
-- authenticated (AEAD)
header = {}
header['device_pubkey'] = devkey:public():base64()
header['community_id'] = keys['community_id']
iv = RNG.new():octet(16)
header['iv'] = iv:base64()

-- content( header ) -- uncomment for debug

-- The output is a table with crypto contents which is standard for
-- zenroom's functions encrypt/decrypt: .checksum .header .iv .text
local session = devkey:session(base64(keys.community_pubkey))
local head = str(MSG.pack(header))
local out = { header = head }
out.text, out.checksum = 
   ECDH.aead_encrypt(session, str(MSG.pack(payload)), iv, head)

output = map(out, base64)
output.zenroom = VERSION
output.encoding = 'base64'
output.curve = curve
-- content(output) -- uncomment for debug
print( JSON.encode( output ) ) -- map(output, base64) ) )


