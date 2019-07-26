-- a dashboard receives an ID and payload packet from an IoT device

-- curve used
curve = 'ed25519'

-- read and validate data
keys = JSON.decode(KEYS)
data = JSON.decode(DATA)
header = JSON.decode(data.header)

community_key = ECDH.new(curve)
community_key:private(url64(keys.community_seckey))

session = community_key:session(url64(header.device_pubkey))

decode = { header = header }
decode.text, decode.checksum =
   ECDH.aead_decrypt(session, url64(data.text), url64(header.iv), url64(data.header))

output = JSON.decode(decode.text)
I.print(output)

