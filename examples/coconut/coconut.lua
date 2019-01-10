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
random = RNG.new()
g1 = ECP.generator()
g2 = ECP2.generator()

challenge = OCTET.serialize({ g1, g2, hs })
-- proofs
function to_challenge(list)
   return INT.new( sha256( challenge .. OCTET.serialize( list ) ) )
end

function hashtopoint(m) return ECP.mapit( sha512( m ) ) end
hs = hashtopoint(str("anystring"))

o = ECP.order()

function rand() return INT.new(random,o) end

-- El-Gamal cryptosystem
function elgamal_keygen()
   local d = rand()
   local gamma = d * g1

   return d, gamma
end

function elgamal_enc(gamma, m, h)
   local k = rand()
   local a = k * g1
   local b = gamma * k + h * m
   return a, b, k
end

function elgamal_dec(d, a, b)
   return b - a * d
end


-- Coconut
function keygen()
   local x = rand()
   local y = rand()
   local sk = { x = x,
            y = y  }
   local vk = { g2 = g2,
            alpha = g2 * x,
            beta  = g2 * y  }

   return sk, vk
end

function aggKey(keys)
  local agg_alpha = keys[1].alpha
  local agg_beta  = keys[1].beta
  for i = 2, #keys do
     agg_alpha = agg_alpha + keys[i].alpha
     agg_beta  = agg_beta  + keys[i].beta
  end

   return {g2 = g2, alpha = agg_alpha, beta = agg_beta}
end

function prepareBlindSign(gamma, m)
   local r = rand()
   local cm = g1 * r + hs * m
   local h = hashtopoint(cm)
   local a, b, k = elgamal_enc(gamma, m, h)
   local c = {a = a, b = b}
   local pi_s = make_pi_s(gamma, cm, k, r, m)
   local Lambda = { cm = cm, c = c, pi_s = pi_s }
   return Lambda
end

function blindSign(sk, gamma, Lambda)
   local ret = verify_pi_s(gamma, Lambda.c, Lambda.cm, Lambda.pi_s)
   assert(ret == true, 'Proof pi_s does not verify') -- verify zero knowledge proof
   local h = hashtopoint(Lambda.cm)
   local a_tilde = Lambda.c.a * sk.y
   local b_tilde = h * sk.x + Lambda.c.b * sk.y
   return { h = h,
         a_tilde = a_tilde,
         b_tilde = b_tilde  }
end

function unblind(sigma_tilde, d)
   local s = elgamal_dec(d, sigma_tilde.a_tilde, sigma_tilde.b_tilde)
   return { h = sigma_tilde.h,
         s = s }
end

function aggCred(sigmas)
   local agg_s = sigmas[1].s
   for i = 2, #sigmas do
     agg_s = agg_s + sigmas[i].s
   end

   return {h = sigmas[1].h, s = agg_s}
end

function proveCred(vk, sigma, m)
   local r = rand()
   local r_prime = rand()
   local sigma_prime = { h_prime = sigma.h * r_prime, 
         s_prime = sigma.s * r_prime  }
   local kappa = vk.alpha + vk.beta * m + vk.g2 * r
   local nu = sigma_prime.h_prime * r
   local pi_v = make_pi_v(vk, sigma_prime, m, r)
   local Theta = {kappa = kappa, nu = nu, sigma_prime = sigma_prime, pi_v = pi_v}
   return Theta
end

function verifyCred(vk, Theta)
   local ret = verify_pi_v(vk, Theta.kappa, Theta.nu, Theta.sigma_prime, Theta.pi_v)
   assert(ret == true, 'Proof pi_v does not verify') -- verify zero knowledge proof
   local ret1 = not Theta.sigma_prime.h_prime:isinf()
   local ret2 = ECP2.miller(Theta.kappa, Theta.sigma_prime.h_prime)
     == ECP2.miller(vk.g2, Theta.sigma_prime.s_prime + Theta.nu)
   return ret1 and ret2
end


function make_pi_s(gamma, cm, k, r, m)
   local h = hashtopoint(cm)
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

function verify_pi_s(gamma, ciphertext, cm, proof)
   local h = hashtopoint(cm)
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


function make_pi_v(vk, sigma_prime, m, r)
   local wm = rand()
   local wr = rand()
   local Aw = g2 * wr + vk.alpha + vk.beta * wm
   local Bw = sigma_prime.h_prime * wr
   local c = to_challenge({ vk.alpha, vk.beta, Aw, Bw })
   local rm = wm:modsub(m * c, o)
   local rr = wr:modsub(r * c, o)
   return { c = c, rm = rm, rr = rr }
end

function verify_pi_v(vk, kappa, nu, sigma_prime, proof)
   local c = proof.c
   local rm = proof.rm
   local rr = proof.rr
   local Aw = kappa * c + g2 * rr + vk.alpha * INT.new(1):modsub(c,o) + vk.beta * rm
   local Bw = nu * c + sigma_prime.h_prime * rr
   return c == to_challenge({ vk.alpha, vk.beta, Aw, Bw })
end



-- tests
m = INT.new(sha256(str("Some sort of secret")))
d, gamma = elgamal_keygen()
a, b, k = elgamal_enc(gamma, m, hs)
dec = elgamal_dec(d, a, b)
assert(dec == hs * m, 'El-Gamal encryption not working')
print('')
print('[ok] test El-Gamal')
print('')

sk, vk = keygen()
Lambda = prepareBlindSign(gamma, m)
sigma_tilde = blindSign(sk, gamma, Lambda)
sigma = unblind(sigma_tilde, d)
Theta = proveCred(vk, sigma, m)
ret = verifyCred(vk, Theta)
assert(ret == true, 'Coconut credentials not verifying')
print('')
print('[ok] test Coconut')
print('')

sk1, vk1 = keygen()
sk2, vk2 = keygen()
---sk3, vk3 = keygen()
agg_vk = aggKey({vk1, vk2, vk3})
Lambda = prepareBlindSign(gamma, m)
sigma_tilde1 = blindSign(sk1, gamma, Lambda)
sigma_tilde2 = blindSign(sk2, gamma, Lambda)
---sigma_tilde3 = blindSign(sk3, gamma, Lambda)
sigma1 = unblind(sigma_tilde1, d)
sigma2 = unblind(sigma_tilde2, d)
---sigma3 = unblind(sigma_tilde3, d)
agg_sigma = aggCred({sigma1, sigma2})
Theta = proveCred(agg_vk, agg_sigma, m)
ret = verifyCred(agg_vk, Theta)
assert(ret == true, 'Coconut credentials not verifying')
print('')
print('[ok] test multi-authority Coconut')
print('')
