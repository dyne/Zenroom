

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
d, gamma = ELGAMAL.keygen()
a, b, k = ELGAMAL.encrypt(gamma, m, hs)
dec = ELGAMAL.decrypt(d, a, b)
assert(dec == hs * m, 'El-Gamal encryption not working')
print('')
print('[ok] test El-Gamal')
print('')

-- A single CA signs
secret = "Some sort of secret credential"
cred_keypair = { }
cred_keypair.private, cred_keypair.public = ELGAMAL.keygen()
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
				   second = ECP.infinity() },
		dec = { }, -- hold the decryption shards
		list = { } -- hold the spent list
	}
	local sig = 1 -- TODO: create a signature over `new_petition` using priv_owner

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
	ret = ret and (parameters.sig == 1) -- TODO: verify the signature
	return ret
end

function sign_petition(inputs, settings)

	-- show coconut credentials
	local Theta, zeta = COCONUT.prove_cred_petition(
	   settings.aggr_vk,
	   settings.cred,
	   settings.priv_owner,
	   inputs.petition.uid)

	table.insert(inputs.petition.list,zeta)

	COCONUT.verify_cred_petition(
	   settings.aggr_vk,
	   Theta, zeta,
	   inputs.petition.uid)
	print "PETITION SIGN SUCCESS"
	-- coconut prov_cred_petition
	-- add zeta to the spend list
	-- (enc_v, enc_v_not, cv, pi_vote) = make proof of correct encryption
	local outputs = { petition = inputs.petition} -- new_petition
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
priv_owner, pub_owner = ELGAMAL.keygen()
-- priv_user, pub_user = ELGAMAL.keygen()
Lambda = COCONUT.prepare_blind_sign(pub_owner, priv_owner)
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, Lambda)
aggsigma = COCONUT.aggregate_creds(priv_owner, {sigma_tilde1, sigma_tilde2, sigma_tilde3})

local inputs = { token = 'Chainspace token' }
local settings = {
	uid = "petition unique identifier",
	priv_owner = priv_owner,
	pub_owner = pub_owner }
local outputs, parameters = create_petition(inputs, settings)
local ret = checker_create_petition(inputs, outputs, parameters)
assert(ret == true, 'Checker of `create_petition` not passing')
-- I.print(inputs)
-- I.print(outputs)
-- I.print(parameters)
inputs = outputs
settings = {
	priv_owner = priv_owner,
	cred = aggsigma,
	aggr_vk = ca_aggkeys} 
-- I.print(settings)
outputs, parameters = sign_petition(inputs, settings)

-- https://github.com/asonnino/coconut-chainspace
-- L44 create petition
-- L86 sign and following needs to be implemented
-- L125 tally
-- direct mapping
