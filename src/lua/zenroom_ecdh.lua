--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
--designed, written and maintained by Alberto Lerda and Denis Roio
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

local ecdh = require'ecdh'

function ecdh.compress_public_key(public)
   local x, y = ECDH.pubxy(public)
   local pfx = fif( BIG.parity(BIG.new(y) ), OCTET.from_hex('03'), OCTET.from_hex('02') )
   local pk = pfx .. x
   return pk
end

function ecdh.uncompress_public_key(public)
   local p = BIG.new(O.from_hex('fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f'))
   local e = BIG.new(O.from_hex('3fffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffff0c'))

   local parity = public:sub(1,1)
   assert(parity == O.from_hex('02') or parity == O.from_hex('03'))
   local x = BIG.new(public:sub(2, #public))
   -- y*y = x*x*x + 7
   local rhs = BIG.mod(BIG.modmul(BIG.modmul(x,x,p),x,p)+BIG.new(7),p)
   local sqrt_rhs = rhs:modpower(e, p)
   assert(BIG.modmul(sqrt_rhs,sqrt_rhs, p) == rhs)
   if sqrt_rhs:parity() ~= (parity == O.from_hex('03')) then -- this is a xor
      sqrt_rhs = sqrt_rhs:modneg(p)
   end
   return O.from_hex('04') .. x .. sqrt_rhs
end

-- it is similar to sign eth, s < order/2
function ecdh.sign_ecdh(sk, data)
   local halfSecp256k1n = INT.new(hex('7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0'))
   local sig
   sig = nil
   repeat
      -- TODO: improve number generation
      k = BIG.modrand(INT.new(2)*halfSecp256k1n):octet()
      sig = ECDH.sign_hashed(sk, data, #data, k)
   until(INT.new(sig.s) < halfSecp256k1n);
   
   return sig, k
end

-- Compute the compressed public key (pubc) from the secret key
function ecdh.sk_to_pubc(sk)
   if not #sk == 32 then
      error("Invalid ecdh private key size: "..#sk) end
   return( ECDH.compress_public_key( ECDH.pubgen(sk) ) )
end

return ecdh
