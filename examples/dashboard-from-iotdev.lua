-- a dashboard receives an ID and payload packet from an IoT device

-- curve used
curve = 'ed25519'

-- data schemas
-- read and validate data
keys = JSON.decode(KEYS)
data = JSON.decode(DATA)

header = MSG.unpack(base64(data.header):str())

community_key = ECDH.new(curve)
community_key:private(base64(keys.community_seckey))

session = community_key:session(base64(header.device_pubkey))

decode = { header = header }
decode.text, decode.checksum =
   ECDH.aead_decrypt(session, base64(data.text), base64(header.iv), base64(data.header))

print(JSON.encode(MSG.unpack(decode.text:str())))

