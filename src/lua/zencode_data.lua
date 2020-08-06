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

-- Used in scenario's schema declarations to cast to zenroom. type
ZEN.get = function(obj, key, conversion)
   ZEN.assert(obj, "ZEN.get no object found")
   ZEN.assert(type(key) == "string", "ZEN.get key is not a string")
   ZEN.assert(not conversion or type(conversion) == 'function',
			  "ZEN.get invalid conversion function")
   local k
   if key == "." then
      k = obj
   else
      k = obj[key]
   end
   ZEN.assert(k, "Key not found in object conversion: "..key)
   local res = nil
   local t = type(k)
   if iszen(t) and conversion then res = conversion(k) goto ok end
   if iszen(t) and not conversion then res = k goto ok end
   if t == 'string' then
      res = CONF.input.encoding.fun(k)
      if conversion then res = conversion(res) end
      goto ok
   end
   if t == 'number' then res = k end
   if t == 'table' then
	  res = deepmap(CONF.input.encoding.fun, k)
	  if conversion then res = deepmap(conversion, res) end
   end
   ::ok::
   assert(ZEN.OK and res, "ZEN.get on invalid key: "..key.." ("..t..")")
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

--- Given block (IN read-only memory)
-- @section Given

---
-- Declare 'my own' name that will refer all uses of the 'my' pronoun
-- to structures contained under this name.
--
-- @function ZEN:Iam(name)
-- @param name own name to be saved in WHO
function ZEN:Iam(name)
   if name then
	  ZEN.assert(not WHO, "Identity already defined in WHO")
	  ZEN.assert(type(name) == "string", "Own name not a string")
	  WHO = name
   else
	  ZEN.assert(WHO, "No identity specified in WHO")
   end
   assert(ZEN.OK)
end

---
-- Guess how to convert the object, using what format or schema
-- check the definition string (coming straight from zencode)
-- considering the type of the object:
-- ```
-- type    def       conv
-- ------------------------------------------------------
-- str     ===       default_encoding
-- str     format    input_encoding(format)
-- str     schema    schema_f(..., default_encoding)
-- num     (number)  num
-- table   ===       deepmap(table, default_encoding)
-- table   format    deepmap(table, input_encoding(format))
-- table   schema    schema_f(table, default_encoding)
-- ```
-- returns a table with function pointers and string desc that
-- will be used by operate conversion
-- { fun   = conversion function pointer
--   name  = conversion string description 
--   check = check function pointer
--   istable = true -- if deepmap required
--   isschema = true -- if schema function required
-- }
function guess_conversion(objtype, definition)
   definition = definition or CONF.input.encoding.name
   -- assert(definition, "Internal error: guess_conversion needs 2 arguments", 2)
   local res = { }
   local t
   -- ZEN.schemas is the other map to check
   if objtype == 'string' then
       t = input_encoding(definition)
       -- t = { name, fun, check}
       if t then
         res = { name = t.name,
               fun = t.fun,
               check = t.check }
       else
         t = ZEN.schemas[definition]
         -- t = function pointer
         if t then
            res = { fun = t,
                  isschema = true,
                  name = definition } -- also t.name
                  -- check = nil
         end
      end
		if not res then
			error('String conversion not found: '..definition, 2)
			return nil
		end
      res.istable = nil -- no deepmap for single string
      
   elseif objtype == 'number' then
      res = input_encoding(objtype)

   elseif objtype == 'table' then
		t = input_encoding(definition)
      if t then
         res = { istable = true,
               name = t.name,
               fun = t.fun,
               check = t.check }
         -- isschema = nil
      else
         t = ZEN.schemas[definition]
         if t then
            res = { fun = t,
                  isschema = true,
                  name = definition }
         end
      end
      if not res then
			error('Table conversion not found: '..definition, 2)
			return nil
      end
   else
	  error('Unrecognized object type when guessing conversion: '..objtype,2)
	  return nil
   end
   return res
end

-- takes a data object and the guessed structure, operates the
-- conversion and returns the resulting raw data to be used inside the
-- WHEN block in HEAP.
function operate_conversion(data, guessed)
   if not guessed.fun then
	  error('No conversion operation guessed: '..guessed.name, 2)
	  return nil
   end
   -- TODO: make xxx print to stderr!
   -- xxx('Operating conversion on: '..guessed.name)
   if guessed.istable then
     -- TODO: better error checking on deepmap?
      if luatype(guessed.check) == 'function' then
         deepmap(guessed.check, data)
      end
      return deepmap(guessed.fun, data)
   elseif guessed.isschema then
	   return guessed.fun(data)
   else
	   if luatype(guessed.check) == 'function' then
         guessed.check(data)
      end
      return guessed.fun(data)      
	end
end

local function save_array_codec(n)
	local toks = strtok(n)
	if toks[2] == 'array' then

   else
      return nil
   end
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
   ZEN.assert(iszen(type(object)), "export_arr called on a ".. type(object))
   local conv_f = nil
   local ft = type(format)
   if format and ft == 'function' then conv_f = format goto ok end
   if format and ft == 'string' then conv_f = output_encoding(format).fun goto ok end
   conv_f = CONF.output.encoding.fun -- fallback to configured conversion function
   ::ok::
   ZEN.assert(type(conv_f) == 'function' , "export_arr conversion function not configured")
   return conv_f(object) -- TODO: protected call? deepmap?
end
function export_obj(object, format)
   -- CONF { encoding = <function 1>,
   --        encoding_prefix = "u64"  }
   ZEN.assert(object, "export_obj object not found")
   if type(object) == 'table' then
	  local tres = { }
	  for k,v in ipairs(object) do -- only flat tables support recursion
		 table.insert(tres, export_arr(v, format))
	  end
	  return tres
   end
   return export_arr(object, format)
end
