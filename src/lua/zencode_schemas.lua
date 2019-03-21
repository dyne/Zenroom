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

ZEN.get = function(conv, obj, key)
   ZEN.assert(type(key) == "string", "Invalid key in object conversion")
   ZEN.assert(obj, "Object not found for conversion")
   ZEN.assert(obj[key], "Key not found in object conversion: "..key)
   local res
   if conv then res = conv(obj[key])
   else res = obj[key] end
   assert(res, "Error converting object key: ".. key)
   return res
end

function import(obj, sname)
   ZEN.assert(sname, "Import error: schema is nil")
   ZEN.assert(obj, "Import error: obj is nil ("..sname..")")
   local s = ZEN.schemas[sname]
   ZEN.assert(s ~= nil, "Import error: schema not found '"..sname.."'")
   return s.import(obj)
end
function export(obj, sname, conv)
   ZEN.assert(obj, "Export error: obj is nil")
   ZEN.assert(type(sname) == "string", "Export error: invalid schema string")
   ZEN.assert(type(conv) == "function", "Export error: invalid conversion function")
   local s = ZEN.schemas[sname]
   ZEN.assert(s ~= nil, "Export error: schema not found '"..sname.."'")
   local out = s.export(obj, conv)
   ZEN.assert(out, "Export error: returned nil for schema '"..sname.."'")
   out.encoding = 'hex' -- hardcoded
   out.curve = 'bls383'
   out.schema = sname
   out.zenroom = VERSION
   return out
end
