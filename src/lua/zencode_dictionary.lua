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


When("create the new dictionary named ''", function(name)
		empty(name)
		ACK[name] = { }
		new_codec(name, { zentype = 'dictionary' })
end)

When("create the array of elements named '' for dictionaries in ''",
     function(name, dict)
	empty'array'
	local src = have(dict)
	ZEN.assert(luatype(src)=='table', "Object is not a table: "..dict)
	local res = { }
	for k, v in pairs(src) do
	   if k == name then table.insert(res, v) end
	   -- dict is most oftern an array of dictionaries
	   for kk, vv in pairs(v) do
	      if kk == name then table.insert(res, vv) end
	   end
	end
	ACK.array = res
	new_codec('array', {luatype='table',zentype='array'}, dict)
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
	local max = nil
	local params = {
				target = name,
				op = function(v)
					if not max then max = v
					elseif max < v then max = v end
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
		   if not sum then sum = v else sum = sum + v end
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

	local sum = nil -- result of reduction
	local params = {
		target = name,
		conditions = { },
		cmp = function(l,r) return l > r end,
		op = function(v) if sum then sum = sum + v else sum = v end end
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
	ACK[name] = val
	new_codec(name, {
                luatype = 'table',
		zentype = 'array'
	}, arr)
end)


local function _extract(tab, ele, root)
   local nr = root or 'nil'
   ZEN.assert(luatype(tab) == 'table', "Object is not a table: "..nr)
   ZEN.assert(ele, "Undefined key or index: "..ele.." in "..nr)
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
	local r = have(root)
	ACK.copy = _extract(r, in1, root)
	if in2 then
	   ACK.copy = _extract(ACK.copy, in2, in1)
	end
	new_codec('copy', nil, root)
end
When("create the copy of '' from dictionary ''", function(name, dict) create_copy_f(dict, name) end)
When("create the copy of '' from ''", function(name, dict) create_copy_f(dict, name) end)
When("create the copy of '' in ''", function(name, dict) create_copy_f(dict, name) end)
When("create the copy of '' in '' in ''", function(obj, branch, root) create_copy_f(root, branch, obj) end)
When("create the copy of object named by '' from dictionary ''", function(name, dict) 
  local label = have(name)
  create_copy_f(dict, label:string())
end)

local function take_out_f(path, dest, format)
	local parr = strtok(uscore(path), '([^.]+)')
	local root = parr[1] -- first
	table.remove(parr, 1)
	if not dest then
	   dest = parr[#parr]
	   table.remove(parr, #parr)
	end
	empty(dest)
	local res = have(root)
	for k,v in pairs(parr) do
	   res = _extract(res, v)
	end
	ACK[dest] = _extract(res, dest)
	if format then
	   new_codec(dest, guess_conversion(ACK[dest], format))
	else
	   new_codec(dest, { encoding = ZEN.CODEC[root].encoding })
	end
end

When("pickup from path ''", function(path)
	take_out_f(path, nil, nil)
end)

When("pickup a '' from path ''", function(format, path)
	take_out_f(path, nil, format)
end)

When("take '' from path ''", function(target, path)
	take_out_f(path, uscore(target), nil)
end)

When("for each dictionary in '' append '' to ''", function(arr, right, left)
	local dicts = have(arr)
	ZEN.assert(luatype(dicts) == 'table', 'Object is not a table: '..arr)
	for kk,vv in pairs(dicts) do
		local l, r
		for k,v in pairs(vv) do
			if k == right then r = v end
			if k == left then l = v end
		end
		ZEN.assert(l, "Object not found: "..kk.."."..left)
		ZEN.assert(r, "Object not found: "..kk.."."..right)
		vv[left] = l..r
	end
end)

local function move_or_copy_in(src_value, src_name, dest)
   local d = have(dest)
   ZEN.assert(luatype(d) == 'table', "Object is not a table: "..dest)
   if ZEN.CODEC[dest].zentype == 'dictionary'
      or ZEN.CODEC[dest].zentype == 'schema' then
      ZEN.assert(not d[src_name], "Dictionary already contains: "..src_name)
      d[src_name] = src_value
      ACK[dest] = d
   elseif ZEN.CODEC[dest].zentype == 'array' then
      table.insert(ACK[dest], src_value)
   else
      ZEN.assert(false, "Invalid destination type: "
		 ..ZEN.CODEC[dest].zentype)
   end
end

When("move named by '' in ''", function(src_name, dest)
	local src = have(src_name):string()
	move_or_copy_in(have(src), src, dest)
	ACK[src] = nil
	ZEN.CODEC[src] = nil
end)

When("move '' in ''", function(src, dest)
	move_or_copy_in(have(src), src, dest)
	ACK[src] = nil
	ZEN.CODEC[src] = nil
end)

When("move '' from '' to ''", function(name, src, dest)
	move_or_copy_in(have({src, name}), name, dest)
	ACK[src][name] = nil
end)

When("copy named by '' in ''", function(src_name, dest)
	local src = have(src_name):string()
	move_or_copy_in(deepcopy(have(src)), src, dest)
end)

When("copy '' in ''", function(src, dest)
	move_or_copy_in(deepcopy(have(src)), src, dest)
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
	ZEN.assert(isdictionary(target) or
		   _is_array_of_dictionaries(t),
		   "Object is nor a dictionary neither an array of dictionaries: "..target)
	local f = have(filters)
	ZEN.assert(isarray(filters), "Object is not an array: "..filters)
	ACK[target] = deepmap(_filter_from, t, f)
end)

