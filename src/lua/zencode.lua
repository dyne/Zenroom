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
   current_step = nil,
   id = 0,
   matches = {},
   verbosity = 0,
   schemas = { },
   checks = { }, -- version, scenario checked, etc.
   scenario = 'simple';
   OK = true -- set false by asserts
}

zencode.machine = MACHINE.create({
	  initial = 'init',
	  events = {
		 { name = 'enter_rule',     from = { 'init', 'rule', 'scenario' }, to = 'rule' },
		 { name = 'enter_scenario', from = { 'init', 'rule' }, to = 'scenario' },
		 { name = 'enter_given',    from = { 'init', 'rule', 'scenario' }, to = 'given' },
		 { name = 'enter_given',    from =   'given',             to = 'given' },
		 { name = 'enter_and',      from =   'given',             to = 'given' },
		 { name = 'enter_when',     from =   'given',             to = 'when' },
		 { name = 'enter_when',     from =   'when',              to = 'when' },
		 { name = 'enter_and',      from =   'when',              to = 'when' },
		 { name = 'enter_then',     from = { 'given', 'when' },   to = 'then' },
		 { name = 'enter_then',     from =   'then',              to = 'then' },
		 { name = 'enter_and',      from =   'then',              to = 'then' }
	  }
})


-- Zencode HEAP globals
IN = { }         -- Given processing, import global DATA from json
IN.KEYS = { }    -- Given processing, import global KEYS from json
TMP = TMP or { } -- Given processing, temp buffer for ack*->validate->push*
ACK = ACK or { } -- When processing,  destination for push*
OUT = OUT or { } -- print out
AST = AST or { } -- AST of parsed Zencode

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

--- Given block (IN read-only memory)
-- @section Given

---
-- Declare 'my own' name that will refer all uses of the 'my' pronoun
-- to structures contained under this name.
--
-- @function ZEN:Iam(name)
-- @param name own name to be saved in ACK.whoami
function zencode:Iam(name)
   if name then
	  ZEN.assert(not ACK.whoami, "Identity already defined in ACK.whoami")
	  ZEN.assert(type(name) == "string", "Own name not a string")
	  ACK.whoami = name
   else
	  ZEN.assert(ACK.whoami, "No identity specified in ACK.whoami")
   end
   assert(ZEN.OK)
end


-- local function used inside ZEN:pick*
-- try obj.*.what (TODO: exclude KEYS and ACK.whoami)
local function inside_pick(obj, what)
   ZEN.assert(obj, "ZEN:pick object is nil")
   -- ZEN.assert(I.spy(type(obj)) == "table", "ZEN:pick object is not a table")
   ZEN.assert(type(what) == "string", "ZEN:pick object index is not a string")
   local got
   if type(obj) == 'string' then  got = obj
   else got = obj[what] end
   if got then
	  -- ZEN:ftrace("inside_pick found "..what.." at object root")
	  goto gotit
   end
   for k,v in pairs(obj) do -- search 1 deeper
      if type(v) == "table" and v[what] then
         got = v[what]
         -- ZEN:ftrace("inside_pick found "..k.."."..what)
         break
      end
   end
   ::gotit::
   return got
end

---
-- Pick a generic data structure from the <b>IN</b> memory
-- space. Looks for named data on the first and second level and makes
-- it ready for @{validate} or @{ack}.
--
-- @function ZEN:pick(name, data)
-- @param name string descriptor of the data object
-- @param data[opt] optional data object (default search inside IN.*)
-- @return true or false
function zencode:pick(what, obj)
   if obj then -- object provided by argument
	  TMP = { data = obj,
			  root = nil,
			  schema = what,
			  valid = false }
	  return(ZEN.OK)
   end
   local got
   got = inside_pick(IN.KEYS, what) or inside_pick(IN,what)
   ZEN.assert(got, "Cannot find '"..what.."' anywhere")
   TMP = { root = nil,
		   data = got,
		   valid = false,
		   schema = what }
   assert(ZEN.OK)
   ZEN:ftrace("pick found "..what)
end

---
-- Pick a data structure named 'what' contained under a 'section' key
-- of the at the root of the <b>IN</b> memory space. Looks for named
-- data at the first and second level underneath IN[section] and moves
-- it to TMP[what][section], ready for @{validate} or @{ack}. If
-- TMP[what] exists already, every new entry is added as a key/value
--
-- @function ZEN:pickin(section, name)
-- @param section string descriptor of the section containing the data
-- @param name string descriptor of the data object
-- @return true or false
function zencode:pickin(section, what)
   ZEN.assert(section, "No section specified")
   local root -- section
   local got  -- what
   root = inside_pick(IN.KEYS,section)
   if root then --    IN KEYS
	  got = inside_pick(root, what)
	  if got then goto found end
   end
   root = inside_pick(IN,section)
   if root then --    IN
	  got = inside_pick(root, what)
	  if got then goto found end
   end
   ZEN.assert(got, "Cannot find '"..what.."' inside '"..section.."'")   
   -- TODO: check all corner cases to make sure TMP[what] is a k/v map
   ::found::
   TMP = { root = section,
		   data = got,
		   valid = false,
		   schema = what }
   assert(ZEN.OK)
   ZEN:ftrace("pickin found "..what.." in "..section)
