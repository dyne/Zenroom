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
--on Saturday, 27th November 2021
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

-- random and hashing operations
When("create the random object of '' bits", function(n)
	empty'random object'
	local bits = tonumber(n)
	ZEN.assert(bits, 'Invalid number of bits: ' .. n)
	ACK.random_object = OCTET.random(math.ceil(bits / 8))
	new_codec('random_object', { zentype = 'element' })
end
)
When("create the random object of '' bytes",function(n)
	empty'random object'
	local bytes = math.ceil(tonumber(n))
	ZEN.assert(bytes, 'Invalid number of bytes: ' .. n)
	ACK.random_object = OCTET.random(bytes)
	new_codec('random_object', { zentype = 'element' })
end
)

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
		new_codec('array', { luatype = 'table', zentype = 'array'})
end)

When("create the array of '' random objects of '' bits", function(s, b)
	empty'array'
	ACK.array = { }
	local q = tonumber(s)
	ZEN.assert(q, "Argument is not a number: "..s)
	local bits = tonumber(b)
	local bytes = math.ceil(bits/8)
	for i = q,1,-1 do
	   table.insert(ACK.array,OCTET.random(bytes))
	end
	new_codec('array', { luatype = 'table', zentype = 'array'})
end)

When("create the array of '' random objects of '' bytes", function(s, b)
	empty'array'
	ACK.array = { }
	local q = tonumber(s)
	ZEN.assert(q, "Argument is not a number: "..s)
	local bytes = math.ceil(tonumber(b))
	for i = q,1,-1 do
	   table.insert(ACK.array,OCTET.random(bytes))
	end
	new_codec('array', { luatype = 'table', zentype = 'array'})
end)

When("create the array of '' random numbers", function(s)
	ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
	ACK.array = { }
	for i = s,1,-1 do
		table.insert(ACK.array,tonumber(random_int16()))
	end
	new_codec('array', { luatype = 'table',	zentype = 'array', encoding = 'number' })
end)

When("create the array of '' random numbers modulo ''", function(s,m)
	ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
	ACK.array = { }
	for i = s,1,-1 do
		table.insert(ACK.array,math.floor(random_int16() % m))
	end
	new_codec('array', { luatype = 'table',	zentype = 'array', encoding = 'number' })
end)

When("pick the random object in ''", function(arr)
    local A = have(arr)
    empty'random object'
    ZEN.assert(luatype(A) == 'table', "Object is not a table: "..arr)
    local tmp = { }
    for _,v in pairs(A) do
       table.insert(tmp, v)
    end
    local r = (random_int16() % #tmp) +1
    ACK.random_object = tmp[r]
	new_codec('random_object', {zentype='element', schema=nil}, arr)
end)

