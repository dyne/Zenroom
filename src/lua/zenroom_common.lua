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
   for _ in n:gmatch("zenroom") do
	  return true
   end
   return false
end

-- workaround for a ternary conditional operator
function fif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

function uscore(input)
   local it = luatype(input)
   if it == 'string' then
      return string.gsub(input, ' ', '_')
   elseif it == 'number' then
      return input
   else
      error("Underscore transform not a string or number: "..it, 3)
   end
end
function space(input)
   local it = luatype(input)
   if it == 'string' then
      return string.gsub(input, '_', ' ')
   elseif it == 'number' then
      return input
   else
      error("Whitespace transform not a string or number: "..it, 3)
   end
end

-- debugging facility
function xxx(s, n)
   n = n or 3
   if DEBUG >= n then
	  printerr("LUA "..s)
   end
end

-- sorted iterator for deterministic ordering of tables
-- from: https://www.lua.org/pil/19.3.html
_G["lua_pairs"]  = _G["pairs"]
_G["lua_ipairs"] = _G["ipairs"]
local function _pairs(t)
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
local function _ipairs(t)
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


-- compare two tables
function deepcmp(left, right)
   if not ( luatype(left) == "table" ) then
      error("Internal error: deepcmp 1st argument is not a table")
   end
   if not ( luatype(right) == "table" ) then
      error("Internal error: deepcmp 2nd argument is not a table")
   end
   if left == right then return true end
   for key1, value1 in pairs(left) do
      local value2 = right[key1]
      if value2 == nil then return false
      elseif value1 ~= value2 then
	 if type(value1) == "table" and type(value2) == "table" then
	    if not deepcmp(value1, value2) then
	       return false
	    end
	 else
	    return false
	 end
      end
   end
   -- check for missing keys in tbl1
   for key2, _ in pairs(right) do
      if left[key2] == nil then
	 return false
      end
   end
   return true
end

-- deep recursive map on a tree structure
-- for usage see test/deepmap.lua
-- operates only on strings, passes numbers through
function deepmap(fun,t,...)
   local luatype = luatype
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


-- function to be used when converting codecs with complex trees
-- mask is a dictionary of functions to be applied in place
function deepmask(fun,t,mask)
   local luatype = luatype
   if luatype(fun) ~= 'function' then
      error("Internal error: deepmask 1st argument is not a function", 3)
      return nil end
   if luatype(t) ~= 'table' then
      error("Internal error: deepmask 2nd argument is not a table", 3)
      return nil end
   if luatype(mask) ~= 'table' then
      error("Internal error: deepmask 3nd argument is not a table", 3)
      return nil end
   local res = { }
   for k,v in pairs(t) do
      if luatype(v) == 'table' then
	 if not mask or not mask[k] then
	    res[k] = deepmask(fun,v) -- switch to deepmap?
	 else
	    res[k] = deepmask(fun,v,mask[k]) -- recursion
	 end
      else
	 if not mask or not mask[k] then -- check tree of funcs
	    res[k] = fun(v,k)
	 else
	    res[k] = mask[k](v,k)
	 end
      end
   end
   return setmetatable(res, getmetatable(t))
end

function isarray(obj)
   if not obj then
	  warn("Argument of isarray() is nil")
	  return false
   end
   if luatype(obj) == 'string' then
      -- seach HEAD for ACK[obj] and check its CODEC
      local o = ACK[obj]
      if not o then return false end
      if luatype(o) ~= 'table' then return false end
      if ZEN.CODEC[obj].zentype == 'array' then return true end
      return false
   end
   if luatype(obj) ~= 'table' then
      -- warn("Argument of isarray() is not a table")
      return false
   end
   local count = 0
   for k, v in pairs(obj) do
	  -- check that all keys are numbers
	  -- don't check sparse ratio (cjson's lua_array_length)
	  if luatype(k) ~= "number" then return false end
	  count = count + 1
   end
   return count
end

function isdictionary(obj)
   if not obj then
	  warn("Argument of isdictionary() is nil")
	  return false
   end
   if luatype(obj) == 'string' then
      -- seach HEAD for ACK[obj] and check its CODEC
      local o = ACK[obj]
      if not o then return false end
      if luatype(o) ~= 'table' then return false end
      if ZEN.CODEC[obj].zentype == 'dictionary'
	 or ZEN.CODEC[obj].zentype == 'schema' then
	 return true end -- TRUE
      return false
   end
   -- check the object itself
   if luatype(obj) ~= 'table' then return false end
   -- error("Argument is not a table: "..type(obj)
   local count = 0
   for k, v in pairs(obj) do
	  -- check that all keys are not numbers
	  -- don't check sparse ratio (cjson's lua_array_length)
	  if luatype(k) ~= "string" then return false end
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

local oldtonumber = tonumber
function tonumber(obj, ...)
    if type(obj) == "zenroom.float" then
        obj = tostring(obj)
    end
    return oldtonumber(obj, ...)
end

function isnumber(n)
  local t = type(n)
  return t == 'number' or t == 'zenroom.float' or t == 'zenroom.big'
end

function deprecated(old, new, func)
    local warn_func = function(...)
	warn(table.concat({"DEPRECATED:\n", old, "\nuse instead\n", new}))
	func(...)
    end
    return old, warn_func
end
