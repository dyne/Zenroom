-- encrypt a secret to multiple recipients

-- run with arguments:
--  -a crypto-to-multi.data -k crypt-to-multi.keys

-- inside KEYS is a list of names and public keys encoded with b58; it
-- returns a list of recipients and encrypted secrets for each and the
-- sender's public key

secret = str(DATA)

keys = JSON.decode(KEYS)

-- this is our own secret key, combined with the recipient's public
-- key to obtain a session key
local private = url64(keys.keyring.secret)
res = {}

-- loop through all recipients
for name,pubkey in pairs(keys.recipients) do
   -- calculate the session key

   session = ECDH.session(private, O.from_url64(pubkey))
   iv = O.random(32)

   out = { header = "encoded using zenroom " .. VERSION.original}
   -- encrypt the message with the session key
   out.text, out.checksum =
	  AES.gcm_encrypt(KDF(session), secret, iv, out.header)

   -- insert results in final json array
   res[name] = url64( JSON.encode(out) )
end

-- return the json array
print(JSON.encode(res))
