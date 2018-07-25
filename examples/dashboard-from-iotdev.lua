-- a dashboard receives an ID and payload packet from an IoT device


-- key schema
keys_schema = schema.Record {
   community_seckey = schema.String
}
-- same as output in iotdev-to-dashboard
data_schema = schema.Record {
   device_pubkey    = schema.String,
   community_id     = schema.String,
   payload          = schema.String
}
-- same as payload in iotdev-to-dashboard
payload_schema = schema.Record {
   device_id   = schema.String,
   data        = schema.String
}

data = read_json(DATA,data_schema)
keys = read_json(KEYS,keys_schema)

dashkey = ecdh.new()
dashkey:private(
   octet.from_base64(keys['community_seckey']))

devkey = ecdh.new()
devkey:public(
   octet.from_base64(data['device_pubkey']))

session = dashkey:session(devkey)

payload = 
   dashkey:decrypt(
	  session,
	  octet.from_base64(data['payload']))
-- validate the schema
read_json(payload:string(),payload_schema)
-- payload is already json encoded
print(payload:string())
