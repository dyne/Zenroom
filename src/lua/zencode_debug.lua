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

-- debug functions
local function debug_traceback()
   for k,v in pairs(ZEN.traceback) do
	  act(v)
   end
end
Given("backtrace", function() debug_traceback() end)
When("backtrace", function() debug_traceback() end)
Then("backtrace", function() debug_traceback() end)

local function debug_heap_dump()
   I.warn({HEAP = ZEN.heap()})
end

local function debug_heap_schema()
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
