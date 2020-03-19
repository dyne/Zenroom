-- one iot device encrypts its data and ID to a community dashboard
-- defines data validation shcemas that can be used on both ends
-- complementary to other script for reception

-- import and validate keys 
keys = JSON.decode(KEYS)

-- generate a new device keypair every time
-- this could be optimised by creating keys onetime at first run
-- or temporarily, i.e: every day or every hour
devkey = ECDH.keygen()

-- compute the session key using private/public keys
-- it may change to use random, but then we need a session channel

-- payload is a nested json structure to be encrypted
payload = {}
payload.device_id = keys.device_id
payload.data      = DATA

-- The device's public key, the 'community_id' and the encryption
-- curve type are transmitted in clear inside the header, which is
-- authenticated (AEAD)
header = {}
header.device_pubkey = devkey.public:url64()
header.community_id = keys.community_id
header.iv = O.random(32):url64()

-- content( header ) -- uncomment for debug

-- The output is a table with crypto contents which is standard for
-- zenroom's functions encrypt/decrypt: .checksum .header .iv .text
local session = ECDH.session(devkey.private, url64(keys.community_pubkey))
local out = { header = url64(JSON.encode(header)) }
out.text, out.checksum = 
   ECDH.aead_encrypt(KDF(session), JSON.encode(payload), header.iv, out.header)

-- content(output) -- uncomment for debug
print( JSON.encode( out ) ) -- map(output, url64) ) )


