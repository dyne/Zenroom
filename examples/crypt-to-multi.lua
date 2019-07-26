-- encrypt a secret to multiple recipients

-- run with arguments:
--  -a crypto-to-multi.data -k crypt-to-multi.keys 

-- inside KEYS is a list of names and public keys encoded with b58; it
-- returns a list of recipients and encrypted secrets for each and the
-- sender's public key
keyring = ECDH.new('ED25519')

secret = str(DATA)

keys = JSON.decode(KEYS)

-- this is our own secret key, combined with the recipient's public
-- key to obtain a session key
keyring:private( url64(keys.keyring.secret) )

res = {}

-- loop through all recipients
for name,pubkey in pairs(keys.recipients) do
   -- calculate the session key
   pub = url64(pubkey)
   session = keyring:session(pub)
   iv = RNG.new():octet(16)

   out = { header = "encoded using zenroom " .. VERSION}
   -- encrypt the message with the session key
   out.text, out.checksum = 
	  ECDH.aead_encrypt(session, secret, iv, out.header)

   -- insert results in final json array
   res[name] = url64( JSON.encode(out) )
end

-- return the json array
print(JSON.encode(res))
