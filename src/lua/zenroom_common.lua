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

-- gets a string and returns the associated function, string and prefix
-- comes before schema check
function input_encoding(what)
   if what == 'u64' or what == 'url64' then
	  return { fun = function(data)
				  if O.is_url64(data) then return O.from_url64(data)
				  else error("Failed import from url64: "..what,3)
					 end end,
			   name = 'url64',
			   check = O.is_url64
	  }
   elseif what == 'b64' or what =='base64' then
	  return { fun = function(data)
				  if O.is_base64(data) then return O.from_base64(data)
				  else error("Failed import from base64: "..what,3)
					 end end,
			   name = 'base64',
			   check = O.is_base64
	  }
   elseif what == 'hex' then
	  return { fun = function(data)
				  if O.is_hex(data) then return O.from_hex(data)
				  else error("Failed import from hex: "..what,3)
				  end end,
			   name = 'hex',
			   check = O.is_hex
	  }
   elseif what == 'bin' or what == 'binary' then
	  return { fun = function(data)
				  if O.is_bin(data) then return O.from_bin(data)
				  else error("Failed import from bin: "..what,3)
					 end end,
			   name = 'binary',
			   check = O.is_bin
	  }
   elseif what == 'str' or what == 'string' then
   	  return { fun = O.from_string,
   			   check = function(_) return true end,
   			   name = 'string'
   	  }
   elseif what == 'num' or what == 'number' then
   	  return { fun = tonumber,
   			   check = tonumber, -- function(_) return true end,
   			   -- check = function(a) if tonumber(a) ~= nil then
   			   -- 		 return true else return false end,
   			   name = 'number'
   	  }
   end
   xxx("Input encoding not found: "..what, 2)
   return nil
end

-- gets a string and returns the associated function, string and prefix
function output_encoding(what)
   if what == 'u64' or what == 'url64' then
	  return { fun = O.to_url64,
			   name = 'url64' }
   elseif what == 'b64' or what =='base64' then
	  return { fun = O.to_base64,
			   name = 'base64' }
   elseif what == 'hex' then
	  return { fun = O.to_hex,
			   name = 'hex' }
   elseif what == 'bin' or what == 'binary' then
	  return { fun = O.to_bin,
			   name = 'binary' }
   elseif what == 'str' or what == 'string' then
	  return { fun = O.to_string,
			   name = 'string' }
   end
   xxx("Output encoding not found: "..what, 2)
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

------------------------------
-- FUNCTIONAL LANGUAGE HELPERS
----------------------------------------
-- stateless map mostly for internal use
-- TODO: remove and leave only deepmap()
function _map(t, f, ...)
   -- safety
   if not (type(t) == "table") then return {} end
   if t == nil then return {} end
   -- if #t == 0  then return {} end

   local _t = {}
   for index,value in sort_pairs(t) do
	  local k, kv, v = index, f(index,value,...)
	  _t[v and kv or k] = v or kv
   end
   return _t
end
-- map values in place, sort tables by keys for deterministic order
function map(data, fun)
   if(type(data) ~= "table") then
	  error "map() first argument is not a table"
	  return nil end
   if(type(fun) ~= "function") then
	  error "map() second argument is not a function"
	  return nil end
   out = {}
   _map(data,function(k,v) out[k] = fun(v) end)
   return(out)
end

-- deep recursive map on a tree structure
-- for usage see test/deepmap.lua
function deepmap(fun,t,...)
   if luatype(fun) ~= 'function' then
	  error("Internal error: deepmap 1st argument is not a function", 3)
	  return nil end
   if luatype(t) ~= 'table' then
	  error("Internal error: deepmap 2nd argument is not a table", 3)
	  return nil end
   local res = {}
   for k,v in pairs(t) do
	  if luatype(v) == 'table' then
		 res[k] = deepmap(fun, v) -- recursion
	  else
		 res[k] = fun(v,...)
	  end
   end
   return setmetatable(res, getmetatable(t))
end

function isarray(obj)
   if not obj then error("Argument of isarray() is nil",2) end
   if luatype(obj) ~= 'table' then error("Argument is not a table: "..type(obj),2) end
   local count = 0
   for k, v in pairs(obj) do
	  -- check that all keys are numbers
	  -- don't check sparse ratio (cjson's lua_array_length)
	  if luatype(k) ~= "number" then return 0 end
	  count = count + 1
   end
   return count
end

function array_contains(arr, obj)
   assert(luatype(arr) == 'table', "Internal error: array_contains argument is not a table")
   local res = false
   for k, v in ipairs(obj) do
	  assert(luatype(k) == 'number', "Internal error: array_contains argument is not an array")
	  res = res or v == obj
   end
   return res
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
function zenguard(tbl)
   for k,v in next,tbl,nil do
	  local ok = false
	  if luatype(v) == 'table' then
		 zenguard(v)
	  else
		 ok = iszen(type(v)) or tonumber(v)
		 ZEN.assert(ok,"Variable "..k.." has unconverted value type: "..type(v))
	  end
   end
end
