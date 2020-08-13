-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2020 Dyne.org foundation
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

-- array operations

When("create the array of '' random objects", function(s)
		ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,OCTET.random(64))
		end
		ZEN.CODEC.array = { name = dest,
							encoding = CONF.output.encoding.name,
							luatype = 'table',
							zentype = 'array' }
end)

When("create the array of '' random objects of '' bits", function(s, bits)
		ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
		ACK.array = { }
		local bytes = math.ceil(bits/8)
		for i = s,1,-1 do
		   table.insert(ACK.array,OCTET.random(bytes))
		end
		ZEN.CODEC.array = { name = dest,
							encoding = CONF.output.encoding.name,
							luatype = 'table',
							zentype = 'array' }
end)

When("create the array of '' random numbers", function(s)
		ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,tonumber(random_int16()))
		end
		ZEN.CODEC.array = { name = dest,
							encoding = 'number',
							luatype = 'number',
							zentype = 'element' }
end)

When("create the array of '' random numbers modulo ''", function(s,m)
		ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,math.floor(random_int16() % m))
		end
		ZEN.CODEC.array = { name = dest,
							encoding = 'number',
							luatype = 'number',
							zentype = 'element' }
end)

When("create the aggregation of array ''", function(arr)
		-- TODO: switch typologies, sum numbers and bigs, aggregate hash
		ZEN.assert(not ACK.aggregation, "Cannot overwrite existing object: ".."aggregation")
    local A = ACK[arr]
    ZEN.assert(A, "Object not found: "..arr)
    local count = isarray(A)
    ZEN.assert( count > 0, "Object is not an array: "..arr)
    if luatype(A[1]) == 'number' then -- TODO: check all elements
       ACK.aggregation = 0
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + tonumber(v)
       end
	elseif type(A[1]) == 'zenroom.big' then
	   ACK.aggregation = BIG.new(0)
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + v
       end
	elseif type(A[1]) == 'zenroom.ecp' then
	   ACK.aggregation = ECP.generator()
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + v
       end
	elseif type(A[1]) == 'zenroom.ecp2' then
	   ACK.aggregation = ECP2.generator()
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + v
       end
    else -- TODO: more aggregators for INT and ECP2
       error("Unknown aggregation for type: "..type(A[1]))
    end
	ZEN.CODEC.aggregation = { name = dest,
							  encoding = 'number',
							  luatype = 'number',
							  zentype = 'element' }
end)

When("pick the random object in ''", function(arr)
    local A = ACK[arr]
    ZEN.assert(A, "Object not found: "..arr)
    local count = isarray(A)
    ZEN.assert( count > 0, "Object is not an array: "..arr)
    local r = (random_int16() % count) +1
    ACK.random_object = A[r]
	ZEN.CODEC.random_object = ZEN.CODEC[arr]
end)

When("randomize the '' array", function(arr)
    local A = ACK[arr]
    ZEN.assert(A, "Object not found: "..arr)
    local count = isarray(A)
    ZEN.assert( count > 0, "Object is not an array: "..arr)
    local res = { }
    for i = count,2,-1 do
       local r = (random_int16() % (i-1))+1
       table.insert(res,A[r]) -- limit 16bit lenght for arrays
       table.remove(A, r)
    end
    table.insert(res,A[1])
    ACK[arr] = res
end)

When("remove the '' from ''", function(ele,arr)
    local E = ACK[ele]
    ZEN.assert(E, "Element not found: "..ele)
    local A = ACK[arr]
    ZEN.assert(A, "Array not found: "..arr)
    ZEN.assert( isarray(A) > 0, "Object is not an array: "..arr)
    local O = { }
	local found = false
    for k,v in next,A,nil do
       if not (v == E) then
		  table.insert(O,v)
	   else
		  found = true
	   end
    end
	ZEN.assert(found, "Element to be removed not found in array")
    ACK[arr] = O
end)

When("insert the '' in ''", function(ele,arr)
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
