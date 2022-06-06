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
   local p = ECDH.prime()
   local e = BIG.shr(p + INT.new(1), 2) -- e = (p+1)/4

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
   local o = ECDH.order()
   local sig, y, sig_s
   sig, y = ECDH.sign_hashed(sk, data, #data)

   sig_s = INT.new(sig.s)
   if sig_s > INT.shr(o, 1) then
      sig_s = INT.modsub(o, sig_s, o)
      sig.s = sig_s:octet():pad(32)
      y = not y
   end
   return sig, y
end

-- Compute the compressed public key (pubc) from the secret key
function ecdh.sk_to_pubc(sk)
   if not #sk == 32 then
      error("Invalid ecdh private key size: "..#sk) end
   return( ECDH.compress_public_key( ECDH.pubgen(sk) ) )
end

return ecdh
