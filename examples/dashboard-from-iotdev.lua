-- a dashboard receives an ID and payload packet from an IoT device


-- key schema
keys_schema = SCHEMA.Record { community_seckey = SCHEMA.String }

data_schema = SCHEMA.Record {
   text     = SCHEMA.string,
   iv       = SCHEMA.string,
   header   = SCHEMA.string,
   checksum = SCHEMA.string
}

-- same as payload in iotdev-to-dashboard
payload_schema = SCHEMA.Record {
   device_id   = SCHEMA.String,
   data        = SCHEMA.String
}

data = read_json(DATA) -- TODO: data_schema validation
keys = read_json(KEYS, keys_schema)
header = msgunpack( base64(data.header) )

dashkey = ECDH.new()
dashkey:private( base64(keys.community_seckey) )

payload,ck = decrypt(dashkey,
   base64( header.device_pubkey ),
   map(data, base64))

-- validate the payload
validate(payload, payload_schema)

-- print("Header:")
-- content(msgunpack(payload.header) )
print(JSON.encode(msgunpack(payload.text) ))
