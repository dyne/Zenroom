--[[
-- This file is part of zenroom
--
-- Copyright (C) 2020-2026 Dyne.org foundation
-- BIP-340 secp256k1 Schnorr implementation
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
--]]

-- BIP-340 Schnorr signatures over secp256k1.
-- Uses SECP point arithmetic and native scalar helpers.
--
-- Sizes: secret key = 32B, x-only public key = 32B, signature = 64B (r||s)

local schnorr = {}
local S = SECP
local G = S.G()
local zero32 = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000000")
local one32  = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000001")

local function fail(message)
   error(message, 2)
end

-- Internal: compute BIP-340 public key point from secret key OCTET.
-- Returns P (SECP point with even y) and d' (possibly negated secret key OCTET).
local function pubpoint_from_sk(sk)
   local d = sk
   local P = G * d
   -- BIP-340: public key must have even y
   -- Check if P has even y via compressed prefix
   local even_y = P:compressed():hex():sub(1,2) == "02"
   if not even_y then
      d = S.bip340_scalar_negate(d)
      P = G * d
   end
   return P, d
end

-- BIP-340 key generation: random 32-byte secret key
function schnorr.keygen()
   local sk
   repeat
      sk = OCTET.random(32)
   until S.bip340_seckey_valid(sk)
   return sk
end

-- BIP-340 public key derivation: returns 32-byte x-only public key
function schnorr.pubgen(sk)
   if iszen(type(sk)) then sk = sk:octet() end
   if #sk ~= 32 then fail("secret key must be 32 bytes") end
   if not S.bip340_seckey_valid(sk) then
      fail("invalid secret key for pubgen")
   end
   local P, _ = pubpoint_from_sk(sk)
   return P:xonly()
end

-- BIP-340 public key validation: x-only value is on curve
function schnorr.pubcheck(pk)
   if iszen(type(pk)) then pk = pk:octet() end
   if #pk ~= 32 then return false end
   local ok, P = pcall(function() return S.bip340_lift_x(pk) end)
   return ok and P ~= nil
end

-- BIP-340 secret key validation: 32 bytes, 1 <= d < n
function schnorr.seccheck(sk)
   if iszen(type(sk)) then sk = sk:octet() end
   return S.bip340_seckey_valid(sk)
end

-- BIP-340 signature validation: 64 bytes
function schnorr.sigcheck(sig)
   if iszen(type(sig)) then sig = sig:octet() end
   return sig and #sig == 64
end

-- BIP-340 signing: returns 64-byte signature (r || s)
-- sk: 32-byte secret key OCTET
-- m:  message OCTET
-- aux_rand: optional 32-byte auxiliary randomness (default: zeros)
function schnorr.sign(sk, m, aux_rand)
   if iszen(type(sk)) then sk = sk:octet() end
   if iszen(type(m)) then m = m:octet() end

   if #sk ~= 32 then fail("secret key must be 32 bytes") end
   if not S.bip340_seckey_valid(sk) then
      fail("invalid secret key")
   end

   -- Default aux_rand to 32 zero bytes
   if not aux_rand then
      aux_rand = zero32
   elseif iszen(type(aux_rand)) then
      aux_rand = aux_rand:octet()
   end

   -- Get the internal (possibly negated) secret key and public key
   local P, d = pubpoint_from_sk(sk)
   local px = P:xonly()

   -- BIP-340 step: t = d XOR tagged_hash("BIP0340/aux", aux_rand)
   local t = S.bip340_tagged_hash("BIP0340/aux", aux_rand)
   t = OCTET.xor(d, t)

   -- rand = tagged_hash("BIP0340/nonce", t || px || m)
   local k
   repeat
      local nonce_input = t .. px .. m
      k = S.bip340_tagged_hash("BIP0340/nonce", nonce_input)
   until k:hex() ~= zero32:hex()

   -- R = k * G; ensure R has even y (negate k if not)
   local R = G * k
   local even_y = R:compressed():hex():sub(1,2) == "02"
   if not even_y then
      k = S.bip340_scalar_negate(k)
      R = G * k  -- re-compute (or we could use R:negative())
   end

   local rx = R:xonly()

   -- e = tagged_hash("BIP0340/challenge", rx || px || m) mod n
   local e_hash = S.bip340_tagged_hash("BIP0340/challenge", rx .. px .. m)
   local e = S.bip340_challenge_reduce(e_hash)

   -- s = k + e*d mod n
   local ed = S.bip340_scalar_mul(e, d)
   local s = S.bip340_scalar_add(k, ed)

   return rx .. s
end

-- BIP-340 verification: pk (32B), m (message OCTET), sig (64B)
function schnorr.verify(pk, m, sig)
   if iszen(type(pk)) then pk = pk:octet() end
   if iszen(type(m)) then m = m:octet() end
   if iszen(type(sig)) then sig = sig:octet() end

   if #sig ~= 64 then
      warn("schnorr.verify: signature must be 64 bytes")
      return false
   end

   -- Parse r (first 32 bytes), s (last 32 bytes)
   -- Avoid OCTET.chop which can truncate; manually extract
   local r_oct = OCTET.from_hex(sig:hex():sub(1,64))
   local s_oct = OCTET.from_hex(sig:hex():sub(65,128))

   -- Check r < p: r must be a valid x-coordinate on the curve.
   -- Per BIP-340, the x-only point for r is not explicitly lifted,
   -- but r must be the x-coordinate of a point (no parity check).
   -- We check r < p by ensuring SECP.bip340_lift_x(r) succeeds.
   local ok, Rp = pcall(function() return S.bip340_lift_x(r_oct) end)
   if not ok or not Rp then
      warn("schnorr.verify: r is not a valid x coordinate")
      return false
   end

   -- Check s < n: reject s >= n (but s = 0 is valid)
   if not S.bip340_seckey_valid(s_oct) and s_oct:hex() ~= "0000000000000000000000000000000000000000000000000000000000000000" then
      warn("schnorr.verify: s >= n")
      return false
   end

   -- Lift public key
   local P
   local ok_pk, P = pcall(function() return S.bip340_lift_x(pk) end)
   if not ok_pk or not P then
      warn("schnorr.verify: public key not on curve")
      return false
   end

   -- e = tagged_hash("BIP0340/challenge", r || pk || m) mod n
   local e_hash = S.bip340_tagged_hash("BIP0340/challenge", r_oct .. pk .. m)
   local e = S.bip340_challenge_reduce(e_hash)

   -- R = s*G - e*P
   local sG = G * s_oct
   local eP = P * e
   local R = sG - eP

   if R:isinf() then
      warn("schnorr.verify: R is infinity")
      return false
   end

   -- R must have even y
   if R:compressed():hex():sub(1,2) ~= "02" then
      warn("schnorr.verify: R has odd y")
      return false
   end

   -- x(R) must equal r
   if R:xonly():hex() ~= r_oct:hex() then
      warn("schnorr.verify: x(R) != r")
      return false
   end

   return true
end

return schnorr
