-- one iot device encrypts its data and ID to a community dashboard
-- defines data validation shcemas that can be used on both ends
-- complementary to other script for reception

-- curve used
curve = 'ed25519'

-- data schemas
keys_schema = SCHEMA.Record {
   device_id     = SCHEMA.String,
   community_id  = SCHEMA.String,
   community_pubkey = SCHEMA.String
}
payload_schema = SCHEMA.Record {
   device_id = SCHEMA.String,
   data      = SCHEMA.String
}
output_schema = SCHEMA.Record {
   device_pubkey = SCHEMA.String,
   community_id  = SCHEMA.String,
   payload       = SCHEMA.String
}

-- import and validate keys 
keys = read_json(KEYS, keys_schema)

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
validate(payload, payload_schema)

-- The device's public key, the 'community_id' and the encryption
-- curve type are transmitted in clear inside the header, which is
-- authenticated (AEAD)
header = {}
header['device_pubkey'] = devkey:public():base64()
header['community_id'] = keys['community_id']
-- content( header ) -- uncomment for debug

-- The output is a table with crypto contents which is standard for
-- zenroom's functions encrypt/decrypt: .checksum .header .iv .text
output = encrypt(devkey,
				 base64(keys.community_pubkey),
				 msgpack(payload), msgpack(header))

output = map(output, O.to_base64)
output.zenroom = VERSION
output.encoding = 'base64'
output.curve = curve
-- content(output) -- uncomment for debug
print( JSON.encode( output ) ) -- map(output, base64) ) )
