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

local J = require('json')


-- automatic conversion to string using prefix (for use in JSON.decode)
function J.autoconv(data)
   local t = type(data)
   if(t == "string") and data ~= "" then
	  if string.sub(data,1,3) == 'u64' and O.is_url64(data) then
		 -- return decoded string format for JSON.decode
		 return O.from_url64(data):string()
	  else -- its already a string
		 return data
	  end
   elseif iszen(t) then
	  return data:str()
   else
	  error("JSON.autoconf failed "..t.." conversion")
   end
end

J.decode = function(str)
   assert(str,      "JSON.decode error decoding nil string")
   -- assert(str ~= "","JSON.decode error decoding empty string")
   -- assert(type(str) == "string", "JSON.decode error unsopported type: "..type(str))
   local t = JSON.raw_decode(JSON.autoconv(str))
   assert(t, "JSON.decode error decoding type: "..type(str))
   -- fixes strange behavior of tables returned
   -- second value returned should be used
   -- first one becomes a string after first transformation
   -- TODO: investigate this behavior
   return t,t
end

J.encode = function(tab)
   return
	  JSON.raw_encode(
		 -- process encodes zencode types
		 I.process(tab)
	  )
   -- return JSON.raw_encode(tab)
end

return J
