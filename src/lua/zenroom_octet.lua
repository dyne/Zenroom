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

local octet = require'octet'

--- implicit convertion functions going both ways
-- if input is an encoded string, will become an octet
-- if input is a non-encoded string, it will become a base64 string
-- if input is an octet, will become an encoded string
function hex(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_hex(data) then return O.from_hex(data)
	  else return O.from_str(data):hex() end
   elseif(t == "number") then return data
   elseif(t == "table") then return data
   elseif(t == "zenroom.octet") then return data:hex()
   elseif iszen(t) then return data:octet():hex() -- any zenroom type to octet
   end
end
function str(data)
   if    (type(data) == "string")        then return octet.from_string(data)
   elseif(type(data) == "zenroom.octet") then return data:string()
   end
end
function bin(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_bin(data) then return O.from_bin(data)
	  else return O.from_str(data):bin() end
   elseif(t == "number") then return data
   elseif(t == "table") then return data
   elseif(t == "zenroom.octet") then return data:bin()
   elseif iszen(t) then return data:octet():bin() -- any zenroom type to octet
   end
end
function base64(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_base64(data) then return O.from_base64(data)
	  else return O.from_str(data):base64() end
   elseif(t == "number") then return data
   elseif(t == "table") then return data
   elseif(t == "zenroom.octet") then return data:base64()
   elseif iszen(t) then return data:octet():base64() -- any zenroom type to octet
   end
end
function url64(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_url64(data) then return O.from_url64(data)
	  else return O.from_str(data):url64() end
   elseif(t == "number") then return data
   elseif(t == "table") then return data
   elseif(t == "zenroom.octet") then return data:url64()
   elseif iszen(t) then return data:octet():url64() -- any zenroom type to octet
   end
end
function base58(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_base58(data) then return O.from_base58(data)
	  else return O.from_str(data):base58() end
   elseif(t == "zenroom.octet") then return data:base58()
   elseif iszen(t) then return data:octet():base58() -- any zenroom type to octet
   end
end

-- serialize an array containing any type of cryptographic numbers
octet.serialize = function(arr)
   concat = O.new()
   map(arr,function(e)
		  t = type(e)
		  -- supported lua native types
		  if(t == "string") then concat = concat .. str(e) return
		  elseif not iszen(t) then
			 error("OCTET.serialize: unsupported type: "..t)
		  end
		  if(t == "zenroom.octet") then
			 concat = concat .. e
		  elseif(t == "zenroom.big"
				 or
				 t == "zenroom.ecp"
				 or
				 t == "zenroom.ecp2") then
			 concat = concat .. e:octet()
		  else
			 error("OCTET.serialize: unsupported zenroom type: "..t)
		  end
   end)
   return concat
end

function zero(len)    return octet.new(len):zero(len) end

return octet
