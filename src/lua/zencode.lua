--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2023 Dyne.org foundation
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
--- <h1>Zencode language parser</h1>
--
-- <a href="https://dev.zenroom.org/zencode/">Zencode</a> is a Domain
-- Specific Language (DSL) made to be understood by humans. Its
-- purpose is detailed in <a
-- href="https://files.dyne.org/zenroom/Zencode_Whitepaper.pdf">the
-- Zencode Whitepaper</a> and DECODE EU project.
--
-- @module Zencode
--
-- @author Denis "Jaromil" Roio
-- @license AGPLv3
-- @copyright Dyne.org foundation 2018-2023
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
-- @module Zencode

ZEN = {
	given_steps = {},
	when_steps = {},
	if_steps = {},
	endif_steps = { endif = function() return end }, --nop
	foreach_steps = {},
	endforeach_steps = { endforeach = function() return end }, --nop
	then_steps = {},
	schemas = {},
	branch = false,
	branch_valid = false,
	id = 0,
	checks = {version = false}, -- version, scenario checked, etc.
	OK = true, -- set false by asserts
	current_instruction = 0, -- first instruction
	next_instruction = 1, -- first instruction
	ITER = nil, -- foreach infos
	traceback = {}, -- transferred into HEAP by zencode_begin
	linenum = 0,
	last_valid_statement = false
}


function ZEN:add_schema(arr)
	local _illegal_schemas = {
		-- const
		whoami = true
	}
	for k, v in pairs(arr) do
		-- check overwrite / duplicate to avoid scenario namespace clash
		if self.schemas[k] then
			error('Add schema denied, already registered schema: ' .. k, 2)
		end
		if _illegal_schemas[k] then
			error('Add schema denied, reserved name: ' .. k, 2)
		end
		self.schemas[k] = v
	end
end

