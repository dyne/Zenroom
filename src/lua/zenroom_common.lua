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
function get_encoding(what)
   if what == 'u64' or what == 'url64' then
	  return { fun = url64,
			   name = 'url64',
			   pfx = 'u64' }
   elseif what == 'b64' or what =='base64' then
	  return { fun = base64,
			   name = 'base64',
			   pfx = 'b64' }
   elseif what == 'hex' then
	  return { fun = hex,
			   name = 'hex',
			   pfx = 'hex' }
   elseif what == 'bin' or what == 'binary' then
	  return { fun = bin,
			   name = 'binary',
			   pfx = 'bin' }
   elseif what == 'str' or what == 'string' then
	  return { fun = str,
			   name = 'string',
			   pfx = 'str' }
   else
	  warn("Conversion encoding not supported: "..what)
   end
   return nil
end
function get_format(what)
   if what == 'json' or what == 'JSON' then
	  return { fun = JSON.auto,
			   name = 'json' }
   elseif what == 'cbor' or what == 'CBOR' then
	  return { fun = CBOR.auto,
			   name = 'cbor' }
   else
	  warn("Conversion format not supported: "..what)
   end
   return nil
end
	  
-- debugging facility
function xxx(n,s)
   if ZEN.verbosity or CONF.debug >= n then act(s) end
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
_G["sort_pairs"]  = _pairs
_G["sort_ipairs"] = _pairs

------------------------------
-- FUNCTIONAL LANGUAGE HELPERS
----------------------------------------
-- stateless map mostly for internal use
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

function isarray(obj)
   assert(obj, "isarray() called on a nil object")
   assert(type(obj), "isarray() argument is not a table")
   for k, v in pairs(obj) do
	  -- check that all keys are numbers
	  -- don't check sparse ratio (cjson's lua_array_length)
	  if type(k) ~= "number" then return false end
   end
   return true
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
function split(src,pat)
   local tbl = {}
   src:gsub(pat, function(x) tbl[#tbl+1]=x end)
   return tbl
end
function strtok(src) return split(src, "%S+") end

-- TODO: investigate use of lua-faces
function set_rule(text)
   local res = false
   local rule = strtok(text) -- TODO: optimise in C (see zenroom_common)
   if rule[2] == 'check' and rule[3] == 'version' and rule[4] then
	  SEMVER = require_once('semver')
	  local ver = SEMVER(rule[4])
	  if ver == VERSION then
		 act("Zencode version match: "..VERSION.original)
		 res = true
	  elseif ver < VERSION then
		 error("Zencode written for an older version: "
				 ..ver.original.." < "..VERSION.original, 2)
	  elseif ver > VERSION then
		 error("Zencode written for a newer version: "
					..ver.original.." > "..VERSION.original, 2)
	  else
		 error("Version check error: "..rule[4])
	  end
	  ZEN.checks.version = res
      -- TODO: check version of running VM
	  -- elseif rule[2] == 'load' and rule[3] then
	  --     act("zencode extension: "..rule[3])
	  --     require("zencode_"..rule[3])
   elseif rule[2] == 'input' and rule[3] then

      -- rule input encoding|format ''
      if rule[3] == 'encoding' and rule[4] then
         CONF.input.encoding = get_encoding(rule[4])
		 res = true and CONF.input.encoding
      elseif rule[3] == 'format' and rule[4] then
		 CONF.input.format = get_format(rule[4])
         res = true and CONF.input.format
	  elseif rule[3] == 'untagged' then
		 res = true
		 CONF.input.tagged = false
      end

   elseif rule[2] == 'output' and rule[3] and rule[4] then

      -- rule input encoding|format ''
      if rule[3] == 'encoding' then
         CONF.output.encoding = get_encoding(rule[4])
		 res = true and CONF.output.encoding
      elseif rule[3] == 'format' then
		 CONF.output.format = get_format(rule[4])
         res = true and CONF.output.format
      elseif rule[3] == 'versioning' then
		 CONF.output.versioning = true
         res = true
      end

   elseif rule[2] == 'unknown' and rule[3] then
	  if rule[3] == 'ignore' then
		 CONF.parser.strict_match = false
		 res = true
	  end

   elseif rule[2] == 'set' and rule[4] then

      CONF[rule[3]] = tonumber(rule[4]) or rule[4]
      res = true and CONF[rule[3]]

   end
   if not res then error("Rule invalid: "..text, 3)
   else act(text) end
   return res
end

-- assert all values in table are converted to zenroom types
-- used in zencode when transitioning out of given memory
function zenguard(tbl)
   for k,v in next,tbl,nil do
	  if luatype(v) == 'table' then
		 zenguard(v)
	  else
		 ZEN.assert
		 (iszen(type(v)),
		  "Variable "..k.." has unconverted value type: "..type(v))
	  end
   end
end
