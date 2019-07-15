-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- Coconut implementation by Alberto Sonnino and Denis Roio
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.


-- Coconut is a selective disclosure credential scheme for Attribute
-- Based Credentials (ABC) supporting public and private attributes,
-- re-randomization, and multiple unlinkable selective attribute
-- revelations. For information about usage see
-- https://zenroom.dyne.org and https://decodeproject.eu


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
local function rand() return INT.new(RNG.new(),o) end

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
   local Aw = l.c.a * l.pi_s.c
	  + g1 * l.pi_s.rk
   local Bw = l.c.b * l.pi_s.c
	  + l.public * l.pi_s.rk
	  + h * l.pi_s.rm
   local Cw = l.cm * l.pi_s.c
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
   local vk = { alpha = g2 * x,
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
			alpha = agg_alpha,
			beta = agg_beta }
end

function coco.prepare_blind_sign(gamma, secret)
   local m = INT.new(sha256(secret))
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
   ZEN.assert(vk, "COCONUT.prove_creds called with empty verifier")
   ZEN.assert(sigma, "COCONUT.prove_creds called with empty credential")
   ZEN.assert(secret, "COCONUT.prove_creds called with empty secret")

   local m = INT.new(sha256(secret))
   local r = rand()
   local r_prime = rand()
   local sigma_prime = { h_prime = sigma.h * r_prime,
                         s_prime = sigma.s * r_prime  }
   local kappa = vk.alpha + vk.beta * m + g2 * r
   local nu = sigma_prime.h_prime * r
   -- make pi_v
   local wm = rand()
   local wr = rand()
   local Aw = vk.alpha + g2 * wr + vk.beta * wm
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
   ZEN.assert(vk, "COCONUT.verify_creds called with empty verifier")
   ZEN.assert(Theta, "COCONUT.verify_creds valled with empty proof")
   if #vk == 1 then vk = vk[1] end -- single element in array
   -- verify pi_v
   local Aw = Theta.kappa * Theta.pi_v.c
	  + g2 * Theta.pi_v.rr
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
				 == ECP2.miller(g2, Theta.sigma_prime.s_prime + Theta.nu),
			  "Credential proof does not verify (miller loop error)")
   return true
end

-----------
-- petition

function coco.prove_cred_petition(vk, sigma, secret, uid)
   local m = INT.new(sha256(secret))
   local o = ECP.order()
   local r = rand()
   -- local m = INT.new(sha256(secret))
   -- material
   local r_prime = rand()
   local sigma_prime = { h_prime = sigma.h * r_prime,
						 s_prime = sigma.s * r_prime  }
   local kappa = vk.alpha
	  + vk.beta * m
	  + g2 * r
   local nu = sigma_prime.h_prime * r
   local zeta = m * ECP.hashtopoint(str(uid))
   -- proof --
   -- create the witnessess
   local wm = rand()
   local wr = rand()
   -- compute the witnessess commitments
   local Aw = g2 * wr
	  + vk.alpha
	  + vk.beta * wm
   local Bw = sigma_prime.h_prime * wr
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

function coco.verify_cred_petition(vk, Theta, zeta, uid)
   local kappa = Theta.kappa
   local nu = Theta.nu
   local sigma_prime = Theta.sigma_prime
   local c = Theta.pi_v.c
   local rm = Theta.pi_v.rm
   local rr = Theta.pi_v.rr
   -- verify proof --
   -- recompute witnessess commitments
   local Aw = kappa * c
	  + g2 * rr
	  + vk.alpha * INT.new(1):modsub(c,ECP.order())
	  + vk.beta * rm
   local Bw = nu * c + sigma_prime.h_prime * rr
   local Cw = rm*ECP.hashtopoint(uid) + zeta*c
   -- compute the challenge prime
   ZEN.assert(c == COCONUT.to_challenge({ vk.alpha, vk.beta, Aw, Bw, Cw }),
			  "verify_cred_petition: invalid challenge")
   -- verify signature --
   ZEN.assert(not sigma_prime.h_prime:isinf(),
			  "verify_cred_petition: sigma_prime.h points at infinite")
   ZEN.assert(ECP2.miller(kappa, sigma_prime.h_prime)
				 == ECP2.miller(g2, sigma_prime.s_prime + nu),
			  "verify_cred_petition: miller loop fails")
   return true
end

