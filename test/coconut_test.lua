
-- elgamal
m = INT.new(sha256(str("Some sort of secret")))

hs = ECP.hashtopoint(str("anystring"))
d, gamma = ELGAMAL.keygen()
a, b, k = ELGAMAL.encrypt(gamma, m, hs)
dec = ELGAMAL.decrypt(d, a, b)
assert(dec == hs * m, 'El-Gamal encryption not working')
print('')
print('[ok] test El-Gamal')
print('')

-- A single CA signs
-- generate the keys of the credential
cred_keypair = { private = d,
				 public = gamma }
secret = cred_keypair.private -- "Some sort of secret credential"
-- simple credential test
ca_keypair = COCONUT.ca_keygen()
Lambda = COCONUT.prepare_blind_sign(cred_keypair.public, secret)
sigmatilde = COCONUT.blind_sign(ca_keypair.sign, Lambda)
aggsigma = COCONUT.aggregate_creds(cred_keypair.private, {sigmatilde})
Theta = COCONUT.prove_creds(ca_keypair.verify, aggsigma, secret)
ret = COCONUT.verify_creds(ca_keypair.verify, Theta)
assert(ret == true, 'Coconut credentials not verifying')
print('')
print('[ok] test Coconut')
print('')

-- Multiple CAs sign
ca2_keypair = COCONUT.ca_keygen()
ca3_keypair = COCONUT.ca_keygen()
ca_aggkeys = COCONUT.aggregate_keys({ca_keypair.verify,
									 ca2_keypair.verify,
									 ca3_keypair.verify})
Lambda = COCONUT.prepare_blind_sign(cred_keypair.public, secret)
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, Lambda)
aggsigma = COCONUT.aggregate_creds(cred_keypair.private, {sigma_tilde1, sigma_tilde2, sigma_tilde3})
-- do the actual test
local Theta = COCONUT.prove_creds(ca_aggkeys, aggsigma, secret)
local ret = COCONUT.verify_creds(ca_aggkeys, Theta)
assert(ret == true, 'Coconut credentials not verifying')
print('')
print('[ok] test multi-authority Coconut')
print('')


-- PETITION
local UID = "petition unique identifier"
-- show coconut credentials
Theta, zeta = COCONUT.prove_cred_petition(ca_aggkeys, aggsigma, secret, UID)
local res = COCONUT.verify_cred_petition(ca_aggkeys, Theta, zeta, UID)
assert(res == true, "Coconut petition credentials not verifying")
print('')
print('[ok] test petition credential Coconut')
print('')

voter = { }
voter.private, voter.public = ELGAMAL.keygen()

psign = COCONUT.prove_sign_petition(voter.public, BIG.new(1))
local res = COCONUT.verify_sign_petition(voter.public, psign)
assert(res == true, "Coconut petition signature not verifying")
print('')
print('[ok] test petition signature Coconut')
print('')
ptally = COCONUT.prove_tally_petition(secret, psign.scores)
local res = COCONUT.verify_tally_petition(psign.scores, ptally)
print('')
print('[ok] test petition tally Coconut')
print('')
