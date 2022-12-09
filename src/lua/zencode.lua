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
	if_steps = {},
	foreach_steps = {},
	then_steps = {},
	schemas = {},
	branch = false,
	branch_valid = false,
	id = 0,
	AST = {},
	traceback = {}, -- execution backtrace
	eval_cache = {}, -- zencode_eval if...then conditions
	checks = {version = false}, -- version, scenario checked, etc.
	OK = true, -- set false by asserts
	current_instruction = 0, -- first instruction
	next_instruction = 1, -- first instruction
	ITER = nil, -- foreach infos
}

-- set_sentence
-- set_rule

local function set_sentence(self, event, from, to, ctx)
	local translate = {
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
	local index = translate[self.current] or self.current
	local reg = ctx.Z[index .. '_steps']
	ctx.Z.OK = false
	xxx('Zencode parser from: ' .. from .. " to: "..to, 3)
	assert(reg,'Callback register not found: ' .. self.current)
	assert(#reg,'Callback register empty: '..self.current)
	local gsub = string.gsub -- optimization
	-- TODO: optimize in C
	-- remove '' contents, lower everything, expunge prefixes
	-- ignore 'the' only in Then statements
	local tt = gsub(ctx.msg, "'(.-)'", "''") -- msg trimmed on parse
	tt = gsub(tt, ' I ', ' ', 1) -- eliminate first person pronoun
	tt = tt:lower() -- lowercase all statement
	if to == 'then' or to == 'thenif' then
		tt = gsub(tt, ' the ', ' ', 1)
	end
	if to == 'given' then
	   tt = gsub(tt, ' the ', ' a ', 1)
	   tt = gsub(tt, ' have ', ' ', 1)
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
	tt = gsub(tt, ' valid ', ' ', 1) -- backward compat
	tt = gsub(tt, ' known as ', ' ', 1)
	tt = gsub(tt, ' all ', ' ', 1)
	tt = gsub(tt, ' inside ', ' in ', 1) -- equivalence
	tt = gsub(tt, '^an ', 'a ', 1)
	tt = gsub(tt, ' +', ' ') -- eliminate multiple internal spaces
	tt = gsub(tt, '^ +', '') -- remove initial spaces
	tt = gsub(tt, ' +$', '') -- remove final spaces
        tt = tt:lower()
        local func = reg[tt]
        if func and type(func) == 'function' then
	        local args = {} -- handle multiple arguments in same string
                for arg in string.gmatch(ctx.msg, "'(.-)'") do
                        -- convert all spaces to underscore in argument strings
                        arg = uscore(arg, ' ', '_')
                        table.insert(args, arg)
                end
                ctx.Z.id = ctx.Z.id + 1
                -- AST data prototype
	        table.insert(
	               ctx.Z.AST,
		       {
		              id = ctx.Z.id, -- ordered number
                              args = args, -- array of vars
                              source = ctx.msg, -- source text
                              section = self.current,
                              from = from,
                              to = to,
                              hook = func
                       }
                ) -- function
                ctx.Z.OK = true
        end
	if not ctx.Z.OK and CONF.parser.strict_match then
	   ZEN.debug()
		exitcode(1)
		error('Zencode pattern not found ('..index..'): ' .. trim(ctx.msg), 1)
		return false
	elseif not ctx.Z.OK and not CONF.parser.strict_match then
		warn('Zencode pattern ignored: ' .. trim(ctx.msg), 1)
	end
end

local function set_rule(text)
	local res = false
	local tr = text.msg:gsub(' +', ' ') -- eliminate multiple internal spaces
	local rule = strtok(trim(tr):lower())
	if rule[2] == 'check' and rule[3] == 'version' and rule[4] then
		-- TODO: check version of running VM
		-- elseif rule[2] == 'load' and rule[3] then
		--     act("zencode extension: "..rule[3])
		--     require("zencode_"..rule[3])
		local ver = V(rule[4]) -- SEMVER
		if ver == ZENROOM_VERSION then
			act('Zencode version match: ' .. ZENROOM_VERSION.original)
			res = true
		elseif ver < ZENROOM_VERSION then
			warn('Zencode written for an older version: ' .. ver.original)
			res = true
		elseif ver > ZENROOM_VERSION then
			warn('Zencode written for a newer version: ' .. ver.original)
			res = true
		else
			error('Version check error: ' .. rule[4])
		end
		text.Z.checks.version = res
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
	elseif rule[2] == 'output' and rule[3] then
		-- TODO: rule debug [ format | encoding ]
		-- rule input encoding|format ''
		if rule[3] == 'encoding' then
			CONF.output.encoding = { fun = guess_outcast(rule[4]),
						 name = rule[4] }
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
	elseif rule[2] == 'collision' and rule[3] then
	   if rule[3] == 'ignore' then
	      CONF.heap.check_collision = false
	      res = true
	   end
	   -- alias of unknown ignore for specific callers
	elseif rule[2] == 'caller' and rule[3] then
		if rule[3] == 'restroom-mw' then
			CONF.parser.strict_match = false
			CONF.heap.check_collision = false
			res = true
		end
	elseif rule[2] == 'set' and rule[4] then
		CONF[rule[3]] = fif( tonumber(rule[4]), tonumber(rule[4]),
							fif( rule[4]=='true', true,
							fif( rule[4]=='false', false,
							rule[4])))
		res = true
	end
	if not res then
		error('Rule invalid: ' .. text.msg, 3)
	else
		act(text.msg)
	end
	return res
end


local function new_state_machine()
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
	local machine =
		MACHINE.create(
		{
			initial = 'init',
			events = {
				{name = 'enter_rule', from = {'init', 'rule', 'scenario'}, to = 'rule'},
				{name = 'enter_scenario', from = {'init', 'rule', 'scenario'}, to = 'scenario'},
				{name = 'enter_given', from = {'init', 'rule', 'scenario'},	to = 'given'},
				{name = 'enter_given', from = {'given'}, to = 'given'},

				{name = 'enter_when', from = {'given', 'when', 'then', 'endif', 'endforeach'}, to = 'when'},
				{name = 'enter_then', from = {'given', 'when', 'then', 'endif', 'endforeach'}, to = 'then'},

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

				{name = 'enter_and', from = 'given', to = 'given'},
				{name = 'enter_and', from = 'when', to = 'when'},
				{name = 'enter_and', from = 'then', to = 'then'},
				{name = 'enter_and', from = 'whenif', to = 'whenif'},
				{name = 'enter_and', from = 'thenif', to = 'thenif'},
				{name = 'enter_and', from = 'if', to = 'if'},

			},
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
			callbacks = {
				-- msg is a table: { msg = "string", Z = ZEN (self) }
				onscenario = function(self, event, from, to, msg)
					-- first word until the colon
					local scenarios =
						strtok(string.match(trim(msg.msg):lower(), '[^:]+'))
					for k, scen in ipairs(scenarios) do
						if k ~= 1 then -- skip first (prefix)
							load_scenario('zencode_' .. trimq(scen))
							ZEN:trace('Scenario ' .. scen)
							return
						end
					end
				end,
				onrule = function(self, event, from, to, msg)
					-- process rules immediately
					if msg then	set_rule(msg) end
				end,
				ongiven = set_sentence,
				onwhen = set_sentence,
				onif = set_sentence,
				onendif = set_sentence,
				onthen = set_sentence,
				onand = set_sentence,
				onwhenif = set_sentence,
				onthenif = set_sentence,
				onforeach = set_sentence,
				onendforeach = set_sentence,
				onwhenforeach = set_sentence,
				onforeachif = set_sentence,
				onwhenforeachif = set_sentence,
				onendforeachif = set_sentence,
				onifforeach = set_sentence,
				onwhenifforeach = set_sentence,
				onendifforeach = set_sentence,
			}
		}
	)
	return machine
end

-- Zencode HEAP globals
IN = {} -- Given processing, import global DATA from json
KIN = {} -- Given processing, import global KEYS from json
TMP = TMP or {} -- Given processing, temp buffer for ack*->validate->push*
ACK = ACK or {} -- When processing,  destination for push*
OUT = OUT or {} -- print out
AST = AST or {} -- AST of parsed Zencode
WHO = nil

-- init statements
zencode.endif_steps = { endif = function() return end } --nop
zencode.endforeach_steps = { endforeach = function() return end } --nop

function Given(text, fn)
        text = text:lower()
	assert(
		not ZEN.given_steps[text],
		'Conflicting GIVEN statement loaded by scenario: ' .. text, 2
	)
	ZEN.given_steps[text] = fn
end
function When(text, fn)
        text = text:lower()
	assert(
		not ZEN.when_steps[text],
		'Conflicting WHEN statement loaded by scenario: ' .. text, 2
	)
	ZEN.when_steps[text] = fn
end
function IfWhen(text, fn)
        text = text:lower()
        assert(
		not ZEN.if_steps[text],
		'Conflicting IF-WHEN statement loaded by scenario: ' .. text, 2
	)
	assert(
		not ZEN.when_steps[text],
		'Conflicting IF-WHEN statement loaded by scenario: ' .. text, 2
	)
	ZEN.if_steps[text]   = fn
	ZEN.when_steps[text] = fn
end
function Foreach(text, fn)
        text = text:lower()
        assert(
		not ZEN.foreach_steps[text],
		'Conflicting FOREACH statement loaded by scenario: ' .. text, 2
	)
	ZEN.foreach_steps[text] = fn
end
function Then(text, fn)
        text = text:lower()
	assert(
		not ZEN.then_steps[text],
		'Conflicting THEN statement loaded by scenario : ' .. text, 2
	)
	ZEN.then_steps[text] = fn
end

---
-- Declare 'my own' name that will refer all uses of the 'my' pronoun
-- to structures contained under this name.
--
-- @function Iam(name)
-- @param name own name to be saved in WHO
function Iam(name)
	if name then
		ZEN.assert(not WHO, 'Identity already defined in WHO')
		ZEN.assert(type(name) == 'string', 'Own name not a string')
		WHO = name
	else
		ZEN.assert(WHO, 'No identity specified in WHO')
	end
	assert(ZEN.OK)
end

-- init schemas
function zencode.add_schema(arr)
	local _illegal_schemas = {
		-- const
		whoami = true
	}
	for k, v in pairs(arr) do
		-- check overwrite / duplicate to avoid scenario namespace clash
		if ZEN.schemas[k] then
			error('Add schema denied, already registered schema: ' .. k, 2)
		end
		if _illegal_schemas[k] then
			error('Add schema denied, reserved name: ' .. k, 2)
		end
		ZEN.schemas[k] = v
	end
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
	local codec = ZEN.CODEC[name]
	if not codec then error("CODEC not found: "..name, 2) end
	return res, codec
end
function empty(obj)
	-- convert all spaces to underscore in argument
	if ACK[uscore(obj)] then
		error('Cannot overwrite existing object: ' .. obj, 2)
	end
end

---------------------------------------------------------------
-- ZENCODE PARSER

local function zencode_iscomment(b)
	local x = string.char(b:byte(1))
	if x == '#' then
		return true
	else
		return false
	end
end
local function zencode_isempty(b)
	if b == nil or b == '' then
		return true
	else
		return false
	end
end
-- returns an iterator for newline termination
local function zencode_newline_iter(text)
	s = trim(text) -- implemented in zen_io.c
	if s:sub(-1) ~= '\n' then
		s = s .. '\n'
	end
	return s:gmatch('(.-)\n') -- iterators return functions
end

function zencode:begin()
	self.id = 0
	self.AST = {}
	self.eval_cache = {}
	self.checks = {version = false} -- version, scenario checked, etc.
	self.OK = true -- set false by asserts
	self.traceback = {}

	-- Reset HEAP
	self.machine = {}
	IN = {} -- Given processing, import global DATA from json
	KIN = {} -- Given processing, import global KEYS from json
	TMP = {} -- Given processing, temp buffer for ack*->validate->push*
	ACK = {} -- When processing,  destination for push*
	OUT = {} -- print out
	AST = {} -- AST of parsed Zencode
	self.CODEC = {} -- saves input conversions for to decode using same
	WHO = nil
	collectgarbage 'collect'
	-- Zencode init traceback
	self.machine = new_state_machine()
end

function zencode:parse(text)
	if #text < 9 then -- strlen("and debug") == 9
   	  warn("Zencode text too short to parse")
		 return false
	end
	local linenum=0
   -- xxx(text,3)
	local prefix
	local branching = false
	local looping = false
	local prefixes = {}
	local parse_prefix = parse_prefix -- optimization
   for line in zencode_newline_iter(text) do
	linenum = linenum + 1
	local tline = trim(line) -- saves trims in isempty / iscomment
	  if zencode_isempty(tline) then goto continue end
	  if zencode_iscomment(tline) then goto continue end
	--   xxx('Line: '.. text, 3)
	  -- max length for single zencode line is #define MAX_LINE
	  -- hard-coded inside zenroom.h
	  prefix = parse_prefix(line) -- trim is included
	  assert(prefix, "Invalid Zencode line "..linenum..": "..line)
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

	  -- try to enter the machine state named in prefix
	  -- xxx("Zencode machine enter_"..prefix..": "..text, 3)
	  local fm = self.machine["enter_"..prefix]
	  assert(fm, "Invalid Zencode line "..linenum..": '"..line.."'")
	  assert(fm(self.machine, { msg = tline, Z = self }),
				line.."\n    "..
				"Invalid transition from: "..self.machine.current)
	  ::continue::
   end
   collectgarbage'collect'
   return true
end

function zencode:trace(src)
	-- take current line of zencode
	local tr = trim(src)
	-- TODO: tabbing, ugly but ok for now
	if string.sub(tr, 1, 1) == '[' then
		table.insert(self.traceback, tr)
	else
		table.insert(self.traceback, ' .  ' .. tr)
	end
end

-- trace function execution also on success
function zencode:ftrace(src)
	-- take current line of zencode
	table.insert(self.traceback, ' D  ZEN:' .. trim(src))
end

-- log zencode warning in traceback
function zencode:wtrace(src)
	-- take current line of zencode
	table.insert(self.traceback, ' W  ZEN:' .. trim(src))
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
local function manage_branching(x)
	if string.match(x.section, '^if') then
		--xxx("START conditional execution: "..x.source, 2)
		if not ZEN.branch then ZEN.branch_valid = true end
		ZEN.branch = true
		return false
	end
	if string.match(x.section, '^endif') then
		--xxx("END   conditional execution: "..x.source, 2)
		ZEN.branch = false
		return true
	end
	if not ZEN.branch then return false end
	if not ZEN.branch_valid then
		--xxx('skip execution in false conditional branch: '..x.source, 2)
		return true
	end
	return false
end

-- return true: caller skip execution and go to ::continue::
-- return false: execute statement
-- TODO(optimization): introduce a second jump to skip all
-- statements in the foreach in the last iteration
local function manage_foreach(x)
	if string.match(x.section, '^foreach') and not ZEN.ITER then
		ZEN.ITER = {jump = ZEN.current_instruction, pos = 1}
		return false
	end
	if string.match(x.section, '^endforeach') then
		local info = ZEN.ITER
		if info.pos > 0 then
			info.pos = info.pos + 1
			ZEN.next_instruction = info.jump
			return true
		else
			ZEN.ITER = nil
		end
	end

	if ZEN.ITER and ZEN.ITER.pos >= MAXITER then
		error("Limit of iterations reached: " .. MAXITER)
	end

	return ZEN.ITER and ZEN.ITER.pos == 0
end
-- assert all values in table are converted to zenroom types
-- used in zencode when transitioning out of given memory
local function zenguard(val, key) -- AKA watchdog
   local tv = type(val)
   if not (tv == 'boolean' or iszen(tv)) then
      ZEN.debug()
      error("Zenguard detected an invalid value in HEAP: "
	    ..key.." ("..type(val)..")", 2)
      return nil
   end
end


-- compare ACK and ZEN.CODEC
function codecguard()
   local left = ZEN.heap().ACK
   local right = ZEN.CODEC
   for key1, value1 in pairs(left) do
      if not right[key1] then
	 ZEN.debug()
	 error("Internal memory error: missing CODEC for "..key1)
	 return false, key1
      end
      -- TODO: base checks if CODEC matches
   end
   -- check for missing keys in tbl1
   for key2, _ in pairs(right) do
      if not left[key2] then
	 ZEN.debug()
	 error("Internal memory error: unbound CODEC for "..key2)
	 return false, key2
      end
   end
   return true
end

function zencode:run()
	-- runtime checks
	if not ZEN.checks.version then
		warn(
			'Zencode is missing version check, please add: rule check version N.N.N'
		)
	end
	-- HEAP setup
	IN = {} -- import global DATA from json
	if DATA then
		-- if plain array conjoin into associative
		IN = CONF.input.format.fun(DATA) or {}
		DATA = nil
	end
	KIN = {} -- import global KEYS from json
	if KEYS then
		KIN = CONF.input.format.fun(KEYS) or {}
		KEYS = nil
	end
	collectgarbage 'collect'

	-- convert all spaces in keys to underscore
	IN = IN_uscore(IN)
	KIN = IN_uscore(KIN)

	-- check name collisions between DATA and KEYS
	if CONF.heap.check_collision then
	   for k in pairs(IN) do
	      if KIN[k] then
		 error("Object name collision in input: "..k)
	      end
	   end
	end

	-- EXEC zencode
	-- TODO: for optimization, to develop a lua iterator, which would save lookup time
	-- https://www.lua.org/pil/7.1.html
	while ZEN.next_instruction <= #self.AST do
		ZEN.current_instruction = ZEN.next_instruction
		local x = self.AST[ZEN.current_instruction]
		ZEN.next_instruction = ZEN.next_instruction + 1
		-- ZEN:trace(x.source)
		if manage_branching(x) then
			goto continue
		end
		if manage_foreach(x) then
			goto continue
		end
		-- trigger upon switch to when or then section
		if x.from == 'given' and x.to ~= 'given' then
			-- delete IN memory
			KIN = {}
			IN = {}
			collectgarbage 'collect'
		end
		table.insert(ZEN.traceback, x.source)
		-- HEAP integrity guard
		if CONF.heapguard then -- watchdog
			-- guard ACK's contents on section switch
			deepmap(zenguard, ACK)
			-- check that everythink in HEAP.ACK has a CODEC
			codecguard()
		end

		ZEN.OK = true
		exitcode(0)
		local ok, err = pcall(x.hook, table.unpack(x.args))
		if not ok or not ZEN.OK then
			if err then
				ZEN:trace('[!] ' .. err)
			end
			fatal(x.source) -- traceback print inside
		end
		collectgarbage 'collect'
		::continue::
	end
	-- PRINT output
	ZEN:trace('--- Zencode execution completed')
	if type(OUT) == 'table' then
		ZEN:trace('<<< Encoding { OUT } to JSON ')
		-- this is all already encoded
		-- needs to be formatted
		-- was used CONF.output.format.fun
		-- suspended until more formats are implemented
		print( JSON.encode(OUT) )
		ZEN:trace('>>> Encoding successful')
	else -- this should never occur in zencode, OUT is always a table
		ZEN:trace('<<< Printing OUT (plain format, not a table)')
		print(OUT)
	end
end

function zencode.serialize(A)
   local t = luatype(A)
   if t == 'table' then
      local res
      res = serialize(A)
      return OCTET.from_string(res.strings) .. res.octets
   elseif t == 'number' then
      return O.from_string(tostring(A))
   elseif t == 'string' then
      return O.from_string(A)
   else
      local zt = type(A)
      if not iszen(zt) then
	 error('Cannot convert value to octet: '..zt, 2)
      end
      -- all zenroom types have :octet() method to export
      return A:octet()
   end
   error('Unknown type, cannot convert to octet: '..type(A), 2)
end

function zencode.heap()
	return ({
		IN = IN,
		KIN = KIN,
		TMP = TMP,
		ACK = ACK,
		OUT = OUT
	})
end


return zencode
