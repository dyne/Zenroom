--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]


-- quick internal debugging facility
function xxx(s, n)
   local n <const> = n or 3
   if DEBUG >= n then
	  if LOGFMT == 'JSON' then
		 printerr("\"LUA "..s.."\",")
	  else
		 printerr("LUA "..s)
	  end
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
function ZEN:crumb(msg)
   self:ftrace(debug.getinfo(2, 'n').name)
   if msg then self:ftrace(msg) end
end

-- debug functions
function ZEN:debug_traceback()
   if CONF.debug.format == 'compact' then
	  local tmp = "J64 TRACE: "..OCTET.to_base64(
		 OCTET.from_string(
			JSON.encode(traceback)))
	  if LOGFMT == 'JSON' then tmp = '"'..tmp..'",' end
	  printerr(tmp)
   else
	  for k,v in pairs(traceback) do
		 if LOGFMT == 'JSON' then
			printerr('"'..v..'",')
		 else
			printerr(v)
		 end
	  end
   end
end
Given("backtrace", function() ZEN:debug_traceback() end)
When("backtrace", function() ZEN:debug_traceback() end)
Then("backtrace", function() ZEN:debug_traceback() end)
Given("trace", function() ZEN:debug_traceback() end)
When("trace", function() ZEN:debug_traceback() end)
Then("trace", function() ZEN:debug_traceback() end)

local function debug_heap_schema()
    -- TODO: here we assume that keyring is only made of BIG or OCTET
    local function zero_all_contents(v)
        local t <const> = type(v)
        if t == 'table' then
            zero_all_contents(v)
        else
            if t == 'zenroom.big' then
                return BIG.new(#v:octet())
            elseif iszen(t) then
                return O.zero(#v:octet())
            else
                return O.zero(1)
            end
        end
    end
    local ik <const> = IN.keyring
    local k <const> = ACK.keyring
    if ACK.keyring then
        ACK.keyring = deepmap(zero_all_contents,ACK.keyring)
    end
    if IN.keyring then
        IN.keyring = deepmap(zero_all_contents, IN.keyring)
    end
    local _heap <const> = I.inspect({
        a_CODEC_ack = CODEC,
        b_GIVEN_in = IN,
        c_WHEN_ack = ACK,
        d_THEN_out = OUT
    },{ schema = true })
    ACK.keyring = k
    IN.keyring = ik
    -- print only keys without values
    if CONF.debug.format == 'compact' and LOGFMT == 'JSON' then
        printerr('"J64 HEAP: '..OCTET.from_string(_heap):base64()..'",')
    else
        warn(_heap)
    end
end

local function debug_heap_dump()
   local ack <const> = ACK
   local keyring = ack.keyring
   if CONF.debug.format == 'compact' then
	  if keyring then
		 ack.keyring = '(hidden)'
	  end
	  local tmp = "J64 HEAP: "..OCTET.to_base64(
		 OCTET.from_string(
			JSON.encode(
			   {GIVEN_data = IN,
				CODEC = CODEC,
				WHEN = ack,
				THEN = OUT,
				CACHE = CACHE},
                CONF.debug.encoding.name)))
	  if LOGFMT == 'JSON' then tmp = '"'..tmp..'",' end
	  printerr(tmp)
   else -- CONF.debug.format == 'log'
	  -- ack.keyring = '(hidden)'
	  if keyring then
          I.inspect({KEYRING = ack.keyring}, { schema = true })
          ack.keyring = '(hidden)'
	  end
      I.inspect({a_GIVEN_in = IN,
                 c_WHEN_ack = ack,
                 c_CODEC_ack = CODEC,
                 c_CACHE_ack = CACHE,
                 d_THEN_out = OUT},
          { schema = true }
      )
   end
   ack.keyring = keyring
end


zencode_assert = function(condition, errmsg)
    if condition then return true end
    if ZEN.branch_condition then
        ZEN.branch_valid = ZEN.branch_valid - 1
        table.insert(traceback, errmsg)
        return false
    end
    -- ZEN.debug() -- prints all data in memory
    -- table.insert(traceback, '[!] '..errmsg)
    ZEN.OK = false
    exitcode(1)
    error(errmsg, 3)
end

function ZEN:debug()
	debug_heap_schema()
	ZEN:debug_traceback()
end

-- local function debug_obj_dump()
-- local function debug_obj_schema()

Given("debug", function() debug_heap_schema() ZEN:debug_traceback() end)
When("debug",  function() debug_heap_schema() ZEN:debug_traceback() end)
Then("debug",  function() debug_heap_schema() ZEN:debug_traceback() end)

Given("schema", function() debug_heap_schema() end)
When("schema",  function() debug_heap_schema() end)
Then("schema",  function() debug_heap_schema() end)

function debug_codec()
   I.warn({CODEC = CODEC})
end

Given("break", function() ZEN.OK = false end)
When("break",  function() ZEN.OK = false end)
Then("break",  function() ZEN.OK = false end)

Given("codec", function() debug_codec() end)
When("codec", function() debug_codec() end)
Then("codec", function() debug_codec() end)

Given("config", function() I.warn(_G["CONF"]) end)
When("config", function() I.warn(_G["CONF"]) end)
Then("config", function() I.warn(_G["CONF"]) end)

Then("print codec", function()
		if OUT.codec then
		   error("Cannot overwrite printed output codec")
		end
		OUT.codec = CODEC
end)
