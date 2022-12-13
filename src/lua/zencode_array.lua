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

local function check_container(name)
   ZEN.assert(ACK[name], "Invalid container, not found: "..name)
   ZEN.assert(luatype(ACK[name]) == 'table', "Invalid container, not a table: "..name)
   if ZEN.CODEC[name] then
	  ZEN.assert(ZEN.CODEC[name].zentype ~= 'element', "Invalid container: "..name.." is a "..ZEN.CODEC[name].zentype)
   else
	  xxx("Object has no CODEC registration: "..name)
   end
end

local function check_element(name)
   local o = ACK[name]
   ZEN.assert(o, "Invalid element, not found: "..name)
   ZEN.assert(iszen(type(o)), "Invalid element, not a zenroom object: "..name.." ("..type(o)..")")
   if ZEN.CODEC[name] then
	  ZEN.assert(ZEN.CODEC[name].zentype == 'element', "Invalid element: "..name.." is a "..ZEN.CODEC[name].zentype)
   else
	  xxx("Object has no CODEC registration: "..name)
   end
   return o
end

local function _when_remove_dictionary(ele, from)
	-- ele is just the name (key) of object to remove
	local dict = have(from)
	ZEN.assert(dict, "Dictionary not found: "..from)
	if dict[ele] then
	   ACK[from][ele] = nil -- remove from dictionary
	elseif ZEN.CODEC[ele].name ~= ele and dict[ZEN.CODEC[ele].name] then
	   -- it may be a copy or random object with different name
	   ACK[from][ZEN.CODEC[ele].name] = nil
	else
	   error("Object not found in dictionary: "..ele.." in "..from)
	end
end
local function _when_remove_array(ele, from)
	local obj = have(ele)
	local arr = have(from)
	local found = false
	local newdest = { }
	if luatype(obj) == 'table' then
	   -- overload __eq for tables
	   local m_obj = {}
	   local m_arr = {}
	   setmetatable(arr, m_arr)
	   setmetatable(obj, m_obj)
	   local fun = function(l, r) return ZEN.serialize(l) == ZEN.serialize(r) end
	   m_arr.__eq = fun
	   m_obj.__eq = fun
	end
	for k,v in next,arr,nil do
	   if not (v == obj) then
		  table.insert(newdest,v)
	   else
		  found = true
	   end
	end
	ZEN.assert(found, "Element to be removed not found in array")
	ACK[from] = newdest
end

When("remove the '' from ''", function(ele,from)
	local codec = ZEN.CODEC[from]
	ZEN.assert(codec, "No codec registration for target: "..from)
	if codec.zentype == 'dictionary'
	or codec.zentype == 'schema' then
		_when_remove_dictionary(ele, from)
	elseif codec.zentype == 'array' then
		_when_remove_array(ele, from)
	else
		I.warn({ CODEC = codec})
		error("Invalid codec registration for target: "..from)
	end
end)

When("create the new array", function()
		ACK.new_array = { }
		new_codec('new array', {zentype='array', luatype='table'})
end)

local function count_f(t)
   local count = 0
   if luatype(t) == 'table' then
      for _, __ in pairs(t) do
	 count = count + 1
      end
   else
      count = #t
   end
   return count
end
When("create the length of ''", function(arr)
	local obj = have(arr)
	ACK.length = F.new(count_f(obj))
	new_codec('length', {zentype='element'})
end)
When("create the size of ''", function(arr)
	local obj = have(arr)
	ACK.size = F.new(count_f(obj))
	new_codec('size', {zentype='element'})
end)

When("create the copy of element '' in array ''", function(pos, arr)
		ZEN.assert(ACK[arr], "No array found in: "..arr)
		ZEN.assert(isarray(ACK[arr]), "Not an array: "..arr)
		local num = tonumber(pos)
		ZEN.assert(num, "Argument is not a position number: "..pos)
		ZEN.assert(ACK[arr][num], "No element found in: "..arr.."["..pos.."]")
		ACK.copy = ACK[arr][num]
		-- TODO: support nested arrays or dictionaries
		new_codec('copy',{zentype='element',luatype=luatype(ACK.copy)},arr)
end)

