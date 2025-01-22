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

-- utils
local function _get_bytes(n)
    local num = tonumber(mayhave(n) or n)
    if not num then error("Argument is not a number: "..n, 2) end
    return math.ceil(num)
end
local function _get_bytes_from_bits(n)
    local num = tonumber(mayhave(n) or n)
    if not num then error("Argument is not a number: "..n, 2) end
    return math.ceil(num/8)
end

-- uniformity obtained with rejection sampling
local function _random_modulo_uniform_distribution(modulo, max_random, random_f)
    if not modulo then
        error("modulo input argument is missing", 2)
    end
    local max_random = max_random or 65536
    if type(max_random) ~= type(modulo) then
        error("max_random and modulo have different types: "..type(max_random).." and "..type(modulo), 2)
    end
    if max_random < modulo then
        error("max_random is less than modulo", 2)
    end
    local random_f = random_f or random_int16
    local max_uniform_random
    if type(modulo) == 'zenroom.big' then
        max_uniform_random = (max_random/modulo)*modulo
    else
        max_uniform_random = math.floor(max_random/modulo)*modulo
    end
    local random = random_f()
    while random >= max_uniform_random do
        random = random_f()
    end
    return (random % modulo) +1
end

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

-- random octets

local function _create_random(dest, bytes)
    empty(dest)
    ACK[dest] = OCTET.random(bytes)
    new_codec(dest, { zentype = 'e' })
end

When("create random ''", function(dest)
    _create_random(dest, 32)
end)
When("create random of '' bits", function(n)
    _create_random('random', _get_bytes_from_bits(n))
end)
When("create random of '' bytes", function(n)
    _create_random('random', _get_bytes(n))
end)

When(
    deprecated(
        "create random object of '' bits",
        "create random of '' bits",
        function(n) _create_random('random_object', n, 8) end
    )
)
When(
    deprecated(
        "create random object of '' bytes",
        "create random of '' bytes",
        function(n) _create_random('random_object', n) end
    )
)

-- array shuffle

-- Fisher-Yates algorithm
local function shuffle_array_f(arr)
    local tab, c_tab = have(arr)
    if (c_tab.zentype ~= 'a' and (not c_tab.schema or not isarray(tab))) then
        error("Object to be randomized is not an array: "..arr, 2)
    end
    local tab_len = #tab
    local res = { }
    for i = tab_len,2,-1 do
        local r = _random_modulo_uniform_distribution(i)
        r = (r % i) + 1
        tab[i], tab[r] = tab[r], tab[i]
    end
end

When("randomize '' array", shuffle_array_f)

-- random array

local function _create_random_array(array_length, fun_input, fun, codec)
    empty 'array'
    local length = tonumber(mayhave(array_length) or array_length)
    zencode_assert(length, "Argument is not a number: "..array_length)
    ACK.array = {}
    for i = length,1,-1 do
        table.insert(ACK.array, fun(fun_input))
    end
    local n_codec = {zentype = 'a'}
    if codec then
        for k, v in pairs(codec) do
            n_codec[k] = v
        end
    end
    new_codec('array', n_codec)
end

When("create array of '' random", function(s)
    _create_random_array(s, 64, OCTET.random)
end)
When("create array of '' random of '' bits", function(s, b)
    _create_random_array(s, _get_bytes_from_bits(b), OCTET.random)
end)
When("create array of '' random of '' bytes", function(s, b)
    _create_random_array(s, _get_bytes(b), OCTET.random)
end)

When(
    deprecated(
        "create array of '' random objects",
        "create array of '' random",
        function(s)
            _create_random_array(s, 64, OCTET.random)
        end
    )
)
When(
    deprecated(
        "create array of '' random objects of '' bits",
        "create array of '' random of '' bits",
        function(s, b)
            _create_random_array(s, _get_bytes_from_bits(b), OCTET.random)
        end
    )
)
When(
    deprecated(
        "create array of '' random objects of '' bytes",
        "create array of '' random of '' bytes",
        function(s, b)
            _create_random_array(s, _get_bytes(b), OCTET.random)
        end
    )
)

When("create array of '' random numbers", function(s)
    _create_random_array(s, null, BIG.random, {encoding = 'integer'})
end)

local random_generator = {
    ['zenroom.big'] = {
        fun = function(input_modulo) return _random_modulo_uniform_distribution(input_modulo, ECP.order(), BIG.random) end,
        enc = {encoding = 'integer'}
    },
    ['zenroom.float'] = {
        fun = function(input_modulo) return F.new(_random_modulo_uniform_distribution(tonumber(input_modulo))) end,
        enc = {encoding = 'float'}
    }
}
When("create array of '' random numbers modulo ''", function(s,m)
    local modulo = mayhave(m)
    if not modulo then
        local mod = tonumber(m)
        zencode_assert(mod, "Argument is not a number: "..m)
        modulo = BIG.new(mod)
    end
    local modulo_type = type(modulo)
    local random_gen = random_generator[modulo_type]
    if not random_gen then
        error("Modulo is not a number nor an integer: "..modulo_type)
    end
    _create_random_array(s, modulo, random_gen.fun, random_gen.enc)
end)

-- pick random element

-- reservoir sampling algorithm
local function _extract_random_elements(dest, num, from)
    empty(dest)
    local n = tonumber(num) or tonumber(tostring(have(num)))
    zencode_assert(n and n>0, "Not a number or not a positive number: "..num)
    local src, src_codec = have(from)
    zencode_assert(luatype(src) == 'table', "Object is not a table: "..from)
    local is_array = isarray(src)

    local keys = {}
    local values = {}
    for k,v in pairs(src) do
        table.insert(keys, k)
        table.insert(values, v)
    end

    local len = #keys
    local max_len = 65536
    zencode_assert(len < max_len, "The number of elements of "..from.." exceed the maximum length: "..max_len)
    zencode_assert(n <= len, num.." is grater than the number of elements in "..from)

    local dst = {}
    for i = 1, n do
        if is_array then
            dst[i] = values[i]
        else
            dst[keys[i]] = values[i]
        end
    end

    for i = n+1, len do
        local r = random_int16()
        if r % i < n then
            local replace_index = (r % n) + 1
            if is_array then
                dst[replace_index] = values[i]
            else
                dst[keys[replace_index]] = nil
                dst[keys[i]] = values[i]
            end
        end
    end

    local n_codec = {encoding = src_codec.encoding}
    if (n == 1) then 
        n_codec.name, ACK[dest] = next(dst)
    else
        ACK[dest] = dst
    end
    new_codec(dest, n_codec) 
end

When("create random pick from ''", function(from)
    _extract_random_elements('random_pick', 1, from)
end)
When("create random table with '' random pick from ''", function(num, from)
    _extract_random_elements('random_table', num, from)
end)

When(
    deprecated(
        "pick random object in ''",
        "create random pick from ''",
        function(from)
            _extract_random_elements('random_object', 1, from)
        end
    )
)
When(
    deprecated(
        "create random dictionary with '' random objects from ''",
        "create random table with '' random pick from ''",
        function(num, from)
            _extract_random_elements('random_dictionary', num, from)
        end
    )
)
