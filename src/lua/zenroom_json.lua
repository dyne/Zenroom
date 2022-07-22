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
--on Friday, 12th November 2021
--]]

local J = require('json')


J.decode = function(data)
   if not data then error("JSON.decode called without argument", 2) end
   if #data < 2 then error("JSON.decode argument is empty string", 2) end
   if luatype(data) ~= "string" then error("JSON.decode argument of unsopported type: "..luatype(data), 2) end
   local res = {}
   local right = tostring(data)
   local left
   local tmp
   while right do
      left, right = jsontok(right) -- function in zen_parser.c
      if not left then break end
      tmp = JSON.raw_decode(left)
      if luatype(tmp) == 'table' then
            for k,v in pairs(tmp) do
               -- adds all unnamed array elements into 'array'
               if luatype(k)=='number' then
                  res.array = fif(res.array, res.array, {})
                  table.insert(res.array, v)
               else
                  res[k] = v
               end
            end
      else
         error("JSON decode has not returned a table", 2)
      end
   end
   return res
end

J.encode = function(tab,enc)
   return
      JSON.raw_encode(
	 -- process encodes zencode types
	 -- it is part of inspect.lua
	 INSPECT.process(tab, enc or CONF.output.encoding.name)
      )
end

J.auto = function(obj)
   local t = type(obj)
   if t == 'table' then
	  -- export table to JSON
	  return JSON.encode(obj)
   elseif t == 'string' then
	  -- import JSON string to table
	  return JSON.decode(obj)
   else
	  error("JSON.auto unrecognised input type: "..t, 3)
	  return nil
   end
end

return J
