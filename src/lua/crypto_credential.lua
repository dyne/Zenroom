--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--Written by Denis Roio and Alberto Sonnino
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

-- Zero-Knowledge proof scheme based on Coconut
--
-- Coconut is a selective disclosure credential scheme supporting public
-- and private attributes, re-randomization, and multiple unlinkable
-- selective attribute revelations.

local credential = {}

local G1 = ECP.generator() -- return value
local G2 = ECP2.generator() -- return value

-- local zero-knowledge proof verifications
local function make_pi_s(gamma, commit, k, r, m)
   local wk = INT.random()
   local wm = INT.random()
   local wr = INT.random()
   local Aw = G1 * wk
   local Bw = gamma * wk + commit * wm
   local Cw = G1 * wr + SALT * wm
   local c = ZKP_challenge({commit, Aw, Bw, Cw})
   -- return pi_s
   return {
      commit = c,
      rk = wk - c * k,
      rm = wm - c * m,
      rr = wr - c * r
   }
end

function credential.verify_pi_s(l)
   local Aw = l.sign.a * l.pi_s.commit + G1 * l.pi_s.rk
   local Bw =
      l.sign.b * l.pi_s.commit + l.public * l.pi_s.rk +
      l.commit * l.pi_s.rm
   local Cw =
      l.commit * l.pi_s.commit + G1 * l.pi_s.rr + SALT * l.pi_s.rm
   -- return a bool for assert
   return l.pi_s.commit == ZKP_challenge({l.commit, Aw, Bw, Cw})
end

-- Public Coconut API
function credential.issuer_keygen()
   return {
      x = INT.random(),
      y = INT.random()
   }
end

function credential.aggregate_keys(keys)
   local agg_alpha = keys[1].alpha
   local agg_beta = keys[1].beta
   if #keys > 1 then
      for i = 2, #keys do
         agg_alpha = agg_alpha + keys[i].alpha
         agg_beta = agg_beta + keys[i].beta
      end
   end
   -- return aggkeys
   return {
      alpha = agg_alpha,
      beta = agg_beta
   }
end

function credential.prepare_blind_sign(secret)
   local gamma = G1 * secret
   local m = INT.new(sha256(secret)) % ECP.order()
   -- ElGamal commitment
   local r = INT.random()
   local commit = G1 * r + SALT * m
   local k = INT.random()
   local sign = {
      a = G1 * k,
      b = gamma * k + commit * m
   }
   -- calculate zero knowledge proofs
   local pi_s = make_pi_s(gamma, commit, k, r, m)
   -- return Lambda
   return {
      commit = commit,
      sign = sign,
      pi_s = pi_s,
      public = gamma
   }
end

function credential.blind_sign(sk, Lambda)
   assert(
      credential.verify_pi_s(Lambda),
      'Zero knowledge proof does not verify (Lambda.pi_s)',
      2
   )
   local h = Lambda.commit
   local a_tilde = Lambda.sign.a * sk.y
   local b_tilde = h * sk.x + Lambda.sign.b * sk.y
   -- sigma tilde
   return {
      h = h,
      a_tilde = a_tilde,
      b_tilde = b_tilde
   }
end

function credential.aggregate_creds(sk, sigma_tilde)
   local agg_s = sigma_tilde[1].b_tilde - sigma_tilde[1].a_tilde * sk -- ElGamal verify commitment

   if #sigma_tilde > 1 then
      for i = 2, #sigma_tilde do
         agg_s =
            agg_s + sigma_tilde[i].b_tilde - sigma_tilde[i].a_tilde * sk
      end
   end
   -- aggregated sigma
   return {
      h = sigma_tilde[1].h,
      s = agg_s
   }
end

