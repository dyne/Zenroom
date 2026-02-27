--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2026 Dyne.org foundation
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
--
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
-- @copyright Dyne.org foundation 2018-2024
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
	branch = 0,
	branch_valid = 0,
	id = 0,
	checks = {version = false}, -- version, scenario checked, etc.
	OK = true, -- set false by asserts
	jump = nil,
	ITER_present = false,
	BRANCH_present = false,
	ITER = {}, -- foreach infos,
	ITER_parse = {},
	ITER_head = nil,
	traceback = {}, -- transferred into HEAP by zencode_begin
	linenum = 0,
	last_valid_statement = false,
	phase = "g"
}

local __maxmem <const> = _G['MAXMEM']
local function gc()
	if collectgarbage'count' > __maxmem then
		collectgarbage'collect'
	end
end


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
   -- Reset parser/runtime state to avoid cross-run contamination on VM reuse.
   AST = {}
   self.branch = 0
   self.branch_valid = 0
   self.id = 0
   self.checks = { version = false }
   self.OK = true
   self.jump = nil
   self.ITER_present = false
   self.BRANCH_present = false
   self.ITER = {}
   self.ITER_parse = {}
   self.ITER_head = nil
   self.traceback = {}
   self.linenum = 0
   self.last_valid_statement = false
   self.phase = "g"
   self.branch_condition = nil
   self.branch_condition_failed = nil
   if new_heap then
	  -- TODO: setup with an existing HEAP
   else
	  IN  = {} -- Given processing, import global DATA from json
	  ACK = {} -- When processing,  destination for push*
	  OUT = {} -- print out
	  CODEC = {} -- metadata
	  CACHE = {} -- contract-wide computation cache
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
		  ifforeach = 'if'
	   }
	   local current <const> = self.current
	   local index <const> = translate[current] or current
	   -- save in reg a pointer to array of statements
	   local reg <const> = ctx.Z[index .. '_steps']
	   -- Keep statement source trimmed for stable errors/traceback semantics.
	   local sentence <const> = trim(ctx.msg)
	   local linenum <const> = ctx.Z.linenum
	   ctx.Z.OK = false
	   xxx('Zencode parser from: ' .. from .. " to: "..to, 3)
	   assert(reg,'Callback register not found: ' .. current)
	   -- Hot normalization moved to zen_parse.c for performance.
	   local tt = normalize_zencode_statement(sentence, to)
	   --
	   local func <const> = reg[tt] -- lookup the statement
	   if func and luatype(func) == 'function' then
		  local args = {} -- handle multiple arguments in same string
		  -- Fast-path: most statements have no quoted arguments.
		  if string.find(sentence, "'", 1, true) then
			 for arg in string.gmatch(sentence, "'(.-)'") do
				-- convert all spaces to underscore in argument strings
				arg = uscore(arg, ' ', '_')
				table.insert(args, arg)
			 end
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
				linenum = linenum,
				f = index == 'foreach' or nil,
				ef = index == 'endforeach' or nil,
				i = index == 'if' or nil,
				ei = index == 'endif' or nil
			 }
		  ) -- function
		  if index == 'foreach' then
			ctx.Z.ITER_present = true
			ctx.Z.ITER[ctx.Z.id] = { jump = ctx.Z.id, pos = 1 }
			table.insert(ctx.Z.ITER_parse, ctx.Z.id)
		  elseif index == 'endforeach' then
			local id = table.remove(ctx.Z.ITER_parse)
			ctx.Z.ITER[id].end_id = ctx.Z.id
		  end
		  ctx.Z.BRANCH_present = ctx.Z.BRANCH_present or index == 'if'
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
			   fif(CONF.parser.strict_parse, warn, error)('Zencode line '..linenum..' pattern ignored: ' .. sentence, 1)
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
		  ['input number'] = function (what)
			if not what or what ~= 'strict' then return false end
			CONF.input.number_strict = true
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
		  ['output sorting'] = function(what)
			 if what == 'true' then
				CONF.output.sorting = true
			 else
				CONF.output.sorting = false
			 end
			 return true
		  end,
		  ['output versioning'] = function ()
			 CONF.output.versioning = true
			 return true
		  end,
		  ['unknown ignore'] = function ()
			 CONF.parser.strict_match = false
			 return true
		  end,
		  ['path separator'] = function (separator)
			if not separator or separator:len() ~= 1 then return false end
			CONF.path.separator = separator
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
	   callbacks.onifforeach = set_sentence
	   callbacks.onwhenifforeach = set_sentence
	   local extra_events <const> = {
		  {name = 'enter_when', from = {'given', 'when', 'then', 'endif', 'endforeach'}, to = 'when'},
		  {name = 'enter_then', from = {'given', 'when', 'then', 'endif', 'endforeach'}, to = 'then'},
		  {name = 'enter_if', from = {'if', 'given', 'when', 'then', 'endif', 'endforeach', 'whenif', 'thenif', 'endforeach', 'foreachif'}, to = 'if'},
		  {name = 'enter_whenif', from = {'if', 'whenif', 'thenif', 'endforeach', 'endif'}, to = 'whenif'},
		  {name = 'enter_thenif', from = {'if', 'whenif', 'thenif', 'endforeach', 'endif'}, to = 'thenif'},
		  {name = 'enter_endif', from = {'whenif', 'whenifforeach', 'thenif', 'endforeach', 'endif'}, to = 'endif'},
		  {name = 'enter_foreach', from = {'given', 'when', 'endif', 'foreach', 'endforeach', 'whenforeach'}, to = 'foreach'},
		  {name = 'enter_whenforeach', from = {'foreach', 'whenforeach', 'endif', 'endforeach'}, to = 'whenforeach'},
		  {name = 'enter_foreachif', from = {'if', 'whenif', 'endforeach', 'foreachif', 'whenforeachif', 'ifforeach', 'whenifforeach', 'endif'}, to = 'foreachif'},
		  {name = 'enter_whenforeachif', from = {'foreachif', 'whenforeachif', 'endif', 'endforeach'}, to = 'whenforeachif'},
		  {name = 'enter_ifforeach', from = {'foreach', 'whenforeach', 'ifforeach', 'whenifforeach', 'foreachif', 'whenforeachif', 'endif', 'endforeach' }, to = 'ifforeach'},
		  {name = 'enter_whenifforeach', from = {'ifforeach', 'whenifforeach', 'endforeach', 'endif'}, to = 'whenifforeach'},
		  {name = 'enter_endforeach', from = {'whenforeach', 'whenforeachif', 'endif', 'endforeach'}, to = 'endforeach'},
		  {name = 'enter_and', from = 'when', to = 'when'},
		  {name = 'enter_and', from = 'then', to = 'then'},
		  {name = 'enter_and', from = 'if', to = 'if'},
		  {name = 'enter_and', from = 'whenif', to = 'whenif'},
		  {name = 'enter_and', from = 'thenif', to = 'thenif'},
		  {name = 'enter_and', from = 'foreach', to = 'foreach'},
		  {name = 'enter_and', from = 'whenforeach', to = 'whenforeach'},
		  {name = 'enter_and', from = 'foreachif', to = 'foreachif'},
		  {name = 'enter_and', from = 'whenforeachif', to = 'whenforeachif'},
		  {name = 'enter_and', from = 'ifforeach', to = 'ifforeach'},
		  {name = 'enter_and', from = 'whenifforeach', to = 'whenifforeach'},
	   }
	   for _,v in pairs(extra_events) do table.insert(events, v) end
	end

	self.machine = MACHINE.create({
		initial = 'init',
		events = events,
		callbacks = callbacks
	})
	gc()
	-- Zencode init traceback
	return true
