--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
-- Implementation by Alberto Ibrisevich and Denis Roio
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
--Last modified by Alberto Lerda
--on Tuesday, 04th October 2021
--]]


local li = {
   _VERSION = 'crypto_lagrange_interpolation.lua 1.0',
   _URL = 'https://zenroom.dyne.org',
   _DESCRIPTION = 'Secret Sharing based on BIG INT using Lagrange Interpolation over 1st order elliptic curves",Attribute-based credential system supporting multiple unlinkable private attribute revelations',
   _LICENSE = [[
Licensed under the terms of the GNU Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.  Unless required by applicable
law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.
]]
}

-- the biggest prime less than 2^(32*8)
-- computed with
-- i:=2^(32*8);
-- while i ge 2^(31*8) do
--     if IsPrime(i) then
--         print(i);
--         break;
--     end if;
--     i:=i-1;
-- end while;

-- at http://magma.maths.usyd.edu.au/calc/

-- 115792089237316195423570985008687907853269984665640564039457584007913129639747


octP = O.from_hex('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43')
P = BIG.new(octP)
assert(P:octet() == octP)

function li.create_shared_secret(total, quorum, secret)
   if quorum >= total then
      error('Error calling create_shared_secret: quorum ('..quorum..') must be smaller than total ('..total..')', 2)
   end
   -- check that BIG can contain the whole secret, depends from curve's size and the choosen prime P
   local secbig = BIG.new(secret)
   if secbig:octet() ~= secret or secbig > P then
      error('Secret exceeds maximum BIG size: '..#O..' bytes or the size of the choosen prime')
   end
   secbig = secbig % P
   -- generation of the coefficients of the secret polynomial
   local coeff = { }
   -- take last argument or create random
   if secret then coeff[1] = BIG.new(secret)
   else coeff[1] = BIG.modrand(P) end
   for i=2,quorum,1 do
      coeff[i] = BIG.modrand(P)
   end
   --generation of the shares
   local shares = { }
   for i=1,total,1 do
      local x
      repeat
	 x = BIG.modrand(P)
	 if x ~=0 then
	    --checking for duplicates in shares
	    for _, k in pairs(shares) do
	       if x == k then x = 0 end
	    end
	 end
      until x ~= 0	--this part provides trivial unleakability: x coordinate is never zero

      local y = coeff[1]     --a_0
      local x_n = BIG.new(1)
      for n=2,quorum,1 do
	 x_n = x_n:modmul(x, P) -- x^(n-1)
	 y = BIG.add(y, coeff[n]:modmul(x_n, P))
	 y = BIG.mod(y, P) -- +a_(n-1)x^(n-1)
      end
      table.insert(shares, {x = x, y = y})
   end -- for i,total
   -- overwrite secret for secure disposal
   return shares, coeff[1]
end

function li.compose_shared_secret(shares)
   local sec = BIG.new(0)
   local num
   local den
   local quorum = #shares
   for i = 1,quorum,1 do
      num = BIG.new(1)
      if quorum % 2 == 0 then
	 num = P - num
      end
      den = BIG.new(1)
      for j = 1,quorum,1 do
	 if j~=i then
	    num = num:modmul(shares[j].x, P)
	    den = den:modmul((shares[i].x):modsub(shares[j].x, P), P)
	 end
      end
      sec = BIG.add(sec, (shares[i].y):modmul(num:moddiv(den, P), P))
      sec = BIG.mod(sec, P)
   end
   return sec
end

return li
