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

--- <h1>Zencode language parser</h1>
--
-- <a href="https://dev.zenroom.org/zencode/">Zencode</a> is a Domain
-- Specific Language (DSL) made to be understood by humans. Its
-- purpose is detailed in <a
-- href="https://files.dyne.org/zenroom/Zencode_Whitepaper.pdf">the
-- Zencode Whitepaper</a> and DECODE EU project.
--
-- @module ZEN
--
-- @author Denis "Jaromil" Roio
-- @license AGPLv3
-- @copyright Dyne.org foundation 2018-2020
--
-- The Zenroom VM is capable of parsing specific scenarios written in
-- Zencode and execute high-level cryptographic operations described
-- in them; this is to facilitate the integration of complex
-- operations in software and the non-literate understanding of what a
-- distributed application does.
--
-- This section doesn't provide the documentation on how to write
-- Zencode. Refer to the links above to learn it. This documentation
-- continues to illustrate internals: how the Zencode direct-syntax
-- parser is made, how it integrates in the Zenroom memory model.

-- This is also the reference implementation to learn how to code
-- Zencode simple scenario using Zeroom's Lua.
--
-- @module ZEN


local zencode = {
   given_steps = {},
   when_steps = {},
   then_steps = {},
   schemas = { },
   id = 0,
   AST = {},
   traceback = { }, -- execution backtrace
   eval_cache = { }, -- zencode_eval if...then conditions
   checks = { version = false }, -- version, scenario checked, etc.
   OK = true -- set false by asserts
}

require('zenroom_ast')


-- set_sentence
-- set_rule

local function new_state_machine()
   local machine = MACHINE.create({
		 initial = 'init',
		 events = {
			{ name = 'enter_rule',     from = { 'init', 'rule', 'scenario' }, to = 'rule' },
			{ name = 'enter_scenario', from = { 'init', 'rule', 'scenario' }, to = 'scenario' },
			{ name = 'enter_given',    from = { 'init', 'rule', 'scenario' }, to = 'given' },
			{ name = 'enter_given',    from =   'given',             to = 'given' },
			{ name = 'enter_and',      from =   'given',             to = 'given' },
			{ name = 'enter_when',     from =   'given',             to = 'when' },
			{ name = 'enter_when',     from =   'when',              to = 'when' },
			{ name = 'enter_and',      from =   'when',              to = 'when' },
			{ name = 'enter_then',     from = { 'given', 'when' },   to = 'then' },
			{ name = 'enter_then',     from =   'then',              to = 'then' },
			{ name = 'enter_and',      from =   'then',              to = 'then' }
		 },
		 callbacks = {
			-- msg is a table: { msg = "string", Z = ZEN (self) }
			onscenario = function(self, event, from, to, msg)
			   -- first word until the colon
			   local scenarios = strtok(string.match(msg.msg, "[^:]+"))
			   for k,scen in ipairs(scenarios) do
				  if k ~= 1 then -- skip first (prefix)
					 require_once("zencode_"..trimq(scen))
					 ZEN:trace("Scenario "..scen)
					 return
				  end
			   end
			end,
			onrule = function(self, event, from, to, msg)
			   -- process rules immediately
			   set_rule(msg)
			end,
			-- set_sentence from zencode_ast
			ongiven = set_sentence,
			onwhen  = set_sentence,
			onthen  = set_sentence,
			onand = set_sentence
		 }
})
   return machine
end

-- Zencode HEAP globals
IN = { }         -- Given processing, import global DATA from json
IN.KEYS = { }    -- Given processing, import global KEYS from json
TMP = TMP or { } -- Given processing, temp buffer for ack*->validate->push*
ACK = ACK or { } -- When processing,  destination for push*
OUT = OUT or { } -- print out
AST = AST or { } -- AST of parsed Zencode
WHO = nil




---------------------------------------------------------------
-- ZENCODE PARSER

function zencode:begin()
   self.id = 0
   self.AST = {}
   self.eval_cache = { }
   self.checks = { version = false } -- version, scenario checked, etc.
   self.OK = true -- set false by asserts
   self.traceback = { }

   -- Reset HEAP
   self.machine = { }
   IN = { }         -- Given processing, import global DATA from json
   IN.KEYS = { }    -- Given processing, import global KEYS from json
   TMP = { } -- Given processing, temp buffer for ack*->validate->push*
   ACK = { } -- When processing,  destination for push*
   OUT = { } -- print out
   AST = { } -- AST of parsed Zencode
   WHO = nil
   collectgarbage'collect'
   -- Zencode init traceback
   self.machine = new_state_machine()
return true
end


