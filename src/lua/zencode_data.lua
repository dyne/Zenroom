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
--on Friday, 12th March 2021 1:17:33 pm
--]]

--- Zencode data internals

-- Used in scenario's schema declarations to cast to zenroom. type
ZEN.get = function(obj, key, conversion)
   ZEN.assert(obj, 'ZEN.get no object found')
   ZEN.assert(type(key) == 'string', 'ZEN.get key is not a string')
   ZEN.assert(
      not conversion or type(conversion) == 'function',
      'ZEN.get invalid conversion function'
   )
   local k
   if key == '.' then
      k = obj
   else
      k = obj[key]
   end
   ZEN.assert(k, 'Key not found in object conversion: ' .. key)
   local res = nil
   local t = type(k)
   if iszen(t) and conversion then
      res = conversion(k)
      goto ok
   end
   if iszen(t) and not conversion then
      res = k
      goto ok
   end
   if t == 'string' then
      res = CONF.input.encoding.fun(k)
      if conversion then
         res = conversion(res)
      end
      goto ok
   end
   if t == 'number' then
      res = k
   end
   if t == 'table' then
      res = deepmap(CONF.input.encoding.fun, k)
      if conversion then
         res = deepmap(conversion, res)
      end
   end
   ::ok::
   assert(
      ZEN.OK and res,
      'ZEN.get on invalid key: ' .. key .. ' (' .. t .. ')'
   )
   return res
end

--- Given block (IN read-only memory)
-- @section Given

