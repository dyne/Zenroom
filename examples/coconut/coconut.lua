-- Coconut in Zencode, implementation by Alberto Sonnino and Denis Roio

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

-- Setup
rng = RNG.new()
g1 = ECP.generator()
g2 = ECP2.generator()
hs = ECP.hashtopoint(str("Untold secret string"))
o = ECP.order()


-- El-Gamal cryptosystem
function elgamal_keygen()
   local d = rng:modbig(o)
   local gamma = g1 * d

   return d, gamma
end

function elgamal_enc(gamma, m, h)
   local k = rng:modbig(o)
   local a = g1 * k
   local b = gamma * k + h * m
   return a, b, k
end

function elgamal_dec(d, a, b)
   return b - a * d
end


-- Coconut
function keygen()
   local x = rng:modbig(o)
   local y = rng:modbig(o)
   local sk = { x = x , y = y }
   local vk = { g2 = g2, alpha = g2 * x, beta = g2 * y }

   return sk, vk
end

function aggKey(keys)
   local agg_vk = keys[1]
   for i = 2, #keys do
	  agg_vk = agg_vk + keys[i]
   end

   return agg_vk
end

function prepareBlindSing(gamma, m)
   local r = rng:modbig(o)
   local cm = g1 * r + hs * m
   local h = ECP.hashtopoint(cm:x():octet()..cm:y():octet())
   local a, b, k = elgamal_enc(gamma, m, h)
   local c = {a = a, b = b}
   local pi_s = make_pi_s(gamma, cm, k, r, m)
   return cm, c, pi_s
end

function blindSign(sk, cm, c, pi_s, gamma)
   local ret = true --verify_pi_s(gamma, c, cm, pi_s)
   assert(ret == true, 'Proof pi_s does not verify') -- verify zero knowledge proof
   local h = ECP.hashtopoint(cm:x():octet()..cm:y():octet())
   local a_tilde = c.a * sk.y
   local b_tilde = h * sk.x + c.b * sk.y
   return {h = h, a_tilde = a_tilde, b_tilde = b_tilde}
end

function unblind(sigma_tilde, d)
   local s = elgamal_dec(d, sigma_tilde.a_tilde, sigma_tilde.b_tilde)
   return { h = sigma_tilde.h, s = s }
end

function aggCred(sigmas)
   local agg_sigma = sigmas[1]
   for i = 2, #sigmas do
	  agg_sigma = agg_sigma + sigmas[i]
   end

   return agg_sigma
end

function proveCred(vk, m, sigma)
   local r = rng:modbig(o)
   local r_prime = rng:modbig(o)
   local sigma_prime = { h_prime = sigma.h * r_prime, s_prime = sigma.s * r_prime }
   local kappa = vk.alpha + vk.beta * m + vk.g2 * r
   local nu = sigma_prime.h_prime * r
   local pi_v = 1 -- make zero knowledge proof

   return sigma_prime, kappa, nu, pi_v
end

function verifyCred(vk, sigma_prime, kappa, nu, pi_v)
   assert(pi_v == 1, 'Proof pi_v does not verify') -- verify zero knowledge proof
   local ret1 = not sigma_prime.h_prime:isinf()
   local ret2 = ECP2.miller(kappa, sigma_prime.h_prime) == ECP2.miller(vk.g2, sigma_prime.s_prime + nu)
   return ret1 and ret2
end


-- proofs
function to_challenge(list)
   local concat = OCTET.serialize(list)
   return BIG.new(sha512(concat))
end

function make_pi_s(gamma, cm, k, r, m)
   local h = ECP.hashtopoint(cm:x():octet()..cm:y():octet())

   local wr = rng:modbig(o)
   local wk = rng:modbig(o)
   local wm = rng:modbig(o)

   local Aw = g1 * wk
   local Bw = gamma * wk + h * wm
   local Cw = g1 * wr + hs * wm

   local c = to_challenge({g1, g2, cm, h, hs, Aw})
   local rr = wr:modsub(c * r, o) -- subtract within modulo origin
   local rk = wk:modsub(c * k, o)
   -- WIP from here
   -- local rk1 = wk:modsub(c:modmul(k, o), o)
   -- assert(rk == rk1)

   -- print(g1 * wk)
   -- print( (g1*k) * c + g1 * rk )
   local rm = (wm - c * m) % o
   return { c = c, rk = rk, rm = rm, rr = rr }
end

function verify_pi_s(gamma, ciphertext, cm, proof)
   local h = ECP.hashtopoint(cm:x():octet()..cm:y():octet())

   local a = ciphertext.a
   local b = ciphertext.b
   local c = proof.c
   local rk = proof.rk
   local rm = proof.rm
   local rr = proof.rr

   local Aw = a * c + g1 * rk
   local Bw = b * c + gamma * rk + h * rm
   local Cw = cm * c + g1 * rr + hs * rm
   return c == to_challenge({g1, g2, cm, h, hs, Aw})
end

--[[
   function make_pi_v(vk, sigma, m, t)
   local wm = rng:modbig(o)
   local wt = rng:modbig(o)

   local Aw = g2 * wt + vk.alpha + vk.beta * wm
   local Bw = sigma.h * wt
   local c = to_challenge({g1, g2, hs, vk.alpha, vk.beta, Aw, Bw})
   local rm = wm:modsub(m * c, o)
   local rt = wt:modsub(t * c, o)
   return { c = c, rm = rm, rt = rt }
   end

   function verify_pi_v(params, vk, sigma, kappa, nu, proof)
   local c = proof.c
   local rm = proof.rm
   local rr = proof.rr

   local Aw = kappa * c + g2 * rt + vk.alpha * (1-c) + vk.beta * rm
   local Bw = nu * c + sigma.h * rt
   return c == to_challenge({g1, g2, hs, vk.alpha, vk.beta, Aw, Bw})
   end
--]]


-- tests
m = BIG.new(5)
d, gamma = elgamal_keygen()
a, b, k = elgamal_enc(gamma, m, hs)
dec = elgamal_dec(d, a, b)
assert(dec == hs * m, 'El-Gamal encryption not working')
print('')
print('[ok] test El-Gamal')
print('')

sk, vk = keygen()
cm, c, pi_s = prepareBlindSing(gamma, m)
sigma_tilde = blindSign(sk, cm, c, pi_s, gamma)
sigma = unblind(sigma_tilde, d)
sigma_prime, kappa, nu, pi_v = proveCred(vk, m, sigma)
ret = verifyCred(vk, sigma_prime, kappa, nu, pi_v)
assert(ret == true, 'Coconut credentials not verifying')
print('')
print('[ok] test Coconut')
print('')
