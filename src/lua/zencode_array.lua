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
local stats = require('stats')
-- array operations

When("create the new array", function()
	ACK.new_array = { }
	new_codec('new array', {zentype='a'})
end)

When("create the copy of element '' in array ''", function(pos, arr)
	empty 'copy'
	local src, src_codec = have(arr)
	zencode_assert(src_codec.zentype == "a", "Not an array: "..arr)
	local num = tonumber(mayhave(pos) or pos)
	zencode_assert(num, "Argument is not a position number: "..pos)
	zencode_assert(src[num], "No element found in: "..arr.."["..pos.."]")
	ACK.copy = src[num]
	local n_codec = { encoding = src_codec.encoding }
	-- table of schemas can only contain elements
	if src_codec.schema then
		n_codec.schema = src_codec.schema
		n_codec.zentype = "e"
	end
	new_codec('copy', n_codec)
end)

local function _insert_in(what, dest)
	local d, d_codec = have(dest)
	zencode_assert(luatype(d) == 'table',
	"Invalid destination, not a table: "..dest)
	zencode_assert(d_codec.zentype == 'a',
	"Invalid destination, not an array: "..dest)
	table.insert(ACK[dest], what)
end

When("insert string '' in ''", function(st, dest)
	_insert_in(O.from_string(st), dest)
end)
When("insert true in ''", function(dest)
	_insert_in(true, dest)
end)
When("insert false in ''", function(dest)
	_insert_in(false, dest)
end)

local function _aggr_array(arr)
	local A = have(arr)
	local codec = CODEC[arr]
	zencode_assert(codec.zentype == 'a', "Object is not a valid array: "..arr)
	local count = isarray(A)
	zencode_assert( count > 0, "Array is empty or invalid: "..arr)
	local res, par
	if luatype(A[1]) == 'number' then
		res = 0
		for _,v in next,A,nil do
			res = res + tonumber(v)
		end
		par = {encoding='number',zentype='e'}
	elseif type(A[1]) == 'zenroom.big' then
		res = BIG.new(0)
		for _,v in next,A,nil do
			res = res + v
		end
		par = {zentype = 'e'}
	elseif type(A[1]) == 'zenroom.ecp' then
		res = ECP.generator()
		for _,v in next,A,nil do
			res = res + v
		end
		par = {zentype = 'e'}
	elseif type(A[1]) == 'zenroom.ecp2' then
		res = ECP2.generator()
		for _,v in next,A,nil do
			res = res + v
		end
		par = {zentype = 'e'}
	elseif type(A[1]) == 'zenroom.float' then
		res = F.new(0)
		for _,v in next,A,nil do
			res = res + v
		end
		par = {zentype = 'e'}
	else
		error("Unknown aggregation for type: "..type(A[1]))
	end
	return res, par
end

When("create the aggregation of array ''", function(arr)
	empty'aggregation'
	local params
	ACK.aggregation, params = _aggr_array(arr)
	new_codec('aggregation', params)
end)
When("create the sum value of elements in array ''", function(arr)
	empty'sum value'
	local params
	ACK.sum_value, params = _aggr_array(arr)
	new_codec('sum value', params)
end)
When("create the average of elements in array ''", function(arr)
	empty'average'
	local data = have(arr)
	ACK.average = O.from_string(stats.average(data):decimal())
	new_codec('average', { encoding="string" })
end)
When("create the variance of elements in array ''", function(arr)
	empty'variance'
	local data = have(arr)
	ACK.variance = O.from_string(stats.variance(data):decimal())
	new_codec('variance', { encoding="string" })
end)
When("create the standard deviation of elements in array ''", function(arr)
	empty'standard_deviation'
	local data = have(arr)
	ACK.standard_deviation = O.from_string(stats.standardDeviation(data):decimal())
	new_codec('standard_deviation', { encoding="string" })
end)

When("create the flat array of contents in ''", function(dic)
	local codec = CODEC[dic]
	zencode_assert(codec.zentype == 'a' or
	codec.zentype == 'd',
	"Target is not a valid: "..dic)
	local data = have(dic)
	zencode_assert(luatype(data) == 'table', "Invalid array: "..dic)
	empty'flat array'
	ACK.flat_array = {}
	deepsortmap(function(v, k, res) table.insert(res, v) end, data, ACK.flat_array)
	new_codec('flat array', { encoding="string" })
end)

local function _keys_flat_array(data, res)
	for k, item in sort_pairs(data) do
		if type(k) == 'string' then
			k = O.from_string(k)
		elseif type(k) == 'number' then
			k = F.new(k)
		end
		table.insert(res, k)
		if luatype(item) == 'table' then
			_keys_flat_array(item, res)
		end
	end
end

When("create the flat array of keys in ''", function(dic)
	local codec = CODEC[dic]
	zencode_assert(codec.zentype == 'a' or
	codec.zentype == 'd',
	"Target is not a valid: "..dic)
	local data = have(dic)
	zencode_assert(luatype(data) == 'table', "Invalid target: "..dic)
	empty'flat array'
	ACK.flat_array = {}
	_keys_flat_array(data, ACK.flat_array)
	new_codec('flat array', { encoding="string" })
end)

When("create the array of objects named by '' found in ''", function(name, dict)
	zencode_assert(isdictionary(dict), "Second argument is not a dictionary")
	local n = have(name):octet():string()
	local src = have(dict)
	empty'array'
	ACK.array = { }
	deepmap(function(v,k,res)
		if k == n then table.insert(res, v) end
	end, src, ACK.array)
	new_codec('array', { encoding='string', zentype='a' })
end)

When("create the array by splitting '' at ''", function(data_name, sep_name)
	local data = uscore(have(data_name):octet():string())
	local sep = uscore(have(sep_name):octet():string())
	zencode_assert(#sep == 1, "You can only split with respect to one character")
	empty'array'
	local strings = strtok(data, sep)
	local octets = {}
	for _, v in ipairs(strings) do
		-- exclude empty strings from conversion
		if v and #v > 0 then
			table.insert(octets, O.from_str(v))
		end
	end
	ACK.array = octets
	new_codec('array', { encoding='string', zentype='a' })
end)

When("create the '' from '' in ''", function(dest, key_name, obj_name)
	empty(dest)
	local obj, obj_codec = have(obj_name)
	local key, key_enc = mayhave(key_name)
	if key then
		if key_enc.encoding == "string" then
			key = key:str()
		elseif key_enc.encoding == "integer" then
			key = key:decimal()
		end
	else
		key = key_name
	end
	if obj_codec.zentype == 'a' then
		local key_num = tonumber(key)
		zencode_assert(#obj >= key_num, "Element "..key_num.." does not exists in array "..obj_name)
		ACK[dest] = obj[key_num]
	elseif obj_codec.zentype == 'd' then
		zencode_assert(obj[key], "Element "..key.." does not exists in dictionary "..obj_name)
		ACK[dest] = obj[key]
	else
		error("Last object must be an array or dictionary, found instead: "..obj_codec.zentype)
	end
	new_codec(dest, {encoding = obj_codec.encoding})
end)
