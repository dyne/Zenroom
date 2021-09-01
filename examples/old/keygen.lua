-- generate a simple keyring
keyring = ECDH.keygen()

-- export the keypair to json
print( JSON.encode( keyring ) )
