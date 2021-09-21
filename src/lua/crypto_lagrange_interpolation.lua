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
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
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

local G1 = ECP.generator() -- return value
local O  = ECP.order() -- return value

function li.create_shared_secret(total, quorum, secret)
   if quorum >= total then
	 error('Error calling create_shared_secret: quorum ('..quorum..') must be smaller than total ('..total..')', 2)
   end
   -- check that BIG can contain the whole secret, depends from curve's size
   local secbig = BIG.new(secret) % O
   if secbig:octet() ~= secret then
      error('Secret exceeds maximum BIG size: '..#O..' bytes')
   end
   -- generation of the coefficients of the secret polynomial
   local coeff = { }
   -- take last argument or create random
   if secret then coeff[1] = BIG.new(secret)
   else coeff[1] = BIG.random() end
   for i=2,quorum,1 do
	  coeff[i] = BIG.random()
   end
   --generation of the shares
   local shares = { }
   for i=1,total,1 do
	  local x
	  repeat	
	  	 x = BIG.random()
		 if x ~=0 then
			--checking for duplicates in shares
			for k in pairs(shares) do
			   if x == k then x = 0 end
			end
		 end
	  until x ~= 0	--this part provides trivial unleakability: x coordinate is never zero
	  
	  local y = coeff[1]     --a_0
	  local x_n = BIG.new(1)
	  for n=2,quorum,1 do
		 x_n = x_n:modmul(x) -- x^(n-1)
		 y = BIG.add(y, coeff[n]:modmul(x_n))
		 y = BIG.mod(y, O) -- +a_(n-1)x^(n-1)
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
    	num = O - num	end
	  den = BIG.new(1)
	  for j = 1,quorum,1 do
		 if j~=i then
			num = num:modmul(shares[j].x)
			den = den:modmul((shares[i].x):modsub(shares[j].x, O))
		 end
	  end
	  sec = BIG.add(sec, (shares[i].y):modmul(num:moddiv(den, O)))
	  sec = BIG.mod(sec, O)
   end
   return sec
end

return li
