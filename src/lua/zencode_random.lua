--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
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
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

-- random operations, mostly on arrays and schemas supported

When("create the random ''", function(dest)
		ZEN.assert(not ACK[dest], "Cannot overwrite existing value: "..dest)
		ACK[dest] = OCTET.random(32) -- TODO: right now hardcoded 256 bit random secrets
end)

function shuffle_array_f(tab)
   -- do not enforce CODEC detection since some schemas are also 1st level arrays
   local count = isarray(tab)
   ZEN.assert( count > 0, "Randomized object is not an array")
   local res = { }
   for i = count,2,-1 do
	  local r = (random_int16() % i)+1
	  table.insert(res,tab[r]) -- limit 16bit lenght for arrays
	  table.remove(tab, r)
   end
   table.insert(res,tab[1])
   return res
end

When("randomize the '' array", function(arr)
		local A = ACK[arr]
		ZEN.assert(A, "Object not found: "..arr)
		-- ZEN.assert(ZEN.CODEC[arr].zentype == 'array', "Object is not an array: "..arr)
		ACK[arr] = shuffle_array_f(A)
end)


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
	-- ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
	-- 		   "Object is not an array: "..arr)
    local count = isarray(A)
    ZEN.assert( count > 0, "Object is not an array: "..arr)
    local r = (random_int16() % count) +1
    ACK.random_object = A[r]
	ZEN.CODEC.random_object = { name = 'random object',
								luatype = 'string',
								encoding = check_codec(arr),
								zentype = 'element' }
end)

