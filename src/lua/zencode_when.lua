-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
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


--- WHEN

When("I append '' to ''", function(content, dest)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ACK[dest] .. ZEN:import(content)
end)
When("I append '' to '' formatted as ''", function(content, dest, format)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ACK[dest] .. ZEN:import(format..":"..content) -- add prefix
end)

-- hardcoded import encoding from_string
When("I write '' in ''", function(content, dest)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ZEN:import(content, O.from_string)
end)
When("I set '' to ''", function(dest, content)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ZEN:import(content, O.from_string)
end)
When("I set '' to '' formatted as ''", function(dest, content, format)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ZEN:import(content, input_encoding(format).fun)
end)
When("I set '' to '' as ''", function(dest, content, format)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ZEN:import(content, input_encoding(format).fun)
end)
When("I create a random ''", function(s)
		ZEN.assert(not ZEN.schemas[s], "When denied, schema collision detected: "..s)
		ACK[s] = OCTET.random(64) -- TODO: right now hardcoded 256 bit random secrets
end)

-- generic comparison using overloaded __eq on any value
When("I verify '' is equal to ''", function(l,r)
		ZEN.assert(ACK[l] == ACK[r],
				   "When comparison failed: objects are not equal: "
					  ..l.." == "..r)
end)

-- hashing single strings
When("I create the hash of ''", function(s)
		local src = ACK[s]
		ZEN.assert(src, "Object not found: "..s)
		ACK.hash = sha256(src)
end)

When("I create the hash of '' using ''", function(s,h)
		local src = ACK[s]
		ZEN.assert(src, "Object not found: "..s)
		if strcasecmp(h,'sha256') then		   
		   ACK.hash = sha256(src)
		elseif strcasecmp(h,'sha512') then
		   ACK.hash = sha512(src)
		end
		ZEN.assert(ACK.hash, "Invalid hash: "..h)
end)

-- numericals
When("I set '' to '' base ''", function(dest, content, base)
		ZEN.assert(not ACK[dest], "When denied, schema collision detected: "..dest)
		local bas = tonumber(base)
		ZEN.assert(bas, "Invalid numerical conversion for base: "..base)
		local num = tonumber(content,bas)
		ZEN.assert(num, "Invalid numerical conversion for value: "..content)
		ACK[dest] = num
end)

local function numcheck(left, right)
   local al = ACK[left]
   ZEN.assert(al, "Object not found for left argument: "..left)
   if type(al) == "zenroom.octet" then al = BIG.new(al):integer() end
   local l = tonumber(al)
   ZEN.assert(l, "Invalid numerical in left argument: "..type(al))
   local ar = ACK[right]
   ZEN.assert(ar, "Object not found for right argument: "..right)
   if type(ar) == "zenroom.octet" then ar = BIG.new(ar):integer() end
   local r = tonumber(ar)
   ZEN.assert(r, "Invalid numerical in right argument: "..type(ar))
   return l, r
end
When("number '' is less than ''", function(left, right)
		local l, r = numcheck(left, right)
		ZEN.assert(l < r, "Failed comparison: "..l.." is not less than "..r)
end)
When("number '' is less or equal than ''", function(left, right)
		local l, r = numcheck(left, right)
		ZEN.assert(l <= r, "Failed comparison: "..l.." is not less than "..r)
end)
When("number '' is more than ''", function(left, right)
		local l, r = numcheck(left, right)
		ZEN.assert(l > r, "Failed comparison: "..l.." is not less than "..r)
end)
When("number '' is more or equal than ''", function(left, right)
		local l, r = numcheck(left, right)
		ZEN.assert(l >= r, "Failed comparison: "..l.." is not less than "..r)
end)

-- array operations
When("I create the array of '' random objects", function(s)
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,OCTET.random(64))
		end
end)

When("I create the array of '' random objects of '' bits", function(s, bits)
		ACK.array = { }
		local bytes = math.ceil(bits/8)
		for i = s,1,-1 do
		   table.insert(ACK.array,OCTET.random(bytes))
		end
end)

When("I create the array of '' random curve points", function(s)
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,ECP.random())
		end
end)


When("I create the aggregation of ''", function(arr)
		local A = ACK[arr]
		ZEN.assert(A, "Object not found: "..arr)
		local count = isarray(A)
		ZEN.assert( count > 0, "Object is not an array: "..arr)
		if type(A[1]) == 'zenroom.ecp' then -- TODO: check all elements
		   xxx(3, "Computing sum of "..count.." ECP") 
		   ACK.aggregation = ECP.generator()
		   for k,v in next,A,nil do
			  if not ACK.aggregation then ACK.aggregation = v
			  else ACK.aggregation = ACK.aggregation + v end
		   end
		else -- TODO: more aggregators for INT and ECP2
		   error("Unknown aggregation for type: "..type(A[1]))
		end
end)

When("I create the hash to point '' of each object in ''", function(what, arr)
		local F = _G[what]
		ZEN.assert(luatype(F.hashtopoint) == 'function',
				   "Hash type "..what.." is invalid (no hashtopoint)")
        local A = ACK[arr]
        ZEN.assert(A, "Object not found: "..arr)
        local count = isarray(A)
        ZEN.assert( count > 0, "Object is not an array: "..arr)
        ACK.hashes = { }
        for k,v in sort_ipairs(A) do
		   ACK.hashes[k] = F.hashtopoint(v)
        end
end)

When("I rename the '' to ''", function(old,new)
		ZEN.assert(ACK[old], "Object not found: "..old)
		ACK[new] = ACK[old]
		ACK[old] = nil
end)

When("I pick the random object in ''", function(arr)
		local A = ACK[arr]
		ZEN.assert(A, "Object not found: "..arr)
		local count = isarray(A)
		ZEN.assert( count > 0, "Object is not an array: "..arr)
		local r = random_int16() % count
		ACK.random_object = A[r]
end)

When("I remove the '' from ''", function(ele,arr)
		local E = ACK[ele]
		ZEN.assert(E, "Element not found: "..ele)
		local A = ACK[arr]
		ZEN.assert(A, "Array not found: "..arr)
		ZEN.assert( isarray(A) > 0, "Object is not an array: "..arr)
		local O = { }
		for k,v in next,A,nil do
		   if v ~= E then table.insert(O,v) end
		end
		ACK[arr] = O
end)

When("I insert the '' in ''", function(ele,arr)
		ZEN.assert(ACK[ele], "Element not found: "..ele)
		ZEN.assert(ACK[arr], "Array not found: "..arr)
		table.insert(ACK[arr], ACK[ele])
end)

When("the '' is not found in ''", function(ele, arr)
		ZEN.assert(ACK[ele], "Element not found: "..ele)
		ZEN.assert(ACK[arr], "Array not found: "..arr)
		for k,v in next,ACK[arr],nil do
		   ZEN.assert(v ~= ACK[ele], "Element '"..ele.."' is contained inside array: "..arr)
		end
end)


When("the '' is found in ''", function(ele, arr)
		ZEN.assert(ACK[ele], "Element not found: "..ele)
		ZEN.assert(ACK[arr], "Array not found: "..arr)
		local found = false
		for k,v in next,ACK[arr],nil do
		   if v == ACK[ele] then found = true end
		end
		ZEN.assert(found, "Element '"..ele.."' is not found inside array: "..arr)
end)


-- TODO:
-- When("I set '' as '' with ''", function(dest, format, content) end)
-- When("I append '' as '' to ''", function(content, format, dest) end)
-- When("I write '' as '' in ''", function(content, dest) end)
-- implicit conversion as string