end

---
-- Optional step inside the <b>Given</b> block to execute schema
-- validation on the last data structure selected by @{pick}.
--
-- @function ZEN:validate(name)
-- @param name string descriptor of the data object
-- @param schema[opt] string descriptor of the schema to validate
-- @return true or false
function zencode:validate(name, schema)
   schema = schema or TMP.schema or name -- if no schema then coincides with name
   ZEN.assert(name, "ZEN:validate error: argument is nil")
   ZEN.assert(TMP, "ZEN:validate error: TMP is nil")
   -- ZEN.assert(TMP.schema, "ZEN:validate error: TMP.schema is nil")
   -- ZEN.assert(TMP.schema == name, "ZEN:validate() TMP does not contain "..name)
   local got = TMP.data -- inside_pick(TMP,name)
   ZEN.assert(TMP.data, "ZEN:validate error: data not found in TMP for schema "..name)
   local s = ZEN.schemas[schema]
   ZEN.assert(s, "ZEN:validate error: "..schema.." schema not found")
   ZEN.assert(type(s) == 'function', "ZEN:validate error: schema is not a function for "..schema)
   ZEN:ftrace("validate "..name.. " with schema "..schema)
   local res = s(TMP.data) -- ignore root
   ZEN.assert(res, "ZEN:validate error: validation failed for "..name.." with schema "..schema)
   TMP.data = res -- overwrite
   assert(ZEN.OK)
   TMP.valid = true
   ZEN:ftrace("validation passed for "..name.. " with schema "..schema)
end

function zencode:validate_recur(obj, name)
   ZEN.assert(name, "ZEN:validate_recur error: schema name is nil")
   ZEN.assert(obj, "ZEN:validate_recur error: object is nil")
   local s = ZEN.schemas[name]
   ZEN.assert(s, "ZEN:validate_recur error: schema not found: "..name)
   ZEN.assert(type(s) == 'function', "ZEN:validate_recur error: schema is not a function: "..name)
   ZEN:ftrace("validate_recur "..name)
   local res = s(obj)
   ZEN.assert(res, "Schema validation failed: "..name)
   return(res)
end

function zencode:ack_table(key,val)
   ZEN.assert(TMP.valid, "No valid object found in TMP")
   ZEN.assert(type(key) == 'string',"ZEN:table_add arg #1 is not a string")
   ZEN.assert(type(val) == 'string',"ZEN:table_add arg #2 is not a string")
   if not ACK[key] then ACK[key] = { } end
   ACK[key][val] = TMP.data
end

---
-- Final step inside the <b>Given</b> block towards the <b>When</b>:
-- pass on a data structure into the ACK memory space, ready for
-- processing.  It requires the data to be present in TMP[name] and
-- typically follows a @{pick}. In some restricted cases it is used
-- inside a <b>When</b> block following the inline insertion of data
-- from zencode.
--
-- @function ZEN:ack(name)
-- @param name string key of the data object in TMP[name]
function zencode:ack(name)
   ZEN.assert(TMP.data and TMP.valid, "No valid object found: ".. name)
   assert(ZEN.OK)
   local t = type(ACK[name])
   if not ACK[name] then -- assign in ACK the single object
	  ACK[name] = TMP.data
	  goto done
   end
   -- ACK[name] already holds an object
   -- not a table?
   if t ~= 'table' then -- convert single object to array
	  ACK[name] = { ACK[name] }
	  table.insert(ACK[name], TMP.data)
	  goto done
   end
   -- it is a table already
   if isarray(ACK[name]) then -- plain array
	  table.insert(ACK[name], TMP.data)
	  goto done
   else -- associative map
	  table.insert(ACK[name], TMP.data) -- TODO: associative map insertion
	  goto done
   end
   ::done::
   assert(ZEN.OK)
end

function zencode:ackmy(name, object)
   local obj = object or TMP.data
   ZEN:trace("f   pushmy() "..name.." "..type(obj))
   ZEN.assert(ACK.whoami, "No identity specified")
   ZEN.assert(obj, "Object not found: ".. name)
   local me = ACK.whoami
   if not ACK[me] then ACK[me] = { } end
   ACK[me][name] = obj
   assert(ZEN.OK)
end

--- When block (ACK read-write memory)
-- @section When

