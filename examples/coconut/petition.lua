local coco =  { }
local g1 = ECP.generator() -- return value
local g2 = ECP2.generator() -- return value
local o  = ECP.order() -- return value

-- stateful challenge hardcoded string
local hs = ECP.hashtopoint(str([[
Developed for the DECODE project]]))
local challenge = g1:octet() .. g2:octet() .. hs:octet()


-- random generator init
local random = RNG.new()
local function rand() return INT.new(random,o) end

-- El-Gamal cryptosystem
function coco.elgamal_keygen()
   local d = rand()
   local gamma = d * g1
   return d, gamma
end
function coco.elgamal_enc(gamma, m, h)
   local k = rand()
   local a = k * g1
   local b = gamma * k + h * m
   return a, b, k
end
function coco.elgamal_dec(d, a, b)
   return b - a * d
end

-- local zero-knowledge proof verifications
local function to_challenge(list)
   -- assert(coco.challenge, "COCONUT secret challenge not set")
   return INT.new( sha256( challenge .. OCTET.serialize(list)))
end
local function make_pi_s(gamma, cm, k, r, m)
   local h = ECP.hashtopoint(cm)
   local wk = rand()
   local wm = rand()
   local wr = rand()
   local Aw = g1 * wk
   local Bw = gamma * wk + h * wm
   local Cw = g1 * wr + hs * wm
   local c = to_challenge({ cm, h, Aw, Bw, Cw })
   local rk = wk:modsub(c * k, o)
   local rm = wm:modsub(c * m, o)
   local rr = wr:modsub(c * r, o)
   return { c  = c,
			rk = rk,
			rm = rm,
			rr = rr }
end
function coco.verify_pi_s(gamma, ciphertext, cm, proof)
   local h = ECP.hashtopoint(cm)
   local a = ciphertext.a
   local b = ciphertext.b
   local c = proof.c
   local rk = proof.rk
   local rm = proof.rm
   local rr = proof.rr
   local Aw = a * c + g1 * rk
   local Bw = b * c + gamma * rk + h * rm
   local Cw = cm * c + g1 * rr + hs * rm
   return c == to_challenge({ cm, h, Aw, Bw, Cw })
end
local function make_pi_v(vk, sigma_prime, m, r)
   local wm = rand()
   local wr = rand()
   local Aw = g2 * wr + vk.alpha + vk.beta * wm
   local Bw = sigma_prime.h_prime * wr
   local c = to_challenge({ vk.alpha, vk.beta, Aw, Bw })
   local rm = wm:modsub(m * c, o)
   local rr = wr:modsub(r * c, o)
   return { c = c, rm = rm, rr = rr }
end
local function verify_pi_v(vk, kappa, nu, sigma_prime, proof)
   local c = proof.c
   local rm = proof.rm
   local rr = proof.rr
   local Aw = kappa * c + g2 * rr + vk.alpha * INT.new(1):modsub(c,o) + vk.beta * rm
   local Bw = nu * c + sigma_prime.h_prime * rr
   return c == to_challenge({ vk.alpha, vk.beta, Aw, Bw })
end

-- Public Coconut API
function coco.ca_keygen()
   local x = rand()
   local y = rand()
   local sk = { x = x,
                y = y  }
   local vk = { g2 = g2,
                alpha = g2 * x,
                beta  = g2 * y  }
   -- return keypair
   return { sign = sk,
            verify = vk }
end
function coco.cred_keygen()
   local d, gamma = coco.elgamal_keygen()
   return { private = d,
			public  = gamma }
end

function coco.aggregate_keys(keys)
   local agg_alpha = keys[1].alpha
   local agg_beta  = keys[1].beta
   if #keys > 1 then
	  for i = 2, #keys do
		 agg_alpha = agg_alpha + keys[i].alpha
		 agg_beta  = agg_beta  + keys[i].beta
	  end
   end
   -- return aggkeys
   return { schema = 'coconut_aggkeys',
			version = coco._VERSION,
			g2 = g2,
			alpha = agg_alpha,
			beta = agg_beta }
end

function coco.prepare_blind_sign(gamma, secret)
   local m = INT.new(sha256(str(secret)))
   local r = rand()
   local cm = g1 * r + hs * m
   local h = ECP.hashtopoint(cm)
   local a, b, k = coco.elgamal_enc(gamma, m, h)
   local c = {a = a, b = b}
   local pi_s = make_pi_s(gamma, cm, k, r, m)
   -- return Lambda
   return { cm   = cm,
            c    = c,
            pi_s = pi_s }
end

function coco.blind_sign(sk, gamma, Lambda)
   local ret = coco.verify_pi_s(gamma, Lambda.c, Lambda.cm, Lambda.pi_s)
   assert(ret == true, 'Proof pi_s does not verify') -- verify zero knowledge proof
   local h = ECP.hashtopoint(Lambda.cm)
   local a_tilde = Lambda.c.a * sk.y
   local b_tilde = h * sk.x + Lambda.c.b * sk.y
   return { h = h,
            a_tilde = a_tilde,
            b_tilde = b_tilde  }
end

