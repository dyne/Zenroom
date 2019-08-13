-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
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

-- Zencode data schemas for validation

-- init schemas
ZEN.add_schema = function(arr)
   -- TODO: check overwrite / duplicate as this will avoid scenarios
   -- to have namespace clashes
   for k,v in pairs(arr) do
	  ZEN.schemas[k] = v
   end
end

-- TODO: return the prefix of an encoded string if found
ZEN.prefix = function(str)
   t = type(str)
   if t ~= "string" then return nil end
   if str:sub(4,4) ~= ":" then return nil end
   return str:sub(1,3)
end

ZEN.get = function(obj, key, conversion)
   local conv = conversion or CONF.encoding
   ZEN.assert(type(key) == "string", "Invalid key in object conversion")
   ZEN.assert(obj, "Object not found for conversion")
   local k = obj[key]
   ZEN.assert(k, "Key not found in object conversion: "..key)
   local res
   if(type(k) == "string") then
	  -- ZEN.assert(ZEN.prefix(obj[key]), "Encoding prefix missing in conversion: "..key)
	  res = conv(k)
	  ZEN.assert(conv(k), "Error converting object key: ".. key)
   else res = k end
   assert(ZEN.OK)
   return res
end


-- import function to have recursion of nested data structures
-- according to their stated schema
function ZEN:valid(sname, obj)
   ZEN.assert(sname, "Import error: schema name is nil")
   ZEN.assert(obj, "Import error: object is nil '"..sname.."'")
   local s = ZEN.schemas[sname]
   ZEN.assert(s, "Import error: schema not found '"..sname.."'")
   ZEN.assert(type(s) == 'function', "Import error: schema is not a function '"..sname.."'")
   return s(obj)
end
