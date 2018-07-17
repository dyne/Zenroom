-- one iot device encrypts its data and ID to a dashboard
-- defines data validation shcemas that can be used on both ends
-- complementary to other script for reception

-- data schemas
keys_schema = schema.Record {
   device_seckey = schema.String,
   device_id     = schema.String,
   dashboard_key = schema.String
}
payload_schema = schema.Record {
   device_id = schema.String,
   data      = schema.String
}
output_schema = schema.Record {
   device_pubkey = schema.String,
   payload       = schema.String
}

-- import and validate keys 
keys = read_json(KEYS, keys_schema)

-- import dashboard's public key
dashkey = ecdh.new()
dashkey:public(
   octet.from_base64(keys['dashboard_key']))
-- import devices private key
devkey = ecdh.new()
devkey:private(
   octet.from_base64(keys['device_seckey']))

-- compute the session key using private/public keys
-- it may change to use random, but then we need a session channel
session = devkey:session(dashkey)

-- payload is a nested json structure to be encrypted
payload = {}
payload['device_id'] = keys['device_id']
payload['data']      = DATA
schema.check(payload, payload_schema)

-- output is the packet, json formatted
-- only the device's public key is transmitted in clear
output = {}
output['device_pubkey'] = devkey:public():base64()
output['payload'] =
   devkey:encrypt(
	  session,
	  octet.from_string(json.encode(payload))
   ):base64()
schema.check(output, output_schema)

-- print out the json packet ready to be sent
print(json.encode(output))
