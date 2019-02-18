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

schema = require 'schema'

-- aliases for back compat with camelcase
schema['function'] = schema.Function
schema.boolean = schema.Boolean
schema['nil'] = schema.Nil
schema.number = schema.Number
schema.string = schema.String
schema.table = schema.Table
schema.userdata = schema.UserData
-- functs
schema.record = schema.Record
schema.check =  schema.CheckSchema
schema.oneof = schema.OneOf
schema.print = schema.FormatOutput
-- zenroom specific typecheckers
schema.octet = schema.OCTET
schema.big = schema.BIG
schema.int = schema.BIG
schema.INT = schema.BIG
schema.ecp = schema.ECP
schema.ecp2 = schema.ECP2

-- content encapsulation types
function ByteSchema(obj, path, enc)
   if type(obj) ~= "string" then
	  return schema.Error("Type mismatch: '"..path.."' should be a string, is "..type(obj), path)
   end
   -- assume previous initialization of OCTET global
   if OCTET["is_"..enc](obj) then return nil -- success
   else
	  return schema.Error("Type mismatch: '"..path.."' should be a "..enc.." encoded string", path)
   end
end
schema.base64 = function(obj, path) return ByteSchema(obj, path, 'base64') end
schema.base58 = function(obj, path) return ByteSchema(obj, path, 'base58') end
schema.hex =    function(obj, path) return ByteSchema(obj, path, 'hex')    end
schema.bin =    function(obj, path) return ByteSchema(obj, path, 'bin')    end

-- TODO: do a schema.pipe() that pipes through transformations
-- (encoding, typecheck and EC checks) to validate using a serialized
-- list of functions

return schema