end

-- returns an iterator for newline termination
local function zencode_newline_iter(text)
	return text:gmatch("[^\r\n]*")
end
local function enter_branching_and_looping(type, info, prefixes, ln)
	local already_prefix = prefixes[1] == type
	if not already_prefix then
		table.insert(prefixes, 1, type)
	end
	table.insert(info, { ln, already_prefix })
	return prefixes[1]..(prefixes[2] or '')
end

local function end_branching_and_looping(type, info, prefixes, ln)
	local n = fif(type == 'if', 'branching', 'loop')
	if #info == 0 then
		error('Ivalid '..n..' closing at line '..ln..': nothing to be closed', 2)
	elseif prefixes[1] ~= type then
		error('Invalid '..n..' closing at line '..ln..': need to close first the '..prefixes[1], 2)
	end
	local rm = table.remove(info)
	if not rm[2] then
		table.remove(prefixes, 1)
	end
end
local function check_open_branching_or_looping(type, info)
	if #info == 0 then return end
	local err_lines = {}
	for _, v in pairs(info) do
		table.insert(err_lines, v[1])
	end
	error('Invalid '..type..' opened at line '..table.concat(err_lines, ', ')..' and never closed', 2)
end

function ZEN:parse(text)
   self:crumb()
   if #text < 9 then -- strlen("and debug") == 9
	  error("Zencode text too short to parse")
	  return false
   end
   local branching = {}
   local looping = {}
   local prefixes = {}
	   local parse_prefix <const> = parse_prefix -- optimization
	   local last_prefix
	   self.linenum = 0
	   local res = fif(CONF.parser.strict_parse, true, { ignored={}, invalid={} })
	   for line in zencode_newline_iter(text) do
		  self.linenum = self.linenum + 1
		  -- Prefix parsing in C already skips leading whitespace.
		  local prefix = parse_prefix(line)
		  --   xxx('Line: '.. text, 3)
		  -- max length for single zencode line is #define MAX_LINE
		  -- hard-coded inside zenroom.h
		  if not prefix then
			 if CONF.parser.strict_parse then
				error("Invalid Zencode line "..self.linenum..": "..line)
			 end
			 table.insert(res.invalid, {line, self.linenum, 'Invalid Zencode line'})
			 goto continue_line
		  elseif prefix == '' or string.sub(prefix,1,1) == '#' then
			 goto continue_line
		  end
			 self.OK = true
			 exitcode(0)
			 if CONF.exec.scope == 'given' and
			(prefix == 'when' or prefix == 'then'
			 or prefix == 'if' or prefix == 'foreach') then
			break -- stop parsing after given block
		 end

		if prefix == 'if' or (prefix == 'and' and last_prefix == 'if') then
			last_prefix = 'if'
			prefix = enter_branching_and_looping('if', branching, prefixes, self.linenum)
		elseif prefix == 'foreach' or (prefix == 'and' and last_prefix == 'foreach') then
			last_prefix = 'foreach'
			prefix = enter_branching_and_looping('foreach', looping, prefixes, self.linenum)
		elseif prefix == 'endif' then
			last_prefix = prefix
			end_branching_and_looping('if', branching, prefixes, self.linenum)
		elseif prefix == 'endforeach' then
			last_prefix = prefix
			end_branching_and_looping('foreach', looping, prefixes, self.linenum)
		else
			last_prefix = prefix
		end
		if prefix == 'when' or prefix == 'then' then
			prefix = prefix .. (prefixes[1] or '').. (prefixes[2] or '')
		end

		 if prefix == "when" or prefix == "if" or prefix == "foreach" then
			ZEN.phase = "w"
		 elseif prefix == "then" then
			ZEN.phase = "t"
		 end
		 -- try to enter the machine state named in prefix
		 -- xxx("Zencode machine enter_"..prefix..": "..text, 3)
		 local fm <const> = self.machine["enter_"..prefix]
		 if CONF.parser.strict_match == true and not fm then
			if CONF.parser.strict_parse then
			   error("Invalid Zencode prefix "..self.linenum..": '"..line.."'")
			end
			table.insert(res.invalid, {line, self.linenum, 'Invalid Zencode prefix'})
		 elseif not fm then
			if ZEN.phase == 'g' and not ZEN.last_valid_statement then
				if CONF.parser.strict_parse then
					table.insert(traceback, '-'..self.linenum..'  '..line)
					warn('Zencode line '..self.linenum..' pattern ignored: ' .. line, 1)
				else
					table.insert(res.ignored, {line, self.linenum})
				 end
			elseif ZEN.phase == 't' then
				ZEN.last_valid_statement = false
				if CONF.parser.strict_parse then
					table.insert(traceback, '-'..self.linenum..'  '..line)
					warn('Zencode line '..self.linenum..' pattern ignored: ' .. line, 1)
				 else
					table.insert(res.ignored, {line, self.linenum})
				 end
			else
				if CONF.parser.strict_parse then
					error("Invalid Zencode line "..self.linenum..": '"..line.."'")
				 else
					table.insert(res.invalid, {line, self.linenum, 'Invalid Zencode line'})
				 end
			end
		 else
				local ok, err <const> = pcall(fm, self.machine, { msg = line, Z = self })
				if not ok or (ok and not err) then
			   if CONF.parser.strict_parse then
				  error(err or "Invalid transition from: "..self.machine.current.." to: "..line)
			   end
			   if type(err) == 'string' and err.find(err, 'pattern ignored') then
				  table.insert(res.ignored, {line, self.linenum})
			   else
				  table.insert(res.invalid, {line, self.linenum, err or 'Invalid transition from '..self.machine.current})
			   end
			end
			 end
		  ::continue_line::
		  -- continue
	   end
	check_open_branching_or_looping('branching', branching)
	check_open_branching_or_looping('looping', looping)
	gc()
   if res == true then
	  return true
   else
	  return JSON.encode(res)
   end
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
	-- skip execution if If statement is the first in a ended loop
	if stack.ITER_head and stack.ITER_head.pos == 0 then return false end

	stack.branch_condition = nil
	local b = stack.branch
	local v = stack.branch_valid
	local s = x.section

	if x.i then
		stack.branch_condition = true
		stack.branch_condition_failed = false
		stack.branch = b+1
		if v == b then
			stack.branch_valid = v+1
			return false
		end
		return true
	elseif x.ei then
		if v == b then
			stack.branch_valid = v-1
		end
		stack.branch = b-1
		return true
	end
	return b ~= 0 and b > v
