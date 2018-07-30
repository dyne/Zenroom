-- generate a simple keyring
keyring = ECDH.new()
keyring:keygen()

-- export the keypair to json
export = JSON.encode(
   {
      public  = keyring: public():base64(),
	  private = keyring:private():base64()
   }
)
print(export)
