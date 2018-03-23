-- generate a signature keypair

-- run with: zenroom keygen.zen

-- any combination of public and private keys generated this way and
-- exchanged among different people will lead to the same secret which
-- is then usable for asymmetric encryption.

json = require "json"
crypto = require "crypto"
pk, sk = crypto.keygen_session_x25519()
keypair = json.encode(
   {
	  public=crypto.encode_b58(pk),
	  secret=crypto.encode_b58(sk)
   })
print(keypair)
