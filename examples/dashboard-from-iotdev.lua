-- a dashboard receives an ID and payload packet from an IoT device

-- read and validate data
keys = JSON.decode(KEYS)
data = JSON.decode(DATA)

decode = { header = JSON.decode(data.header) }

commsec = O.from_url64(keys.community_seckey)
devpub = O.from_url64(decode.header.device_pubkey)
session = ECDH.session(commsec, devpub)
decode.text, decode.checksum =
   AES.gcm_decrypt(KDF(session), O.from_url64(data.text), 
					 O.from_url64(decode.header.iv), data.header)

assert(data.checksum == data.checksum)
print(JSON.encode(decode))

