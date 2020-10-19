-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2020 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- array operations

local function check_container(name)
   ZEN.assert(ACK[name], "Invalid container, not found: "..name)
   ZEN.assert(luatype(ACK[name]) == 'table', "Invalid container, not a table: "..name)
   ZEN.assert(ZEN.CODEC[name].zentype ~= 'element', "Invalid container: "..name.." is a "..ZEN.CODEC[name].zentype)
end

local function check_element(name)
   local o = ACK[name]
   ZEN.assert(o, "Invalid element, not found: "..name)
   ZEN.assert(iszen(type(o)), "Invalid element, not a zenroom object: "..name)
   ZEN.assert(ZEN.CODEC[name].zentype == 'element', "Invalid element: "..name.." is a "..ZEN.CODEC[name].zentype)
   return o
end

local function _when_remove(ele, from)
		check_container(from)
        local found = false
		local obj = ACK[ele]
		local newdest = { }
        if not obj then -- inline key name (string) requires dictionary
           ZEN.assert(ZEN.CODEC[from].zentype ~= 'dictionary', "Element "..ele.." not found and target "..from.." is not a dictionary")
           ZEN.assert(ACK[from][ele], "Key not found: "..ele.." in dictionary "..from)
           ACK[from][ele] = nil -- remove from dictionary
           found = true
        else
           -- remove value of element from array
           ZEN.assert(ZEN.CODEC[from].zentype == 'array', "Element "..ele.." found and target "..from.." is not an array")
		   check_element(ele)
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

When("insert '' in ''", function(ele, dest)
		ZEN.assert(ACK[dest], "Invalid destination, not found: "..dest)
        ZEN.assert(luatype(ACK[dest]) == 'table', "Invalid destination, not a table: "..dest)
        ZEN.assert(ZEN.CODEC[dest].zentype ~= 'element', "Invalid destination, not a container: "..dest)
        ZEN.assert(ACK[ele], "Invalid insertion, object not found: "..ele)
        if ZEN.CODEC[dest].zentype == 'array' then
           table.insert(ACK[dest], ACK[ele])
        elseif ZEN.CODEC[dest].zentype == 'dictionary' then
           ACK[dest][ele] = ACK[ele]
		else
		   ZEN.assert(false, "Invalid destination type: "..ZEN.CODEC[dest].zentype)
        end
		ZEN.CODEC[dest][ele] = ZEN.CODEC[ele]
end)

-- When("insert the '' in ''", function(ele,arr)
--     ZEN.assert(ACK[ele], "Element not found: "..ele)
--     ZEN.assert(ACK[arr], "Array not found: "..arr)
-- 	ZEN.assert(ZEN.CODEC[arr].zentype == 'array',
-- 			   "Object is not an array: "..arr)
--     table.insert(ACK[arr], ACK[ele])
-- end)

When("the '' is not found in ''", function(ele, arr)
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

When("the '' is found in ''", function(ele, arr)
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
