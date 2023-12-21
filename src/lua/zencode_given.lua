--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2022 Dyne.org foundation
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
--]]

-- TODO: use strict table
-- https://stevedonovan.github.io/Penlight/api/libraries/pl.strict.html

-- the main security concern in this Zencode module is that no data
-- passes without validation from IN to ACK or from
-- inline input.

-- data coming in is analyzed through a series of functions:
-- guess_conversion(raw, conv or name) -> zenode_data.lua L:100 approx 
--- |_ if luatype(string) && format -> input encoding(format)

-- GIVEN
local function gc()
   ZEN.TMP = {}
   collectgarbage 'collect'
end

-- safely take any zenroom object as index
local function _index_to_string(what)
   local t <const> = type(what)
   if t == 'string' then
      return what
   elseif iszen(t) then
      return what:octet():string()
   end
   error("Invalid type to index variable in heap: "..t, 3)
   return nil
end

---
-- Pick a generic data structure from the <b>IN</b> memory
-- space. Looks for named data on the first and second level and makes
-- it ready in ZEN.TMP for @{validate} or @{ack}.
--
-- @function pick(name, data, encoding)
-- @param what string descriptor of the data object
-- @param conv[opt] optional encoding spec (default CONF.input.encoding)
-- @return true or false
local function pick(what, conv)
   local name <const> = _index_to_string(what)
   local raw <const> = IN[name]
   local err
   if CONF.missing.fatal then err = error else err = warn end
   if not raw and CONF.missing.fatal then
	  err("Cannot find '" .. name .. "' anywhere (null value?)", 2) end
   if raw == '' and CONF.missing.fatal then
	  err("Found empty string in '" .. name) end
   -- if not conv and ZEN.schemas[what] then conv = what end
   ZEN.TMP = guess_conversion(raw, conv or name)
   if not ZEN.TMP then
	  error('Cannot guess any conversion for: ' ..
			luatype(raw) .. ' ' .. (conv or name or '(nil)')) end
   ZEN.TMP.name = name
   assert(ZEN.OK)
   if DEBUG > 1 then
	  ZEN.ftrace('pick found ' .. name .. '('..ZEN.TMP.zentype..')')
   end
end

---
-- Pick a data structure named 'what' contained under a 'section' key
-- of the at the root of the <b>IN</b> memory space. Looks for named
-- data at the first and second level underneath IN[section] and moves
-- it to ZEN.TMP[what][section], ready for @{validate} or @{ack}. If
-- ZEN.TMP[what] exists already, every new entry is added as a key/value
--
-- @function pickin(section, name)
-- @param section string descriptor of the section containing the data
-- @param what string descriptor of the data object
-- @param conv string explicit conversion or schema to use
-- @param fail bool bail out or continue on error
-- @return true or false
local function pickin(section, what, conv, fail)
   zencode_assert(section, 'No section specified')
   local root <const> = IN[section]
   if not root then error("Cannot find '"..section.."'", 2) end
   local name <const> = _index_to_string(what)
   local raw  -- data pointer
   if luatype(root) ~= 'table' then
      error("Object is not a table: "..section, 2)
   end
   if #root == 1 then
      raw = root[name]
      if not raw and luatype(root[1]) == 'table' then
		 raw = root[1][name]
      end
   else
      raw = root[name]
   end
   if not raw and CONF.missing.fatal then
      error("Object not found: "..name.." in "..section, 2)
   end
   if raw == '' and CONF.missing.fatal then
      error("Found empty string '" .. name .."' inside '"..section.."'", 2) end
   -- conv = conv or name
   -- if not conv and ZEN.schemas[name] then conv = name end
   -- if no encoding provided then conversion is same as name (schemas etc.)
   ZEN.TMP = guess_conversion(raw, conv or name)
   ZEN.TMP.name = name
   ZEN.TMP.root = section
   assert(ZEN.OK)
   if DEBUG > 1 then
      ZEN.ftrace('pickin found ' .. name .. ' in ' .. section)
   end
end


