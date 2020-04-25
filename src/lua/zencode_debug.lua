-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2020 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- limit output of string if too long
function limit(anystr)
   local t = luatype(anystr)
   ZEN.assert(t=='string',"Argument to limit on-screen not a string")
   if #anystr > 32 then
	  return(string.sub(anystr,1,32).."..")
   end
   return(anystr)
end

-- debug functions
function debug_traceback()
   for k,v in pairs(ZEN.traceback) do
	  warn(v)
   end
end
Given("backtrace", function() debug_traceback() end)
When("backtrace", function() debug_traceback() end)
Then("backtrace", function() debug_traceback() end)

function debug_heap_dump()
   I.warn({HEAP = ZEN.heap()})
end

function debug_heap_schema()
   I.schema({SCHEMA = ZEN.heap()})
   -- print only keys without values
end

-- local function debug_obj_dump()
-- local function debug_obj_schema()

Given("debug", function() ZEN.debug() end)
When("debug",  function() ZEN.debug() end)
Then("debug",  function() ZEN.debug() end)

Given("schema", function() debug_heap_schema() end)
When("schema",  function() debug_heap_schema() end)
Then("schema",  function() debug_heap_schema() end)
