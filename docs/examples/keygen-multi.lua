-- generate a private keyring and other fictional public keys

-- run with: zenroom keygen.zen

-- any combination of public and private keys generated this way and
-- exchanged among different people will lead to the same secret which
-- is then usable for asymmetric encryption.

recipients={'jaromil','francesca','jim','mark','paulus','mayo'}
keys={}
for i,name in ipairs(recipients) do
   kk = ECDH.keygen()
   keys[name] = kk.public:url64()
end


keyring = ECDH.keygen()

keypairs = JSON.encode({
	  keyring={public=keyring.public:url64(),
			   secret=keyring.private:url64()},
	  recipients=keys})
print(keypairs)
