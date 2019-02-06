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
   -- return Lambda
   return { c  = c,
			rk = rk,
			rm = rm,
			rr = rr }
end

function coco.verify_pi_s(l)
   local h = ECP.hashtopoint(l.cm)
   local Aw =
	  l.c.a * l.pi_s.c
	  + g1 * l.pi_s.rk
   local Bw =
	  l.c.b * l.pi_s.c
	  + l.public * l.pi_s.rk
	  + h * l.pi_s.rm
   local Cw =
	  l.cm * l.pi_s.c
	  + g1 * l.pi_s.rr
	  + hs * l.pi_s.rm
   -- return a bool for assert
   return l.pi_s.c == coco.to_challenge({ l.cm, h, Aw, Bw, Cw })
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

function coco.blind_sign(sk, Lambda)
   ZEN.assert(coco.verify_pi_s(Lambda),
			  'Zero knowledge proof does not verify (Lambda.pi_s)')
   local h = ECP.hashtopoint(Lambda.cm)
   local a_tilde = Lambda.c.a * sk.y
   local b_tilde = h * sk.x + Lambda.c.b * sk.y
   -- sigma tilde
   return { h = h,
            a_tilde = a_tilde,
            b_tilde = b_tilde  }
end

function coco.aggregate_creds(d, sigma_tilde)
   local agg_s = ELGAMAL.decrypt(d,
								 sigma_tilde[1].a_tilde,
								 sigma_tilde[1].b_tilde)
   if #sigma_tilde > 1 then
      for i = 2, #sigma_tilde do
         agg_s = agg_s + ELGAMAL.decrypt(d,
										 sigma_tilde[i].a_tilde,
										 sigma_tilde[i].b_tilde)
      end
   end
   -- aggregated sigma
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
   -- make pi_v
   local wm = rand()
   local wr = rand()
   local Aw = vk.alpha + vk.g2 * wr + vk.beta * wm
   local Bw = sigma_prime.h_prime * wr
   local ch = coco.to_challenge({ vk.alpha, vk.beta, Aw, Bw })
   local pi_v = { c = ch,
				  rm = wm:modsub(m * ch, o),
				  rr = wr:modsub(r * ch, o)  }
   -- return Theta
   local Theta = {
      kappa = kappa,
      nu = nu,
      sigma_prime = sigma_prime,
      pi_v = pi_v }
   return Theta
end

function coco.verify_creds(vk, Theta)
   -- verify pi_v
   local Aw = Theta.kappa * Theta.pi_v.c
	  + vk.g2 * Theta.pi_v.rr
	  + vk.alpha * INT.new(1):modsub(Theta.pi_v.c, o)
	  + vk.beta * Theta.pi_v.rm
   local Bw = Theta.nu * Theta.pi_v.c
	  + Theta.sigma_prime.h_prime * Theta.pi_v.rr
   -- check zero knowledge proof
   ZEN.assert(Theta.pi_v.c == coco.to_challenge({vk.alpha, vk.beta, Aw, Bw}),
			  "Credential proof does not verify (wrong challenge)")
   ZEN.assert(not Theta.sigma_prime.h_prime:isinf(),
			  "Credential proof does not verify (sigma.h is infinite)")
   ZEN.assert(ECP2.miller(Theta.kappa, Theta.sigma_prime.h_prime)
				 == ECP2.miller(vk.g2, Theta.sigma_prime.s_prime + Theta.nu),
			  "Credential proof does not verify (miller loop error)")
   return true
end



return coco
