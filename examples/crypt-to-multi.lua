-- encrypt a secret to multiple recipients

-- run with arguments:
--  -a crypto-to-multi.data -k crypt-to-multi.keys 

-- inside KEYS is a list of names and public keys encoded with b58; it
-- returns a list of recipients and encrypted secrets for each and the
-- sender's public key
json = require "json"
crypto = require "crypto"

secret=DATA

-- this should be a random string every time
nonce="eishai7Queequot7pooc3eiC7Ohthoh1"

keys = json.decode(KEYS)
-- this is our own secret key, combined with the recipient's public
-- key to obtain a session key
seckey = keys.keyring.seckey;

res = {}

-- loop through all recipients
for name,pubkey in pairs(keys.recipients) do
   -- calculate the session key
   k = crypto.exchange_session_x25519(
	  crypto.decode_b58(seckey),
	  crypto.decode_b58(pubkey))
   -- encrypt the message with the session key
   enc = crypto.encrypt_norx(k,nonce,secret)
   -- insert results in final json array
   res[name]=crypto.encode_b58(enc)
end

-- return the json array
print(json.encode(res))