---
-- Draft a new text made of a simple string: convert it to @{OCTET}
-- and append it to ACK.draft.
--
-- @function ZEN:draft(string)
-- @param string any string to be appended as draft
function zencode:draft(s)
   if s then
	  ZEN.assert(type(s) == "string", "Provided draft is not a string")
	  if not ACK.draft then
		 ACK.draft = str(s)
	  else
		 ACK.draft = ACK.draft .. str(s)
	  end
   else -- no arg: sanity checks
	  ZEN.assert(ACK.draft, "No draft found in ACK.draft")
   end
   assert(ZEN.OK)
end


---
-- Compare equality of two data objects (TODO: octet, ECP, etc.)
-- @function ZEN:eq(first, second)

---
-- Check that the first object is greater than the second (TODO)
-- @function ZEN:gt(first, second)

---
-- Check that the first object is lesser than the second (TODO)
-- @function ZEN:lt(first, second)


--- Then block (OUT write-only memory)
-- @section Then

---
-- Move a generic data structure from ACK to OUT memory space, ready
-- for its final JSON encoding and print out.
-- @function ZEN:out(name)

---
-- Move 'my own' data structure from ACK to OUT.whoami memory space,
-- ready for its final JSON encoding and print out.
-- @function ZEN:outmy(name)

---
-- Convert a data object to the desired format (argument name provided
-- as string), or use CONF.encoding when called without argument
--
-- @function ZEN:export(object, format)
-- @param object data element to be converted
-- @param format pointer to a converter function
-- @return object converted to format
function zencode:export(object, format)
   -- CONF { encoding = <function 1>,
   --        encoding_prefix = "u64"  }
   ZEN.assert(object, "ZEN:export object not found")
   ZEN.assert(iszen(type(object)), "ZEN:export called on a ".. type(object))
   local conv_f = nil
   local ft = type(format)
   if format and ft == 'function' then conv_f = format goto ok end
   if format and ft == 'string' then conv_f = get_encoding(format).fun goto ok end
   conv_f = CONF.output.encoding.fun -- fallback to configured conversion function
   ::ok::
   ZEN.assert(type(conv_f) == 'function' , "ZEN:export conversion function not configured")
   return conv_f(object) -- TODO: protected call
end

