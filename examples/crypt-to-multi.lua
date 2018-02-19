-- encrypt a secret to multiple recipients

-- run with: zenroom -a recipients.json crypt-to-multi.lua

-- inside recipients.json is a list of names and public keys encoded
-- with b58

-- returns a list of recipients and encrypted secrets for each and the
-- sender's public key

secret="this is a secret that noone knows"
-- this should be a random string every time
nonce="eishai7Queequot7pooc3eiC7Ohthoh1"

json = cjson_safe()
keys = json.decode(arguments)

res = {}

for name,pubkey in pairs(keys.recipients) do
   k = exchange_session_x25519(
	  decode_b58(keys.keyring.secret),
	  decode_b58(pubkey))
   enc = encrypt_norx(k,nonce,secret)
   -- insert in results
   res[name]=encode_b58(enc)
end
print(json.encode(res))
