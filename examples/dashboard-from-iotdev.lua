-- a dashboard receives an ID and payload packet from an IoT device


-- key schema
keys_schema = SCHEMA.Record {
   community_seckey = SCHEMA.String
}
-- same as output in iotdev-to-dashboard
data_schema = SCHEMA.Record {
   device_pubkey    = SCHEMA.String,
   community_id     = SCHEMA.String,
   payload          = SCHEMA.String
}
-- same as payload in iotdev-to-dashboard
payload_schema = SCHEMA.Record {
   device_id   = SCHEMA.String,
   data        = SCHEMA.String
}

data = read_json(DATA,data_schema)
keys = read_json(KEYS,keys_schema)

dashkey = ECDH.new()
dashkey:private( base64(keys['community_seckey']) )

devkey = ECDH.new()
devkey:public( base64(data['device_pubkey']) )

session = dashkey:session(devkey)

payload = 
   dashkey:decrypt_weak_aes_cbc(
	  session,
	  base64(data['payload']))
-- validate the schema
read_json(payload:string(),payload_schema)
-- payload is already json encoded
print(payload:string())
