-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2021 Dyne.org foundation designed, written and
-- maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public
-- License along with this program.  If not, see
-- <https://www.gnu.org/licenses/>.

-- override type to recognize zenroom's types
luatype = type
_G['type'] = function(var)
   local simple = luatype(var)
   if simple == "userdata" then
	  local meta = getmetatable(var)
	  if meta then return(meta.__name)
	  else return("unknown") end
   else return(simple) end
end
-- TODO: optimise in C
function iszen(n)
   for c in n:gmatch("zenroom") do
	  return true
   end
   return false
end

-- workaround for a ternary conditional operator
function fif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

-- gets a string and returns the associated function, string and prefix
-- comes before schema check
function input_encoding(what)
   if not luatype(what) == 'string' then
	  error("Call to input_encoding argument is not a string: "..type(what),2)
   end
   if what == 'u64' or what == 'url64' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.from_url64(data)
				  end
					 end,
			   encoding = 'url64',
			   check = O.is_url64
	  }
   elseif what == 'b64' or what =='base64' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.from_base64(data)
				  end
					 end,
			   encoding = 'base64',
			   check = O.is_base64
	  }
	elseif what == 'b58' or what =='base58' then
		return { fun = function(data)
					if luatype(data) == 'number' then
					   return data
					else
					   return O.from_base58(data)
					end
					   end,
				 encoding = 'base58',
				 check = O.is_base58
		}
   elseif what == 'hex' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.from_hex(data)
				  end
					 end,
			   encoding = 'hex',
			   check = O.is_hex
	  }
   elseif what == 'bin' or what == 'binary' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.from_bin(data)
				  end
					 end,
			   encoding = 'binary',
			   check = O.is_bin
	  }
   elseif what == 'str' or what == 'string' then
   	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.from_string(data)
				  end
					 end,
   			   check = function(_) return true end,
   			   encoding = 'string'
   	  }
   elseif what == 'num' or what == 'number' then
	return ({ fun = function(x) return(tonumber(x)) end,
			check = function(x)
	   			ZEN.assert(tonumber(x), "Invalid encoding, not a number: "..type(x))
			end,
			encoding = 'number' })
   end
   error("Input encoding not found: " .. what, 2)
   return nil
end

-- gets a string and returns the associated function, string and prefix
function output_encoding(what)
   if what == 'u64' or what == 'url64' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.to_url64(data)
				  end
					 end,
			   name = 'url64' }
   elseif what == 'b64' or what =='base64' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.to_base64(data)
				  end
					 end,
			   name = 'base64' }
   elseif what == 'b58' or what =='base58' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.to_base58(data)
				  end
					 end,
			   name = 'base58' }
   elseif what == 'hex' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.to_hex(data)
				  end
					 end,
			   name = 'hex' }
   elseif what == 'bin' or what == 'binary' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.to_bin(data)
				  end
					 end,
			   name = 'binary' }
   elseif what == 'str' or what == 'string' then
	  return { fun = function(data)
				  if luatype(data) == 'number' then
					 return data
				  else
					 return O.to_string(data)
				  end
					 end,
			   name = 'string' }
   end
   error("Output encoding not found: "..what, 2)
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

-- debugging facility
function xxx(s, n)
   n = n or 3
   if DEBUG >= n then
	  print("LUA "..s)
   end
end

function content(var)
   if type(var) == "zenroom.octet" then
	  INSPECT.print(var:array())
   else
	  INSPECT.print(var)
   end
end


-- sorted iterator for deterministic ordering of tables
-- from: https://www.lua.org/pil/19.3.html
_G["lua_pairs"]  = _G["pairs"]
_G["lua_ipairs"] = _G["ipairs"]
function _pairs(t)
   local a = {}
   for n in lua_pairs(t) do table.insert(a, n) end
   table.sort(a)
   local i = 0      -- iterator variable
   return function ()   -- iterator function
	  i = i + 1
	  -- if a[i] == nil then return nil
	  return a[i], t[a[i]]
   end
end
function _ipairs(t)
   local a = {}
   for n in lua_ipairs(t) do table.insert(a, n) end
   table.sort(a)
   local i = 0      -- iterator variable
   return function ()   -- iterator function
	  i = i + 1
	  -- if a[i] == nil then return nil
	  return a[i]
   end
end
-- Switch to deterministic (sorted) table iterators: this breaks lua
-- tests in particular those stressing i/pairs and pack/unpack, which
-- are anyway unnecessary corner cases in zenroom, which exits cleanly
-- and signaling a stack overflow. Please report back if this
-- generates problems leading to the pairs for loop in function above.
_G["sort_pairs"]  = _pairs
_G["sort_ipairs"] = _pairs