---
-- Import a generic data element from the tagged format, or use
-- CONF.encoding
--
-- @function ZEN:import(object)
-- @param object data element to be read
-- @param secured block implicit conversion from untagget string
-- @return object read
function zencode:import(object, secured)
   ZEN.assert(object, "ZEN:import object is nil")
   local t = type(object)
   if iszen(t) then
	  warn("ZEN:import object already converted to "..t)
	  return t
   end
   ZEN.assert(t ~= 'table', "ZEN:import table is impossible: object needs to be 'valid'")
   ZEN.assert(t == 'string', "ZEN:import object is not a string: "..t)
   -- OK, convert
   if string.sub(object,1,3) == 'u64' and O.is_url64(object) then
	  -- return decoded string format for JSON.decode
	  return O.from_url64(object)
   elseif string.sub(object,1,3) == 'b64' and O.is_base64(object) then
	  -- return decoded string format for JSON.decode
	  return O.from_base64(object)
   elseif string.sub(object,1,3) == 'hex' and O.is_hex(object) then
	  -- return decoded string format for JSON.decode
	  return O.from_hex(object)
   elseif string.sub(object,1,3) == 'bin' and O.is_bin(object) then
	  -- return decoded string format for JSON.decode
	  return O.from_bin(object)
   -- elseif CONF.input.encoding.fun then
   -- 	  return CONF.input.encoding.fun(object)
   elseif string.sub(object,1,3) == 'str' then
	  return O.from_string(object)
   end
   if not secured then
	  ZEN:wtrace("import implicit conversion from string ("..#object.." bytes)")
	  return O.from_string(object)
   end
   error("Import secured to fail on untagged object",1)
   return nil
   -- error("ZEN:import failed conversion from "..t, 3)
end



---------------------------------------------------------------
-- ZENCODE PARSER

function zencode:begin(verbosity)
   if verbosity > 0 then
      xxx(2,"Zencode debug verbosity: "..verbosity)
      self.verbosity = verbosity
   end
   self.current_step = self.given_steps
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
function zencode:step(text)
   if ZEN:isempty(text) then return true end
   if ZEN:iscomment(text) then return true end
   -- max length for single zencode line is #define MAX_LINE
   -- hard-coded inside zenroom.h
   local prefix = parse_prefix(text)
   local defs -- parse in what phase are we
   ZEN.OK = true
   exitcode(0)
   -- given block, may also skip scenario
   if prefix == 'given' then
	  ZEN.assert(ZEN.machine:enter_given(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to Given block")
      self.current_step = self.given_steps
      defs = self.current_step
	  if not ZEN.checks.scenario then
		 require_once("zencode_"..ZEN.scenario)
		 ZEN.checks.scenario = true
	  end

	  -- when, then, and blocks
   elseif prefix == 'when'  then
	  ZEN.assert(ZEN.machine:enter_when(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.."to When block")
      self.current_step = self.when_steps
      defs = self.current_step
	  collectgarbage()
   elseif prefix == 'then'  then
	  ZEN.assert(ZEN.machine:enter_then(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to Then block")
      self.current_step = self.then_steps
      defs = self.current_step
	  collectgarbage()
   elseif prefix == 'and'   then
	  ZEN.assert(ZEN.machine:enter_and(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to And block")
      defs = self.current_step

   elseif prefix == 'scenario' then
	  ZEN.assert(ZEN.machine:enter_scenario(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to Scenario block")
	  -- string.gmatch to cut away text after the colon
	  local scenarios = strtok(string.match(text, "[^:]+"))
	  for k,scen in ipairs(scenarios) do
		 if k ~= 1 then -- skip prefix
			require_once("zencode_"..trimq(scen))
			ZEN:trace("Scenario "..scen)
		 end
	  end
	  ZEN.checks.scenario = true
   elseif prefix == 'rule' then
	  ZEN.assert(ZEN.machine:enter_rule(), text.."\n    "..
					"Invalid transition from "
					..ZEN.machine.current.." to Rule block")
	  -- process rules immediately
	  set_rule(text)
   else -- defs = nil end
	    -- if not defs then
		 exitcode(1)
		 error("Zencode pattern not found: "..text, 2)
		 ZEN.OK = false
   end
   if not ZEN.OK then
	  print(ZEN_traceback)
	  exitcode(1)
	  assert(ZEN.OK)
   end
   -- nothing further to parse
   if not defs then return false end
   -- TODO: optimize and write a faster function in C
   -- support simplified notation for arg match
   local tt = string.gsub(text,"'(.-)'","''")
   tt = string.gsub(tt:lower(),"when " ,"", 1)
   tt = string.gsub(tt,"then " ,"", 1)
   tt = string.gsub(tt,"given ","", 1)
   tt = string.gsub(tt,"and "  ,"", 1)
   tt = string.gsub(tt,"that "  ,"", 1)

   local match = false
   for pattern,func in pairs(defs) do
      if (type(func) ~= "function") then
         error("Zencode function missing: "..pattern, 2)
         return false
      end
      if strcasecmp(tt, string.gsub(pattern,"that "  ,"", 1)) then
		 local args = {} -- handle multiple arguments in same string
		 for arg in string.gmatch(text,"'(.-)'") do
			-- xxx(2,"+arg: "..arg)
			arg = string.gsub(arg, ' ', '_')
			table.insert(args,arg)
		 end
		 self.id = self.id + 1
		 table.insert(self.matches,
					  { id = self.id,
						args = args,
						source = text,
						hook = func       })
		 match = true
	  end
   end

   if not match and CONF.parser.strict_match then
	  exitcode(1)
	  error("Zencode pattern not found: "..text, 2)
	  ZEN.OK = false
	  return false
   end
   if not match then
	  warn("Ignored unknown zencode line: "..text)
   end
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
	  self:step(line)
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
   -- act(src) TODO: print also debug when verbosity is high
end

-- trace function execution also on success
function zencode:ftrace(src)
   -- take current line of zencode
   _G['ZEN_traceback'] = _G['ZEN_traceback']..
	  " D  ZEN:"..trim(src).."\n"
   -- "    -> ".. src:gsub("^%s*", "") .."\n"
   -- act(src) TODO: print also debug when verbosity is high
end

-- log zencode warning in traceback
function zencode:wtrace(src)
   -- take current line of zencode
   _G['ZEN_traceback'] = _G['ZEN_traceback']..
	  " W  ZEN:"..trim(src).."\n"
   -- "    -> ".. src:gsub("^%s*", "") .."\n"
   -- act(src) TODO: print also debug when verbosity is high
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
   for i,x in sort_ipairs(self.matches) do
	  ZEN:trace(x.source)
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
		 OUT.zenroom.curve = CONF.curve
		 OUT.zenroom.scenario = ZEN.scenario
		 OUT.zenroom.encoding = CONF.output.encoding.name
	  end
	  ZEN:trace("<<< Encoding { OUT } to "..CONF.output.format.name)
	  print(CONF.output.format.fun(OUT))
	  ZEN:trace(">>> Encoding successful")
   end
end

function zencode.debug()
   -- TODO: print to stderr
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
   -- print ''
   -- error(errmsg) -- prints zencode backtrace
   -- print ''
   -- assert(false, "Execution aborted.")
end

_G["Given"] = function(text, fn)
   zencode.given_steps[text] = fn
end
_G["When"] = function(text, fn)
   zencode.when_steps[text] = fn
end
_G["Then"] = function(text, fn)
   zencode.then_steps[text] = fn
end

return zencode
