-- Coconut implementation by Alberto Sonnino and Denis Roio

-- Coconut is a selective disclosure credential scheme for Attribute
-- Based Credentials (ABC) supporting public and private attributes,
-- re-randomization, and multiple unlinkable selective attribute
-- revelations. For information about usage see
-- https://zenroom.dyne.org and https://decodeproject.eu

-- Licensed under the terms of the GNU Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.  Unless required by applicable
-- law or agreed to in writing, software distributed under the License
-- is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied.

local coco = {
   _VERSION = 'crypto_coconut.lua 1.0',
   _URL = 'https://zenroom.dyne.org',
   _DESCRIPTION = 'Attribute-based credential system supporting multiple unlinkable private attribute revelations',
   _LICENSE = [[
Licensed under the terms of the GNU Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.  Unless required by applicable
law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.
]]
}

local g1 = ECP.generator() -- return value
local g2 = ECP2.generator() -- return value
local o  = ECP.order() -- return value

-- stateful challenge hardcoded string
local hs = ECP.hashtopoint(str([[
Developed for the DECODE project
]] .. coco._LICENSE))
local challenge = g1:octet() .. g2:octet() .. hs:octet()
function coco.to_challenge(list)
   -- assert(coco.challenge, "COCONUT secret challenge not set")
   return INT.new( sha256( challenge .. OCTET.serialize(list)))
end


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
local function make_pi_s(gamma, cm, k, r, m)
   local h = ECP.hashtopoint(cm)
   local wk = rand()
   local wm = rand()
   local wr = rand()
   local Aw = g1 * wk
   local Bw = gamma * wk + h * wm
   local Cw = g1 * wr + hs * wm
   local c = coco.to_challenge({ cm, h, Aw, Bw, Cw })
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
   return c == coco.to_challenge({ cm, h, Aw, Bw, Cw })
end


local function make_pi_v(vk, sigma_prime, m, r)
   local wm = rand()
   local wr = rand()
   local Aw = g2 * wr + vk.alpha + vk.beta * wm
   local Bw = sigma_prime.h_prime * wr
   local c = coco.to_challenge({ vk.alpha, vk.beta, Aw, Bw })
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
   return c == coco.to_challenge({ vk.alpha, vk.beta, Aw, Bw })
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
   local d, gamma = ELGAMAL.keygen()
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
   local a, b, k = ELGAMAL.encrypt(gamma, m, h)
   local c = {a = a, b = b}
   local pi_s = make_pi_s(gamma, cm, k, r, m)
   -- return Lambda
   return { cm   = cm,
            c    = c,
            pi_s = pi_s,
			public = gamma }
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
   local agg_s = ELGAMAL.decrypt(d, sigma_tilde[1].a_tilde, sigma_tilde[1].b_tilde)
   if #sigma_tilde > 1 then
      for i = 2, #sigma_tilde do
         agg_s = agg_s + ELGAMAL.decrypt(d, sigma_tilde[i].a_tilde, sigma_tilde[i].b_tilde)
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



return coco