When("insert string '' in ''", function(st, dest)
	local d = have(dest)
        ZEN.assert(luatype(d) == 'table',
		   "Invalid destination, not a table: "..dest)
        ZEN.assert(ZEN.CODEC[dest].zentype == 'array',
		   "Invalid destination, not an array: "..dest)
	table.insert(ACK[dest], O.from_string(st))
end)

When("insert true in ''", function(dest)
	local d = have(dest)
        ZEN.assert(luatype(d) == 'table',
		   "Invalid destination, not a table: "..dest)
        ZEN.assert(ZEN.CODEC[dest].zentype == 'array',
		   "Invalid destination, not an array: "..dest)
	table.insert(ACK[dest], true)
end)
When("insert false in ''", function(dest)
	local d = have(dest)
        ZEN.assert(luatype(d) == 'table',
		   "Invalid destination, not a table: "..dest)
        ZEN.assert(ZEN.CODEC[dest].zentype == 'array',
		   "Invalid destination, not an array: "..dest)
	table.insert(ACK[dest], false)
end)

When(deprecated("insert '' in ''",
		"move '' in ''",
		function(ele, dest)
		    local d = have(dest)
		    local e = have(ele)
		    ZEN.assert(luatype(d) == 'table',
			       "Invalid destination, not a table: "..dest)
		    ZEN.assert(ZEN.CODEC[dest].zentype ~= 'element',
			       "Invalid destination, not a container: "..dest)
		    if ZEN.CODEC[dest].zentype == 'array' then
			table.insert(ACK[dest], e)
		    elseif ZEN.CODEC[dest].zentype == 'dictionary' then
			ACK[dest][ele] = e
		    elseif ZEN.CODEC[dest].zentype == 'schema' then
			ACK[dest][ele] = e
		    else
			ZEN.assert(false, "Invalid destination type: "
				   ..ZEN.CODEC[dest].zentype)
		    end
		    ZEN.CODEC[dest][ele] = ZEN.CODEC[ele]
		    ACK[ele] = nil
		    ZEN.CODEC[ele] = nil
	       end)
)

-- When("insert the '' in ''", function(ele,arr)
--     ZEN.assert(ACK[ele], "Element not found: "..ele)
--     ZEN.assert(ACK[arr], "Array not found: "..arr)
-- 	ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
-- 			   "Object is not an array: "..arr)
--     table.insert(ACK[arr], ACK[ele])
-- end)

IfWhen("the '' is not found in ''", function(ele, arr)
        local obj = ACK[ele]
        ZEN.assert(obj, "Element not found: "..ele)
        ZEN.assert(ACK[arr], "Array not found: "..arr)
		if ZEN.CODEC[arr].zentype == 'array' then
		   for k,v in pairs(ACK[arr]) do
			  ZEN.assert(v ~= obj, "Element '"..ele.."' is contained inside: "..arr)
		   end
		elseif ZEN.CODEC[arr].zentype == 'dictionary' then
		   for k,v in pairs(ACK[arr]) do
			  local val = k
			  if luatype(k) == 'string' then
			  	 val = O.from_string(k)
			  end
			  ZEN.assert(val ~= obj, "Element '"..ele.."' is contained inside: "..arr)
		   end
		else
		   ZEN.assert(false, "Invalid container type: "..arr.." is "..ZEN.CODEC[arr].zentype)
		end
end)

IfWhen("the '' is found in ''", function(ele, arr)
		local obj = ACK[ele]
		ZEN.assert(obj, "Element not found: "..ele)
		ZEN.assert(ACK[arr], "Array not found: "..arr)
		local found = false
		if ZEN.CODEC[arr].zentype == 'array' then
		   for k,v in pairs(ACK[arr]) do
			  if v == obj then found = true end
		   end
		elseif ZEN.CODEC[arr].zentype == 'dictionary' then
		   for k,v in pairs(ACK[arr]) do
			  local val = k
			  if luatype(k) == 'string' then
			  	 val = O.from_string(k)
			  end
			  if val == obj then found = true end
		   end
		else
		   ZEN.assert(false, "Invalid container type: "..arr.." is "..ZEN.CODEC[arr].zentype)
		end
		ZEN.assert(found, "The content of element '"..ele.."' is not found inside: "..arr)
end)

