--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2022 Dyne.org foundation
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
                new_codec(dest, { zentype = 'element' })
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
		table.insert(ACK.array,F.new(random_int16()))
	end
	new_codec('array', { luatype = 'table',	zentype = 'array', encoding = 'number' })
end)

When("create the array of '' random numbers modulo ''", function(s,m)
	ZEN.assert(not ACK.array, "Cannot overwrite existing object: ".."array")
	ACK.array = { }
	for i = s,1,-1 do
		table.insert(ACK.array,F.new(math.floor(random_int16() % m)))
	end
	new_codec('array', { luatype = 'table',	zentype = 'array', encoding = 'number' })
end)

local function _extract_random_elements(num, from, random_fun)
   local n = tonumber(num) or tonumber(tostring(have(num)))
   ZEN.assert(n and n>=0, "Not a number or not a positive number: "..num)
   local src = have(from)
   ZEN.assert(luatype(src) == 'table', "Object is not a table: "..from)

   local tmp = { }
   local keys = { }
   for k,v in pairs(src) do
      table.insert(keys, k)
      table.insert(tmp, v)
   end

   local len = #tmp
   local max_len = 65536
   ZEN.assert(len < max_len, "The number of elements of "..from.." exceed the maximum length: "..max_len)
   ZEN.assert(n < len, num.." is grater than the number of elements in "..from)
   local max_random = math.floor(max_len/len)*len

   local dst = { }
   while(n ~= 0) do
      local r = random_fun()
      while r >= max_random do
         r = random_fun()
      end
      r = (r % len) +1
      if keys[r] ~= nil then
         if tonumber(keys[r]) then
            table.insert(dst ,tmp[r])
         else
            dst[keys[r]] = tmp[r]
         end
         keys[r] = nil
         tmp[r] = nil
         n = n - 1
      end
   end
   return dst
end

When("pick the random object in ''", function(from)
        key, ACK.random_object = next(_extract_random_elements(1, from, random_int16))
        new_codec('random_object', {name=key})
end)

When("create the random dictionary with '' random objects from ''", function(num, from)
        ACK.random_dictionary = _extract_random_elements(num, from, random_int16)
        new_codec('random_dictionary')
end)