end

-- return true: caller skip execution and go to ::continue::
-- return false: execute statement
local function manage_foreach(stack, x, ci)
	local last_iter = stack.ITER_head
	-- if no foreach is defined skip all
	if not last_iter and not x.f then return false end
	if x.f then
		if last_iter and last_iter.pos == 0 then
			stack.jump = last_iter.end_id
			return true
		end
		stack.ITER_head = stack.ITER[x.id]
		if last_iter and stack.ITER_head.pos == 1 then
			stack.ITER_head.parent = last_iter
		end
		return false
	elseif x.ef then
		if last_iter.pos > 0 then
			last_iter.pos = last_iter.pos + 1
			stack.jump = last_iter.jump
			return true
		else
			last_iter.pos = 1
			last_iter = stack.ITER_head.parent
			stack.ITER_head = last_iter
		end
	end
	if last_iter then
		if last_iter.pos > MAXITER then
			error("Limit of iterations exceeded: " .. MAXITER)
		-- skip all statements on last (not valid) loop
		elseif last_iter.pos == 0 then
			stack.jump = last_iter.end_id
			return true
		end
	end
	return last_iter and last_iter.pos == 0
end

local function AST_iterator()
	local i = 0
	local AST_size <const> = table_size(AST)
	local manage
	if ZEN.ITER_present and ZEN.BRANCH_present then
		manage = function(z, v, j) return manage_branching(z, v) or manage_foreach(z, v, j) end
	elseif ZEN.ITER_present and not ZEN.BRANCH_present then
		manage = function(z, v, j) return manage_foreach(z, v, j) end
	elseif not ZEN.ITER_present and ZEN.BRANCH_present then
		manage = function(z, v, j) return manage_branching(z, v) end
	else
		manage = function(z, v, j) return false end
	end
	return function()
		i = i+1
		-- End of iteration (i exceeds the AST length)
		if i > AST_size then
			return nil
		end
		local value = AST[i]
		while i < AST_size and manage(ZEN, value, i) do
			if ZEN.jump then
				i = ZEN.jump - 1
				ZEN.jump = nil
			end
			i = i+1
			value = AST[i]
		end
		return value
	end