function coco.aggregate_creds(d, sigma_tilde)
   local agg_s = coco.elgamal_dec(d, sigma_tilde[1].a_tilde, sigma_tilde[1].b_tilde)
   if #sigma_tilde > 1 then
      for i = 2, #sigma_tilde do
         agg_s = agg_s + coco.elgamal_dec(d, sigma_tilde[i].a_tilde, sigma_tilde[i].b_tilde)
      end
   end
   return { h = sigma_tilde[1].h,
            s = agg_s }
end

function coco.prove_creds(vk, sigma, secret)
   local m = INT.new(sha256(str(secret)))
   local r = rand()
   local r_prime = rand()
   local sigma_prime = { h_prime = sigma.h * r_prime,
                         s_prime = sigma.s * r_prime  }
   local kappa = vk.alpha + vk.beta * m + vk.g2 * r
   local nu = sigma_prime.h_prime * r
   local pi_v = make_pi_v(vk, sigma_prime, m, r)
   -- return Theta
   local Theta = {
      kappa = kappa,
      nu = nu,
      sigma_prime = sigma_prime,
      pi_v = pi_v }
   return Theta
end

function coco.verify_creds(vk, Theta)
   local ret = verify_pi_v(vk, Theta.kappa, Theta.nu, Theta.sigma_prime, Theta.pi_v)
   assert(ret == true, 'Proof pi_v does not verify') -- verify zero knowledge proof
   local ret1 = not Theta.sigma_prime.h_prime:isinf()
   local ret2 = ECP2.miller(Theta.kappa, Theta.sigma_prime.h_prime)
	  == ECP2.miller(vk.g2, Theta.sigma_prime.s_prime + Theta.nu)
   return ret1 and ret2
end

local COCONUT = coco

-- elgamal
m = INT.new(sha256(str("Some sort of secret")))

hs = ECP.hashtopoint(str("anystring"))
d, gamma = coco.elgamal_keygen()
a, b, k = coco.elgamal_enc(gamma, m, hs)
dec = coco.elgamal_dec(d, a, b)
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



-- Petition Contract
function create_petition(inputs, settings)
	local priv_owner = settings.priv_owner

	local petition = {
		object_type = 'PObject',
		uid = settings.uid,
		pub_owner = settings.pub_owner,
		scores = {first = ECP.infinity(), second = ECP.infinity(),
		dec = {}, -- hold the decryption shards
		list = {}} -- hold the spent list
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
    local r = rand()
    local r_prime = rand()
    local sigma_prime = { h_prime = sigma.h * r_prime, s_prime = sigma.s * r_prime  }
    local kappa = vk.alpha + vk.beta * m + vk.g2 * r
    local nu = sigma_prime.h_prime * r
    local zeta = m * ECP.hashtopoint(str(uid))
    
    local wm = rand()
    local wr = rand()
    local Aw = g2 * wr + vk.alpha + vk.beta * wm
    local Bw = sigma_prime.h_prime * wr
    local Cw = wm * ECP.hashtopoint(uid)
    local c = to_challenge({ vk.alpha, vk.beta, Aw, Bw, Cw })
    local rm = wm:modsub(m * c, o)
    local rr = wr:modsub(r * c, o)
    local pi_v = { c = c, rm = rm, rr = rr }

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
    local Aw = kappa * c + g2 * rr + vk.alpha * INT.new(1):modsub(c,o) + vk.beta * rm
    local Bw = nu * c + sigma_prime.h_prime * rr
    local Cw = rm*ECP.hashtopoint(uid) + zeta*c
    local ret1 = c == to_challenge({ vk.alpha, vk.beta, Aw, Bw, Cw })

    local ret2 = not sigma_prime.h_prime:isinf()
    local ret3 = ECP2.miller(kappa, sigma_prime.h_prime) == ECP2.miller(vk.g2, sigma_prime.s_prime + nu)
    return ret1 and ret2 and ret3
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
priv_owner, pub_owner = COCONUT.elgamal_keygen()
priv_user, pub_user = COCONUT.elgamal_keygen()
Lambda = COCONUT.prepare_blind_sign(pub_user, secret)
sigma_tilde1 = COCONUT.blind_sign(ca_keypair.sign, pub_user, Lambda)
sigma_tilde2 = COCONUT.blind_sign(ca2_keypair.sign, pub_user, Lambda)
sigma_tilde3 = COCONUT.blind_sign(ca3_keypair.sign, pub_user, Lambda)
aggsigma = COCONUT.aggregate_creds(priv_user, {sigma_tilde1, sigma_tilde2, sigma_tilde3})

local inputs = { token = 'Chainspace token' }
local settings = {
	uid = str([[petition unique identifier]]),
	priv_owner = priv_owner,
	pub_owner = pub_owner }
local outputs, parameters = create_petition(inputs, settings)
local ret = checker_create_petition(inputs, outputs, parameters)
assert(ret == true, 'Checker of `create_petition` not passing')

inputs = outputs
settings = {
	priv_user = priv_user,
	cred = aggsigma,
	aggr_vk = ca_aggkeys} 
outputs, parameters = sign_petition(inputs, settings)

-- https://github.com/asonnino/coconut-chainspace
-- L44 create petition
-- L86 sign and following needs to be implemented
-- L125 tally
-- direct mapping