function ZEN:begin(new_heap)
   self:crumb()
   if new_heap then
	  -- TODO: setup with an existing HEAP
   else
	  IN  = {} -- Given processing, import global DATA from json
	  ACK = {} -- When processing,  destination for push*
	  OUT = {} -- print out
	  CODEC = {} -- metadata
	  WHO = nil
	  traceback = {}
   end

	-- stateDiagram
    -- [*] --> Given
    -- Given --> When
    -- When --> Then
    -- state branch {
    --     IF
    --     when then
    --     --
    --     EndIF
    -- }
    -- When --> branch
    -- branch --> When
    -- Then --> [*]

	local function set_sentence(self, event, from, to, ctx)
	   local translate <const> = {
		  whenif = 'when',
		  thenif = 'then',
		  whenforeach = 'when',
		  whenforeachif = 'when',
		  whenifforeach = 'when',
		  foreachif = 'foreach',
		  endforeachif = 'endforeach',
		  ifforeach = 'if',
		  endifforeach = 'endif',
	   }
	   local current <const> = self.current
	   local index <const> = translate[current] or current
	   -- save in reg a pointer to array of statements
	   local reg <const> = ctx.Z[index .. '_steps']
	   local sentence <const> = ctx.msg
	   local linenum <const> = ctx.Z.linenum
	   ctx.Z.OK = false
	   xxx('Zencode parser from: ' .. from .. " to: "..to, 3)
	   assert(reg,'Callback register not found: ' .. current)
	   -- assert(#reg,'Callback register empty: '..current)
	   local gsub <const> = string.gsub -- optimization
	   -- TODO: optimize in C
	   -- remove '' contents, lower everything, expunge prefixes
	   -- ignore 'the' only in Then statements
	   local tt = gsub(sentence, "'(.-)'", "''") -- msg trimmed on parse
	   tt = gsub(tt, ' I ', ' ', 1) -- eliminate first person pronoun
	   tt = tt:lower() -- lowercase all statement
	   if to == 'then' or to == 'thenif' then
		  tt = gsub(tt, ' the ', ' ', 1)
	   end
	   if to == 'given' then
		  tt = gsub(tt, ' the ', ' ', 1)
		  tt = gsub(tt, ' a ', ' ', 1)
		  tt = gsub(tt, ' an ', ' ', 1)
		  tt = gsub(tt, ' have ', ' ', 1)
		  tt = gsub(tt, ' known as ', ' ', 1)
		  tt = gsub(tt, ' valid ', ' ', 1)
	   end
	   -- prefixes found at beginning of statement
	   tt = gsub(tt, '^when ', '', 1)
	   tt = gsub(tt, '^then ', '', 1)
	   tt = gsub(tt, '^given ', '', 1)
	   tt = gsub(tt, '^if ', '', 1)
	   tt = gsub(tt, '^foreach ', '', 1)
	   tt = gsub(tt, '^and ', '', 1) -- TODO: expunge only first 'and'
	   -- generic particles
	   tt = gsub(tt, '^that ', ' ', 1)
	   tt = gsub(tt, ' the ', ' ')
	   tt = gsub(tt, '^an ', 'a ', 1) -- equivalence
	   tt = gsub(tt, ' valid ', ' ', 1) -- backward compat (v1)
	   tt = gsub(tt, ' all ', ' ', 1)
	   tt = gsub(tt, ' inside ', ' in ', 1) -- equivalence
	   -- TODO: expire deprecation then activate equivalence
	   -- tt = gsub(tt, ' size ', ' length ', 1)
	   -- trimming
	   tt = gsub(tt, ' +', ' ') -- eliminate multiple internal spaces
	   tt = gsub(tt, '^ +', '') -- remove initial spaces
	   tt = gsub(tt, ' +$', '') -- remove final spaces
	   --
	   local func <const> = reg[tt] -- lookup the statement
	   if func and luatype(func) == 'function' then
		  local args = {} -- handle multiple arguments in same string
		  for arg in string.gmatch(sentence, "'(.-)'") do
			 -- convert all spaces to underscore in argument strings
			 arg = uscore(arg, ' ', '_')
			 table.insert(args, arg)
		  end
		  ctx.Z.id = ctx.Z.id + 1
		  -- AST data prototype
		  table.insert(
			 AST,
			 {
				id = ctx.Z.id, -- ordered number
				args = args, -- array of vars
				source = sentence, -- source text
				section = current,
				from = from,
				to = to,
				hook = func,
				linenum = linenum
			 }
		  ) -- function
		  ctx.Z.OK = true
	   end
	   if not ctx.Z.OK and CONF.parser.strict_match then
		  ctx.Z.debug()
		  exitcode(1)
		  error('Zencode line '..linenum..' pattern not found ('..index..'): ' .. trim(sentence), 1)
		  return false
	   end
	   if not CONF.parser.strict_match then
		   if index == 'given' then
			   assert(not ctx.Z.last_valid_statement or ctx.Z.OK,
					  'Zencode line '..linenum..' found invalid statement after a valid one in the given phase: '..trim(sentence))
		   elseif index == 'then' then
			   assert(ctx.Z.last_valid_statement or not ctx.Z.OK,
					  'Zencode line '..linenum..' found valid statement after an invalid one in the then phase: '..trim(sentence))
		   else
			   assert(ctx.Z.OK, 'Zencode line '..linenum..' found invalid statement out of given or then phase: '..trim(sentence))
		   end
		   if not ctx.Z.OK then
			   table.insert(traceback, '-'..linenum..'	'..sentence)
			   warn('Zencode line '..linenum..' pattern ignored: ' .. sentence, 1)
		   end
	   end
	   ctx.Z.last_valid_statement = ctx.Z.OK
	   return true
	end
	-- END local function set_sentence

	local function set_rule(text)
	   local tr = text.msg:gsub(' +', ' ') -- eliminate multiple internal spaces
	   local rule = strtok(trim(tr):lower())
	   local rules <const> = {
		  -- TODO: rule debug [ format | encoding ]
		  -- ['load'] = function(extension)
		  --	if not extension then return false end
		  --  act("zencode extension: "..extension)
		  --  require("zencode_"..extension)
		  -- 	return true
		  -- end,
		  ['check version'] = function (version)
			 -- TODO: check version of running VM
			 if not version then return false end
			 local ver = SEMVER(version)
			 if ver == ZENROOM_VERSION then
				act('Zencode version match: ' .. ZENROOM_VERSION.original)
			 elseif ver < ZENROOM_VERSION then
				warn('Zencode written for an older version: ' .. ver.original)
			 elseif ver > ZENROOM_VERSION then
				warn('Zencode written for a newer version: ' .. ver.original)
			 else
				error('Version check error: ' .. version)
			 end
			 text.Z.checks.version = true
			 return true
		  end,
		  ['input encoding'] = function (encoding)
			 if not encoding then return false end
			 CONF.input.encoding = input_encoding(encoding)
			 return true and CONF.input.encoding
		  end,
		  ['input format'] = function (format)
			 if not format then return false end
			 CONF.input.format = get_format(format)
			 return true and CONF.input.format
		  end,
		  ['input untagged'] = function ()
			 CONF.input.tagged = false
			 return true
		  end,
		  ['output encoding'] = function (encoding)
			 if not encoding then return false end
			 CONF.output.encoding = { fun = get_encoding_function(encoding),
									  name = encoding }
			 return true and CONF.output.encoding
		  end,
		  ['output format'] = function (format)
			 if not format then return false end
			 CONF.output.format = get_format(format)
			 return true and CONF.output.format
		  end,
		  ['output versioning'] = function ()
			 CONF.output.versioning = true
			 return true
		  end,
		  ['unknown ignore'] = function ()
			 CONF.parser.strict_match = false
			 return true
		  end,
		  ['set'] = function (conf, value)
			 if not conf or not value then return false end
			 CONF[conf] = fif( tonumber(value), tonumber(value),
							   fif( value=='true', true,
									fif( value=='false', false,
										 value)))
			 return true
		  end,
	   }
	   local res
	   if rule[2] == 'set' then
		  res = rules[rule[2]](rule[3], rule[4])
	   else
		  res = rules[rule[2]..' '..rule[3]] and rules[rule[2]..' '..rule[3]](rule[4])
	   end
	   if res then act(text.msg) else error('Rule invalid: ' .. text.msg, 3) end
	   return res
	end
	-- END local function set_rule

	-- state machine callback events
	-- graph TD
	--     Given --> When
	--     IF --> When
	--     Then --> When
	--     Given --> IF
	--     When --> IF
	--     Then --> IF
	--     IF --> Then
	--     IF -> FOR
	--     When -> FOR
	--     FOR -> When
	--     FOR -> Then
	--     FOR -> IF
	--     FOR -> Then
	--     When --> Then
	--     Given --> Then
	local callbacks = {
	   -- msg is a table: { msg = "string", Z = stack (self) }
	   onscenario = function(self, event, from, to, msg)
		  -- first word until the colon
		  local scenarios =
			 strtok(string.match(trim(msg.msg):lower(), '[^:]+'))
		  for k, scen in ipairs(scenarios) do
			 if k ~= 1 then -- skip first (prefix)
				load_scenario('zencode_' .. trimq(scen))
				-- self:trace('Scenario ' .. scen)
				return
			 end
		  end
	   end,
	   onrule = function(self, event, from, to, msg)
		  -- process rules immediately
		  if msg then	set_rule(msg) end
	   end,
	   ongiven = set_sentence,
	   onthen = set_sentence,
	   onand = set_sentence
	}
	local events = {
	   {name = 'enter_rule', from = {'init', 'rule', 'scenario'}, to = 'rule'},
	   {name = 'enter_scenario', from = {'init', 'rule', 'scenario'}, to = 'scenario'},
	   {name = 'enter_given', from = {'init', 'rule', 'scenario'},	to = 'given'},
	   {name = 'enter_given', from = {'given'}, to = 'given'},
	   {name = 'enter_and', from = 'given', to = 'given'},
	}
	if CONF.exec.scope == 'full' then
	   -- rule output given-only
	   callbacks.onwhen = set_sentence
	   callbacks.onif = set_sentence
	   callbacks.onendif = set_sentence
	   callbacks.onwhenif = set_sentence
	   callbacks.onthenif = set_sentence
	   callbacks.onforeach = set_sentence
	   callbacks.onendforeach = set_sentence
	   callbacks.onwhenforeach = set_sentence
	   callbacks.onforeachif = set_sentence
	   callbacks.onwhenforeachif = set_sentence
	   callbacks.onendforeachif = set_sentence
	   callbacks.onifforeach = set_sentence
	   callbacks.onwhenifforeach = set_sentence
	   callbacks.onendifforeach = set_sentence
	   local extra_events <const> = {
		  {name = 'enter_when', from = {'given', 'when', 'then', 'endif', 'endforeach'}, to = 'when'},
		  {name = 'enter_if', from = {'if', 'given', 'when', 'then', 'endif', 'endforeach'}, to = 'if'},
		  {name = 'enter_whenif', from = {'if', 'whenif', 'thenif', 'endforeachif'}, to = 'whenif'},
		  {name = 'enter_thenif', from = {'if', 'whenif', 'thenif'}, to = 'thenif'},
		  {name = 'enter_endif', from = {'whenif', 'thenif', 'endforeachif'}, to = 'endif'},
		  {name = 'enter_foreachif', from = {'if', 'whenif', 'endforeachif', 'foreachif'}, to = 'foreachif'},
		  {name = 'enter_whenforeachif', from = {'foreachif', 'whenforeachif'}, to = 'whenforeachif'},
		  {name = 'enter_endforeachif', from = {'foreachif', 'whenforeachif'}, to = 'endforeachif'},
		  {name = 'enter_ifforeach', from = {'foreach', 'whenforeach', 'ifforeach', 'endifforeach'}, to = 'ifforeach'},
		  {name = 'enter_whenifforeach', from = {'ifforeach', 'whenifforeach'}, to = 'whenifforeach'},
		  {name = 'enter_endifforeach', from = {'ifforeach', 'whenifforeach'}, to = 'endifforeach'},
		  {name = 'enter_foreach', from = {'given', 'when', 'endif', 'foreach'}, to = 'foreach'},
		  {name = 'enter_whenforeach', from = {'foreach', 'whenforeach', 'endifforeach'}, to = 'whenforeach'},
		  {name = 'enter_endforeach', from = {'whenforeach', 'endifforeach'}, to = 'endforeach'},
		  {name = 'enter_and', from = 'when', to = 'when'},
		  {name = 'enter_and', from = 'whenif', to = 'whenif'},
		  {name = 'enter_and', from = 'thenif', to = 'thenif'},
		  {name = 'enter_and', from = 'if', to = 'if'},
		  {name = 'enter_and', from = 'foreach', to = 'foreach'},
		  {name = 'enter_and', from = 'ifforeach', to = 'ifforeach'},
		  {name = 'enter_and', from = 'foreachif', to = 'foreachif'},
		  {name = 'enter_and', from = 'whenforeach', to = 'whenforeach'},
		  {name = 'enter_and', from = 'whenifforeach', to = 'whenifforeach'},
		  {name = 'enter_then', from = {'given', 'when', 'then', 'endif', 'endforeach'}, to = 'then'},
		  {name = 'enter_and', from = 'then', to = 'then'},
	   }
	   for _,v in pairs(extra_events) do table.insert(events, v) end
	end

	self.machine = MACHINE.create({
		initial = 'init',
		events = events,
		callbacks = callbacks
	})
	collectgarbage 'collect'
	-- Zencode init traceback
	return true
end

-- returns an iterator for newline termination
local function zencode_newline_iter(text)
	return text:gmatch("[^\r\n]*")
end
local function zencode_isempty(b)
	if b == nil or b == '' then
		return true
	else
		return false
	end
end
local function zencode_iscomment(b)
	local x <const> = string.sub(b,1,1) -- string.char(b:byte(1))
	if x == '#' then
		return true
	else
		return false
	end
end


function ZEN:parse(text)
   self:crumb()
   if #text < 9 then -- strlen("and debug") == 9
	  error("Zencode text too short to parse")
	  return false
   end
   local branching = false
   local looping = false
   local prefixes = {}
   local parse_prefix <const> = parse_prefix -- optimization
   self.linenum = 0
   for line in zencode_newline_iter(text) do
	  self.linenum = self.linenum + 1
	  local tline = trim(line) -- saves trims in isempty / iscomment
	  if not zencode_isempty(tline) and not zencode_iscomment(tline) then
		 --   xxx('Line: '.. text, 3)
		 -- max length for single zencode line is #define MAX_LINE
		 -- hard-coded inside zenroom.h
		 local prefix = parse_prefix(line) -- trim is included
		 assert(prefix, "Invalid Zencode line "..self.linenum..": "..line)
		 self.OK = true
		 exitcode(0)
		 if not branching and prefix == 'if' then
			branching = true
			table.insert(prefixes, 1, 'if')
		 elseif not looping and prefix == 'foreach' then
			looping = true
			table.insert(prefixes, 1, 'foreach')
		 elseif prefix == 'endif' then
			branching = false
			table.remove(prefixes, 1)
		 elseif prefix == 'endforeach' then
			looping = false
			table.remove(prefixes, 1)
		 end
		 if prefix == 'if' or prefix == 'foreach' then
			prefix =  table.concat(prefixes,'')
		 elseif prefix == 'when' or prefix == 'then'
			or prefix == 'endif' or prefix == 'endforeach' then
			prefix =  prefix .. table.concat(prefixes,'')
		 end

		 if CONF.exec.scope == 'given' and (prefix == 'when' or prefix == 'then'
											or prefix == 'if' or prefix == 'foreach') then
			 break
		 end

		 -- try to enter the machine state named in prefix
		 -- xxx("Zencode machine enter_"..prefix..": "..text, 3)
		 local fm <const> = self.machine["enter_"..prefix]
		 if CONF.parser.strict_match == true and not fm then
			assert(fm, "Invalid Zencode prefix "..self.linenum..": '"..line.."'")
		 elseif not fm then
			table.insert(traceback, '-'..self.linenum..'	'..line)
			warn('Zencode line '..self.linenum..' pattern ignored: ' .. line, 1)
		 else
			assert(fm(self.machine, { msg = tline, Z = self }),
				   line.."\n    "..
				   "Invalid transition from: "..self.machine.current)
		 end
	  end
	  -- continue
   end
   collectgarbage'collect'
   return true
end


local function IN_uscore(i)
	-- convert all element keys of IN to underscore
	local res = {}
    for k,v in pairs(i) do
	if luatype(v) == 'table' then
		 res[uscore(k)] = IN_uscore(v) -- recursion
	  else
		 res[uscore(k)] = v
	  end
   end
   return setmetatable(res, getmetatable(i))
end

-- return true: caller skip execution and go to ::continue::
-- return false: execute statement
local function manage_branching(stack, x)
	if string.match(x.section, '^if') then
		--xxx("START conditional execution: "..x.source, 2)
		if not stack.branch then stack.branch_valid = true end
		stack.branch = true
		return false
	end
	if string.match(x.section, '^endif') then
		--xxx("END   conditional execution: "..x.source, 2)
		stack.branch = false
		return true
	end
	if not stack.branch then return false end
	if not stack.branch_valid then
		--xxx('skip execution in false conditional branch: '..x.source, 2)
		return true
	end
	return false
end

-- return true: caller skip execution and go to ::continue::
-- return false: execute statement
-- TODO(optimization): introduce a second jump to skip all
-- statements in the foreach in the last iteration
local function manage_foreach(stack, x)
	if string.match(x.section, '^foreach') and not stack.ITER then
		stack.ITER = {jump = stack.current_instruction, pos = 1}
		return false
	end
	if string.match(x.section, '^endforeach') then
		local info = stack.ITER
		if info.pos > 0 then
			info.pos = info.pos + 1
			stack.next_instruction = info.jump
			return true
		else
			stack.ITER = nil
		end
	end
	if stack.ITER and stack.ITER.pos >= MAXITER then
		error("Limit of iterations reached: " .. MAXITER)
	end
	return stack.ITER and stack.ITER.pos == 0
end

function ZEN:run()
   self:crumb()
   local runtime_trace = function(x)
	  table.insert(traceback, '+'..x.linenum..'  '..x.source)
   end
   local runtime_error = function(x, err)
	  table.insert(traceback, '[!] Error at Zencode line '..x.linenum)
	  if err then table.insert(traceback, '[!] '..err) end
   end
   -- runtime checks
   if not self.checks.version then
	  warn(
		 'Zencode is missing version check, please add: rule check version N.N.N'
	  )
   end
   -- HEAP setup
   local tmp
   if EXTRA then
	  tmp  = CONF.input.format.fun(EXTRA) or {}
	  for k, v in pairs(tmp) do
		 IN[k] = v
	  end
	  EXTRA = nil
   end
   if DATA then
	  tmp  = CONF.input.format.fun(DATA) or {}
	  for k, v in pairs(tmp) do
		 if IN[k] then
			error("Object name collision in input: "..k)
		 end
		 IN[k] = v
	  end
	  DATA = nil
   end
   if KEYS then
	  tmp  = CONF.input.format.fun(KEYS) or {}
	  for k, v in pairs(tmp) do
		 if IN[k] then
			error("Object name collision in input: "..k)
		 end
		 IN[k] = v
	  end
	  KEYS = nil
   end
   tmp = nil
   collectgarbage 'collect'

   -- convert all spaces in keys to underscore
   IN = IN_uscore(IN)

   -- EXEC zencode
   -- TODO: for optimization, to develop a lua iterator, which would save lookup time
   -- https://www.lua.org/pil/7.1.html
   local AST_size <const> = table_size(AST)
   while self.next_instruction <= AST_size do
	  self.current_instruction = self.next_instruction
	  local x <const> = AST[self.current_instruction]
	  self.next_instruction = self.next_instruction + 1
	  if not manage_branching(self, x) and not manage_foreach(self, x) then
		 -- trigger upon switch to when or then section
		 if x.from == 'given' and x.to ~= 'given' then
			-- delete IN memory
			IN = {}
			collectgarbage 'collect'
		 end
		 -- HEAP integrity guard
		 if CONF.heapguard then -- watchdog
			-- guard ACK's contents on section switch
			deepmap(zenguard, ACK)
			-- check that everythink in HEAP.ACK has a CODEC
			self:codecguard()
		 end

		 self.OK = true
		 exitcode(0)
		 runtime_trace(x)
		 local ok, err <const> = pcall(x.hook, table.unpack(x.args))
		 if not ok or not self.OK then
			runtime_error(x, err)
			fatal({msg=x.source, linenum=x.linenum}) -- traceback print inside
		 end
		 collectgarbage 'collect'
	  end
	  --	::continue::
   end
   -- PRINT output
   self:ftrace('--- Zencode execution completed')
   if CONF.exec.scope == 'full' then
	  if type(OUT) == 'table' then
		 self:ftrace('<<< Encoding { OUT } to JSON ')
		 -- this is all already encoded
		 -- needs to be formatted
		 -- was used CONF.output.format.fun
		 -- suspended until more formats are implemented
		 print( JSON.encode(OUT) )
		 self:ftrace('>>> Encoding successful')
	  else -- this should never occur in zencode, OUT is always a table
		 self:ftrace('<<< Printing OUT (plain format, not a table)')
		 print(OUT)
	  end
   elseif CONF.exec.scope == 'given' then
	  print(JSON.encode({CODEC = CODEC}))
	  ZEN:debug() -- J64 HEAP and TRACE
   end
end

-------------------
-- ZENCODE WATCHDOG
-- assert all values in table are converted to zenroom types
-- used in zencode when transitioning out of given memory
function zenguard(val, key) -- AKA watchdog
   local tv <const> = type(val)
   if not (tv == 'boolean' or iszen(tv)) then
      error("Zenguard detected an invalid value in HEAP: "
	    ..key.." ("..type(val)..")", 3)
      return nil
   end
end
-- compare heap.ACK and heap.CODEC
function ZEN:codecguard()
   local left <const> = ACK
   local right <const> = CODEC
   local fatal <const> = CONF.missing.fatal
   for key1, value1 in pairs(left) do
      if not right[key1] then
		 self:debug()
		 error("Internal memory error: missing CODEC for "..key1)
		 return false, key1
      end
      -- TODO: base checks if CODEC matches
   end
   -- check for missing keys in tbl1
   for key2, _ in pairs(right) do
      if not left[key2] and fatal then
		 self:debug()
		 error("Internal memory error: unbound CODEC for "..key2)
		 return false, key2
      end
   end
   return true
end

------------------------------------------
-- ZENCODE STATEMENT DECLARATION FUNCTIONS
function Given(text, fn)
   text = text:lower()
   if ZEN.given_steps[text] then
	  error('Conflicting GIVEN statement loaded by scenario: ' .. text, 2)
   end
   ZEN.given_steps[text] = fn
end
function When(text, fn)
   if ZENCODE_SCOPE == 'GIVEN' then
	  text = nil
	  fn = nil
   else
	  text = text:lower()
	  if ZEN.when_steps[text] then
		 error('Conflicting WHEN statement loaded by scenario: ' .. text, 2)
	  end
	  ZEN.when_steps[text] = fn
   end
end
function IfWhen(text, fn)
   if ZENCODE_SCOPE == 'GIVEN' then
	  text = nil
	  fn = nil
   else
	  text = text:lower()
	  if ZEN.if_steps[text] then
		 error('Conflicting IF-WHEN statement loaded by scenario: '..text, 2)
	  end
	  if ZEN.when_steps[text] then
		 error('Conflicting IF-WHEN statement loaded by scenario: '..text, 2)
	  end
	  ZEN.if_steps[text]   = fn
	  ZEN.when_steps[text] = fn
   end
end
function Foreach(text, fn)
   if ZENCODE_SCOPE == 'GIVEN' then
	  text = nil
	  fn = nil
   else
	  text = text:lower()
	  if ZEN.foreach_steps[text] then
			error('Conflicting FOREACH statement loaded by scenario: ' .. text, 2)
	  end
	  ZEN.foreach_steps[text] = fn
   end
end
function Then(text, fn)
   if ZENCODE_SCOPE == 'GIVEN' then
	  text = nil
	  fn = nil
   else
	  text = text:lower()
	  if ZEN.then_steps[text] then
			error('Conflicting THEN statement loaded by scenario : ' .. text, 2)
	  end
	  ZEN.then_steps[text] = fn
   end
end

---------------------------
-- ZENCODE GLOBAL UTILITIES
function Iam(name)
	if name then
		zencode_assert(not WHO, 'Identity already defined in WHO')
		zencode_assert(type(name) == 'string', 'Own name not a string')
		WHO = uscore(name)
	else
		zencode_assert(WHO, 'No identity specified in WHO')
	end
	assert(ZEN.OK)
end
function have(obj) -- accepts arrays for depth checks
	local res
	-- depth check used in pick
	if luatype(obj) == 'table' then
		local prev = ACK
		for k, v in ipairs(obj) do
			res = prev[uscore(v)]
			if not res then
				error('Cannot find object: ' .. v, 2)
			end
			prev = res
		end
		return res
	end

	local name = uscore(trim(obj))
	res = ACK[name]
	if not res then
	   error('Cannot find object: ' .. name, 2)
	end
	local codec = CODEC[name]
	if not codec then error("CODEC not found: "..name, 2) end
	return res, codec
end
function empty(obj)
	-- convert all spaces to underscore in argument
	if ACK[uscore(obj)] then
		error('Cannot overwrite existing object: ' .. obj, 2)
	end
end
function mayhave(obj)
	-- TODO: accept arrays for depth checks as the `have` function
	local name = uscore(trim(obj))
	res = ACK[name]
	if not res then
		warn(name .. " not found in DATA or KEYS")
		return nil
	end
	local codec = CODEC[name]
	if not codec then error("CODEC not found: "..name, 2) end
	return res, codec
end

function zencode_serialize(A)
   local t <const> = luatype(A)
   if t == 'table' then
      local res
      res = serialize(A)
      return OCTET.from_string(res.strings) .. res.octets
   elseif t == 'number' then
      return O.from_string(tostring(A))
   elseif t == 'string' then
      return O.from_string(A)
   else
      local zt <const> = type(A)
      if not iszen(zt) then
	 error('Cannot convert value to octet: '..zt, 2)
      end
      -- all zenroom types have :octet() method to export
      return A:octet()
   end
   error('Unknown type, cannot convert to octet: '..type(A), 2)
end

return ZEN
