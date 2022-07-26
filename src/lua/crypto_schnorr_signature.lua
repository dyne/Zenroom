--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
--Implementation by Alberto Ibrisevic and Denis Roio

--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
--Last modified by Matteo Cristino
--on Thursday, 24th March 2021
--]]

local schnorr = {}

-- prime modulus of the coordinates of ECP and order of the curve
p = ECP.prime()
o = ECP.order()
-- generator of the curve
G = ECP.generator()

-- method for obtaining a valid EC secret key that is chosen at random
function schnorr.keygen()
   local sk, d
   repeat
      sk = OCTET.random(32)
      d = BIG.new(sk)
      if  o <= d then d = BIG.new(0) end --guaranties that the generated keypair is valid
   until (d ~= BIG.new(0))
   return sk
end

-- given a valid secret key, extracts the related public key not encoded (i.e. as the point P=(P:x(), P:y()))
local function pubpoint_gen(sk)
   assert(sk, "no secret key found")
   assert(#sk == 32, 'invalid secret key: length is not of 32B')
   local d = BIG.new(sk)
   assert(d ~= BIG.new(0), 'invalid secret key, is zero')
   assert(d < o, 'invalid secret key, overflow with curve order')
   local P = d*G
   return P
end

-- given a valid secret key, extracts the related encoded public key 
-- @param sk a 32 Byte OCTET, secret key
-- @return a 48 Byte OCTET, public key
function schnorr.pubgen(sk)
   if iszen(type(sk)) then sk = sk:octet() end
   local P = pubpoint_gen(sk)
   local pk = (P:x()):octet():pad(48)
   return pk
end

-- validation of the public key done in two steps:
-- 1.check the point is on the curve
-- 2.check the point is not infinte
-- @param pk a 48 Byte OCTET, public key
-- @return true if the public key is valid, otherwise false
function schnorr.pubcheck(pk)
   if iszen(type(pk)) then pk = pk:octet() end
   local P = ECP.new(BIG.new(pk))
   return ECP.validate(P) and not ECP.isinf(P)
end

-- validation of the private key done in two steps:
-- 1.check the length
-- 2.check that it is grater than 0 and lower than the order of the curve
-- @param sk a 32 Byte OCTET, secret key
-- @return true if the secret key is valid, otherwise false
function schnorr.seccheck(sk)
   if iszen(type(sk)) then sk = sk:octet() end
   local d = BIG.new(sk)
   return (#sk == 32) and (d ~= BIG.new(0)) and (d <= o)
end

-- validation of the signature (sig=(r,s)) done in three steps:
-- 1.check the length of the signature
-- 2.check that r is lower than p
-- 3.check that s is lower than o
-- @param sig a 80 Byte OCTET, signature ('sig=(r,s)')
-- @return true if the signature is valid, otherwise false
function schnorr.sigcheck(sig)
   if sig and (#sig == 80) then
      local r_arr, s_arr = OCTET.chop(sig,48)
      local r = BIG.new(r_arr)
      local s = BIG.new(s_arr)
      return (r <= p) and (s <= o)
   end
   return false
end


-- method for obtaining an hash digest using a (UTF-8) encoded tag name together with the data to process
-- N.B1: By doing this, we make sure hashes used in one context can't be reinterpreted in another one, 
--      in such a way that collisions across contexts can be assumed to be infeasible.
-- N.B2: tag names can be customized at will
local function hash_tag(tag, data)
   local h = sha256(O.str(tag))
   return sha256(h..h..data)
end


-- signing algorithm
-- @param sk a 32 Byte OCTET, secret key
-- @param m an arbitrary long OCTET, message 
-- @return an 80 Byte OCTET, signature '(r,s)'', r is 48 Byte long and s is 32 Byte long
function schnorr.sign(sk, m)
   if iszen(type(sk)) then sk = sk:octet() end
   local d = BIG.new(sk)
   local P = pubpoint_gen(sk)
   --for convention we need that P has even y-coordinate
   --N.B: we don't change the point with the new one, but only store the coefficient d needed to obtain it
   if P:y():parity()  then d = o - d end 
   local k
   repeat 
      local a = OCTET.random(32)
      local h = hash_tag("BIP0340/aux", a)
      local t = OCTET.xor(d:octet(), h)
      local rand = hash_tag("BIP0340/nonce", t..((P:x()):octet())..m)
      k = BIG.new(rand) % o  --maybe it is not needed since o is bigger
   until k ~= BIG.new(0)
   local R = k*G
   
   if R:y():parity() then k = o - k end
   --also here we store only the coefficient k, /wo changing the point R
   local e = BIG.new(hash_tag("BIP0340/challenge", ((R:x()):octet())..((P:x()):octet())..m)) % o
   local r = (R:x()):octet():pad(48) --padding is fundamental, otherwise we could lose non-significant zeros

   local s = BIG.mod(k + e*d, o):octet():pad(32)
   local sig = r..s
   return sig
end


-- verification algortihm
-- @param pk a 48 Byte OCTET, public key
-- @param m an arbitrary long OCTET, message 
-- @param sig an 80 Byte OCTET, signature ('sig=(r,s)')
-- @return true if verification passes, false otherwise
function schnorr.verify(pk, m, sig)
   if iszen(type(pk)) then pk = pk:octet() end
   --the follwing "lifts" pk to an ECP with x = pk and y is even
   local P = ECP.new(BIG.new(pk))    
   assert(P, "lifting failed")
   local r_arr, s_arr = OCTET.chop(sig,48)
   local r = BIG.new(r_arr)
   assert(r <= p, "Verification failed, r overflows p")
   local s = BIG.new(s_arr)
   assert(s <= o, "Verification failed, s overflows o")
   
   local e = BIG.new(hash_tag("BIP0340/challenge", r:octet()..(P:x()):octet()..m)) % o 
   local R = (s*G) - (e*P)     --if the signature is valid the result will be k*G as expected   
   assert(not ECP.isinf(R), "Verification failed, point to infinity")
   assert(not R:y():parity() , "Verification failed, y is odd")
   assert((R:x() == r), "Verification failed")
   return true
end


return schnorr
-- TODO: batch verification