-- takes a data object and the guessed structure, operates the
-- conversion and returns the resulting raw data to be used inside the
-- WHEN block in HEAP.
function operate_conversion(guessed)
   -- carry guessed detection in CODEC
   CODEC[guessed.name] = {
	  name = guessed.name,
	  encoding = guessed.encoding,
	  zentype = guessed.zentype,
	  root = guessed.root,
	  schema = guessed.schema,
	  missing = guessed.missing
   }
   -- data not found (and CONF.missing.fatal == false)
   if guessed.missing then return nil end
   -- check if already a zenroom type
   -- (i.e. zenroom.big from json decode)
   if not guessed.fun then
	  error('No conversion operation guessed', 2)
	  return nil
   end

   -- xxx('Operating conversion on: '..guessed.name)
   local fun = guessed.fun
   if luatype(fun) == 'table' then fun = fun.import end
   local lt = luatype(guessed.raw)
   if lt == 'table' then
        -- check correctness of the data type
        if guessed.zentype == "a" then assert(isarray(guessed.raw),
            "Incorrect data type, expected array for "..guessed.name)
        elseif guessed.zentype == "d" then assert(isdictionary(guessed.raw),
            "Incorrect data type, expected dictionary for "..guessed.name)
        end
	  if guessed.schema then
		 -- error('Invalid schema conversion for encoding: '..guessed.encoding, 2)
		 local res = {}
		 local zt <const> = guessed.zentype
		 if zt == 'e' then -- single schema element
			return fun(guessed.raw)
			-- array of schemas
		 elseif zt == 'a' then
			for _,v in pairs(guessed.raw) do
			   table.insert(res, fun(v))
			end
			-- dictionary of schemas
		 elseif zt == 'd' then
			for k, v in pairs(guessed.raw) do
			   res[k] = fun(v)
			end
		 else
			error('Unknown zentype to operate schema conversion: '..guessed.zentype, 2)
		 end
		 return(res) -- a, d
	  else
		 -- TODO: better error checking on deepmap?
		 if luatype(guessed.check) == 'function' then
			deepmap(guessed.check, guessed.raw)
		 end
		 return deepmap(fun, guessed.raw)
	  end
   else -- element

	  -- corner case: input is already a zenroom type
	  if lt == 'userdata' then
		 if iszen(type(guessed.raw)) then
			return(guessed.raw)
		 else
			error("Unknown userdata type for element: "..guessed.name, 2)
		 end
	  end
	  ---

	  if guessed.check then
		 if not guessed.check(guessed.raw) then
			error("Could not read " .. guessed.name)
		 end
	  end
	  return fun(guessed.raw)
   end
end

local function ack_table(key, val)
   zencode_assert(
      luatype(key) == 'string',
      'ZEN.table_add arg #1 is not a string'
   )
   zencode_assert(
      luatype(val) == 'string',
      'ZEN.table_add arg #2 is not a string'
   )
   if not ACK[key] then
      ACK[key] = {}
   end
   local t <const> = ZEN.TMP
   local v <const> = operate_conversion(t)
   ACK[key][val] = v
   local n <const> = t.name
   if key ~= n then
      CODEC[key] = CODEC[n]
      CODEC[n] = nil
   end
   if not CODEC[key].missing then
	  local vt <const> = type(v)
	  if iszen(vt) then
		 CODEC[key].bintype = vt
	  end
   end
end

---
-- Final step inside the <b>Given</b> block towards the <b>When</b>:
-- pass on a data structure into the ACK memory space, ready for
-- processing.  It requires the data to be present in ZEN.TMP[name] and
-- typically follows a @{pick}. In some restricted cases it is used
-- inside a <b>When</b> block following the inline insertion of data
-- from zencode.
--
-- @function ack(name)
-- @param name string key of the data object in ZEN.TMP[name]
local function ack(what)
   local t <const> = ZEN.TMP
   local name <const> = _index_to_string(what)
   zencode_assert(t, 'No valid object found: ' .. name)
   empty(name)
   local v <const> = operate_conversion(t)
   ACK[name] = v
   if not CODEC[name].missing then
	  local vt <const> = type(v)
	  if iszen(vt) then
		 CODEC[name].bintype = vt
	  end
   end
   -- name of schema may differ from name of object
   -- new_codec(name, { schema = ZEN.TMP.schema })

   -- if ZEN.TMP.schema and (ZEN.TMP.schema ~= 'number') and ( ZEN.TMP.schema ~= ZEN.TMP.encoding ) then
   --    CODEC[name].schema = ZEN.TMP.schema
   -- end

end

Given("nothing",function()
      zencode_assert(
         (next(IN) == nil),
         'Undesired data passed as input'
      )
end)

-- maybe TODO: Given all valid data
-- convert and import data only when is known by schema and passes validation
-- ignore all other data structures that are not known by schema or don't pass validation

Given("am ''",function(name)
      Iam(name)
end)

Given("my name is in '' named ''",function(sc, name)
      pick(name, sc)
      assert(ZEN.TMP.name, 'No name found in: ' .. name)
      Iam(O.to_string(operate_conversion(ZEN.TMP)))
      CODEC[name] = nil -- just used to get name
end)

Given("my name is in '' named '' in ''",function(sc, name, struct)
      pickin(struct, name, sc)
      assert(ZEN.TMP.name,  'No name found in: '..name)
      Iam(O.to_string(operate_conversion(ZEN.TMP)))
      CODEC[name] = nil -- just name string
end)

