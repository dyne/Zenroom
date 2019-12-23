print''
print '= TEST ELGAMAL COMMITMENT'
print''
--- small test to see if ElGamal commitment works

G = ECP.generator()
O = ECP.order()
salt = ECP.hashtopoint("Constant random string")
secret = INT.new(sha256("Secret message to be hashed to a number"))
r = INT.modrand(O)
commitment = G * r + salt * secret

-- keygen
seckey = INT.modrand(O)
pubkey = seckey * G

-- encrypt
k = INT.modrand(O)
cipher = { a = G * k,
		   b = pubkey * k + commitment * secret }

-- decrypt
assert(cipher.b - cipher.a * seckey
		  ==
		  commitment * secret, "ELGAMAL failure")


print''
print('ELGAMAL OK')
print''
