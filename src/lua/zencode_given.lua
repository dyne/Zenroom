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
-- passes without validation from IN to ACK or from inline input.

-- data coming in is analyzed through a series of functions:
-- guess_conversion(raw, conv or name) -> zenode_data.lua L:100 approx 
--- |_ if luatype(string) && format -> input encoding(format)

-- GIVEN
local function gc()
   TMP = {}
   collectgarbage 'collect'
end

-- safely take any zenroom object as index
local function _index_to_string(what)
   local t = type(what)
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
-- it ready in TMP for @{validate} or @{ack}.
--
-- @function pick(name, data, encoding)
-- @param what string descriptor of the data object
-- @param conv[opt] optional encoding spec (default CONF.input.encoding)
-- @return true or false
local function pick(what, conv)
   local guess
   local data
   local raw
   local name = _index_to_string(what)
   -- keyring special object
   if name == 'keyring' then -- backward compat
      local keyring = KIN.keyring or IN.keyring
      if not keyring then error("Keyring not found in input", 2) end
      TMP = { fun = import_keyring,
	      encoding = 'keyring',
	      raw = keyring,
	      name = 'keyring',
	      luatype = 'table',
	      zentype = 'schema' }
      return true
   end
   ---
   raw = KIN[name] or IN[name]
   if not raw then error("Cannot find '" .. name .. "' anywhere (null value?)", 2) end
   if raw == '' then error("Found empty string in '" .. name) end
   -- if not conv and ZEN.schemas[what] then conv = what end
   TMP = guess_conversion(raw, conv or name)
   if not TMP then error('Cannot guess any conversion for: ' ..
         luatype(raw) .. ' ' .. (conv or name or '(nil)')) end
   TMP.name = name
   TMP.schema = conv
   assert(ZEN.OK)
   if DEBUG > 1 then
      ZEN:ftrace('pick found ' .. name .. '('..TMP.zentype..')')
   end
end

---
-- Pick a data structure named 'what' contained under a 'section' key
-- of the at the root of the <b>IN</b> memory space. Looks for named
-- data at the first and second level underneath IN[section] and moves
-- it to TMP[what][section], ready for @{validate} or @{ack}. If
-- TMP[what] exists already, every new entry is added as a key/value
--
-- @function pickin(section, name)
-- @param section string descriptor of the section containing the data
-- @param what string descriptor of the data object
-- @param conv string explicit conversion or schema to use
-- @param fail bool bail out or continue on error
-- @return true or false
local function pickin(section, what, conv, fail)
   ZEN.assert(section, 'No section specified')
   local root  -- section
   local raw  -- data pointer
   local bail  -- fail
   local name = _index_to_string(what)

   if KIN[section] then
      root = KIN[section]
   elseif IN[section] then
      root = IN[section]
   else
      root = nil
   end
   if not root then
      error("Cannot find '"..section.."'", 2)
   end
   if name == 'keyring' then -- backward compat
      local keyring = root.keyring
      if not keyring then error("Keyring not found in section: "..section, 2) end
      TMP = { fun = import_keyring,
	      encoding = 'keyring',
	      raw = keyring,
	      root = section,
	      name = 'keyring',
	      luatype = 'table',
	      zentype = 'schema' }
      return true
   end

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
   if not raw then
      error("Object not found: "..name.." in "..section, 2)
   end

   if raw == '' then
      error("Found empty string '" .. name .."' inside '"..section.."'", 2) end
   -- conv = conv or name
   -- if not conv and ZEN.schemas[name] then conv = name end
   -- if no encoding provided then conversion is same as name (schemas etc.)
   TMP = guess_conversion(raw, conv or name)
   TMP.name = name
   TMP.root = section
   TMP.schema = conv
   assert(ZEN.OK)
   if DEBUG > 1 then
      ZEN:ftrace('pickin found ' .. name .. ' in ' .. section)
   end
