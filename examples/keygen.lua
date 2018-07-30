-- generate a simple keyring
keyring = ECDH.new()
keyring:keygen()
keypair = JSON.encode(
   {
      public = keyring:public():base64(),
	  private = keyring:private():base64()
   }
)
print(keypair)
