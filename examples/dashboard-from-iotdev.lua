-- a dashboard receives an ID and payload packet from an IoT device

-- read and validate data
keys = I.spy( JSON.decode(KEYS) )
data = I.spy( JSON.decode(DATA) )

decode = { header = JSON.decode(url64(data.header)) }

commsec = url64(keys.community_seckey)
devpub = url64(decode.header.device_pubkey)
session = ECDH.session(commsec, devpub)
decode.text, decode.checksum =
   ECDH.aead_decrypt(KDF(session), url64(data.text), url64(decode.header.iv), data.header)

assert(decode.checksum == url64(data.checksum))
print(JSON.encode(decode))

