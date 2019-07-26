-- override type to recognize zenroom's types
luatype = type
function type(var)
   local simple = luatype(var)
   if simple == "userdata" then
	  if getmetatable(var).__name then
		 return(getmetatable(var).__name)
	  else
		 return("unknown")
	  end
   else return(simple) end
end
function iszen(n)
   for c in n:gmatch("zenroom") do
	  return true
   end
   return false
end


-- global
_G["REQUIRED"] = { }
-- avoid duplicating requires (internal includes)
function require_once(ninc)
   local class = REQUIRED[ninc]
   if type(class) == "table" then return class end
   -- new require
   class = require(ninc)
   if type(class) == "table" then REQUIRED[ninc] = class end
   return class
end

function content(var)
   if type(var) == "zenroom.octet" then
	  INSIDE.print(var:array())
   else
	  INSIDE.print(var)
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
   local iter = function ()   -- iterator function
	  i = i + 1
	  if a[i] == nil then return nil
	  else return a[i], t[a[i]]
	  end
   end
   return iter
end
function _ipairs(t)
   local a = {}
   for n in lua_ipairs(t) do table.insert(a, n) end
   table.sort(a)
   local i = 0      -- iterator variable
   local iter = function ()   -- iterator function
	  i = i + 1
	  if a[i] == nil then return nil
	  else return a[i]
	  end
   end
   return iter
end
-- Switch to deterministic (sorted) table iterators: this breaks lua
-- tests in particular those stressing i/pairs and pack/unpack, which
-- are anyway unnecessary corner cases in zenroom, which exits cleanly
-- and signaling a stack overflow. Please report back if this
-- generates problems leading to the pairs for loop in function above.
_G["pairs"]  = _pairs
_G["ipairs"] = _pairs
-- stateless map mostly for internal use
function _map(t, f, ...)
   -- safety
   if not (type(t) == "table") then return {} end
   if t == nil then return {} end
   -- if #t == 0  then return {} end

   local _t = {}
   for index,value in _pairs(t) do
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
   if module.new == nil then return end
   local inst = module.new()
   for s,f in pairs(getmetatable(inst)) do
	  if(string.sub(s,1,2)~='__') then print("object method: "..s) end
   end
end
