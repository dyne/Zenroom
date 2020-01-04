-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
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
   id = 0,
   AST = {},
   verbosity = 0,
   schemas = { },
   checks = { version = false }, -- version, scenario checked, etc.
   OK = true -- set false by asserts
}

function sentence(self, event, from, to, msg)
   local prefix = parse_prefix(msg)
   local reg
   ZEN.OK = false
   if prefix == 'and' then
	  reg = ZEN[ZEN.machine.current.."_steps"]
   else
    reg = ZEN[prefix.."_steps"]
   end
   ZEN.assert(reg, "Steps register not found: "..prefix.."_steps")
   for pattern,func in pairs(reg) do
	  if (type(func) ~= "function") then
		 error("Zencode function missing: "..pattern, 2)
		 return false
	  end
	  -- TODO: optimize in c
	  -- remove '' contents, lower everything, expunge prefixes
	  local tt = string.gsub(msg,"'(.-)'","''")
	  tt = string.gsub(tt:lower() ,"when " ,"", 1)
	  tt = string.gsub(tt,"then " ,"", 1)
	  tt = string.gsub(tt,"given ","", 1)
	  tt = string.gsub(tt,"and "  ,"", 1) -- TODO: expunge only first 'and'
	  tt = string.gsub(tt,"that " ,"", 1)
	  if strcasecmp(tt, pattern) then
		 local args = {} -- handle multiple arguments in same string
		 for arg in string.gmatch(msg,"'(.-)'") do
			-- xxx(2,"+arg: "..arg)
			arg = string.gsub(arg, ' ', '_')
			table.insert(args,arg)
		 end
		 ZEN.id = ZEN.id + 1
		 -- AST data prototype
		 table.insert(ZEN.AST,
					  { id = ZEN.id, -- ordered number
						args = args,  -- array of vars
						source = msg, -- source text
						section = strtok(msg)[1]:lower(),
						hook = func       }) -- function
		 ZEN.OK = true
		 break
	  end
   end
   if not ZEN.OK and CONF.parser.strict_match then
	  print(ZEN_traceback)
   	  exitcode(1)
   	  error("Zencode pattern not found: "..msg, 2)
   	  return false
   end
end

zencode.machine = MACHINE.create({
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
		 onscenario = function(self, event, from, to, msg)
			-- first word until the colon
			local scenarios = strtok(string.match(msg, "[^:]+"))
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
		 ongiven = sentence,
		 onwhen  = sentence,
		 onthen  = sentence,
		 onand = sentence
	  }
})

-- Zencode HEAP globals
IN = { }         -- Given processing, import global DATA from json
IN.KEYS = { }    -- Given processing, import global KEYS from json
TMP = TMP or { } -- Given processing, temp buffer for ack*->validate->push*
ACK = ACK or { } -- When processing,  destination for push*
OUT = OUT or { } -- print out
AST = AST or { } -- AST of parsed Zencode
WHO = nil

-- Zencode init traceback
_G['ZEN_traceback'] = "Zencode traceback:\n"

-- global
_G["REQUIRED"] = { }
-- avoid duplicating requires (internal includes)
function require_once(ninc)
   local class = REQUIRED[ninc]
   if type(class) == "table" then return class end
   -- new require
   class = require(ninc)
   if type(class) == "table" then REQUIRED[ninc] = class end
   return class
end

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
         CONF.input.encoding = input_encoding(rule[4])
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


---------------------------------------------------------------
-- ZENCODE PARSER

function zencode:begin(verbosity)
   if verbosity > 0 then
      xxx(2,"Zencode debug verbosity: "..verbosity)
      self.verbosity = verbosity
   end
   return true
end

function zencode:iscomment(b)
   local x = string.char(b:byte(1))
   if x == '#' then
	  return true
   else return false
end end
function zencode:isempty(b)
   if b == nil or b == '' then
	   return true
   else return false
end end
function zencode:parse_step(text)
   if ZEN:isempty(text) then return true end
   if ZEN:iscomment(text) then return true end
   -- max length for single zencode line is #define MAX_LINE
   -- hard-coded inside zenroom.h
   local prefix = parse_prefix(text)
   ZEN.assert(prefix, "Invalid Zencode text: "..text)
   local defs -- parse in what phase are we
   ZEN.OK = true
   exitcode(0)
   -- try to enter the machine state named in prefix
   -- xxx(3,"Zencode machine enter_"..prefix..": "..text)
   local fm = ZEN.machine["enter_"..prefix]
   ZEN.assert(fm,"Invalid Zencode prefix: "..prefix)
   ZEN.assert(fm(ZEN.machine, text), text.."\n    "..
				 "Invalid transition from "
				 ..ZEN.machine.current.." to Rule block")
   return true
end


-- returns an iterator for newline termination
function zencode:newline_iter(text)
   s = trim(text) -- implemented in zen_io.c
   if s:sub(-1)~="\n" then s=s.."\n" end
   return s:gmatch("(.-)\n") -- iterators return functions
end

function zencode:parse(text)
   if  #text < 9 then -- strlen("and debug") == 9
   	  warn("Zencode text too short to parse")
   	  return false end
   for line in self:newline_iter(text) do
	  self:parse_step(line)
   end
   collectgarbage'collect'
end

function zencode:trace(src)
   -- take current line of zencode
   local tr = trim(src)
   -- TODO: tabbing, ugly but ok for now
   if string.sub(tr,1,1) == '[' then
	  _G['ZEN_traceback'] = _G['ZEN_traceback']..tr.."\n"
   else
	  _G['ZEN_traceback'] = _G['ZEN_traceback'].." .  "..tr.."\n"
   end
	  -- "    -> ".. src:gsub("^%s*", "") .."\n"
end

-- trace function execution also on success
function zencode:ftrace(src)
   -- take current line of zencode
   _G['ZEN_traceback'] = _G['ZEN_traceback']..
	  " D  ZEN:"..trim(src).."\n"
   -- "    -> ".. src:gsub("^%s*", "") .."\n"
end

-- log zencode warning in traceback
function zencode:wtrace(src)
   -- take current line of zencode
   _G['ZEN_traceback'] = _G['ZEN_traceback']..
	  " W  ZEN:"..trim(src).."\n"
   -- "    -> ".. src:gsub("^%s*", "") .."\n"
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
   end
end

function zencode.debug()
   warn(ZEN_traceback)
   I.warn({ HEAP = { IN = IN,
					TMP = TMP,
					ACK = ACK,
					OUT = OUT }})
end

function zencode.debug_json()
   write(JSON.encode({ TRACE = ZEN_traceback,
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
