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
--on Monday, 26th April 2021
--]]

-- TODO: use strict table
-- https://stevedonovan.github.io/Penlight/api/libraries/pl.strict.html

-- the main security concern in this Zencode module is that no data
-- passes without validation from IN to ACK or from inline input.

-- GIVEN
local function gc()
   TMP = {}
   collectgarbage 'collect'
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
   raw = IN.KEYS[what] or IN[what]
   ZEN.assert(raw, "Cannot find '" .. what .. "' anywhere (null value?)")
   ZEN.assert(raw ~= '', "Found empty string in '" .. what)
   -- if not conv and ZEN.schemas[what] then conv = what end
   TMP = guess_conversion(raw, conv or what)
   ZEN.assert(
      TMP,
      'Cannot guess any conversion for: ' ..
         luatype(raw) .. ' ' .. (conv or what or '(nil)')
   )
   TMP.name = what
   assert(ZEN.OK)
   if DEBUG > 1 then
      ZEN:ftrace('pick found ' .. what)
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
   root = IN.KEYS[section]
   if root then
      raw = root[what]
      if raw then
         goto found
      end
   end
   root = IN[section]
   if root then
      raw = root[what]
      if raw then
         goto found
      end
   end

   -- TODO: check all corner cases to make sure TMP[what] is a k/v map
   ::found::
   ZEN.assert(
      raw,
      "Cannot find '" .. what .. "' inside '" .. section .. "' (null value?)"
   )
   ZEN.assert(raw ~= '', "Found empty string '" .. what .."' inside '"..section.."'")

   -- conv = conv or what
   -- if not conv and ZEN.schemas[what] then conv = what end
   -- if no encoding provided then conversion is same as name (schemas etc.)
   TMP = guess_conversion(raw, conv or what)
   TMP.name = what
   TMP.root = section
   assert(ZEN.OK)
   if DEBUG > 1 then
      ZEN:ftrace('pickin found ' .. what .. ' in ' .. section)
   end
end

local function ack_table(key, val)
   ZEN.assert(
      type(key) == 'string',
      'ZEN:table_add arg #1 is not a string'
   )
   ZEN.assert(
      type(val) == 'string',
      'ZEN:table_add arg #2 is not a string'
   )
   if not ACK[key] then
      ACK[key] = {}
   end
   ACK[key][val] = operate_conversion(TMP)
   ZEN.CODEC[key] = {
      name = TMP.name,
      luatype = 'table',
      zentype = 'dictionary',
      encoding = TMP.encoding,
      root = TMP.root
   }
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
local function ack(name)
   ZEN.assert(TMP, 'No valid object found: ' .. name)
   -- CODEC[what] = CODEC[what] or {
   --    name = guess.name,
   --    istable = guess.istable,
   --    isschema = guess.isschema }
   ZEN.assert(
      not ACK[name],
      'Destination already exists, cannot overwrite: ' .. name,
      2
   )
   assert(ZEN.OK)
   ACK[name] = operate_conversion(TMP)
   -- save codec state
   ZEN.CODEC[name] = {
      name = TMP.name,
      luatype = TMP.luatype,
      zentype = TMP.zentype,
      encoding = TMP.encoding,
      root = TMP.root
   }
   -- ACK[name] already holds an object
   -- not a table?
   -- if not (dsttype == 'table') then -- convert single object to array
   -- 	  ACK[name] = { ACK[name] }
   -- 	  table.insert(ACK[name], operate_conversion(TMP))
   -- 	  goto done
   -- end
   -- -- it is a table already
   -- if isarray(ACK[name]) then -- plain array
   -- 	  table.insert(ACK[name], operate_conversion(TMP))
   -- 	  goto done
   -- else -- associative map (dictionary)
   -- 	  table.insert(ACK[name], operate_conversion(TMP)) -- TODO: associative map insertion
   -- 	  goto done
   -- end
   -- ::done::
   -- assert(ZEN.OK)
end

Given(
   'nothing',
   function()
      ZEN.assert(
         not DATA and not KEYS,
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
   "a '' named '' in ''",
   function(s, n, t)
      pickin(t, n, s)
      ack(n) -- save it in ACK.name
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