---
-- Guess how to convert the object, using what format or schema
-- check the definition string (coming straight from zencode)
-- considering the type of the object:
-- ```
-- type    def       conv
-- ------------------------------------------------------
--         schema    schema_f(===, default_encoding)
-- str     format    input_encoding(format)
-- num               input_encoding(number)
-- table   f dict    deepmap(table, input_encoding(f))
-- table   f array   deepmap(table, input_encoding(f))
-- ```
-- returns a table with function pointers and string desc that
-- will be used by @{operate_conversion}
-- { fun         = conversion function pointer
--   conversion  = conversion string description
--   check       = check function pointer
--   raw         = raw data pointer
--   (name)      = key name of data (set externally)
--   (root)      = root section name (set externally)
--   luatype     = type of raw data for lua
--   zentype     = type of data for zenroom (array, dict, element, schema)
-- }
function guess_conversion(obj, definition)
   local t
   local objtype = luatype(obj)
   local res
   -- a defined schema overrides any other conversion
   t = ZEN.schemas[definition]
   if t then
      return ({
         fun = t,
         zentype = 'schema',
         luatype = objtype,
         raw = obj,
         encoding = CONF.output.encoding.name
      })
   end
   if objtype == 'string' then
      if not definition then
         error('Undefined conversion for string object', 2)
         return nil
      end
      res = input_encoding(definition)
      res.luatype = 'string'
      res.zentype = 'element'
      res.raw = obj
      return (res)
   end
   if objtype == 'number' then
      res = input_encoding(objtype)
      res.luatype = 'number'
      res.zentype = 'element'
      res.raw = obj
      return (res)
   end
   -- definition: value_encoding .. data_type
   -- value_encoding: base64, hex, etc.
   -- data_type: array, dictionary, structure
   if objtype == 'table' then
      toks = strtok(definition, '[^_]+')
      if not (#toks > 1) then
         error(
            'Invalid definition: ' ..
               definition ..
                  ' (must be "base64 array" or "string dictionary" etc.)',
            2
         )
         return nil
      end
      local rightmost = #toks
      local leftwords = '' -- concat all left words in toks minus the last
      for i = 1, rightmost - 2 do
         leftwords = leftwords .. toks[i] .. '_'
      end
      leftwords = leftwords .. toks[rightmost - 1] -- no trailing underscore
      -- check if the last word is among zentype collections
      if
         not ((toks[rightmost] == 'array') or
            (toks[rightmost] == 'dictionary'))
       then
         error(
            'Invalid table type: ' ..
               toks[rightmost] .. ' (must be array or dictionary)',
            2
         )
         return nil
      end
      -- schema type in array or dict
      t = ZEN.schemas[leftwords]
      if t then
         return ({
            fun = t,
            zentype = 'schema',
            schema = leftwords,
            luatype = objtype,
            raw = obj,
            encoding = toks[rightmost]
         })
      end
      -- normal type in input encoding
      res = input_encoding(leftwords)
      if res then
         res.luatype = 'table'
         res.zentype = toks[rightmost] -- zentypes couples with table
         res.raw = obj
         return (res)
      end
      error(
         'Invalid ' .. toks[rightmost] .. ' encoding: ' .. leftwords,
         2
      )
      return nil
   end
   error(
      'Invalid conversion for type ' .. objtype .. ': ' .. definition,
      2
   )
   return nil
end

-- takes a data object and the guessed structure, operates the
-- conversion and returns the resulting raw data to be used inside the
-- WHEN block in HEAP.
function operate_conversion(guessed)
   if not guessed.fun then
      error('No conversion operation guessed', 2)
      return nil
   end
   -- TODO: make xxx print to stderr!
   -- xxx('Operating conversion on: '..guessed.name)
   if guessed.zentype == 'schema' then
      -- error('Invalid schema conversion for encoding: '..guessed.encoding, 2)
      if guessed.encoding == 'array' or guessed.encoding == 'dictionary' then
         local res = {}
         for k, v in pairs(guessed.raw) do
            res[k] = guessed.fun(v[guessed.schema])
         end
         return (res)
      else
         return guessed.fun(guessed.raw)
      end
   elseif guessed.luatype == 'table' then
      -- TODO: better error checking on deepmap?
      if luatype(guessed.check) == 'function' then
         deepmap(guessed.check, guessed.raw)
      end
      return deepmap(guessed.fun, guessed.raw)
   else -- object
      if guessed.check then
         guessed.check(guessed.raw)
      end
      return guessed.fun(guessed.raw)
   end
end

-- Octet to string encoding conversion mechanism: takes the name of
-- the encoding and returns the function. Octet is a first class
-- citizen in Zenroom therefore all WHEN/ACK r/w HEAP types can be
-- converted by its methods.
function outcast_string(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_string(obj)
end
function outcast_hex(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_hex(obj)
end
function outcast_base64(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_base64(obj)
end
function outcast_url64(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_url64(obj)
end
function outcast_base58(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_base58(obj)
end
function outcast_bin(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_bin(obj)
end
-- takes a string returns the function, good for use in deepmap(fun,table)
function guess_outcast(cast)
   if not cast then
      error('guess_outcast called with nil argument', 2)
   end
   if cast == 'string' then
      return outcast_string
   elseif cast == 'hex' then
      return outcast_hex
   elseif cast == 'base64' then
      return outcast_base64
   elseif cast == 'url64' then
      return outcast_url64
   elseif cast == 'base58' then
      return outcast_base58
   elseif cast == 'bin' then
      return outcast_bin
   elseif cast == 'binary' then
      return outcast_bin
   elseif cast == 'number' then
      -- in case is a schema then outcast uses default output encoding
      return (function(v)
         return (v)
      end)
   elseif ZEN.schemas[string.gsub(cast, ' ', '_')] then
      return CONF.output.encoding.fun
   else
      error('Invalid output conversion: ' .. cast, 2)
      return nil
   end
end

function check_codec(value)
   if not ZEN.CODEC then
      return CONF.output.encoding.name
   end
   if not ZEN.CODEC[value] then
      xxx('Object has no CODEC registration: ' .. value)
      return CONF.output.encoding.name
   end
   if ZEN.CODEC[value].zentype == 'schema' then
      return CONF.output.encoding.name
   else
      return ZEN.CODEC[value].encoding or CONF.output.encoding.name
   end
   return CONF.output.encoding.name
end

-- Crawls a whole table structure and collects all strings and octets
-- contained in its keys and values. Converts numbers to
-- strings. Structure returned is:
-- { octets = zenroom.octet
--   strings = string }
-- calling function may want to convert all to octet or string
function serialize(tab)
   assert(luatype(tab) == 'table', 'Cannot serialize: not a table', 2)
   local octets = OCTET.zero(1)
   local strings = 'K'
   sort_apply(
      function(v, k)
         strings = strings .. tostring(k)
         local t = type(v)
         if iszen(t) then
            if t == 'zenroom.octet' then
               octets = octets .. v
            else
               octets = octets .. v:octet()
            end
         else -- number
            strings = strings .. tostring(v)
         end
      end,
      tab
   )
   return {
      octets = octets,
      strings = strings
   }
end

---
-- Compare equality of two data objects (TODO: octet, ECP, etc.)
-- @function ZEN:eq(first, second)

---
-- Check that the first object is greater than the second (TODO)
-- @function ZEN:gt(first, second)

---
-- Check that the first object is lesser than the second (TODO)
-- @function ZEN:lt(first, second)

--- Then block (OUT write-only memory)
-- @section Then

---
-- Move a generic data structure from ACK to OUT memory space, ready
-- for its final JSON encoding and print out.
-- @function ZEN:out(name)

---
-- Move 'my own' data structure from ACK to OUT.whoami memory space,
-- ready for its final JSON encoding and print out.
-- @function ZEN:outmy(name)

---
-- Convert a data object to the desired format (argument name provided
-- as string), or use CONF.encoding when called without argument
--
-- @function export_obj(object, format)
-- @param object data element to be converted
-- @param format pointer to a converter function
-- @return object converted to format
local function export_arr(object, format)
   ZEN.assert(
      iszen(type(object)),
      'export_arr called on a ' .. type(object)
   )
   local conv_f = nil
   local ft = type(format)
   if format and ft == 'function' then
      conv_f = format
      goto ok
   end
   if format and ft == 'string' then
      conv_f = output_encoding(format).fun
      goto ok
   end
   if not CONF.output.encoding then
      error('CONF.output.encoding is not configured', 2)
   end
   conv_f = CONF.output.encoding.fun -- fallback to configured conversion function
   ::ok::
   ZEN.assert(
      type(conv_f) == 'function',
      'export_arr conversion function not configured'
   )
   return conv_f(object) -- TODO: protected call? deepmap?
end
function export_obj(object, format)
   -- CONF { encoding = <function 1>,
   --        encoding_prefix = "u64"  }
   ZEN.assert(object, 'export_obj object not found')
   if type(object) == 'table' then
      local tres = {}
      for k, v in ipairs(object) do -- only flat tables support recursion
         table.insert(tres, export_arr(v, format))
      end
      return tres
   end
   return export_arr(object, format)
end
