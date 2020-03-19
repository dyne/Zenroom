-- generate a simple keyring
keyring = ECDH.new()
keyring:keygen()

-- export the keypair to json
export = JSON.encode(
   {
      public  = keyring: public():url64(),
	  private = keyring:private():url64()
   }
)
print(export)
