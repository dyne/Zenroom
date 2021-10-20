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
--on Sunday, 11th July 2021
--]]
--- Zencode data internals

-- Used in scenario's schema declarations to cast to zenroom. type
ZEN.get = function(obj, key, conversion, encoding)
   assert(type(key) == 'string', 'ZEN.get key is not a string', 2)
   assert(not conversion or type(conversion) == 'function',
	  'ZEN.get invalid conversion function', 2)
   assert(not encoding or type(encoding) == 'function',
	  'ZEN.get invalid encoding function', 2)
   local k
   if not obj then -- take from IN root
	  -- does not support to pick in WHO (use of 'my')
	  k = IN.KEYS[key] or IN[key]
   else
	  if key == '.' then
		 k = obj
	  else
		 k = obj[key]
	  end
   end
   assert(k, 'Key not found in object conversion: ' .. key, 2)
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
      if encoding then
	 res = encoding(k)
      else
	 res = CONF.input.encoding.fun(k)
      end
      if conversion then
         res = conversion(res)
      end
      goto ok
   end
   if t == 'number' then
      res = k
   end
   if t == 'table' then
      if encoding then
	 res = deepmap(encoding, k)
      else
	 res = deepmap(CONF.input.encoding.fun, k)
      end
      if conversion then
         res = deepmap(conversion, res)
      end
   end
   ::ok::
   assert(
      ZEN.OK and res,
      'ZEN.get on invalid key: ' .. key .. ' (' .. t .. ')', 2)
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
      -- complex schema specfying output conversion as: {import=fun, export=fun}
      local c = fif(luatype(t)=='table', 'complex', CONF.output.encoding.name)
      return ({
         fun = t,
         zentype = 'schema',
         luatype = objtype,
         raw = obj,
         encoding = c
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
      if definition then
         if definition ~= 'number' then
            error('Invalid conversion for number object: '..definition, 2)
         end
      end
      res = input_encoding(objtype)
      res.luatype = 'number'
      res.zentype = 'element'
      if obj > 2147483647 then
         error('Overflow of number object over 32bit signed size', 2)
         -- TODO: maybe support unsigned native here
      end
      res.raw = obj
         -- any type of additional conversion from a native number
         -- detected at input can happen here, for instance using a new
         -- native unsigned integer
      return (res)
   end
   -- definition: value_encoding .. data_type
   -- value_encoding: base64, hex, etc.
   -- data_type: array, dictionary, structure
   if objtype == 'table' then
      local toks = strtok(definition, '[^_]+')
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
   -- carry guessed detection in CODEC
   ZEN.CODEC[guessed.name] = {
      name = guessed.name,
      encoding = guessed.encoding,
      zentype = guessed.zentype,
      luatype = guessed.luatype
   }
   -- TODO: make xxx print to stderr!
   -- xxx('Operating conversion on: '..guessed.name)
   if guessed.zentype == 'schema' then
      -- error('Invalid schema conversion for encoding: '..guessed.encoding, 2)
	  local res = {}
      if guessed.encoding == 'array' then
	 for _,v in pairs(guessed.raw) do
	    table.insert(res, guessed.fun(v))
	 end
	 return(res)
      elseif guessed.encoding == 'dictionary' then
         for k, v in pairs(guessed.raw) do
            res[k] = guessed.fun(v[guessed.schema])
         end
         return (res)	
      elseif guessed.encoding == 'complex' then
	 return guessed.fun.import(guessed.raw)
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
local function outcast_string(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_string(obj)
end
local function outcast_hex(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_hex(obj)
end
local function outcast_base64(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_base64(obj)
end
local function outcast_url64(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_url64(obj)
end
local function outcast_base58(obj)
   local t = luatype(obj)
   if t == 'number' then
      return obj
   end
   return O.to_base58(obj)
end
local function outcast_bin(obj)
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
   if luatype(cast) ~= 'string' then
      error('guess_outcast called with wrong argument: '..type(cast), 3) end
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
   end
   -- try schemas
   local fun = ZEN.schemas[uscore(cast, ' ', '_')]
   if luatype(fun) == 'table' then
      -- complex schema encoding
      assert(luatype(fun.export) == 'function',
		"Guess outcast cannot find schema export")
      return fun.export
   else
      return CONF.output.encoding.fun
   end
   error('Invalid output conversion: ' .. cast, 2)
   return nil
end

-- CODEC format:
-- { name: string,
--   encoding: encoder name string or 'complex' handled by schema
--   zentype:  zencode type: element, array, dictionary or schema
--   luatype:  lua type (string, number, table or userdata) 
-- }
-- TODO: rename to check_output_codec_encoding(v)
function check_codec(value)
   if not ZEN.CODEC then
      return CONF.output.encoding.name
   end
   if not ZEN.CODEC[value] then
      xxx('Object has no CODEC registration: ' .. value)
      return CONF.output.encoding.name
   end
   if ZEN.CODEC[value].zentype == 'schema' then
      if ZEN.CODEC[value].encoding == 'complex' then
	 assert(luatype(ZEN.schemas[value].export) == 'function',
		"Complex export for schema is not a function: "..value)
	 return value -- name of schema itself as it contains export
      else
	 return ZEN.CODEC[value].encoding or CONF.output.encoding.name
      end
   end
   return CONF.output.encoding.name
end

function new_codec(cname, parameters, clone)
   if not cname then error("Missing name in new codec", 2) end
   local name = fif(luatype(cname) == 'string', uscore(cname), cname) -- may be a numerical index
   if not ACK[name] then error("Cannot create codec, object not found: "..name, 2) end
   if ZEN.CODEC[name] then error("Cannot overwrite ZEN.CODEC."..name, 2) end
   local res
   if clone and not ZEN.CODEC[clone] then error("Clone not found in ZEN.CODEC."..clone, 2) end
   if ZEN.CODEC[clone] then
      res = ZEN.CODEC[clone]
      res.name = name
   else
      res = { name = name }
   end
   -- overwrite with paramenters in argument
   if parameters then
	  for k,v in pairs(parameters) do
		 res[k] = v
	  end
   end
   -- detect zentype and luatype
   if not res.luatype then
      res.luatype = luatype(ACK[name])
   end
   if not res.zentype then
      if res.luatype == 'table' then
         if isdictionary(ACK[name]) then
            res.zentype = 'dictionary'
         elseif isarray(ACK[name]) then
            res.zentype = 'array'
         else
            error("Unknown zentype for lua table: "..name, 2)
         end
      else
         res.zentype = type(ACK[name])
      end
   end
   ZEN.CODEC[name] = res
   return(res) -- redundant, should not use return value for efficiency
end

-- Crawls a whole table structure and collects all strings and octets
-- contained in its keys and values. Converts numbers to
-- strings. Structure returned is:
-- { octets = zenroom.octet
--   strings = string }
-- calling function may want to convert all to octet or string
--
-- apply a function on all keys and values of a tree structure
-- uses sorted listing for deterministic order
local function sort_apply(fun,t,...)
   if luatype(fun) ~= 'function' then
	  error("Internal error: apply 1st argument is not a function", 3)
	  return nil end
   -- if luatype(t) == 'number' then
   -- 	  return t end
   if luatype(t) ~= 'table' then
	  error("Internal error: apply 2nd argument is not a table", 3)
	  return nil end
   for k,v in sort_pairs(t) do -- OPTIMIZATION: was sort_pairs
	  if luatype(v) == 'table' then
		 sort_apply(fun,v,...) -- recursion
	  else
		 fun(v,k,...)
	  end
   end
end
function serialize(tab)
   assert(luatype(tab) == 'table', 'Cannot serialize: not a table', 2)
   local octets = OCTET.zero(1)
   local strings = 'K'
   sort_apply(
      function(v, k)
         strings = strings .. tostring(k)
         if iszen(type(v)) then
	    octets = octets .. v:octet()
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

-- eliminate all empty string objects "" and all empty dictionaries
-- (containing only empy objects), uses recursion into tables
function prune(tab)
   assert(luatype(tab) == 'table', 'Cannot prune: not a table', 2)
   local pruned_values = deepmap(function(v)
      if #v == 0 then return nil
      else return v end
   end, tab)
   local function prune_in(ttab)
         local res = { }
         local next = next
         local luatype = luatype
         for k,v in pairs(ttab) do
            if luatype(v) == 'table' then
               if next(v) == nil then
                  res[k] = nil -- {} to nil
               else
                  res[k] = prune_in(v) -- recursion
               end
            else
               res[k] = v
            end
         end
         return setmetatable(res, getmetatable(ttab))
   end
   pruned_tables = prune_in(pruned_values)
   return pruned_tables
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