-- variable names:
-- s = schema of variable (or encoding)
-- n = name of variable
-- t = table containing the variable

-- TODO: I have a '' as ''
Given("''",function(n)
      pick(n)
      ack(n)
      gc()
end)

Given("'' in ''",function(s, t)
      pickin(t, s)
      ack(s) -- save it in ACK.obj
      gc()
end)

-- public keys for keyring arrays
-- returns a special array for upcoming session:
-- public_key_session : { name : value }
Given("'' public key from ''",function(s, t)
      -- if not pickin(t, s, nil, false) then
      -- 	pickin(s, t)
      -- end
      pickin(t, s..'_public_key', s..'_public_key', false)
      ack_table('public_key_session', t)
end)

Given("'' from ''",function(s, t)
      -- if not pickin(t, s, nil, false) then
      -- 	pickin(s, t)
      -- end
      pickin(t, s, s, false)
      ack_table(s, t)
      gc()
end)

Given("'' named ''",function(s, n)
      -- zencode_assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      pick(n, s)
      ack(n)
      gc()
end)

Given("'' named by ''",function(s, n)
      -- local name = have(n)
      local name = _index_to_string(IN[n])
      -- zencode_assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      pick(name, s)
      ack(name)
      gc()
end)

Given("'' named '' in ''",function(s, n, t)
      pickin(t, n, s)
      ack(n) -- save it in ACK.name
      gc()
end)

Given("'' named by '' in ''",function(s, n, t)
      local name = _index_to_string(IN[n])
      pickin(t, name, s)
      ack(name) -- save it in ACK.name
      gc()
end)

Given("my ''",function(n)
      zencode_assert(WHO, 'No identity specified, use: Given I am ...')
      pickin(WHO, n)
      ack(n)
      gc()
end)

Given("my '' named ''",function(s, n)
      -- zencode_assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      pickin(WHO, n, s)
      ack(n)
      gc()
end)
Given("my '' named by ''",function(s, n)
      -- zencode_assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      local name = _index_to_string(IN[n])
      pickin(WHO, name, s)
      ack(name)
      gc()
end)

Given("'' is valid",function(n)
      pick(n)
      gc()
end)
Given("my '' is valid",function(n)
      pickin(WHO, n)
      gc()
end)

Given("rename '' to ''",function(old, new)
       empty(new)
       have(old)
       ACK[new] = ACK[old]
       new_codec(new, CODEC[old])
       CODEC[new].name = new

       ACK[old] = nil
       CODEC[old] = nil
end)

Given("'' part of '' after string prefix ''", function(enc, src, pfx)
		 local whole = IN[src]
		 zencode_assert(whole, "Cannot find '" .. src .. "' anywhere (null value?)")
		 local plen = #pfx
		 local wlen = #whole
		 zencode_assert(wlen > plen, "String too short: "
					.. src.. "("..wlen..") prefix("..plen..")")
		 zencode_assert(string.sub(whole, 1, plen) == pfx,
					"Prefix not found in "..src..": "..pfx)
		 -- if not conv and ZEN.schemas[what] then conv = what end
		 ZEN.TMP = guess_conversion(string.sub(whole,plen+1,wlen), enc)
		 ZEN.TMP.name = src
		 ack(src)
		 gc()
end)

Given("'' part of '' before string suffix ''", function(enc, src, sfx)
		 local whole = IN[src]
		 zencode_assert(whole, "Cannot find '" .. src .. "' anywhere (null value?)")
		 local slen = #sfx
		 local wlen = #whole
		 zencode_assert(wlen > slen, "String too short: "
					.. src.. "("..wlen..") suffix("..slen..")")
		 zencode_assert(string.sub(whole, wlen-slen+1, wlen) == sfx,
					"Suffix not found in "..src..": "..sfx)
		 -- if not conv and ZEN.schemas[what] then conv = what end
		 ZEN.TMP = guess_conversion(string.sub(whole,1,wlen-slen), enc)
		 ZEN.TMP.name = src
		 ack(src)
		 gc()
end)

Given("'' in path ''", function(enc, path)
    local path_array = strtok(uscore(path), '.')
    local root = path_array[1]
    table.remove(path_array, 1)
    local dest = path_array[#path_array]
    local res = IN[root]
    for k,v in pairs(path_array) do
        zencode_assert(luatype(res) == 'table', "Object is not a table: "..root)
        zencode_assert(res[v] ~= nil, "Key "..v.." not found in "..root)
        res = res[v]
        root = v
    end
    ZEN.TMP = guess_conversion(res, enc)
    ZEN.TMP.name = dest
    ack(dest)
    gc()
end)

