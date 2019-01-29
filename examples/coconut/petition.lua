

local g1 = ECP.generator() -- return value
local g2 = ECP2.generator() -- return value
local o  = ECP.order() -- return value
-- random generator init
local random = RNG.new()
local function rand() return INT.new(random,o) end

-- generic coconut TESTS
-- elgamal
m = INT.new(sha256(str("Some sort of secret")))
hs = ECP.hashtopoint(str("anystring"))
d, gamma = COCONUT.elgamal_keygen()
a, b, k = COCONUT.elgamal_enc(gamma, m, hs)
dec = COCONUT.elgamal_dec(d, a, b)
assert(dec == hs * m, 'El-Gamal encryption not working')
print('')
print('[ok] test El-Gamal')
print('')

-- A single CA signs
secret = "Some sort of secret credential"
cred_keypair = COCONUT.cred_keygen()
ca_keypair = COCONUT.ca_keygen()
Lambda = COCONUT.prepare_blind_sign(cred_keypair.public, secret)
sigmatilde = COCONUT.blind_sign(ca_keypair.sign, cred_keypair.public, Lambda)
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
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign,  cred_keypair.public, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, cred_keypair.public, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, cred_keypair.public, Lambda)
aggsigma = COCONUT.aggregate_creds(cred_keypair.private, {sigma_tilde1, sigma_tilde2, sigma_tilde3})
Theta = COCONUT.prove_creds(ca_aggkeys, aggsigma, secret)
ret = COCONUT.verify_creds(ca_aggkeys, Theta)
assert(ret == true, 'Coconut credentials not verifying')
print('')
print('[ok] test multi-authority Coconut')
print('')
-------------


-- Petition Contract
function create_petition(inputs, settings)
	local priv_owner = settings.priv_owner

	local petition = {
		object_type = 'PObject',
		uid = settings.uid,
		pub_owner = settings.pub_owner,
		scores = { first = ECP.infinity(),
				   second = ECP.infinity(),
				   dec = { }, -- hold the decryption shards
				   list = { } } -- hold the spent list
	}
	local sig = 1 -- /!\ create a signature over `new_petition` using priv_owner

	local outputs = { token = inputs.token, petition = petition}
	local parameters = { sig = sig }
	return outputs, parameters
end
function checker_create_petition(inputs, outputs, parameters)
	local ret = true
	local petition = outputs.petition

	-- check lenght of inputs, outputs and params
	-- check new_petition fields
	ret = ret and (inputs.token == outputs.token)
	ret = ret and (petition.scores.first == ECP.infinity())
	ret = ret and (petition.scores.second == ECP.infinity())
	ret = ret and (parameters.sig == 1) -- /!\ verify the signature
	return ret
end


local function prove_cred_petition(vk, sigma, m, uid)
   -- material
    local r = rand()
    local r_prime = rand()
    local sigma_prime = { h_prime = sigma.h * r_prime,
						  s_prime = sigma.s * r_prime  }
    local kappa = vk.g2 * r
	   + vk.alpha
	   + vk.beta * m
    local nu = r * sigma_prime.h_prime
    local zeta = m * ECP.hashtopoint(uid)
    
	-- proof
	-- create the witnesses
    local wm = rand()
    local wr = rand()
	-- compute the witnesses commitments
    local Aw = g2 * wr + vk.alpha + vk.beta * wm
    local Bw = wr * sigma_prime.h_prime
    local Cw = wm * ECP.hashtopoint(uid)
	-- create the challenge
    local c = COCONUT.to_challenge({ vk.alpha, vk.beta, Aw, Bw, Cw })
	-- create responses
    local rm = wm:modsub(m * c, o)
    local rr = wr:modsub(r * c, o)
    local pi_v = { c = c, 
				   rm = rm,
				   rr = rr }
    local Theta = {
       kappa = kappa,
       nu = nu,
       sigma_prime = sigma_prime,
       pi_v = pi_v }
    return Theta, zeta
end
local function verify_cred_petition(vk, Theta, zeta, uid)
	local kappa = Theta.kappa
	local nu = Theta.nu
	local sigma_prime = Theta.sigma_prime
	local c = Theta.pi_v.c
    local rm = Theta.pi_v.rm
    local rr = Theta.pi_v.rr
    local Aw = kappa * c
	   + g2 * rr
	   + vk.alpha * INT.new(1):modsub(c,o)
	   + vk.beta * rm
    local Bw = nu * c + sigma_prime.h_prime * rr
    local Cw = rm*ECP.hashtopoint(uid) + zeta*c
	assert(c == COCONUT.to_challenge({ vk.alpha, vk.beta, Aw, Bw, Cw }),
		   "COCONUT internal error: failure to compute the challenge prime")
    assert(not sigma_prime.h_prime:isinf(),
		   "COCONUT internal error: sigma_prime.h points to infinity")
    assert(ECP2.miller(kappa, sigma_prime.h_prime) == ECP2.miller(vk.g2, sigma_prime.s_prime + nu),
		   "COCONUT internal error: petition credential signature does not verify")
    return true
end
function sign_petition(inputs, settings)
	local old_petition = inputs.petition
	local new_petition = inputs.petition
	local priv_user = settings.priv_user
	local cred = settings.cred
	local aggr_vk = settings.aggr_vk

	-- show coconut credentials
	local Theta, zeta = prove_cred_petition(aggr_vk, cred, priv_user, old_petition.uid)

	assert(true == verify_cred_petition(aggr_vk, Theta, zeta, old_petition.uid), 
		   'Credentials petition proof does not verify') -- ret3 line 303 is failing
	-- coconut prov_cred_petition
	-- add zeta to the spend list
	-- (enc_v, enc_v_not, cv, pi_vote) = make proof of correct encryption
	local outputs = { petition = new_petition}
	local parameters = { Theta = Theta }
	return outputs, parameters
end




-- Test Petition Contract
ca_keypair = COCONUT.ca_keygen()
ca2_keypair = COCONUT.ca_keygen()
ca3_keypair = COCONUT.ca_keygen()
ca_aggkeys = COCONUT.aggregate_keys({ca_keypair.verify,
									 ca2_keypair.verify,
									 ca3_keypair.verify})

priv_owner, pub_owner = COCONUT.elgamal_keygen()
priv_user, pub_user = COCONUT.elgamal_keygen()
Lambda = COCONUT.prepare_blind_sign(pub_user, secret)
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign, pub_user, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, pub_user, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, pub_user, Lambda)
aggsigma = COCONUT.aggregate_creds(priv_user, {sigma_tilde1, sigma_tilde2, sigma_tilde3})

local inputs = { token = 'Chainspace token' }
local settings = {
	uid = "petition unique identifier",
	priv_owner = priv_owner,
	pub_owner = pub_owner }
local outputs, parameters = create_petition(inputs, settings)
local ret = checker_create_petition(inputs, outputs, parameters)
assert(ret == true, 'Checker of `create_petition` not passing')
I.print(inputs)
I.print(outputs)
I.print(parameters)
inputs = outputs
settings = {
	priv_user = priv_user,
	cred = aggsigma,
	aggr_vk = ca_aggkeys} 
I.print(settings)
outputs, parameters = sign_petition(inputs, settings)

-- https://github.com/asonnino/coconut-chainspace
-- L44 create petition
-- L86 sign and following needs to be implemented
-- L125 tally
-- direct mapping
