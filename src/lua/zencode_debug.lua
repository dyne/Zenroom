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

function ZEN:trace(src)
	-- take current line of zencode
	if not src then return end
	local tr = trim(src)

	-- TODO: tabbing, ugly but ok for now
	if string.sub(tr, 1, 1) == '[' then
		table.insert(traceback, tr)
	else
		table.insert(traceback, ' Z  '..tr)
	end
end
-- trace function execution also on success
function ZEN:ftrace(src)
   if DEBUG < 3 then return end
   if not src then return end
   if not traceback then _G['traceback'] = {} end
   table.insert(traceback, ' D  ZEN:' .. trim(src))
end
-- log zencode warning in traceback
function ZEN:wtrace(src)
	table.insert(traceback, ' W  +' .. trim(src))
end
function ZEN:crumb()
   self:ftrace(debug.getinfo(2, 'n').name)
end

-- debug functions
function ZEN:debug_traceback()
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
   local ack = ACK
   local keyring = ack.keyring
   if CONF.debug.format == 'compact' then
	  if keyring then
		 ack.keyring = '(hidden)'
	  end
	  act("HEAP: "..OCTET.to_base64(
			  OCTET.from_string(
				 JSON.encode(
					{GIVEN_data = IN,
					 CODEC = CODEC,
					 WHEN = ack,
					 THEN = OUT}))))
   else -- CONF.debug.format == 'log'
	  -- ack.keyring = '(hidden)'
	  if keyring then
		 I.schema({KEYRING = keyring})
		 ack.keyring = '(hidden)'
	  end
	  I.warn({a_GIVEN_in = IN,
			  c_WHEN_ack = ack,
			  c_CODEC_ack = CODEC,
			  d_THEN_out = OUT})
	  ack.keyring = keyring
   end
end

local function debug_heap_schema()
   I.schema({SCHEMA = {a_GIVEN_in = IN,
					   c_WHEN_ack = ACK,
					   c_CODEC_ack = CODEC,
					   d_THEN_out = OUT}})
   -- print only keys without values
end


zencode_assert = function(condition, errmsg)
   if condition then
      return true
   else
      ZEN.branch_valid = false
   end
   -- in conditional branching zencode_assert doesn't quit
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

function ZEN:debug()
	debug_heap_dump()
	ZEN:debug_traceback()
end

-- local function debug_obj_dump()
-- local function debug_obj_schema()

Given("debug", function() ZEN:debug() end)
When("debug",  function() ZEN:debug() end)
Then("debug",  function() ZEN:debug() end)

Given("schema", function() debug_heap_schema() end)
When("schema",  function() debug_heap_schema() end)
Then("schema",  function() debug_heap_schema() end)

function debug_codec()
   I.warn({CODEC = CODEC})
end

Given("codec", function() debug_codec() end)
When("codec", function() debug_codec() end)
Then("codec", function() debug_codec() end)

Given("config", function() I.warn(_G["CONF"]) end)
When("config", function() I.warn(_G["CONF"]) end)
Then("config", function() I.warn(_G["CONF"]) end)
