-- one iot device encrypts its data and ID to a community dashboard
-- defines data validation shcemas that can be used on both ends
-- complementary to other script for reception

-- data schemas
keys_schema = schema.Record {
   device_id     = schema.String,
   community_id  = schema.String,
   community_pubkey = schema.String
}
payload_schema = schema.Record {
   device_id = schema.String,
   data      = schema.String
}
output_schema = schema.Record {
   device_pubkey = schema.String,
   community_id  = schema.String,
   payload       = schema.String
}

-- import and validate keys 
keys = read_json(KEYS, keys_schema)

-- import community's public key
comkey = ecdh.new()
comkey:public(
   octet.from_base64(keys['community_pubkey']))
-- generate a new device keypair every time
-- this could be optimised by creating keys onetime at first run
-- or temporarily, i.e: every day or every hour
devkey = ecdh.new()
devkey:keygen()

-- compute the session key using private/public keys
-- it may change to use random, but then we need a session channel
session = devkey:session(comkey)

-- payload is a nested json structure to be encrypted
payload = {}
payload['device_id'] = keys['device_id']
payload['data']      = DATA
schema.check(payload, payload_schema)

-- output is the packet, json formatted
-- only the device's public key is transmitted in clear
output = {}
output['device_pubkey'] = devkey:public():base64()
output['community_id'] = keys['community_id']
output['payload'] =
   devkey:encrypt(
	  session,
	  octet.from_string(json.encode(payload))
   ):base64()
schema.check(output, output_schema)

-- print out the json packet ready to be sent
print(json.encode(output))
