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



--- Zencode data internals

-- the main security concern in this Zencode module is that no data
-- passes without validation from IN to ACK or from inline input.


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
   ZEN.assert(obj, "ZEN.get no object found")
   ZEN.assert(type(key) == "string", "ZEN.get key is not a string")
   ZEN.assert(not conversion or type(conversion) == 'function',
			  "ZEN.get invalid conversion function")
   local k = obj[key]
   ZEN.assert(k, "Key not found in object conversion: "..key)
   local res = nil
   local t = type(k)
   if iszen(t) and conversion then res = conversion(k) goto ok end
   if iszen(t) and not conversion then res = k goto ok end
   if t == 'string' and conversion == str then res = k goto ok end
   if t == 'string' and conversion and conversion ~= str then
	  res = conversion(ZEN:import(k)) goto ok end
   if t == 'string' and not conversion then res = ZEN:import(k) goto ok end
   ::ok::
   assert(ZEN.OK and res)
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

-- basic encoding schemas
ZEN.add_schema({
	  base64 = function(obj) return ZEN:convert(obj, OCTET.from_base64) end,
	  url64  = function(obj) return ZEN:convert(obj, OCTET.from_url64)  end,
	  str =    function(obj) return ZEN:convert(obj, OCTET.from_string) end,
	  secret = function(obj) return ZEN:import(obj) end
})

-- refer basic scenario implementations for data
require_once('zencode_given')
require_once('zencode_when')
require_once('zencode_then')

-- debug functions
Given("debug", function() ZEN.debug() end)
When("debug",  function() ZEN.debug() end)
Then("debug",  function() ZEN.debug() end)
