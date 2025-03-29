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
--on Wednesday, 6th October 2021
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
	 if found and av[params.target] ~= nil then
         params.op(av[params.target])
	 end
      end -- av is a table
   end
end

When("create new dictionary", function()
		empty'new dictionary'
		ACK.new_dictionary = { }
		new_codec('new dictionary', { zentype = 'd',
                                      encoding = 'string'})
end)


When("create new dictionary named ''", function(name)
		empty(name)
		ACK[name] = { }
		new_codec(name, { zentype = 'd',
                          encoding = 'string'})
end)

When("create array of elements named '' for dictionaries in ''",
     function(name, dict)
	empty'array'
	local src = have(dict)
	zencode_assert(luatype(src)=='table', "Object is not a table: "..dict)
	local res = { }
	for k, v in pairs(src) do
	   if k == name then table.insert(res, v) end
	   -- dict is most oftern an array of dictionaries
	   for kk, vv in pairs(v) do
	      if kk == name then table.insert(res, vv) end
	   end
	end
	ACK.array = res
	new_codec('array', {zentype='a'}, dict)
end)

When("create pruned dictionary of ''", function(dict)
	empty'pruned dictionary'
	local d = have(dict)
	zencode_assert(luatype(d) == 'table', 'Object is not a table: '..dict)
	ACK.pruned_dictionary = prune(d)
	new_codec('pruned dictionary', nil, dict)
end)

local function _initial_set(number, name, arr)
    local t = type(number)
    local enc
    if t == "zenroom.float" then
        enc = "float"
    elseif t == "zenroom.big" then
        enc = "integer"
    elseif t == "zenroom.time" then
        enc = "time"
    else
        error(name.." inside dictionaires in "..arr.." is neither a integer nor a float")
    end
    return number, enc
end

When("find max value '' for dictionaries in ''", function(name, arr)
	zencode_assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	empty'max value'
	local max = nil
    local max_enc = nil
	local params = {
				target = name,
				op = function(v)
					if not max then
                        max, max_enc = _initial_set(v, name, arr)
					elseif max < v then max = v end
				end
			}
	dicts_reduce(ACK[arr],params) -- optimization? operate directly on ACK
    zencode_assert(max, "No max value "..name.." found across dictionaries in "..arr)
    ACK.max_value = max
	new_codec('max value', {
        zentype = 'e',
        encoding = max_enc
	})
end)

When("find min value '' for dictionaries in ''", function(name, arr)
	zencode_assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	empty'min value'
	local min = nil
    local min_enc = nil
	local params = {
		target = name,
		op = function(v)
            if not min then
                min, min_enc = _initial_set(v, name, arr)
			elseif v < min then min = v end
		 end
	}
	dicts_reduce(ACK[arr],params)
    zencode_assert(min, "No min value "..name.." found across dictionaries in "..arr)
	ACK.min_value = min
	new_codec('min value', {
        zentype = 'e',
        encoding = min_enc
    })
end)

When("create sum value '' for dictionaries in ''", function(name,arr)
	zencode_assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	empty'sum value'
	local sum -- result of reduction
    local sum_enc
	local params = {
		target = name,
		op = function(v)
            if not sum then
                sum, sum_enc = _initial_set(v, name, arr)
            else sum = sum + v end
		end
	}
    dicts_reduce(ACK[arr], params)
    zencode_assert(sum, "No sum of value "..name
				  .." found across dictionaries in "..arr)
    ACK.sum_value = sum
	new_codec('sum value', {
        zentype = 'e',
        encoding = sum_enc
	})
end)

When("create sum value '' for dictionaries in '' where '' > ''", function(name,arr, left, right)
	zencode_assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
	have(right)
	empty'sum value'

	local sum = nil -- result of reduction
    local sum_enc
	local params = {
		target = name,
		conditions = { },
		cmp = function(l,r) return l > r end,
		op = function(v)
            if sum == nil then
                sum, sum_enc = _initial_set(v, name, arr)
            else sum = sum + v end
        end
	}
	params.conditions[left] = ACK[right] -- used in cmp
    dicts_reduce(ACK[arr], params)
    zencode_assert(sum, "No sum of value "..name
				  .." found across dictionaries in"..arr)
    ACK.sum_value = sum
	new_codec('sum value', {
        zentype = 'e',
        encoding = sum_enc
	})
end)

When("find '' for dictionaries in '' where '' = ''",function(name, arr, left, right)
	zencode_assert(luatype(have(arr)) == 'table', 'Object is not a table: '..arr)
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
	zencode_assert(val, "No value found "..name.." across dictionaries in "..arr)
	ACK[name] = val
	new_codec(name, {zentype = 'a'}, arr)
end)


local function _extract(tab, ele, root)
   local nr = root or 'nil'
   zencode_assert(luatype(tab) == 'table', "Object is not a table: "..nr)
   zencode_assert(ele, "Undefined key or index: "..ele.." in "..nr)
   if #tab == 1 then
      if tab[ele] then return tab[ele] end
      if luatype(tab[1]) == 'table' and tab[1][ele] then
	 return tab[1][ele]
      end
   else
      if tab[ele] then return tab[ele] end
   end
   error("Member not found: "..ele.." in "..nr, 3)
end
local function create_copy_f(root, in1, in2)
	empty'copy'
	local r, r_codec = have(root)
	ACK.copy = _extract(r, in1, root)
	if in2 then
	   ACK.copy = _extract(ACK.copy, in2, in1)
	end
    local n_codec = { encoding = r_codec.encoding }
    -- table of schemas can only contain elements
    if r_codec.schema then
        n_codec.schema = r_codec.schema
        n_codec.zentype = "e"
    end
    n_codec.mask = r_codec.mask -- encoding mask if not nil
	new_codec('copy', n_codec)
	CODEC['copy'].name = in2 or in1
end
When("create copy of '' from dictionary ''", function(name, dict) create_copy_f(dict, name) end)
When("create copy of '' from ''", function(name, dict) create_copy_f(dict, name) end)
When("create copy of object named by '' from dictionary ''", function(name, dict)
  local label = have(name)
  create_copy_f(dict, label:string())
end)

When("for each dictionary in '' append '' to ''", function(arr, right, left)
	local dicts = have(arr)
	zencode_assert(luatype(dicts) == 'table', 'Object is not a table: '..arr)
	for kk,vv in pairs(dicts) do
		local l, r
		for k,v in pairs(vv) do
			if k == right then r = v end
			if k == left then l = v end
		end
		zencode_assert(l, "Object not found: "..kk.."."..left)
		zencode_assert(r, "Object not found: "..kk.."."..right)
		vv[left] = l..r
	end
end)

local function _filter_from(v, k, f)
   for _, fv in pairs(f) do
      if fv:str() == k then
	 return v
      end
   end
   return nil
end

local function _is_array_of_dictionaries(a)
   if not isarray(a) then return false end
   for _, v in pairs(a) do
      if luatype(v) ~= 'table' then
	 return false
      end
   end
   return true
end

When("filter '' fields from ''", function(filters, target)
	local t = have(target)
	zencode_assert(isdictionary(target) or
		   _is_array_of_dictionaries(t),
		   "Object is nor a dictionary neither an array of dictionaries: "..target)
	local f = have(filters)
	zencode_assert(isarray(filters), "Object is not an array: "..filters)
	ACK[target] = deepmap(_filter_from, t, f)
end)
