-- generate a signature keypair

-- run with: zenroom keygen.zen

-- any combination of public and private keys generated this way and
-- exchanged among different people will lead to the same secret which
-- is then usable for asymmetric encryption.

json = cjson()
pk, sk = keygen_session_x25519()
keypair = json.encode(
   {
	  public=encode_b58(pk),
	  secret=encode_b58(sk)
   })
print(keypair)