end


 -- takes a data object and the guessed structure, operates the
 -- conversion and returns the resulting raw data to be used inside the
 -- WHEN block in HEAP.
 function operate_conversion(guessed)
    -- check if already a zenroom type
    -- (i.e. zenroom.big from json decode)
    if not guessed.fun then
       I.warn(guessed)
       error('No conversion operation guessed', 2)
       return nil
    end
    -- carry guessed detection in CODEC
    ZEN.CODEC[guessed.name] = {
       name = guessed.name,
       encoding = guessed.encoding,
       zentype = guessed.zentype,
       luatype = guessed.luatype,
       root = guessed.root,
       schema = guessed.schema,
    }
    -- I.warn({ codec = ZEN.CODEC[guessed.name],
    --	     guessed = guessed })
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
    else -- element

       -- corner case: input is already a zenroom type
       if guessed.luatype == 'userdata' then
	  if iszen(guessed.rawtype) then
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
       return guessed.fun(guessed.raw)
    end
 end

local function ack_table(key, val)
   ZEN.assert(
      luatype(key) == 'string',
      'ZEN:table_add arg #1 is not a string'
   )
   ZEN.assert(
      luatype(val) == 'string',
      'ZEN:table_add arg #2 is not a string'
   )
   if not ACK[key] then
      ACK[key] = {}
   end
   ACK[key][val] = operate_conversion(TMP)
   if key ~= TMP.name then
      ZEN.CODEC[key] = ZEN.CODEC[TMP.name]
      ZEN.CODEC[TMP.name] = nil
   end
end

---
-- Final step inside the <b>Given</b> block towards the <b>When</b>:
-- pass on a data structure into the ACK memory space, ready for
-- processing.  It requires the data to be present in TMP[name] and
-- typically follows a @{pick}. In some restricted cases it is used
-- inside a <b>When</b> block following the inline insertion of data
-- from zencode.
--
-- @function ack(name)
-- @param name string key of the data object in TMP[name]
local function ack(what)
   local name = _index_to_string(what)
   ZEN.assert(TMP, 'No valid object found: ' .. name)
   empty(name)
   ACK[name] = operate_conversion(TMP)
   -- name of schema may differ from name of object
   -- new_codec(name, { schema = TMP.schema })

   -- if TMP.schema and (TMP.schema ~= 'number') and ( TMP.schema ~= TMP.encoding ) then
   --    ZEN.CODEC[name].schema = TMP.schema
   -- end

end

Given(
   'nothing',
   function()
      ZEN.assert(
         (next(IN) == nil) and (next(KIN) == nil),
         'Undesired data passed as input'
      )
   end
)

-- maybe TODO: Given all valid data
-- convert and import data only when is known by schema and passes validation
-- ignore all other data structures that are not known by schema or don't pass validation

Given(
   "am ''",
   function(name)
      Iam(name)
   end
)

Given(
   "my name is in a '' named ''",
   function(sc, name)
      pick(name, sc)
      assert(TMP.name, 'No name found in: ' .. name)
      Iam(O.to_string(operate_conversion(TMP)))
      ZEN.CODEC[name] = nil -- just used to get name
   end
)

Given(
   "my name is in a '' named '' in ''",
   function(sc, name, struct)
      pickin(struct, name, sc)
      assert(TMP.name,  'No name found in: '..name)
      Iam(O.to_string(operate_conversion(TMP)))
      ZEN.CODEC[name] = nil -- just name string
   end
)

-- variable names:
-- s = schema of variable (or encoding)
-- n = name of variable
-- t = table containing the variable

-- TODO: I have a '' as ''
Given(
   "a ''",
   function(n)
      pick(n)
      ack(n)
      gc()
   end
)

Given(
   "a '' in ''",
   function(s, t)
      pickin(t, s)
      ack(s) -- save it in ACK.obj
      gc()
   end
)

