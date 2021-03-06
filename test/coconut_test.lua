local COCONUT = require_once('crypto_credential')
local G2 = ECP2.generator()

-- elgamal
m = INT.new(sha256(str('Some sort of secret')))
hs = ECP.hashtopoint(str('anystring'))
d = INT.random()
gamma = ECP.generator() * d

-- A single CA signs
-- generate the keys of the credential
cred_keypair = {private = INT.random()}
cred_keypair.public = ECP.generator() * cred_keypair.private
secret = cred_keypair.private -- "Some sort of secret credential"

-- simple credential test
local ca_keypair = {}
ca_keypair.sign = COCONUT.issuer_keygen()
ca_keypair.verify = {
   alpha = G2 * ca_keypair.sign.x,
   beta = G2 * ca_keypair.sign.y
}
Lambda = COCONUT.prepare_blind_sign(secret)
sigmatilde = COCONUT.blind_sign(ca_keypair.sign, Lambda)
aggsigma = COCONUT.aggregate_creds(cred_keypair.private, {sigmatilde})
Theta = COCONUT.prove_cred(ca_keypair.verify, aggsigma, secret)
ret = COCONUT.verify_cred(ca_keypair.verify, Theta)
assert(ret == true, 'Coconut credentials not verifying')

-- wrong verifier test
-- sk, pk = COCONUT.ca_keygen()
-- wca_keypair = { verify = pk, sign = sk }
-- assert(wca_keypair ~= ca_keypair) -- wrong ca is different
-- Theta = COCONUT.prove_creds(ca_keypair.verify, aggsigma, secret)
-- ret = COCONUT.verify_creds(wca_keypair.verify, Theta)
-- assert(ret == false, 'Coconut credentials not failing')

print('')
print('[ok] test Coconut')
print('')

-- Multiple CAs sign
local ca2_keypair = {}
ca2_keypair.sign = COCONUT.issuer_keygen()
ca2_keypair.verify = {
   alpha = G2 * ca2_keypair.sign.x,
   beta = G2 * ca2_keypair.sign.y
}
local ca3_keypair = {}
ca3_keypair.sign = COCONUT.issuer_keygen()
ca3_keypair.verify = {
   alpha = G2 * ca3_keypair.sign.x,
   beta = G2 * ca3_keypair.sign.y
}

ca_aggkeys =
   COCONUT.aggregate_keys(
   {
      ca_keypair.verify,
      ca2_keypair.verify,
      ca3_keypair.verify
   }
)
Lambda = COCONUT.prepare_blind_sign(secret)
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, Lambda)
aggsigma =
   COCONUT.aggregate_creds(
   cred_keypair.private,
   {sigma_tilde1, sigma_tilde2, sigma_tilde3}
)
-- do the actual test
local Theta = COCONUT.prove_cred(ca_aggkeys, aggsigma, secret)
local ret = COCONUT.verify_cred(ca_aggkeys, Theta)
assert(ret == true, 'Coconut credentials not verifying')
print('')
print('[ok] test multi-authority Coconut')
print('')

-- PETITION
local UID = 'petition unique identifier'
issuer = cred_keypair -- reuse the signed credential keypair for the issuer
voter = {private = INT.random()} -- create a new signed credential keypair for the voter
voter.public = ECP.generator() * voter.private
Lambda = COCONUT.prepare_blind_sign(voter.private)
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, Lambda)
voter.aggsigma =
   COCONUT.aggregate_creds(
   voter.private,
   {sigma_tilde1, sigma_tilde2, sigma_tilde3}
)
local Theta =
   COCONUT.prove_cred(ca_aggkeys, voter.aggsigma, voter.private)
local ret = COCONUT.verify_cred(ca_aggkeys, Theta)

-- show coconut credentials
Theta, zeta =
   COCONUT.prove_cred_uid(
   ca_aggkeys,
   voter.aggsigma,
   voter.private,
   UID
)
local res = COCONUT.verify_cred_uid(ca_aggkeys, Theta, zeta, UID)
assert(res == true, 'Coconut petition credentials not verifying')
print('')
print('[ok] test petition credential Coconut')
print('')

local PET = require_once'crypto_petition'

-- create the petition scores
local scores = {
   pos = {left = ECP.infinity(), right = ECP.infinity()},
   neg = {left = ECP.infinity(), right = ECP.infinity()}
}
-- loop through votes
local loops = 6
for v = 1, loops do
   psign = PET.prove_sign_petition(issuer.public, BIG.new(1))
   local res = PET.verify_sign_petition(issuer.public, psign)
   assert(res == true, 'Coconut petition signature not verifying')
   print('[ok] test petition signature Coconut')
   -- sum the vote to the petition scores
   scores.pos.left = scores.pos.left + psign.scores.pos.left
   scores.pos.right = scores.pos.right + psign.scores.pos.right
   scores.neg.left = scores.neg.left + psign.scores.neg.left
   scores.neg.right = scores.neg.right + psign.scores.neg.right
end
print('')
ptally = PET.prove_tally_petition(issuer.private, scores)
local res = PET.verify_tally_petition(scores, ptally)
print('')
print('[ok] test petition tally Coconut')
print('')

assert(
   PET.count_signatures_petition(scores, ptally).pos == loops,
   'Invalid vote count for petition'
)
print('')
print('[ok] test petition count Coconut')
print('')