-- takes an array of bigs and a curve order (modulo)
function coco.lagrange_interpolation(indexes)
   ZEN.assert(type(indexes) == "table", "Lagrange interpolation argument is not an array")
   local l = {}
   local numerator
   local denominator
   for i in indexes do
	  numerator = BIG.new(1)
	  denominator = BIG.new(1)
	  for j in indexes do
		 if (j ~= i)
		 then
            numerator = numerator:modmul(x:modsub(j,o),o)
            denominator = denominator:modmul(i:modsub(j,o),o)
		 end
		 l[#l+1] = numerator:modmul(denominator:modinv(o),o)
	  end
   end
   return l
end

function coco.prove_sign_petition(pub, m)
   -- sign == vote
   local k = rand()
   -- vote encryption
   local enc_v = { left = g1 * k,
				   right = pub * k + hs * m }
   -- opposite of vote encryption
   local enc_v_neg = { left = enc_v.left:negative(),
					   right = enc_v.right:negative() + hs }
   -- commitment to the vote
   local r1 = rand()
   local r2 = r1:modmul(BIG.new(1):modsub(m,o), o)
   local cv = g1 * m + hs * r1

   -- proof
   -- create the witnesess
   local wk = rand()
   local wm = rand()
   local wr1 = rand()
   local wr2 = rand()
   -- compute the witnessess commitments
   local Aw = g1*wk
   local Bw = pub*wk + hs*wm
   local Cw = g1*wm + hs*wr1
   local Dw = cv*wm + hs*wr2
   -- create the challenge
   local c = COCONUT.to_challenge({enc_v.left, enc_v.right,
								   cv, Aw, Bw, Cw, Dw}) % o
   -- create responses
   local rk = wk:modsub(c*k, o)
   local rm = wm:modsub(c*m, o)
   local rr1 = wr1:modsub(c*r1, o)
   local rr2 = wr2:modsub(c*r2, o)
   local pi_vote = { c = c,
					 rk = rk,
					 rm = rm,
					 rr1 = rr1,
					 rr2 = rr2 }

   -- signature's Theta
   return { scores = { pos = enc_v,
					   neg = enc_v_neg }, -- left/right tuples
			cv = cv, -- ecp
			pi_vote = pi_vote } -- pi
end

function coco.verify_sign_petition(pub, theta)
   -- recompute witnessess commitment
   local scores = theta.scores.pos -- only positive, not negative?
   local Aw = g1 * theta.pi_vote.rk
	  + scores.left * theta.pi_vote.c
   local Bw = pub * theta.pi_vote.rk
	  + hs * theta.pi_vote.rm
	  + scores.right * theta.pi_vote.c
   local Cw = g1 * theta.pi_vote.rm
	  + hs * theta.pi_vote.rr1
	  + theta.cv * theta.pi_vote.c
   local Dw = theta.cv * theta.pi_vote.rm
	  + hs * theta.pi_vote.rr2
	  + theta.cv * theta.pi_vote.c
   -- verify challenge
   ZEN.assert(theta.pi_vote.c == COCONUT.to_challenge(
				 {scores.left, scores.right,
				  theta.cv, Aw, Bw, Cw, Dw }),
			  "verify_sign_petition: challenge fails")
   return true
end

function coco.prove_tally_petition(sk, scores)
   local wx = rand()
   local Aw = { wx:modneg(o) * scores.pos.left,
				wx:modneg(o) * scores.neg.left  }
   local c = COCONUT.to_challenge(Aw)
   local rx = wx:modsub(c*sk, o)
   local dec = { pos = scores.pos.left * sk:modneg(o),
				 neg = scores.neg.left * sk:modneg(o) }
   -- return pi_tally
   return { dec = dec,
			rx = rx,
			c = c    }
end

function coco.verify_tally_petition(scores, pi_tally)
   local rxneg = pi_tally.rx:modneg(o)
   local Aw = { rxneg*scores.pos.left + pi_tally.c * pi_tally.dec.pos,
				rxneg*scores.neg.left + pi_tally.c * pi_tally.dec.neg  }
   ZEN.assert(pi_tally.c == COCONUT.to_challenge(Aw),
			  "verify_tally_petition: challenge fails")
   return true
end

function coco.count_signatures_petition(scores, pi_tally)
   local restab = { }
   for idx=-100,100 do
	  restab[hex(BIG.new(idx) * hs)] = idx
   end
   local res = { pos = scores.pos.right + pi_tally.dec.pos,
				 neg = scores.neg.right + pi_tally.dec.neg  }
   return { pos = restab[hex(res.pos)],
			neg = restab[hex(res.neg)]  }
end
return coco
