
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
local sk, pk
sk, pk = COCONUT.ca_keygen()
ca_keypair = { verify = pk, sign = sk }
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
sk, pk = COCONUT.ca_keygen()
ca2_keypair = { verify = pk, sign = sk }
sk, pk = COCONUT.ca_keygen()
ca3_keypair = { verify = pk, sign = sk }
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
issuer = cred_keypair -- reuse the signed credential keypair for the issuer
voter = { } -- create a new signed credential keypair for the voter
voter.private, voter.public = ELGAMAL.keygen()
Lambda = COCONUT.prepare_blind_sign(voter.public, voter.private)
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, Lambda)
voter.aggsigma = COCONUT.aggregate_creds(voter.private, {sigma_tilde1, sigma_tilde2, sigma_tilde3})
local Theta = COCONUT.prove_creds(ca_aggkeys, voter.aggsigma, voter.private)
local ret = COCONUT.verify_creds(ca_aggkeys, Theta)

-- show coconut credentials
Theta, zeta = COCONUT.prove_cred_petition(ca_aggkeys, voter.aggsigma, voter.private, UID)
local res = COCONUT.verify_cred_petition(ca_aggkeys, Theta, zeta, UID)
assert(res == true, "Coconut petition credentials not verifying")
print('')
print('[ok] test petition credential Coconut')
print('')

-- create the petition scores
local scores = { pos = { left = ECP.infinity(), right = ECP.infinity() },
				 neg = { left = ECP.infinity(), right = ECP.infinity() } }
-- loop through votes
local loops=6
for v=1,loops do
   psign = COCONUT.prove_sign_petition(issuer.public, BIG.new(1))
   local res = COCONUT.verify_sign_petition(issuer.public, psign)
   assert(res == true, "Coconut petition signature not verifying")
   print('[ok] test petition signature Coconut')
   -- sum the vote to the petition scores
   scores.pos.left =  scores.pos.left  + psign.scores.pos.left
   scores.pos.right = scores.pos.right + psign.scores.pos.right
   scores.neg.left =  scores.neg.left  + psign.scores.neg.left
   scores.neg.right = scores.neg.right + psign.scores.neg.right
end
print('')
ptally = COCONUT.prove_tally_petition(issuer.private, scores)
local res = COCONUT.verify_tally_petition(scores, ptally)
print('')
print('[ok] test petition tally Coconut')
print('')

assert( COCONUT.count_signatures_petition(scores, ptally).pos
		== loops, "Invalid vote count for petition")
print('')
print('[ok] test petition count Coconut')
print('')

