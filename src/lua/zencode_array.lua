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

local function _when_remove(ele, from)
		check_container(from)
        local found = false
		local obj = ACK[ele]
		local newdest = { }
        if not obj then -- inline key name (string) requires dictionary
		   if ZEN.CODEC[from] then
			  ZEN.assert(
				 (ZEN.CODEC[from].zentype ~= 'dictionary')
				 or
				 (ZEN.CODEC[from].zentype ~= 'schema')
				 , "Element "..ele.." not found and target "
				 ..from.." is not a dictionary")
		   else
			  xxx("Object has no CODEC registration: "..from)
		   end
           ZEN.assert(ACK[from][ele], "Key not found: "..ele.." in dictionary "..from)
           ACK[from][ele] = nil -- remove from dictionary
           found = true
        else
           -- remove value of element from array
		   if ZEN.CODEC[from] then
			  ZEN.assert(ZEN.CODEC[from].zentype == 'array', "Element "..ele.." found and target "..from.." is not an array")
		   else
			  xxx("Object has no CODEC registration: "..from)
		   end
		   -- check_element(ele)
           local tempp = ACK[from]
           for k,v in next,tempp,nil do
              if not (v == obj) then
                 table.insert(newdest,v)
              else
                 found = true
              end
           end
        end
        ZEN.assert(found, "Element to be removed not found in array")
        ACK[from] = newdest
end
When("remove '' from ''", function(ele,from) _when_remove(ele, from) end)
When("remove the '' from ''", function(ele,from) _when_remove(ele, from) end)

When("create the new array", function()
		ACK.new_array = { }
		ZEN.CODEC.new_array = new_codec('new array',
										{ encoding = CONF.output.encoding.name,
										  zentype = 'array',
										  luatype = 'table' })
end)

When("create the length of ''", function(arr)
	local obj = have(arr)
	ZEN.assert(luatype(obj) == 'table', "Not a table: "..arr)
	ACK.length = #obj
	ZEN.CODEC.length = new_codec('length', { luatype = 'number' })
end)

When("create the copy of element '' in array ''", function(pos, arr)
		ZEN.assert(ACK[arr], "No array found in: "..arr)
		ZEN.assert(isarray(ACK[arr]), "Not an array: "..arr)
		local num = tonumber(pos)
		ZEN.assert(num, "Argument is not a position number: "..pos)
		ZEN.assert(ACK[arr][num], "No element found in: "..arr.."["..pos.."]")
		ACK.copy = ACK[arr][num]
		-- TODO: support nested arrays or dictionaries
		ZEN.CODEC.copy = new_codec('copy',nil,arr)
end)

When("insert '' in ''", function(ele, dest)
		ZEN.assert(ACK[dest], "Invalid destination, not found: "..dest)
        ZEN.assert(luatype(ACK[dest]) == 'table', "Invalid destination, not a table: "..dest)
        ZEN.assert(ZEN.CODEC[dest].zentype ~= 'element', "Invalid destination, not a container: "..dest)
        ZEN.assert(ACK[ele], "Invalid insertion, object not found: "..ele)
        if ZEN.CODEC[dest].zentype == 'array' then
           table.insert(ACK[dest], ACK[ele])
        elseif ZEN.CODEC[dest].zentype == 'dictionary' then
           ACK[dest][ele] = ACK[ele]
        elseif ZEN.CODEC[dest].zentype == 'schema' then
           ACK[dest][ele] = ACK[ele]
		else
		   ZEN.assert(false, "Invalid destination type: "..ZEN.CODEC[dest].zentype)
        end
		ZEN.CODEC[dest][ele] = ZEN.CODEC[ele]
		ACK[ele] = nil
		ZEN.CODEC[ele] = nil
end)

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
	ZEN.assert( luatype(num) == 'number', "Not a number: "..times)
	local list = have(arr)
	ZEN.assert( luatype(list) == 'table', "Not a table: "..arr)
	ZEN.assert( isarray(list), "Not an array: "..arr)
	local found = 0
	for _,v in pairs(list) do
		if v == obj then found = found + 1 end
	end
	ZEN.assert(found >= num, "Object "..ele.." found only "..found.." times instead of "..num.." in array "..arr)
end)
