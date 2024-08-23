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

When("seed random with ''",
     function(seed)
         local s = have(seed)
         zencode_assert(iszen(type(s)), "New random seed is not a valid zenroom type: "..seed)
         local fingerprint = random_seed(s:octet()) -- pass the seed for srand init
         act("New random seed of "..#s.." bytes")
         xxx("New random fingerprint: "..fingerprint:hex())
     end
)

When("create random ''", function(dest)
		zencode_assert(not ACK[dest], "Cannot overwrite existing value: "..dest)
		ACK[dest] = OCTET.random(32) -- TODO: right now hardcoded 256 bit random secrets
                new_codec(dest, { zentype = 'e' })
end)

local function shuffle_array_f(tab)
   -- do not enforce CODEC detection since some schemas are also 1st level arrays
   local count = isarray(tab)
   zencode_assert( count > 0, "Randomized object is not an array")
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
When("create random object of '' bits", function(n)
	empty'random object'
	local bits = tonumber(mayhave(n) or n)
	zencode_assert(bits, 'Invalid number of bits: ' .. n)
	ACK.random_object = OCTET.random(math.ceil(bits / 8))
	new_codec('random_object', { zentype = 'e' })
end
)
When("create random object of '' bytes",function(n)
	empty'random object'
	local bytes = math.ceil(tonumber(mayhave(n) or n))
	zencode_assert(bytes, 'Invalid number of bytes: ' .. n)
	ACK.random_object = OCTET.random(bytes)
	new_codec('random_object', { zentype = 'e' })
end
)

When("randomize '' array", function(arr)
		local A = have(arr)
		-- ZEN.assert(ZEN.CODEC[arr].zentype == 'a', "Object is not an array: "..arr)
		ACK[arr] = shuffle_array_f(A)
end)

local function _create_random_array(array_length, fun_input, fun)
    empty 'array'
    ACK.array = { }
    local length = tonumber(mayhave(array_length) or array_length)
    zencode_assert(length, "Argument is not a number: "..array_length)
    for i = length,1,-1 do
        table.insert(ACK.array, fun(fun_input))
    end
end

When("create array of '' random objects", function(s)
    _create_random_array(s, 64, OCTET.random)
    new_codec('array', {zentype = 'a'})
end)

When("create array of '' random objects of '' bits", function(s, b)
    local bits = tonumber(mayhave(b) or b)
    zencode_assert(bits, "Argument is not a number: "..b)
    local bytes = math.ceil(bits/8)
    _create_random_array(s, bytes, OCTET.random)
    new_codec('array', {zentype = 'a'})
end)

When("create array of '' random objects of '' bytes", function(s, b)
    local n_bytes = tonumber(mayhave(b) or b)
    zencode_assert(n_bytes, "Argument is not a number: "..b)
    local bytes = math.ceil(n_bytes)
    _create_random_array(s, bytes, OCTET.random)
    new_codec('array', {zentype = 'a'})
end)

When("create array of '' random numbers", function(s)
    _create_random_array(s, null, BIG.random)
    new_codec('array', {zentype = 'a', encoding = 'integer' })
end)


When("create array of '' random numbers modulo ''", function(s,m)
    local modulo = mayhave(m)
    if not modulo then
        local mod = tonumber(m)
        zencode_assert(mod, "Argument is not a number: "..m)
        modulo = BIG.new(mod)
    end
    local fun
    local enc
    local modulo_type = type(modulo)
    if modulo_type == "zenroom.big" then
        fun = function(input) return BIG.random() % input end
        enc = 'integer'
    elseif modulo_type == "zenroom.float" then
        fun = function(input) return F.new(math.floor(random_int16() % tonumber(input))) end
        enc = 'float'
    else
        error("Modulo is not a number nor an integer: "..modulo_type)
    end
    _create_random_array(s, modulo, fun)
    new_codec('array', {zentype = 'a', encoding = enc })
end)


local function _extract_random_elements(num, from, random_fun)
   local n = tonumber(num) or tonumber(tostring(have(num)))
   zencode_assert(n and n>=0, "Not a number or not a positive number: "..num)
   local src = have(from)
   zencode_assert(luatype(src) == 'table', "Object is not a table: "..from)

   local tmp = { }
   local keys = { }
   for k,v in pairs(src) do
      table.insert(keys, k)
      table.insert(tmp, v)
   end

   local len = #tmp
   local max_len = 65536
   zencode_assert(len < max_len, "The number of elements of "..from.." exceed the maximum length: "..max_len)
   zencode_assert(n <= len, num.." is grater than the number of elements in "..from)
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

When("pick random object in ''", function(from)
        key, ACK.random_object = next(_extract_random_elements(1, from, random_int16))
        new_codec('random_object', {name=key, encoding = CODEC[from].encoding})
end)

When("create random dictionary with '' random objects from ''", function(num, from)
        ACK.random_dictionary = _extract_random_elements(num, from, random_int16)
        new_codec('random_dictionary', {encoding = CODEC[from].encoding})
end)
