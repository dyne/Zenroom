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
 --on Saturday, 13th November 2021
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
	   k = KIN[key] or IN[key]
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

-- return leftmost and rightmost if definition string indicates
-- a lua table: dictionary, array or schema
local function expect_table(definition)
   local toks = strtok(definition, '[^_]+')
   local res = { rightmost = toks[#toks] }
   if res.rightmost == 'array'
      or
      res.rightmost == 'dictionary'
   then
      res.leftwords = '' -- concat all left words in toks minus the last
       for i = 1, #toks - 2 do
	  res.leftwords = res.leftwords .. toks[i] .. '_'
       end
       res.leftwords = uscore( res.leftwords .. toks[#toks - 1] )
       -- no trailing underscore
      return res
   end
   -- schemas may or may be not tables
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
    if not definition then
       error("Cannot take undefined object, found a "..type(obj), 3)
    end
    -- a defined schema overrides any other conversion
    t = ZEN.schemas[definition]
    if t then
       -- complex schema is a table specfying in/out conversions as: {import=fun, export=fun}
       local c = fif(luatype(t)=='table', 'complex', CONF.output.encoding.name)
       -- default is always the configured output encoding
       return ({
	  fun = t,
	  zentype = 'schema',
	  luatype = objtype,
	  raw = obj,
	  encoding = c
       })
    end

    if objtype == 'string' then
       if expect_table(definition) then
	  error("Cannot take object: expected '"..definition.."' but found '"..objtype.."' (not a table)",3)
       end
       res = input_encoding(definition)
       res.luatype = 'string'
       res.zentype = 'element'
       res.raw = obj
       return (res)
    end

    -- definition: value_encoding .. data_type
    -- value_encoding: base64, hex, etc.
    -- data_type: array, dictionary, structure
    if objtype == 'table' then
       local def = expect_table(definition)
       if not def then -- check if the last word is among zentype collections
	  error("Cannot take object: expected '"..definition
		.."' but found '"..objtype.."' (not a dictionary or array)",3)
       end
       -- schema type in array or dict
       t = ZEN.schemas[ def.leftwords ]
       if t then
	  return ({
	     fun = t,
	     zentype = 'schema',
	     schema = def.leftwords,
	     luatype = objtype,
	     raw = obj,
	     encoding = def.rightmost
	  })
       end
       -- normal type in input encoding: string, base64 etc.
       res = input_encoding(def.leftwords)
       if res then
	  res.luatype = 'table'
	  res.zentype = def.rightmost -- zentypes couples with table
	  res.raw = obj
	  return (res)
       end
       error("Cannot take object: invalid "..def.rightmost.." with encoding "..def.leftwords, 3)
       return nil
    end

    if objtype == 'number' or tonumber(obj) then
       if expect_table(definition) then
	  error("Cannot take object: expected '"..definition.."' but found '"..objtype.."' (not a table)",3)
       elseif definition ~= 'number' then
	  error("Cannot take object: expected '"..definition.."' but found '"..objtype.."'",3)
       end
       res = input_encoding(objtype)
       res.luatype = 'number'
       res.zentype = 'element'
       if obj > 2147483647 then
	  error('Overflow of number object over 32bit signed size', 3)
	  -- TODO: maybe support unsigned native here
       end
       res.raw = obj
	  -- any type of additional conversion from a native number
	  -- detected at input can happen here, for instance using a new
	  -- native unsigned integer
       return (res)
    end

    error('Cannot take object: invalid conversion for type '..objtype..': '..definition, 3)
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
       luatype = guessed.luatype,
       root = guessed.root
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

-- factory function to generate a function and return its pointer the
-- function is generated using another pointer to function which is
-- the encoder, plus it applies common safety checks for data types
-- that must be excluded for encoding, as for instance numbers and
-- booleans.
-- arguments: encoder's name, conversion and check functions
local function f_factory_encoder(encoder_n, encoder_f, encoder_c)
   return { fun = function(data)
	       local dt = luatype(data)
	       if dt == 'number' then
		  return data
	       elseif dt == 'boolean' then
		  return data
	       end
	       return encoder_f(data)
   end,
	    encoding = encoder_n,
	    check = encoder_c
   }
end

-- gets a string and returns the associated function, string and prefix
-- comes before schema check
function input_encoding(what)
   if not luatype(what) == 'string' then
      error("Call to input_encoding argument is not a string: "..type(what),2)
   end
   if what == 'u64' or what == 'url64' then
      return f_factory_encoder('url64', O.from_url64, O.is_url64)
   elseif what == 'b64' or what =='base64' then
      return f_factory_encoder('base64', O.from_base64, O.is_base64)
   elseif what == 'b58' or what =='base58' then
      return f_factory_encoder('base58', O.from_base58, O.is_base58)
   elseif what == 'hex' then
      return f_factory_encoder('hex', O.from_hex, O.is_hex)
   elseif what == 'bin' or what == 'binary' then
      return f_factory_encoder('binary', O.from_bin, O.is_bin)
   elseif what == 'str' or what == 'string' then
      -- string has no check function
      return f_factory_encoder('string', O.from_string, nil)
   elseif what =='mnemonic' then
      -- mnemonic has no check function (TODO:)
      return f_factory_encoder('mnemonic', O.from_mnemonic, nil)
   elseif what == 'num' or what == 'number' then
      return f_factory_encoder('number', 
			       function(data) return tonumber(data) end,
			       function(data)
				  if not tonumber(data) then
				     error("Invalid encoding, not a number: "
					   ..type(data), 3)
				  end
			       end)
   end
   error("Input encoding not found: " .. what, 2)
   return nil
end

-- factory function returns a small outcast function that applies
-- return guessed.fun(guessed.raw)safety checks on values like
-- exceptions for numbers and booleans

local function f_factory_outcast(fun)
   return function(data)
      local dt = luatype(data)
      -- passthrough native number data
      if dt == 'number' or dt == 'boolean' then
	 return data
      elseif iszen(dt) and dt ~= 'zenroom.octet' then
	 -- leverage first class citizen method on zenroom data
	 return fun(data:octet())
      end
      return fun(data)
   end
end

 -- takes a string returns the function, good for use in deepmap(fun,table)
 function guess_outcast(cast)
    if not cast then
       error('guess_outcast called with nil argument', 2)
    end
    if luatype(cast) ~= 'string' then
       error('guess_outcast called with wrong argument: '..type(cast), 3) end
    if cast == 'string' then
       return f_factory_outcast(O.to_string)
    elseif cast == 'hex' then       
       return f_factory_outcast(O.to_hex)
    elseif cast == 'base64' then
       return f_factory_outcast(O.to_base64)
    elseif cast == 'url64' then
       return f_factory_outcast(O.to_url64)
    elseif cast == 'base58' then
       return f_factory_outcast(O.to_base58)
    elseif cast == 'binary' or cast == 'bin' then
       return f_factory_outcast(O.to_bin)
    elseif cast == 'mnemonic' then
       return f_factory_outcast(O.to_mnemonic)
    elseif cast == 'number' then
       return f_factory_outcast(tonumber)
    elseif cast == 'boolean' then
       return function(data) return data end
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

function get_format(what)
   if what == 'json' or what == 'JSON' then
      return { fun = JSON.auto,
	       name = 'json' }
   elseif what == 'cbor' or what == 'CBOR' then
      return { fun = CBOR.auto,
	       name = 'cbor' }
   end
   error("Conversion format not supported: "..what, 2)
   return nil
end

 -- CODEC format:
 -- { name: string,
 --   encoding: encoder name string or 'complex' handled by schema
 --   zentype:  zencode type: element, array, dictionary or schema
 --   luatype:  lua type (string, number, table or userdata)
 --   schema: schema name used to import (may differ from name)
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
    local codec = ZEN.CODEC[value]
    if codec.zentype == 'schema' then
       if codec.encoding == 'complex' then
        local sch = codec.schema or codec.name
   	  assert(ZEN.schemas[sch],
   	   "Complex export for schema not found: "..value)
	       assert(luatype(ZEN.schemas[sch].export) == 'function',
		     "Complex export for schema is not a function: "..value)
	  return value -- name of schema itself as it contains export
       end
    else
       return codec.encoding or CONF.output.encoding.name
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
      res = deepcopy(ZEN.CODEC[clone])
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
         res.zentype = 'element'
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
    local strings = { 'K' }
    sort_apply(
       function(v, k)
	      table.insert(strings, tostring(k))
	      if iszen(type(v)) then
            -- TODO: optimize octet concatenation in C
            -- to avoid reallocation of new octets in this loop
            -- should count total length allocate one and insert
	         octets = octets.. v:octet()
         else -- number
	         table.insert(strings, tostring(v))
         end
       end,
       tab
    )
    return {
       octets = octets,
       -- string concatenation is optimized
       strings = table.concat(strings)
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
