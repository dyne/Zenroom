-- one iot device encrypts its data and ID to a community dashboard
-- defines data validation shcemas that can be used on both ends
-- complementary to other script for reception

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

-- import community's public key
comkey = ECDH.new()
comkey:public(
   base64(keys['community_pubkey']))
-- generate a new device keypair every time
-- this could be optimised by creating keys onetime at first run
-- or temporarily, i.e: every day or every hour
devkey = ECDH.new()
devkey:keygen()

-- compute the session key using private/public keys
-- it may change to use random, but then we need a session channel
session = devkey:session(comkey)

-- payload is a nested json structure to be encrypted
payload = {}
payload['device_id'] = keys['device_id']
payload['data']      = DATA
SCHEMA.check(payload, payload_schema)

-- output is the packet, json formatted
-- only the device's public key is transmitted in clear
header = {}
header['device_pubkey'] = devkey:public():base64()
header['community_id'] = keys['community_id']
-- content( header )
output = encrypt(devkey, comkey, MSG.pack(payload), MSG.pack(header))
print( JSON.encode( map(output, base64) ) )