end


function ZEN:run()
   self:crumb()
   local max_statements = tonumber(CONF.parser.max_statements) or 1000000
   local executed_statements = 0
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
   gc()

   -- convert all spaces in keys to underscore
   IN = IN_uscore(IN)

	-- EXEC zencode
	for x in AST_iterator() do
		-- trigger upon switch to when or then section
		if x.from == 'given' and x.to ~= 'given' then
			-- delete IN memory
			IN = {}
			gc()
		end
		-- HEAP integrity guard
		if CONF.heapguard then -- watchdog
			-- guard ACK's contents on section switch
			deepmap(zenguard, ACK)
			-- check that everythink in HEAP.ACK has a CODEC
			self:codecguard()
			self:keyringguard()
		end

			executed_statements = executed_statements + 1
			if executed_statements > max_statements then
				error("Zencode execution limit exceeded: "..max_statements.." statements")
			end
			self.OK = true
		exitcode(0)
		runtime_trace(x)
		local ok, err <const> = pcall(x.hook, table.unpack(x.args))
		if not ok or not self.OK then
			runtime_error(x, err)
			fatal({msg=x.source, linenum=x.linenum}) -- traceback print inside
		end
		-- give a notice about the CACHE being used
		-- TODO: print it in debug
		if #CACHE > 0 then xxx('Contract CACHE is in use') end
		gc()
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
	   ZEN:debug()
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
      if right[key1] == nil then
		 self:debug()
		 error("Internal memory error: missing CODEC for "..key1)
		 return false, key1
      end
      -- TODO: base checks if CODEC matches
   end
   -- check for missing keys in tbl1
   for key2, _ in pairs(right) do
      if left[key2] == nil and fatal then
		 self:debug()
		 error("Internal memory error: unbound CODEC for "..key2)
		 return false, key2
      end
   end
   return true
end
function ZEN:keyringguard()
	local keys <const> = ACK.keyring
	if not keys then return end
	for k,v in pairs(keys) do
		if not v:octet():is_secure() then -- sfpool check
			error("Key out of secure memory: "..k)
		end
	end
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
	if res == nil then
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
