 --[[
 --This file is part of zenroom
 --
 --Copyright (C) 2018-2025 Dyne.org foundation
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

-- Spec for number input / output
-- input  |  spec  |  internal     |  output

-- num       none     float           float
-- num       float    float           float
-- num       int      int             string (TODO)
-- string    none     mixed           string
-- string    int      int             string
-- string    float    float           float


 -- Used in scenario's schema declarations to cast to zenroom. type
 function schema_get(obj, key, conversion, encoding)
	-- I.warn({obj=obj,key=key,conversion=conversion,encoding=encoding})
	if type(key) ~= 'string' then
	   error('get key is not a string', 2)
	end
	if conversion and type(conversion) ~= 'function' then
	   error('get invalid conversion function', 2)
	end
	if encoding and type(encoding) ~= 'function' then
	   error('get invalid encoding function', 2)
	end
	local k
	if not obj then -- take from IN root
	   k = IN[key]
	else
	   if key == '.' then
          k = obj
	   else
          k = obj[key]
	   end
	end
	if k == nil then
	   error('Key not found in object conversion: ' .. key, 2)
	end
	local res = nil
	local t = type(k)
	-- BIG/INT default export is decimal
	if conversion == INT.new and not encoding then
	   -- compare function address and use default
	   res = INT.from_decimal(k)
	elseif iszen(t) and conversion then
	   res = conversion(k)
	elseif iszen(t) and not conversion then
	   res = k
	elseif t == 'string' then
	   if encoding then
          res = encoding(k)
	   else
          res = CONF.input.encoding.fun(k)
	   end
	   if conversion then
          res = conversion(res)
	   end
  elseif t == 'boolean' then
     res = k
	   if conversion then
          res = conversion(res)
	   end
	else
	   if t == 'number' then
          res = k
	   end
	   if t == 'table' then
          res = deepmap(encoding or CONF.input.encoding.fun, k)
          if conversion then
			 res = deepmap(conversion, res)
          end
	   end
	end
   if ZEN then
       assert(ZEN.OK and res ~= nil,'get on invalid key: ' .. key .. ' (' .. t .. ')', 2)
   end
	return res
 end

 -- return leftmost and rightmost if definition string indicates
 -- a lua table: dictionary, array or schema
 local function expect_table(definition)
   local toks = strtok(definition, '_')
   local res = { rightmost = toks[#toks] }
   if #toks == 1 and res.rightmost == 'dictionary' then
     return res -- dictionary alone is accepted as customizable
   end
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
   return nil
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
 --   missing     = true if the raw data was not found just expected
 -- }
 function guess_conversion(obj, definition)
    local t
    local objtype <const> = luatype(obj)
    local res
    if not definition then
       error("Cannot take undefined object, found a "..type(obj), 3)
    end
    -- a defined schema overrides any other conversion
    t = ZEN.schemas[definition]
    if t then
       -- complex schema is a table specfying in/out conversions as:
       -- {import=fun, export=fun}
       local c = fif(luatype(t)=='table', 'complex', 'def')
       -- default is always the configured output encoding
	   res = {
		  fun = t,
		  schema = definition,
		  zentype = 'e',
		  raw = obj,
		  encoding = c }
	   if not obj then res.missing = true end
	   return(res)
    end

    -- definition: value_encoding .. data_type
    -- value_encoding: base64, hex, etc.
    -- data_type: array, dictionary, structure
    if objtype == 'table' then
      local def = expect_table(definition)
      if not def then -- check if the last word is among zentype collections
        -- fallback to string dictionary or array
        if isdictionary(obj) then
          def = expect_table('string_dictionary')
        else
          def = expect_table('string_array')
        end
      end
      -- mixed dictionary has a custom deepmask CODEC defined in Given
      if not def.leftwords and def.rightmost == 'dictionary' then
        res = input_encoding('string')
        res.zentype = 'd'
        res.raw = obj
        res.st = 'c' -- '__custom_dictionary__'
        return(res)
      end
      -- schema type in array or dict
      t = ZEN.schemas[ def.leftwords ]
      if t then
        return ({
            fun = t,
            zentype = string.sub(def.rightmost,1,1),
            schema = def.leftwords,
            luatype = objtype,
            raw = obj,
        })
      end
      -- normal type in input encoding: string, base64 etc.
      res = input_encoding(def.leftwords)
      if res then
        res.zentype = string.sub(def.rightmost,1,1)
        res.raw = obj
        res.schema = nil
        return (res)
      end
      error("Cannot take object: invalid "..def.rightmost.." with encoding "..def.leftwords, 3)
      return nil
    end

    if objtype == 'number' then
       if expect_table(definition) then
	  error("Cannot take object: expected '"..definition.."' but found '"..objtype.."' (not a table)",3)
	  -- elseif definition ~= 'number' then
	  --	  error("Cannot take object: expected '"..definition.."' but found '"..objtype.."'",3)
       end
       res = input_encoding(definition)
       res.zentype = 'e'
       -- if obj > 2147483647 then
       --	  error('Overflow of number object over 32bit signed size', 3)
       --	  -- TODO: maybe support unsigned native here
       -- end
       res.raw = obj
       -- any type of additional conversion from a native number
       -- detected at input can happen here, for instance using a new
       -- native unsigned integer
       return (res)
    end

    if objtype == 'string' then
       res = input_encoding(definition)
       res.zentype = 'e'
       res.schema = nil
       res.raw = obj
       return (res)
    end

    if objtype == 'boolean' then
      if expect_table(definition) then
	      error("Cannot take object: expected '"..definition.."' but found '"..objtype.."' (not a table)",3)
      end
       res = input_encoding(definition)
       res.zentype = 'e'
       res.schema = nil
       res.raw = obj
       return (res)
    end

	if objtype == 'nil' then
	   local tab <const> = expect_table(definition)
	   if tab then -- double encoding_zentype definition
		  if ZEN.schemas[tab.leftwords] then
			 return({ zentype = string.sub(tab.rightmost,1,1),
					  schema = tab.leftwords,
					  luatype = objtype,
					  missing = true
					})
		  else
			 res = input_encoding(tab.leftwords)
			 if res then
				res.zentype = string.sub(tab.rightmost,1,1)
				res.schema = nil
				res.missing = true
				return(res)
			 end
		  end
	   end
	   -- single encoding definition
	   res = input_encoding(definition)
	   res.zentype = 'e'
	   res.missing = true
	   return(res)
	end

    -- objtype is not a luatype
    if iszen(type(obj)) then
       res = input_encoding(definition)
       res.zentype = 'e'
       res.schema = nil
       res.raw = obj
       return(res)
    end

    error('Invalid object: no conversion for type '..objtype..': '..definition, 3)
    return nil
 end

 -- factory function to generate a function and return its pointer the
 -- function is generated using another pointer to function which is
 -- the encoder, plus it applies common safety checks for data types
 -- that must be excluded for encoding, as for instance numbers and
 -- booleans.
 -- arguments: encoder's name, conversion and check functions
 local function f_factory_encoder(encoder_n, encoder_f, encoder_c)
    local res = { }
    if not encoder_f then
       res.fun = function(data) return(data) end
    else
       res.fun = function(data)
	  local dt = luatype(data)
    if dt == 'boolean' then
      return data
    end
	  -- wrap all conversion functions nested in deepmaps
	  -- TODO: optimize
	  if dt == 'number' and encoder_n ~= 'float' and encoder_n ~= 'time' then
       if TIME.detect_time_value(data) and not CONF.input.number_strict then
          warn("Number value imported as timestamp: "..data)
          return TIME.new(data)
       else
          return FLOAT.new(data)
       end
  end
	  return encoder_f(data)
       end
    end
    res.encoding = encoder_n
    res.check = encoder_c
    return(res)
 end

 -- gets a string and returns the associated function, string and prefix
 -- comes before schema check
 function input_encoding(what)
   if not what then
     error("Call to input_encoding with argument nil",2)
   end
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
    elseif what =='b32' or what =='base32' then
       return f_factory_encoder('base32', O.from_base32, O.is_base32)
    elseif what =='b32crockford' or what =='base32crockford' then
       return f_factory_encoder('base32crockford', function(s) return O.from_base32_crockford(s, false) end, O.is_base32_crockford)
    elseif what =='b32crockford_cs' or what =='base32crockford_cs' then
      return f_factory_encoder('base32crockford_cs', function(s) return O.from_base32_crockford(s, true) end, O.is_base32_crockford)
    elseif what =='uuid' then
      return f_factory_encoder('uuid', O.from_uuid, nil)
    elseif what == 'int' or what == 'integer' then -- aka BIG
       return f_factory_encoder('integer', BIG.from_decimal, BIG.is_integer)
    elseif what == 'float' or what == 'num' or what == 'number' then
       return f_factory_encoder('float', FLOAT.new, FLOAT.is_float)
    elseif what == 'time' then
       return f_factory_encoder('time', TIME.new, nil)
    elseif what == 'boolean' then
       return f_factory_encoder('boolean', function(b) return b end, nil)
    end
    warn("Unknown input encoding '"..what.."': using default '"..
         CONF.input.encoding.encoding.."'")
    return input_encoding(CONF.input.encoding.encoding)
 end

local function to_number_f(data)
  local res = tonumber(tostring(data))
  zencode_assert(res, "Could not read the float number")
  return res
end

-- a new 'description' codec to print out dictionaries in unusable but
-- readable form.  this is a non-reversible transformation that
-- outputs just size of objects when they are 64 bytes long or above,
-- else string
local function to_description_f(data)
  local s <const> = #data
  if s < 64 then -- assume is not a string over 32 bytes
    return data:to_string()
  else
    local t <const> = type(data)
    local res <const> = "( "..tostring(s).." bytes "..t.." )"
    return res
  end
end

 -- factory function returns a small outcast function that applies
 -- return guessed.fun(guessed.raw)safety checks on values like
 -- exceptions for numbers and booleans
 local function f_factory_outcast(fun)
    return function(data)
       local dt = type(data)
       if dt == 'table' then error("invalid table conversion",2) end
       -- passthrough native number data
       if dt == 'number' or dt == 'boolean' then
		  return data
       elseif dt == 'zenroom.big' then
        zencode_assert(fun ~= to_number_f and fun ~= O.to_mnemonic, "Encoding not valid for integers")
        local correct_fun = fun
        if correct_fun == O.to_string then correct_fun = BIG.to_decimal end
        if correct_fun ~= BIG.to_decimal then
          zencode_assert(BIG.zenpositive(data), "Negative integers can not be encoded")
          data = data:octet()
        end
        return correct_fun(data)
       elseif dt == 'zenroom.float' or dt == 'zenroom.time' then
		    return to_number_f(data)
       elseif iszen(dt) then
        if fun(data) == nil then return "" end
        -- leverage first class citizen method on zenroom data
        return fun(data:octet())
       end
       return fun(data)
    end
 end

 function default_export_f(obj)
	local f = O.to_octet
	if luatype(obj) == 'table' then
	   return deepmap(f,obj)
	else
	   return f(obj)
	end
 end

 local data_encoding_table = {
    string = O.to_string,
    hex = O.to_hex,
    base64 = O.to_base64,
    url64 = O.to_url64,
    base58 = O.to_base58,
    base32 = O.to_base32,
    base32crockford = function(octet) return O.to_base32_crockford(octet, false, 0) end,
    base32crockford_cs = function(octet) return O.to_base32_crockford(octet, true, 0) end,
    binary = O.to_bin,
    bin = O.to_bin,
    mnemonic = O.to_mnemonic,
    uuid = O.to_uuid,
    float = to_number_f,
    number = to_number_f,
    integer = BIG.to_decimal,
    time = to_number_f,
    description = to_description_f
 }

-- takes a string returns the function, good for use in deepmap(fun,table)
function get_encoding_function(cast)
  if not cast then
    error('get_encoding_function called with nil argument', 2)
  end
  if luatype(cast) ~= 'string' then
    error('get_encoding_function called with wrong argument: '..type(cast), 3)
  end
  if cast == 'def' then
    return CONF.output.encoding.fun
  elseif cast == 'boolean' then
    return function(data) return data end
  end
  local _enc <const> = data_encoding_table[cast]
  if _enc then
    return f_factory_outcast(_enc)
  end
  -- try schemas
  local fun = ZEN.schemas[uscore(cast)]
  if luatype(fun) == 'table' then
    if fun.export then
      return fun.export
    else
      return default_export_f
    end
  end
  -- last default
  return CONF.output.encoding.fun
end

 function get_format(what)
    if what == 'json' or what == 'JSON' then
       return { fun = JSON.auto,
		name = 'json' }
    -- elseif what == 'cbor' or what == 'CBOR' then
    --    return { fun = CBOR.auto,
	-- 	name = 'cbor' }
    end
    error("Conversion format not supported: "..what, 2)
    return nil
 end

-- CACHE format: { key = val, ... }
-- r/w memory invisible to zencode (used inside statements)
-- can overwrite existing data
function new_cache(key, val)
   if not key then error("new_cache called with empty key", 2) end
   if not val then error("new_cache called with empty value", 2) end
   xxx("zencode_cache set value: "..key)
   CACHE[uscore(key)] = val
end

 -- CODEC format:
 -- { name: string,
 --   encoding: encoding of object data, both basic and schema
 --   zentype:  zencode type: 'e'lement, 'a'rray or 'd'ictionary
 --   schema: schema name used to import or nil when basic object
 --   st: schema type properties, so far just 'o'pen or 'c'ustom
 -- }
 function new_codec(cname, parameters, clone)
    if not cname then error("Missing name in new codec", 2) end
    local name
	if luatype(cname) == 'string' then
	   name = uscore(cname)
	else -- may be a numerical index
	   name = cname
	end
	local ackn = ACK[name]
    if ackn == nil then error("Cannot create codec, object not found: "..name, 2) end
    if CODEC[name] then error("Cannot overwrite CODEC."..name, 2) end
    local res
    if clone then
	   local cclone = CODEC[clone]
	   if not cclone then
		  error("Clone not found in CODEC."..clone, 2)
	   end
       res = deepcopy(cclone)
       res.name = name
    else
       res = { name = name }
	   -- check if name is a schema
	   if ZEN.schemas[name] then res.schema = name end
    -- always detect zentype (may be an element extracted from dict)
      local lt = luatype(ackn)
      if lt == 'table' then
         if ZEN.schemas[name] then
          res.zentype = 'e'
         elseif isdictionary(ackn) then
          res.zentype = 'd'
         elseif isarray(ackn) then
          res.zentype = 'a'
         else
          error("Unknown zentype for lua table: "..name, 2)
         end
      else
         res.zentype = 'e'
      end
    end
    -- overwrite with paramenters in argument
    if parameters then
       for k,v in pairs(parameters) do
		  res[k] = v
       end
    end
	-- default encoding if not specified
	if not res.encoding then res.encoding = 'def' end
    CODEC[name] = res
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
    --	  return t end
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
	  if v.__len and #v == 0 then return nil
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
    local pruned_tables = prune_in(pruned_values)
    return pruned_tables
 end

-- encode the octet in ACK[src_name] following the src_enc
-- and then it transform it back to octet following the dest_enc
-- @param src_name name of the variable in ACK
-- @param src_enc the encoding to use when transforming ACK[src_name] into string
-- @param dest_enc the encoding to use when transfroming back the string into octet
-- @return the octet/table of octets of the above transformation
function apply_encoding(src_name, src_enc, dest_enc)
  local src_value, src_codec = have(src_name)
  f_src_enc = get_encoding_function(src_enc)
  if not f_src_enc then error("Encoding format not found: "..src_enc, 2) end
  local encoded_src
  -- accpet also schemas as encoding
  if ZEN.schemas[uscore(src_enc)] then
      if src_codec.schema and uscore(src_enc) ~= src_codec.schema then
          error("Source schema: "..src_codec.schema.." does not match encoding "..src_enc)
      end
      if f_src_enc == default_export_f then
          f_src_enc = function (obj)
              if luatype(obj) == "table" then
                  return deepmap(CONF.output.encoding.fun, obj)
              else
                  return CONF.output.encoding.fun(obj)
              end
          end
      end
      if src_codec.zentype == "e" then
          encoded_src = f_src_enc(src_value)
      else
          encoded_src = {}
          for k,v in src_value do
              encoded_src[k] = f_src_enc(src_value)
          end
      end
  else
      encoded_src = deepmap(f_src_enc, src_value)
  end
  f_dest_enc = input_encoding(dest_enc)
  if not f_dest_enc then error("Destination encoding format not found: "..dest_enc, 2) end
  return deepmap(f_dest_enc.fun, encoded_src)
end