IfWhen("the '' is found in '' at least '' times", function(ele, arr, times)
	local obj = have(ele)
	ZEN.assert( luatype(obj) ~= 'table', "Invalid use of table in object comparison: "..ele)
	local num = have(times)
	local list = have(arr)
	ZEN.assert( luatype(list) == 'table', "Not a table: "..arr)
	ZEN.assert( isarray(list), "Not an array: "..arr)
	local constructor = fif(type(num) == "zenroom.big", BIG.new, F.new)
	local found = constructor(0)
	local one = constructor(1)
	for _,v in pairs(list) do
		if type(v) == type(obj) and v == obj then found = found + one end
	end
    if type(num) == "zenroom.big" then
	    ZEN.assert(found >= num, "Object "..ele.." found only "..found:decimal().." times instead of "..num:decimal().." in array "..arr)
    else
	    ZEN.assert(found >= num, "Object "..ele.." found only "..tostring(found).." times instead of "..tostring(num).." in array "..arr)
    end
end)

local function _aggr_array(arr)
   local A = have(arr)
   local codec = ZEN.CODEC[arr]
   ZEN.assert(codec.zentype == 'array' or
	      (codec.zentype == 'schema' and codec.encoding == 'array'),
	      "Object is not a valid array: "..arr)
   local count = isarray(A)
   ZEN.assert( count > 0, "Array is empty or invalid: "..arr)
   local res, par
   if luatype(A[1]) == 'number' then
      res = 0
      for k,v in next,A,nil do
	 res = res + tonumber(v)
      end
      par = {encoding='number',zentype='element'}
   elseif type(A[1]) == 'zenroom.big' then
      res = BIG.new(0)
      for k,v in next,A,nil do
	 res = res + v
      end
      par = {zentype = 'element'}
   elseif type(A[1]) == 'zenroom.ecp' then
      res = ECP.generator()
      for k,v in next,A,nil do
	 res = res + v
      end
      par = {zentype = 'element'}
   elseif type(A[1]) == 'zenroom.ecp2' then
      res = ECP2.generator()
      for k,v in next,A,nil do
	 res = res + v
      end
      par = {zentype = 'element'}
   elseif type(A[1]) == 'zenroom.float' then
      res = F.new(0)
      for k,v in next,A,nil do
          res = res + v
      end
      par = {zentype = 'element'}
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
	local codec = ZEN.CODEC[dic]
	ZEN.assert(codec.zentype == 'array' or
		   codec.zentype == 'dictionary',
		   "Target is not a valid: "..dic)
	local data = have(dic)
	ZEN.assert(luatype(data) == 'table', "Invalid array: "..dic)
	empty'flat array'
	ACK.flat_array = {}
	deepmap(function(v, k, res) table.insert(res, v) end, data, ACK.flat_array)
	new_codec('flat array', { encoding="string" })
end)

local function _keys_flat_array(data, res)
   for k, item in pairs(data) do
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
	local codec = ZEN.CODEC[dic]
	ZEN.assert(codec.zentype == 'array' or
		   codec.zentype == 'dictionary',
		   "Target is not a valid: "..dic)
	local data = have(dic)
	ZEN.assert(luatype(data) == 'table', "Invalid target: "..dic)
	empty'flat array'
	ACK.flat_array = {}
	_keys_flat_array(data, ACK.flat_array)
	new_codec('flat array', { encoding="string" })
end)

When("create the array of objects named by '' found in ''", function(name, dict)
	ZEN.assert(isdictionary(dict), "Second argument is not a dictionary")
	local n = have(name):octet():string()
	local src = have(dict)
	empty'array'
	ACK.array = { }
	deepmap(function(v,k,res) 
	      if k == n then table.insert(res, v) end
	      end, src, ACK.array)
	new_codec('array', { encoding='string', zentype='array' })
end)

When("create the array by splitting '' at ''", function(data_name, sep_name)
        local data = uscore(have(data_name):octet():string())
        local sep = uscore(have(sep_name):octet():string())
        ZEN.assert(#sep == 1, "You can only split with respect to one character")
        empty'array'
        local strings = strtok(data, "[^" .. sep .. "]*")
        local octets = {}
        for k, v in ipairs(strings) do
                -- exclude empty strings from conversion
                if v and #v > 0 then
                        table.insert(octets, O.from_str(v))
                end
        end
        ACK.array = octets

        new_codec('array', { encoding='string', zentype='array' })

end)
