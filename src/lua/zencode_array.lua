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
							luatype = 'table',
							zentype = 'array' }
end)

When("create the array of '' random numbers modulo ''", function(s,m)
		ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,math.floor(random_int16() % m))
		end
		ZEN.CODEC.array = { name = dest,
							encoding = 'number',
							luatype = 'table',
							zentype = 'array' }
end)

When("create the aggregation of array ''", function(arr)
		-- TODO: switch typologies, sum numbers and bigs, aggregate hash
		ZEN.assert(not ACK.aggregation, "Cannot overwrite existing object: ".."aggregation")
		local A = ACK[arr]
    ZEN.assert(A, "Object not found: "..arr)
	ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
			   "Object is not an array: "..arr)
    local count = isarray(A)
    ZEN.assert( count > 0, "Object is not an array: "..arr)
    if luatype(A[1]) == 'number' then
       ACK.aggregation = 0
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + tonumber(v)
       end
	   ZEN.CODEC.aggregation =
		  { name = dest,
			encoding = 'number',
			luatype = 'number',
			zentype = 'element' }
	elseif type(A[1]) == 'zenroom.big' then
	   ACK.aggregation = BIG.new(0)
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + v
       end
	   ZEN.CODEC.aggregation =
		  { name = dest,
			encoding = CONF.output.encoding.name,
			luatype = 'string',
			zentype = 'element' }
	elseif type(A[1]) == 'zenroom.ecp' then
	   ACK.aggregation = ECP.generator()
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + v
       end
	   ZEN.CODEC.aggregation =
		  { name = dest,
			encoding = CONF.output.encoding.name,
			luatype = 'string',
			zentype = 'element' }
	elseif type(A[1]) == 'zenroom.ecp2' then
	   ACK.aggregation = ECP2.generator()
       for k,v in next,A,nil do
		  ACK.aggregation = ACK.aggregation + v
       end
	   ZEN.CODEC.aggregation =
		  { name = dest,
			encoding = CONF.output.encoding.name,
			luatype = 'string',
			zentype = 'element' }
    else
       error("Unknown aggregation for type: "..type(A[1]))
    end
end)

When("pick the random object in ''", function(arr)
    local A = ACK[arr]
    ZEN.assert(A, "Object not found: "..arr)
	ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
			   "Object is not an array: "..arr)
    local count = isarray(A)
    ZEN.assert( count > 0, "Object is not an array: "..arr)
    local r = (random_int16() % count) +1
    ACK.random_object = A[r]
	ZEN.CODEC.random_object = { name = 'random object',
								encoding = ZEN.CODEC[arr].encoding,
								luatype = 'string',
								zentype = 'element' }
end)

When("randomize the '' array", function(arr)
    local A = ACK[arr]
    ZEN.assert(A, "Object not found: "..arr)
	ZEN.assert(ZEN.CODEC[arr].zentype == 'array', "Object is not an array: "..arr)
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

local function check_container(name)
   ZEN.assert(ACK[name], "Invalid container, not found: "..name)
   ZEN.assert(luatype(ACK[name]) == 'table', "Invalid container, not a table: "..name)
   ZEN.assert(ZEN.CODEC[name].zentype ~= 'element', "Invalid container: "..name.." is a "..ZEN.CODEC[name].zentype)
end

local function check_element(name)
   local o = ACK[name]
   ZEN.assert(o, "Invalid element, not found: "..name)
   ZEN.assert(iszen(type(o)), "Invalid element, not a zenroom object: "..name)
   ZEN.assert(ZEN.CODEC[name].zentype == 'element', "Invalid element: "..name.." is a "..ZEN.CODEC[name].zentype)
   return o
end

local function _when_remove(ele, from)
		check_container(from)
        local found = false
		local obj = ACK[ele]
		local newdest = { }
        if not obj then -- inline key name (string) requires dictionary
           ZEN.assert(ZEN.CODEC[from].zentype ~= 'dictionary', "Element "..ele.." not found and target "..from.." is not a dictionary")
           ZEN.assert(ACK[from][ele], "Key not found: "..ele.." in dictionary "..from)
           ACK[from][ele] = nil -- remove from dictionary
           found = true
        else
           -- remove value of element from array
           ZEN.assert(ZEN.CODEC[from].zentype == 'array', "Element "..ele.." found and target "..from.." is not an array")
		   check_element(ele)
           local tempp = ACK[from]
           for k,v in next,tempp,nil do
              if not (v == obj) then
                 table.insert(newdest,v)
              else
                 found = true
              end
           end
        end
        ZEN.assert(found, "Element to be removed not found in array")
        ACK[from] = newdest
end
When("remove '' from ''", function(ele,from) _when_remove(ele, from) end)
When("remove the '' from ''", function(ele,from) _when_remove(ele, from) end)

When("insert '' in ''", function(ele, dest)
		ZEN.assert(ACK[dest], "Invalid destination, not found: "..dest)
        ZEN.assert(luatype(ACK[dest]) == 'table', "Invalid destination, not a table: "..dest)
        ZEN.assert(ZEN.CODEC[dest].zentype ~= 'element', "Invalid destination, not a container: "..dest)
        ZEN.assert(ACK[ele], "Invalid insertion, object not found: "..ele)
        ZEN.assert(ZEN.CODEC[ele].zentype == 'element', "Invalid insertion, not an element: "..ele)
        if isarray(ACK[dest]) then
           table.insert(ACK[dest], ACK[ele])
        else
           ACK[dest][ele] = ACK[ele]
        end
        -- ACK[ele] = nil
end)

-- When("insert the '' in ''", function(ele,arr)
--     ZEN.assert(ACK[ele], "Element not found: "..ele)
--     ZEN.assert(ACK[arr], "Array not found: "..arr)
-- 	ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
-- 			   "Object is not an array: "..arr)
--     table.insert(ACK[arr], ACK[ele])
-- end)

-- TODO: 
When("the '' is not found in ''", function(ele, arr)
    ZEN.assert(ACK[ele], "Element not found: "..ele)
    ZEN.assert(ACK[arr], "Array not found: "..arr)
	ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
			   "Object is not an array: "..arr)
    for k,v in next,ACK[arr],nil do
       ZEN.assert(v ~= ACK[ele], "Element '"..ele.."' is contained inside array: "..arr)
    end
end)

When("the '' is found in ''", function(ele, arr)
    ZEN.assert(ACK[ele], "Element not found: "..ele)
    ZEN.assert(ACK[arr], "Array not found: "..arr)
	ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
			   "Object is not an array: "..arr)
    local found = false
    for k,v in next,ACK[arr],nil do
       if v == ACK[ele] then found = true end
    end
    ZEN.assert(found, "Element '"..ele.."' is not found inside array: "..arr)
end)
