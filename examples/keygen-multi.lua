-- generate a private keyring and other fictional public keys

-- run with: zenroom keygen.zen

-- any combination of public and private keys generated this way and
-- exchanged among different people will lead to the same secret which
-- is then usable for asymmetric encryption.

recipients={'jaromil','francesca','jim','mark','paulus','mayo'}
keys={}
for i,name in ipairs(recipients) do
   kk = ecdh.new()
   kk:keygen()
   keys[name] = kk:public():base64()
   assert(kk:checkpub(kk:public()))
end


keyring = ecdh.new()
keyring:keygen()

keypairs = json.encode({
	  keyring={public=keyring:public():base64(),
			   secret=keyring:private():base64()},
	  recipients=keys})
print(keypairs)
