-- This file is an extension of the petition algorithm presented in Coconut
-- At the moment it this extension allows to build a 2-preferences voting system 
-- Basically it recycles some of the already exisiting functions 
-- and data structures of the original petition scheme

-- The file also contains the test code used in coconut_test.lua readapted for the preference system 

COCONUT = require_once('crypto_coconut')

 local G1 = ECP.generator() -- return value
 local G2 = ECP2.generator() -- return value
 local O  = ECP.order() -- return value
 
 -- stateful challenge hardcoded string
 local hs = ECP.hashtopoint(str([[
 Developed for the DECODE project
 ]]))
 
 -----------
 -- preference algorithm
 
 function prove_sign_preference(pub, m, choice)
 -- is the analogous of COCONUT.prove_sign_petition

 -- sign == m
 local k = INT.random()
 -- preference encryption
 local enc_v = { left = G1 * k,
             right = pub * k + hs * m * choice }
 -- opposite of preference encryption
 local enc_v_neg = { left = enc_v.left:negative(),
                right = (pub * k):negative() - (BIG.new(1) - choice) * m * hs }
 -- commitment to the preference
 local r1 = INT.random()
 local r2 = r1 * (BIG.new(1) - m)
 local cv = G1 * m + hs * r1
 -- proof
 -- create the witnesess
 local wk = INT.random()
 local wm = INT.random()
 local wr1 = INT.random()
 local wr2 = INT.random()
 -- compute the witnessess commitments
 local Aw = G1*wk
 local Bw = pub*wk + hs*wm
 local Cw = G1*wm + hs*wr1
 local Dw = cv*wm + hs*wr2
 -- create the challenge
 local c = COCONUT.to_challenge({enc_v.left, enc_v.right,
                         cv, Aw, Bw, Cw, Dw}) % O
 -- create responses
 local rk = wk - c * k
 local rm = wm - c * m
 local rr1 = wr1 - c * r1
 local rr2 = wr2 - c * r2
 local pi_vote = { c = c,
              rk = rk,
              rm = rm,
              rr1 = rr1,
              rr2 = rr2 }
 -- Theta
 return { scores = { pos = enc_v,
                neg = enc_v_neg }, -- left/right tuples
       cv = cv, -- ecp
       pi_vote = pi_vote } -- pi
end

 
 function verify_sign_preference(pub, theta)
    -- analogous of COCONUT.verify_sign_petition but it should can be used also for the petition

    -- recompute witnessess commitment
    local scores = theta.scores 
    local Aw = G1 * theta.pi_vote.rk
      + scores.pos.left * theta.pi_vote.c
    -- the pararmeter Bw has been modified in order to be compliant with the new function
    local Bw = pub * theta.pi_vote.rk
      + hs * theta.pi_vote.rm
      + (BIG.modinv(BIG.new(2),O)*(scores.pos.right - scores.neg.right - hs) + hs) * theta.pi_vote.c
    local Cw = G1 * theta.pi_vote.rm
       + hs * theta.pi_vote.rr1
       + theta.cv * theta.pi_vote.c
    local Dw = theta.cv * theta.pi_vote.rm
       + hs * theta.pi_vote.rr2
       + theta.cv * theta.pi_vote.c
    -- verify challenge
    ZEN.assert(theta.pi_vote.c == COCONUT.to_challenge(
                  {scores.pos.left, scores.pos.right,
                   theta.cv, Aw, Bw, Cw, Dw }),
               "verify_sign_petition: challenge fails")
    return true
 end
 
 function count_preferences(scores, pi_tally)
    -- analogous of COCONUT.count_tally_petition
    local restab = { }
    for idx=0,1000 do      -- added the zero case since it can be a possibility
       -- if idx ~= 0 then -- not zero
       restab[(BIG.new(idx) * hs):octet():hex()] = idx
       -- end
    end
    local res = { pos = scores.pos.right + pi_tally.dec.pos,
                  neg = scores.neg.right + pi_tally.dec.neg  }
    return { pos = restab[res.pos:octet():hex()],
             neg = restab[res.neg:negative():octet():hex()]  }
 end
 
--TESTING
-- A single CA signs
-- generate the keys of the credential
cred_keypair = { private = INT.random() }
cred_keypair.public = ECP.generator() * cred_keypair.private
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

--VOTING
local UID = "petition unique identifier"
issuer = cred_keypair -- reuse the signed credential keypair for the issuer
voter = { private = INT.random() } -- create a new signed credential keypair for the voter
voter.public = ECP.generator() * voter.private
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


-- create the voting scores
local scores = { pos = { left = ECP.infinity(), right = ECP.infinity() },
				 neg = { left = ECP.infinity(), right = ECP.infinity() } }
-- loop through votes
local loops=37
for v=1,loops do
   local choice = INT.modrand(INT.new(2))
   --print(vote:hex())
   psign = prove_sign_preference(issuer.public, BIG.new(1), choice)
   local res = verify_sign_preference(issuer.public, psign)
   assert(res == true, "Coconut petition signature not verifying")
   print('[ok] test petition signature Coconut')
   -- sum the preference to the petition scores
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

results = count_preferences(scores, ptally)
I.print(results)
assert(results.pos + results.neg
        == loops, "Invalid preference count for petition")
print('')
print('[ok] test petition count Coconut')
print('')