-- generate a simple keyring
keyring = ecdh.new()
keyring:keygen()
keypair = json.encode(
   {
      public = keyring:public():base64(),
	  private = keyring:private():base64()
   }
)
print(keypair)
