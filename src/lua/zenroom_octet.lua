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
   elseif iszen(t) then return data:octet():hex() -- any zenroom type to octet
   end
end
function str(data)
   local t = type(data)
   if(t == "string") and data ~= "" then
	  if OCTET.is_url64(data) then
		 -- return decoded string format for JSON.decode
		 return OCTET.from_url64(data):str()
	  elseif OCTET.is_base64(data) then
		 -- return decoded string format for JSON.decode
       return OCTET.from_base64(data):str()
      elseif OCTET.is_base58(data) then
         -- return decoded string format for JSON.decode
         return OCTET.from_base58(data):str()
	  elseif OCTET.is_hex(data) then
		 -- return decoded string format for JSON.decode
		 return OCTET.from_hex(data):str()
	  elseif OCTET.is_bin(data) then
		 -- return decoded string format for JSON.decode
		 return OCTET.from_bin(data):str()
	  else -- its already a string (we suppose, this is not deterministic)
		 return data
	  end
   elseif iszen(t) then
	  return data:octet():str()
   else
	  error("automatic str() conversion failed for type: "..t)
   end
end

function bin(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_bin(data) then return O.from_bin(data)
	  else return O.from_str(data):bin() end
   elseif(t == "number") then return data
   elseif(t == "table") then return data
   elseif iszen(t) then return data:octet():bin() -- any zenroom type to octet
   end
end
function base64(data)
   if not data then error("Internal data conversion on nil",2) end
   local t = type(data)
   if(t == "string") then
	  if O.is_base64(data) then return O.from_base64(data)
	  else return O.from_str(data):base64() end
   elseif(t == "number") then return data
   elseif(t == "table") then return data
   elseif iszen(t) then return data:octet():base64() -- any zenroom type to octet
   end
end
function url64(data)
   if not data then error("Internal data conversion on nil",2) end
   local t = type(data)
   if(t == "string") then
	  if O.is_url64(data) then return O.from_url64(data)
	  else return O.from_str(data):url64() end
   elseif(t == "number") then return data
   elseif(t == "table") then return data
   elseif iszen(t) then return data:octet():url64() -- any zenroom type to octet
   end
end
function base58(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_base58(data) then return O.from_base58(data)
	  else return O.from_str(data):base58() end
   elseif iszen(t) then return data:octet():base58() -- any zenroom type to octet
   end
end

return octet
