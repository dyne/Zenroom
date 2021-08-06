--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
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

-- this is a map reduce function processing a single argument as
-- values found, it uses function pointers and conditions from the
-- params structure.
-- param.target = key name of the value to find
-- param.op = single argument function to run on found value
-- param.cmp = dual argument comparison for dictionary eligibility
-- param.conditions = k/v list of elements to compare in dictionary

local function dicts_reduce(dicts, params)
   local found
   local arr
   for ak,av in pairs(dicts) do
      if luatype(av) == 'table' then
	 found = false
	 -- apply params filters, boolean just check key presence
	 if params.conditions and params.cmp then
	    for pk,pv in pairs(params.conditions) do
	       local tv = av[pk]
	       if tv then
		  if params.cmp(tv, pv) then
		     found = true
		  end
	       end
	    end
	 else found = true end -- no filters, apply everywhere
	 -- apply sum of selected key/value
	 if found then
	    for k,v in pairs(av) do
	       if k == params.target then
		  params.op(v)
	       end
	    end
	 end
      end -- av is a table
   end
end

When("create the new dictionary", function()
		empty'new dictionary'
		ACK.new_dictionary = { }
		new_codec('new dictionary', { zentype = 'dictionary' })
end)

When("create the pruned dictionary of ''", function(dict)
	empty'pruned dictionary'
	local d = have(dict)
	ZEN.assert(luatype(d) == 'table', 'Object is not a table: '..dict)
	ACK.pruned_dictionary = prune(d)
	new_codec('pruned dictionary', nil, dict)
end)

When("find the max value '' for dictionaries in ''", function(name, arr)
	ZEN.assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	empty'max value'
    local max = 0
	local params = {
				target = name,
				op = function(v)
					if max < v then max = v end
				end
			}
	dicts_reduce(ACK[arr],params) -- optimization? operate directly on ACK
    ZEN.assert(max, "No max value "..name.." found across dictionaries in"..arr)
    ACK.max_value = max
	new_codec('max value', {
		zentype = 'element', -- introduce scalar?
		luatype = 'number'
	}, arr) -- clone array's encoding
end)

When("find the min value '' for dictionaries in ''", function(name, arr)
	ZEN.assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	empty'min value'
	local min
	-- init min with any value
	for k,v in pairs(ACK[arr]) do
	   min = v[name] -- suppose existance of key
	   break
	end
	local params = {
		target = name,
		op = function(v)
			if v < min then min = v end
		 end
	}
	dicts_reduce(ACK[arr],params)
	ACK.min_value = min
	new_codec('min value', {
		zentype = 'element', -- introduce scalar?
		luatype = 'number'
	}, arr) -- clone array's encoding
end)

When("create the sum value '' for dictionaries in ''", function(name,arr)
	ZEN.assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	empty'sum value'
	local sum -- result of reduction
	local params = {
		target = name,
		op = function(v)
		   if not sum then sum = v
		   else sum = sum + v end
		end
	}
    dicts_reduce(ACK[arr], params)
    ZEN.assert(sum, "No sum of value "..name
				  .." found across dictionaries in "..arr)
    ACK.sum_value = sum
	new_codec('sum value', {
		zentype = type(sum), -- introduce scalar?
	}) -- clone array's encoding
end)

When("create the sum value '' for dictionaries in '' where '' > ''", function(name,arr, left, right)
	ZEN.assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	have(right)
	empty'sum value'

	local sum = 0 -- result of reduction
	local params = {
		target = name,
		conditions = { },
		cmp = function(l,r) return l > r end,
		op = function(v) sum = sum + v end
	}
	params.conditions[left] = ACK[right] -- used in cmp
    dicts_reduce(ACK[arr], params)
    ZEN.assert(sum, "No sum of value "..name
				  .." found across dictionaries in"..arr)
    ACK.sum_value = sum
	new_codec('sum value', {
		zentype = 'element', -- introduce scalar?
		luatype = 'number'
	}, arr) -- clone array's encoding
end)

When("find the '' for dictionaries in '' where '' = ''",function(name, arr, left, right)
	ZEN.assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	have(right)
	empty(name)

	local val = { }
	local params = {
		target = name,
		conditions = { },
		cmp = function(l,r) return l == r end,
		op = function(v) table.insert(val, v) end
	}
	params.conditions[left] = ACK[right]
	dicts_reduce(ACK[arr], params)
	ZEN.assert(val, "No value found "..name.." across dictionaries in "..arr)
	if #val == 1 then
		ACK[name] = val[1]
		new_codec(name, {
			luatype = luatype(ACK[name]),
			zentype = 'element'
		}, arr)
	else
	   ACK[name] = val
	   new_codec(name, {
		   luatype = 'table',
		   zentype = 'array'
	   }, arr)
	end
end)

local function create_copy_f(root, in1, in2)
	local r = have(root)
	empty'copy'
	ZEN.assert(luatype(r) == 'table', "Object is not a table:"..root)
	ZEN.assert(in1, "Undefined key or index: "..in1.." in "..root)
	local res
	if tonumber(in1) then
		ZEN.assert(isarray(r), "Invalid index "..in1.." as object is not an array: "..root)
	else
		ZEN.assert(isdictionary(r), "Invalid key "..in1.." as object is not a dictionary:"..root)
	end
	ACK.copy = r[in1]
	ZEN.assert(ACK.copy, "Member not found: "..in1.." in "..root)
	if in2 then
		if tonumber(in2) then
			ZEN.assert(isarray(ACK.copy), "Invalid index "..in2.." as object is not an array: "..in1.." in "..root)
		else
			ZEN.assert(isdictionary(ACK.copy), "Invalid key "..in2.." as object is not a dictionary:"..in1.." in "..root)
		end	
		ACK.copy = ACK.copy[in2]
		ZEN.assert(ACK.copy, "Member not found: "..in2.." in "..in1.." in "..root)
	end
	new_codec('copy', { luatype = luatype(ACK[copy]) }, root)
	if ZEN.CODEC.copy.luatype == 'table' then
		if isdictionary(ACK.copy) then
			   ZEN.CODEC.copy.zentype = 'dictionary'
		elseif isarray(ACK.copy) then
			   ZEN.CODEC.copy.zentype = 'array'
		else
		   ZEN.assert(false, "Unknown zentype for lua table element: "..dict.."."..name)
		end
	else
		ZEN.CODEC.copy.zentype = 'element'
	end
end
When("create the copy of '' from dictionary ''", function(name, dict) create_copy_f(dict, name) end)
When("create the copy of '' from ''", function(name, dict) create_copy_f(dict, name) end)
When("create the copy of '' in ''", function(name, dict) create_copy_f(dict, name) end)
When("create the copy of '' in '' in ''", function(obj, branch, root) create_copy_f(root, branch, obj) end)
