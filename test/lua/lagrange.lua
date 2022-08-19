-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2020 Dyne.org foundation
-- implementation by Alberto Ibrisevich
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


--all integers here are computed modulo the order of the curve ECP.order()

Q = 4 -- quorum
N = 9 -- participants
assert(Q < N)

shares = { }
coeff = { }

--generation of the coefficients of the secret polynomial
for i=1,Q,1 do
    coeff[i] = BIG.random()
end

--generation of the shares
for i=1,N,1 do
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
    for n=2,Q,1 do
        x_n = x_n:modmul(x)                  --x^(n-1)
        y = BIG.add(y, coeff[n]:modmul(x_n))  
        y = BIG.mod(y, ECP.order())   --"+a_(n-1)x^(n-1)"
    end
    table.insert(shares, {x = x, y = y})
end


I.print(shares)

--derivation of the (secret) polynomial from a selection of (at least) Q of the partecipants
--TODO: implement by using a list of selected T shares
--[[ function genpoly(shares){         \\it can be a subset of it
        ...
            ]]--

local sec = BIG.new(0)
local num
local den
for i = 1,Q,1 do 
    num = BIG.new(1)
    if Q % 2 == 0 then
     num = ECP.order() - num 
    end
    den = BIG.new(1)
    for j = 1,Q,1 do
    if j~=i then
        num = num:modmul(shares[j].x)
        den = den:modmul((shares[i].x):modsub(shares[j].x, ECP.order()))
    end
    end
    sec = BIG.add(sec, (shares[i].y):modmul(num:moddiv(den, ECP.order())))   
    sec = BIG.mod(sec, ECP.order()) 
end

print(coeff[1])
print(sec)
assert(coeff[1] == sec)