-- public keys for keyring arrays
-- returns a special array for upcoming session:
-- public_key_session : { name : value }
Given(
   "a '' public key from ''",
   function(s, t)
      -- if not pickin(t, s, nil, false) then
      -- 	pickin(s, t)
      -- end
      pickin(t, s..'_public_key', s..'_public_key', false)
      ack_table('public_key_session', t)
   end
)

Given(
   "a '' from ''",
   function(s, t)
      -- if not pickin(t, s, nil, false) then
      -- 	pickin(s, t)
      -- end
      pickin(t, s, s, false)
      ack_table(s, t)
      gc()
   end
)

Given(
   "a '' named ''",
   function(s, n)
      -- ZEN.assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      pick(n, s)
      ack(n)
      gc()
   end
)

Given(
   "a '' named by ''",
   function(s, n)
      -- local name = have(n)
      local name = _index_to_string(KIN[n] or IN[n])
      -- ZEN.assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      pick(name, s)
      ack(name)
      gc()
   end
)

Given(
   "a '' named '' in ''",
   function(s, n, t)
      pickin(t, n, s)
      ack(n) -- save it in ACK.name
      gc()
   end
)

Given(
   "a '' named by '' in ''",
   function(s, n, t)
      local name = _index_to_string(KIN[n] or IN[n])
      pickin(t, name, s)
      ack(name) -- save it in ACK.name
      gc()
   end
)

Given(
   "my ''",
   function(n)
      ZEN.assert(WHO, 'No identity specified, use: Given I am ...')
      pickin(WHO, n)
      ack(n)
      gc()
   end
)

Given(
   "my '' named ''",
   function(s, n)
      -- ZEN.assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      pickin(WHO, n, s)
      ack(n)
      gc()
   end
)
Given(
   "my '' named by ''",
   function(s, n)
      -- ZEN.assert(encoder, "Invalid input encoding for '"..n.."': "..s)
      local name = _index_to_string(KIN[n] or IN[n])
      pickin(WHO, name, s)
      ack(name)
      gc()
   end
)

Given(
   "a '' is valid",
   function(n)
      pick(n)
      gc()
   end
)
Given(
   "my '' is valid",
   function(n)
      pickin(WHO, n)
      gc()
   end
)

Given(
   "rename '' to ''",
   function(old, new)
       empty(new)
       have(old)
       ACK[new] = ACK[old]
       new_codec(new, ZEN.CODEC[old])
       ZEN.CODEC[new].name = new

       ACK[old] = nil
       ZEN.CODEC[old] = nil
   end
)

Given("a '' part of '' after string prefix ''", function(enc, src, pfx)
		 local whole = KIN[src] or IN[src]
		 ZEN.assert(whole, "Cannot find '" .. src .. "' anywhere (null value?)")
		 local plen = #pfx
		 local wlen = #whole
		 ZEN.assert(wlen > plen, "String too short: "
					.. src.. "("..wlen..") prefix("..plen..")")
		 ZEN.assert(string.sub(whole, 1, plen) == pfx,
					"Prefix not found in "..src..": "..pfx)
		 -- if not conv and ZEN.schemas[what] then conv = what end
		 TMP = guess_conversion(string.sub(whole,plen+1,wlen), enc)
		 TMP.name = src
		 ack(src)
		 gc()
end)

Given("a '' part of '' before string suffix ''", function(enc, src, sfx)
		 local whole = KIN[src] or IN[src]
		 ZEN.assert(whole, "Cannot find '" .. src .. "' anywhere (null value?)")
		 local slen = #sfx
		 local wlen = #whole
		 ZEN.assert(wlen > slen, "String too short: "
					.. src.. "("..wlen..") suffix("..slen..")")
		 ZEN.assert(string.sub(whole, wlen-slen+1, wlen) == sfx,
					"Suffix not found in "..src..": "..sfx)
		 -- if not conv and ZEN.schemas[what] then conv = what end
		 TMP = guess_conversion(string.sub(whole,1,wlen-slen), enc)
		 TMP.name = src
		 ack(src)
		 gc()
end)