function credential.prove_cred(verify, sigma, secret)
   local m = INT.new(sha256(secret)) % ECP.order()
   local r = INT.random()
   local r_prime = INT.random()
   local sigma_prime = {
      h_prime = sigma.h * r_prime,
      s_prime = sigma.s * r_prime
   }
   local kappa = verify.alpha + verify.beta * m + G2 * r
   local nu = sigma_prime.h_prime * r
   local wm = INT.random()
   local wr = INT.random()
   local challenge =
      ZKP_challenge(
      {
         verify.alpha,
         verify.beta,
         verify.alpha + G2 * wr + verify.beta * wm, -- Aw
         sigma_prime.h_prime * wr
      }
   ) -- Bw
   -- return Theta
   return {
      kappa = kappa,
      nu = nu,
      sigma_prime = sigma_prime,
      pi_v = {
         c = challenge,
         rr = wr - r * challenge,
         rm = wm - m * challenge
      }
   }
end

function credential.verify_cred(verify, Theta)
   if #verify == 1 then
      verify = verify[1]
   end -- single element in array
   -- verify pi_v
   local Aw =
      Theta.kappa * Theta.pi_v.c + G2 * Theta.pi_v.rr +
      verify.alpha * (BIG.new(1) - Theta.pi_v.c) +
      verify.beta * Theta.pi_v.rm
   local Bw =
      Theta.nu * Theta.pi_v.c +
      Theta.sigma_prime.h_prime * Theta.pi_v.rr
   -- check zero knowledge proof
   assert(
      Theta.pi_v.c == ZKP_challenge({verify.alpha, verify.beta, Aw, Bw}),
      'credential verification: invalid challenge',
      2
   )
   assert(
      not Theta.sigma_prime.h_prime:isinf(),
      'credential verification: invalid signature (infinite sigma)',
      2
   )
   assert(
      ECP2.miller(Theta.kappa, Theta.sigma_prime.h_prime) ==
         ECP2.miller(G2, Theta.sigma_prime.s_prime + Theta.nu),
      'credential verification: invalid signature (miller loop)',
      2
   )
   return true
end

function credential.prove_cred_uid(vk, sigma, secret, uid)
   local m = INT.new(sha256(secret)) % ECP.order()
   local r = INT.random()
   -- material
   local r_prime = INT.random()
   local sigma_prime = {
      h_prime = sigma.h * r_prime,
      s_prime = sigma.s * r_prime
   }
   local kappa = vk.alpha + vk.beta * m + G2 * r
   local nu = sigma_prime.h_prime * r
   local zeta = m * ECP.hashtopoint(uid)
   -- proof --
   -- create the witnessess
   local wm = INT.random()
   local wr = INT.random()
   -- compute the witnessess commitments
   local Aw = vk.alpha + vk.beta * wm + G2 * wr
   local Bw = sigma_prime.h_prime * wr
   local Cw = wm * ECP.hashtopoint(uid)
   -- create the challenge
   local c = ZKP_challenge({vk.alpha, vk.beta, Aw, Bw, Cw})
   -- create responses
   local pi_v = {
      c = c,
      rm = wm - m * c,
      rr = wr - r * c
   }
   local Theta = {
      kappa = kappa,
      nu = nu,
      sigma_prime = sigma_prime,
      pi_v = pi_v
   }
   return Theta, zeta
end

function credential.verify_cred_uid(vk, theta, zeta, uid)
   -- recompute witnessess commitments
   local Aw =
      theta.kappa * theta.pi_v.c + G2 * theta.pi_v.rr +
      vk.alpha * (BIG.new(1) - theta.pi_v.c) +
      vk.beta * theta.pi_v.rm
   local Bw =
      theta.pi_v.rr * theta.sigma_prime.h_prime +
      theta.nu * theta.pi_v.c
   local Cw = theta.pi_v.rm * ECP.hashtopoint(uid) + zeta * theta.pi_v.c
   -- compute the challenge prime
   assert(
      theta.pi_v.c == ZKP_challenge({vk.alpha, vk.beta, Aw, Bw, Cw}),
      'credential verification: invalid challenge for UID',
      2
   )
   -- verify signature --
   assert(
      not theta.sigma_prime.h_prime:isinf(),
      'credential verification: invalid signature (infinite sigma) for UID',
      2
   )
   assert(
      ECP2.miller(theta.kappa, theta.sigma_prime.h_prime) ==
         ECP2.miller(G2, theta.sigma_prime.s_prime + theta.nu),
      'credential verification: invalid signature (miller loop) for UID',
      2
   )
   return true
end

return credential
