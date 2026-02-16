--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--Last modified by Denis Roio
--on Friday, 12th November 2021
--]]

local J = require('json')


J.decode = function(data)
   if not data then error("JSON.decode called without argument", 2) end
   if luatype(data) ~= "string" then error("JSON.decode argument of unsopported type: "..luatype(data), 2) end
   if #data < 2 then error("JSON.decode argument is empty string", 2) end
   local right = tostring(data)
   local left
   local tmp
   local ok, decoded = pcall(JSON.raw_decode, right)
   if ok then
      if luatype(decoded) ~= 'table' then
         error("JSON decode has not returned a table", 2)
      end
      return decoded
   end
   local res = {}
   while right and right ~= "" do
      left, right = jsontok(right) -- function in zen_parser.c
      if not left then
         error("JSON decode input is not a encoded table", 2)
         break
      end
      tmp = JSON.raw_decode(left)
      if luatype(tmp) == 'table' then
            for k,v in pairs(tmp) do
               res[k] = v
            end
      else
         error("JSON decode has not returned a table", 2)
      end
   end
   return res
end

J.encode = function(tab,enc,whitespace)
   -- tab not a table
   if luatype(tab) ~= 'table' then
    error("JSON encode input is not a table", 2)
   end
   return
      JSON.raw_encode(
	 -- process encodes zencode types
	 -- it is part of inspect.lua
	 INSPECT.process(tab, enc or CONF.output.encoding.name),
	 whitespace
      )
end


-- generate a serialized url64(JSON) encoded octet string of any object
-- @param any the object to serialize
-- @return octet which should be printed as string
J.serialize = function(any)
    if luatype(any) == 'table' then
        return (
            O.from_string
            (O.to_url64
             (O.from_string
              (JSON.encode
               (deepmap
                (function(o)
                        local t <const> = type(o)
                        if t == 'boolean' or t == 'zenroom.time' then
                            return(o)
                        elseif iszen(t) then
                            return O.to_string(o:octet())
                        else
                            return(tostring(o))
                        end
                end,any))
              )
             )
            )
        )
    else
        if not iszen(type(any)) then
            error("JSON serialize called with wrong argument type: "
                  ..type(any),2)
        end
        if #any == 0 then return O.from_string('') end
        return O.from_string(O.to_url64(any:octet()))
    end
end

-- generate a de-serialized object from
-- any serialized octet
-- @param jws the object to serialize
-- @return object which can be also a table
J.deserialize = function(any)
    if not iszen(type(any)) then
        error("JOSE deserialize called with wrong argument type: "
              ..type(any),2)
    end
    local u <const> = O.from_url64(O.to_string(any))
    local s <const> = O.to_string(u)
    local ok, decoded = pcall(JSON.decode, s)
    if ok then return decoded end
    return(u)
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

-- validate a JSON
-- @param input string encoded json
-- @return status: true if input was valid json, false otherwise
-- @return value: error in case status is false, table if status is true
J.validate = function(input)
    local ok, res = pcall(JSON.raw_decode, input)
    if ok then return true, res end
    return pcall(JSON.decode, input)
end

return J
