--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
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


-- quick internal debugging facility
function xxx(s, n)
   n = n or 3
   if DEBUG >= n then
	  printerr("LUA "..s)
   end
end

-- set and get to keep track of traceback before HEAP creation
-- ZEN.traceback is moved to HEAP by zencode_begin()
local function get_tb(Z)
	if Z.HEAP then
	   return Z.HEAP.traceback
	else
	   return {}
	end
end
local function set_tb(Z, tb)
	if Z.HEAP then
	   Z.HEAP.traceback = tb
	else
	   Z.traceback = tb
	end
end

function ZEN:trace(src)
	-- take current line of zencode
	if not src then return end
	local tr = trim(src)
	local traceback = get_tb(self)

	-- TODO: tabbing, ugly but ok for now
	if string.sub(tr, 1, 1) == '[' then
		table.insert(traceback, tr)
	else
		table.insert(traceback, ' .  ' .. tr)
	end
	set_tb(self,traceback)
end
-- trace function execution also on success
function ZEN:ftrace(src)
   if not src then return end
	local traceback = get_tb(self)

	table.insert(traceback, ' D  ZEN:' .. trim(src))
	set_tb(self,traceback)
end
-- log zencode warning in traceback
function ZEN:wtrace(src)
	local traceback = get_tb(self)
	table.insert(traceback, ' W  +' .. trim(src))
	set_tb(self,traceback)
end
function ZEN:crumb()
   self:ftrace(debug.getinfo(2, 'n').name)
end

-- debug functions
function ZEN:debug_traceback()
   local traceback = self.HEAP.traceback
   if CONF.debug.format == 'compact' then
	  act("TRACE: "..OCTET.to_base64(
			  OCTET.from_string(
				 JSON.encode(traceback))))
   else
	  for k,v in pairs(traceback) do
		 warn(v)
	  end
   end
end
Given("backtrace", function() ZEN:debug_traceback() end)
When("backtrace", function() ZEN:debug_traceback() end)
Then("backtrace", function() ZEN:debug_traceback() end)
Given("trace", function() ZEN:debug_traceback() end)
When("trace", function() ZEN:debug_traceback() end)
Then("trace", function() ZEN:debug_traceback() end)

local function debug_heap_dump()
   local HEAP = ZEN.HEAP
   local ack = HEAP.ACK
   local keyring = ack.keyring
   if CONF.debug.format == 'compact' then
	  if keyring then
		 ack.keyring = '(hidden)'
	  end
	  act("HEAP: "..OCTET.to_base64(
			  OCTET.from_string(
				 JSON.encode(
					{GIVEN_data = HEAP.IN,
					 CODEC = HEAP.CODEC,
					 WHEN = ack,
					 THEN = HEAP.OUT}))))
   else -- CONF.debug.format == 'log'
	  -- ack.keyring = '(hidden)'
	  if keyring then
		 I.schema({KEYRING = keyring})
		 ack.keyring = '(hidden)'
	  end
	  I.warn({a_GIVEN_in = HEAP.IN,
			  c_WHEN_ack = ack,
			  c_CODEC_ack = HEAP.CODEC,
			  d_THEN_out = HEAP.OUT})
	  ack.keyring = keyring
   end
end

local function debug_heap_schema()
   I.schema({SCHEMA = ZEN.HEAP})
   -- print only keys without values
end


ZEN.assert = function(condition, errmsg)
   local traceback = ZEN.HEAP.traceback
   if condition then
      return true
   else
      ZEN.branch_valid = false
   end
   -- in conditional branching ZEN.assert doesn't quit
   if ZEN.branch then
      table.insert(traceback, errmsg)
   else
      -- ZEN.debug() -- prints all data in memory
      table.insert(traceback, errmsg)
      ZEN.OK = false
      exitcode(1)
      error(errmsg, 3)
   end
end

ZEN.debug = function()
	debug_heap_dump()
	ZEN:debug_traceback()
end

-- local function debug_obj_dump()
-- local function debug_obj_schema()

Given("debug", function() ZEN.debug() end)
When("debug",  function() ZEN.debug() end)
Then("debug",  function() ZEN.debug() end)

Given("schema", function() debug_heap_schema() end)
When("schema",  function() debug_heap_schema() end)
Then("schema",  function() debug_heap_schema() end)

function debug_codec()
   I.warn({CODEC = ZEN.HEAP.CODEC})
end

Given("codec", function() debug_codec() end)
When("codec", function() debug_codec() end)
Then("codec", function() debug_codec() end)

Given("config", function() I.warn(_G["CONF"]) end)
When("config", function() I.warn(_G["CONF"]) end)
Then("config", function() I.warn(_G["CONF"]) end)