function zencode:parse(text)
   if  #text < 9 then -- strlen("and debug") == 9
   	  warn("Zencode text too short to parse")
   	  return false end
   -- xxx(3,text)
   for line in zencode_newline_iter(text) do
	  if zencode_isempty(line) then goto continue end
	  if zencode_iscomment(line) then goto continue end
	  -- max length for single zencode line is #define MAX_LINE
	  -- hard-coded inside zenroom.h
	  local prefix = parse_prefix(line)
	  self.assert(prefix, "Invalid Zencode line: "..line)
	  local defs -- parse in what phase are we
	  self.OK = true
	  exitcode(0)
	  -- try to enter the machine state named in prefix
	  -- xxx(3,"Zencode machine enter_"..prefix..": "..text)
	  local fm = self.machine["enter_"..prefix]
	  self.assert(fm,"Invalid Zencode prefix: "..prefix)
	  self.assert(fm(self.machine, { msg = line, Z = self }),
				  line.."\n    "..
					 "Invalid transition from "
					 ..self.machine.current.." to Rule block")
	  ::continue::
   end
   collectgarbage'collect'
   return true
end

function zencode:trace(src)
   -- take current line of zencode
   local tr = trim(src)
   -- TODO: tabbing, ugly but ok for now
   if string.sub(tr,1,1) == '[' then
	  table.insert(self.traceback, tr)
   else
	  table.insert(self.traceback, " .  "..tr)
   end
end

-- trace function execution also on success
function zencode:ftrace(src)
   -- take current line of zencode
   table.insert(self.traceback, " D  ZEN:"..trim(src))
end

-- log zencode warning in traceback
function zencode:wtrace(src)
   -- take current line of zencode
   table.insert(self.traceback, " W  ZEN:"..trim(src))
end

function zencode:run()
   -- runtime checks
   if not ZEN.checks.version then
	  warn("Zencode is missing version check, please add: rule check version N.N.N")
   end
   -- HEAP setup
   IN = { } -- import global DATA from json
   if DATA then
	  -- if plain array conjoin into associative
	  IN = CONF.input.format.fun(DATA) or { }
   end
   IN.KEYS = { } -- import global KEYS from json
   if KEYS then IN.KEYS = CONF.input.format.fun(KEYS) or { } end
   -- EXEC zencode
   for i,x in sort_ipairs(self.AST) do
	  ZEN:trace(x.source)

	  -- HEAP integrity guard
	  if CONF.heapguard then
		 if x.section == 'then' or x.section == 'when' then
			-- delete IN memory
			IN.KEYS = { }
			IN = { }
			collectgarbage'collect'
			-- guard ACK's contents on section switch
			zenguard(ACK)
		 end
	  end

	  ZEN.OK = true
	  exitcode(0)
      local ok, err = pcall(x.hook,table.unpack(x.args))
      if not ok or not ZEN.OK then
	  	 if err then ZEN:trace("[!] "..err) end
		 fatal(x.source) -- traceback print inside
	  end
	  collectgarbage'collect'
   end
   -- PRINT output
   ZEN:trace("--- Zencode execution completed")
   if type(OUT) == 'table' then
	  ZEN:trace("+++ Adding setup information to { OUT }")
	  if CONF.output.versioning == true then
		 OUT.zenroom = { }
		 OUT.zenroom.version = VERSION.original
		 -- OUT.zenroom.scenario = ZEN.scenario
	  end
	  ZEN:trace("<<< Encoding { OUT } to "..CONF.output.format.name)
	  print(CONF.output.format.fun(OUT))
	  ZEN:trace(">>> Encoding successful")
   else -- this should never occur in zencode, OUT is always a table
	  ZEN:trace("<<< Printing OUT (plain format, not a table)")
	  print(OUT)
   end
   -- print the AST to stderr
   if CONF.output.AST == true then
	  printerr("#+AST_BEGIN")
	  printerr(CONF.output.format.fun(ZEN.AST))
	  printerr("#+AST_END")
   end
end

function zencode.heap()
   return({ IN = IN,
			TMP = TMP,
			ACK = ACK,
			OUT = OUT })
end

function zencode.debug()
   debug_traceback()
   debug_heap_dump()

   -- I.warn(ZEN.traceback)
   -- I.warn({ HEAP = { IN = IN,
   -- 					TMP = TMP,
   -- 					ACK = ACK,
   -- 					OUT = OUT }})
end

function zencode.debug_json()
   write(JSON.encode({ TRACE = ZEN.traceback,
                       HEAP = { IN = IN,
                                TMP = TMP,
                                ACK = ACK,
                                OUT = OUT }}))
end

function zencode.assert(condition, errmsg)
   if condition then return true end
   -- ZEN.debug() -- prints all data in memory
   ZEN:trace("ERR "..errmsg)
   ZEN.OK = false
   exitcode(1);
   error(errmsg, 3)
end

return zencode