-- deep recursive map on a tree structure
-- for usage see test/deepmap.lua
-- operates only on strings, passes numbers through
function deepmap(fun,t,...)
   if luatype(fun) ~= 'function' then
	  error("Internal error: deepmap 1st argument is not a function", 3)
	  return nil end
   -- if luatype(t) == 'number' then
   -- 	  return t end
   if luatype(t) ~= 'table' then
	  error("Internal error: deepmap 2nd argument is not a table", 3)
	  return nil end
   local res = {}
   for k,v in pairs(t) do
	  if luatype(v) == 'table' then
		 res[k] = deepmap(fun,v,...) -- recursion
	  else
		 res[k] = fun(v,k,...)
	  end
   end
   return setmetatable(res, getmetatable(t))
end

function deepcopy(orig)
   local orig_type = type(orig)
   local copy
   if orig_type == 'table' then
	  copy = {}
	  for orig_key, orig_value in next, orig, nil do
		 copy[deepcopy(orig_key)] = deepcopy(orig_value)
	  end
	  setmetatable(copy, deepcopy(getmetatable(orig)))
   else -- number, string, boolean, etc
	  copy = orig
   end
   return copy
end

-- apply a function on all keys and values of a tree structure
-- uses sorted listing for deterministic order
function sort_apply(fun,t,...)
   if luatype(fun) ~= 'function' then
	  error("Internal error: apply 1st argument is not a function", 3)
	  return nil end
   -- if luatype(t) == 'number' then
   -- 	  return t end
   if luatype(t) ~= 'table' then
	  error("Internal error: apply 2nd argument is not a table", 3)
	  return nil end
   for k,v in sort_pairs(t) do
	  if luatype(v) == 'table' then
		 sort_apply(fun,v,...) -- recursion
	  else
		 fun(v,k,...)
	  end
   end
end

-- deep recursive map on a tree structure
-- for usage see test/deepmap.lua
-- operates only on strings, passes numbers through
function deepmap(fun,t,...)
   if luatype(fun) ~= 'function' then
	  error("Internal error: deepmap 1st argument is not a function", 3)
	  return nil end
   -- if luatype(t) == 'number' then
   -- 	  return t end
   if luatype(t) ~= 'table' then
	  error("Internal error: deepmap 2nd argument is not a table", 3)
	  return nil end
   local res = {}
   for k,v in pairs(t) do
	  if luatype(v) == 'table' then
		 res[k] = deepmap(fun,v,...) -- recursion
	  else
		 res[k] = fun(v,k,...)
	  end
   end
   return setmetatable(res, getmetatable(t))
end

function isarray(obj)
   if not obj then
	  warn("Argument of isarray() is nil")
	  return 0
   end
   if luatype(obj) ~= 'table' then return 0 end -- error("Argument is not a table: "..type(obj)
   local count = 0
   for k, v in pairs(obj) do
	  -- check that all keys are numbers
	  -- don't check sparse ratio (cjson's lua_array_length)
	  if luatype(k) ~= "number" then return 0 end
	  count = count + 1
   end
   return count
end

function isdictionary(obj)
   if not obj then
	  warn("Argument of isdictionary() is nil")
	  return 0
   end
   if luatype(obj) ~= 'table' then return 0 end -- error("Argument is not a table: "..type(obj)
   local count = 0
   for k, v in pairs(obj) do
	  -- check that all keys are not numbers
	  -- don't check sparse ratio (cjson's lua_array_length)
	  if luatype(k) ~= "string" then return 0 end
	  count = count + 1
   end
   return count
end

function array_contains(arr, obj)
   assert(luatype(arr) == 'table', "Internal error: array_contains argument is not a table")
   for k, v in pairs(arr) do
	  assert(luatype(k) == 'number', "Internal error: array_contains argument is not an array")
	  if v == obj then return true end
   end
   return false
end


function help(module)
   if module == nil then
	  print("usage: help(module)")
	  print("example > help(octet)")
	  print("example > help(ecdh)")
	  print("example > help(ecp)")
	  return
   end
   for k,v in pairs(module) do
	  if type(v)~='table' and string.sub(k,1,1)~='_' then
		 print("class method: "..k)
	  end
   end
   -- local inst = module.new()
   -- if inst == nil then return end
   -- for s,f in pairs(getmetatable(inst)) do
   -- 	  if(string.sub(s,1,2)~='__') then print("object method: "..s) end
   -- end
end

-- TODO: optimize in C using strtok
local function split(src,pat)
   local tbl = {}
   src:gsub(pat, function(x) tbl[#tbl+1]=x end)
   return tbl
end
function strtok(src, pat)
   if not src then return { } end
   pat = pat or "%S+"
   ZEN.assert(luatype(src) == "string", "strtok error: argument is not a string")
   return split(src, pat)
end

-- assert all values in table are converted to zenroom types
-- used in zencode when transitioning out of given memory
function zenguard(val)
   if not (iszen(type(val)) or tonumber(val)) then
		I.print(ZEN.heap().ACK)
		-- xxx("Invalid value: "..val)
		debug_heap_dump()
		error("Zenguard detected an invalid value in HEAP: type "..type(val), 2)
		return nil
   end
end
