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
-- Zencode is a <a
-- href="https://en.wikipedia.org/wiki/Domain-specific_language">Domain
-- Specific Language (DSL)</a> made to be understood by humans and
-- inspired by <a
-- href="https://en.wikipedia.org/wiki/Behavior-driven_development">Behavior
-- Driven Development (BDD)</a> and <a
-- href="https://en.wikipedia.org/wiki/Domain-driven_design">Domain
-- Driven Design (DDD)</a>.
--
-- The Zenroom VM is capable of parsing specific scenarios written in
-- Zencode and execute high-level cryptographic operations described
-- in them; this is to facilitate the integration of complex
-- operations in software and the non-literate understanding of what a
-- distributed application does. A generic Zencode looks like this:
--
-- <code>
-- Given that I am known as 'Alice'
--
-- When I create my new keypair
--
-- Then print my data
-- </code>
--
-- This section doesn't provide the documentation on how to write
-- Zencode, but illustrates the internals on how the Zencode parser is
-- made and how it integrates with the Zenroom memory model. It serves
-- as a reference documentation on functions used to write parsers for
-- new Zencode scenarios in Zenroom's Lua.
--
--  @module ZEN
--  @author Denis "Jaromil" Roio
--  @license AGPLv3
--  @copyright Dyne.org foundation 2018-2019


local zencode = {
   given_steps = {},
   when_steps = {},
   then_steps = {},
   current_step = nil,
   id = 0,
   matches = {},
   verbosity = 0,
   schemas = { },
   scenario = 'basic';
   OK = true -- set false by asserts
}

zencode.machine = MACHINE.create({
	  initial = 'init',
	  events = {
		 { name = 'enter_rule',     from = { 'init', 'rule' }, to = 'rule' },
		 { name = 'enter_scenario', from = { 'init', 'rule' }, to = 'scenario' },
		 { name = 'enter_given',    from = { 'init', 'rule', 'scenario' }, to = 'given' },
		 { name = 'enter_when',     from =   'given',             to = 'when' },
		 { name = 'enter_then',     from = { 'given', 'when' },   to = 'then' },
		 { name = 'enter_and',      from =   'given',             to = 'given' },
		 { name = 'enter_and',      from =   'when',              to = 'when' },
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
			  schema = what }
	  return(ZEN.OK)
   end
   local got
   got = inside_pick(IN.KEYS, what) or inside_pick(IN,what)
   ZEN.assert(got, "Cannot find "..what.." anywhere")
   TMP = { root = nil,
		   data = got,
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
   root = inside_pick(IN.KEYS,section) or inside_pick(IN, section)
   ZEN.assert(root, "Cannot find "..section.." anywhere")
   got = inside_pick(root, what)
   ZEN.assert(got, "Cannot find "..what.." inside "..section)   
   -- TODO: check all corner cases to make sure TMP[what] is a k/v map
   TMP = { root = section,
		   data = got,
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
   TMP.valid = res -- overwrite
   assert(ZEN.OK)
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
   ACK[key][val] = TMP.valid
end

---
-- Final step inside the <b>Given</b> block towards the <b>When</b>:
-- pass on a data structure into the ACK memory space, ready for
-- processing.  It requires the data to be present in TMP[name] and
-- typically follows a @{pick}. In some cases it is used inside a
-- <b>When</b> block following the inline insertion of data from
-- zencode.
--
-- @function ZEN:ack(name)
-- @param name string key of the data object in TMP[name]
function zencode:ack(name)
   local obj = TMP.valid
   ZEN.assert(obj, "No valid object found: ".. name)
   assert(ZEN.OK)
   local t
   if not ACK[name] then -- assign in ACK the single object
	  ACK[name] = obj
	  goto done
   end
   -- ACK[name] already holds an object
   t = type(ACK[name])
   -- not a table?
   if t ~= 'table' then -- convert single object to array
	  ACK[name] = { ACK[name] }
	  table.insert(ACK[name], obj)
	  goto done
   end
   -- it is a table already
   if isarray(ACK[name]) then -- plain array
	  table.insert(ACK[name], obj)
	  goto done
   else -- associative map
	  table.insert(ACK[name], obj) -- TODO:
	  goto done
   end
   ::done::
   assert(ZEN.OK)
end

function zencode:ackmy(name, object)
   local obj = object or TMP[name]
   ZEN:trace("f   pushmy() "..name.." "..type(obj))
   ZEN.assert(ACK.whoami, "No identity specified")
   ZEN.assert(obj, "Object not found: ".. name)
   local me = ACK.whoami
   if not ACK[me] then ACK[me] = { } end
   ACK[me][name] = obj
   if not object then tmp[name] = nil end
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
   if format and ft == 'string' then conv_f = get_encoding(format) goto ok end
   conv_f = CONF.encoding_fun -- fallback to configured conversion function
   ::ok::
   ZEN.assert(conv_f , "ZEN:export conversion function not configured")
   return conv_f(object) -- TODO: protected call
end

---
-- Import a generic data element from the tagged format, or use
-- CONF.encoding
--
-- @function ZEN:import(object)
-- @param object data element to be read
-- @return object read
function zencode:import(object)
   ZEN.assert(object, "ZEN:import object is nil")
   local t = type(object)
   if iszen(t) then
	  warn("ZEN:import object already converted to "..t)
	  return t
   end
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
   end
   ZEN:wtrace("import implicit conversion from string: " ..object)
   return O.from_string(object)
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
   if prefix == 'given' then
	  ZEN.assert(ZEN.machine:enter_given(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to Given block")
      self.current_step = self.given_steps
      defs = self.current_step
	  ZEN:trace("|   Scenario "..ZEN.scenario)
   elseif prefix == 'when'  then
	  ZEN.assert(ZEN.machine:enter_when(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.."to When block")
      self.current_step = self.when_steps
      defs = self.current_step
   elseif prefix == 'then'  then
	  ZEN.assert(ZEN.machine:enter_then(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to Then block")
      self.current_step = self.then_steps
      defs = self.current_step
   elseif prefix == 'and'   then
	  ZEN.assert(ZEN.machine:enter_and(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to And block")
      defs = self.current_step
   elseif prefix == 'scenario' then
	  ZEN.assert(ZEN.machine:enter_scenario(), text.."\n    ".."Invalid transition from "..ZEN.machine.current.." to Scenario block")
      self.current_step = self.given_steps
      defs = self.current_step
	  ZEN.scenario = string.match(text, "'(.-)'")
	  if ZEN.scenario ~= "" then
		 require("zencode_"..ZEN.scenario)
		 ZEN:trace("|   Scenario "..ZEN.scenario)
		 act("config scenario: "..ZEN.scenario)
	  end
   elseif prefix == 'rule' then
	  ZEN.assert(ZEN.machine:enter_rule(), text.."\n    "..
					"Invalid transition from "
					..ZEN.machine.current.." to Rule block")
	  -- process rules immediately
	  local rule = strtok(text) -- TODO: optimise in C (see zenroom_common)
	  if rule[2] == 'check' and rule[3] == 'version' then
		 act("Zencode version check >= "..rule[4])
		 -- TODO: check version of running VM
	  elseif rule[2] == 'load' and rule[3] then
		 act("zencode extension: "..rule[3])
		 require("zencode_"..rule[3])
	  elseif rule[2] == 'set' and rule[4] then
		 act("rule set: "..rule[3].." = "..rule[4])
		 if rule[3] == 'encoding' then
			set_encoding(rule[4])
		 else
			CONF[rule[3]] = tonumber(rule[4]) or rule[4]
		 end
	  end
	  -- TODO: rule to set version of zencode
   else -- defs = nil end
	    -- if not defs then
		 ZEN.assert("Zencode invalid: "..text)
   end
   if not ZEN.OK then
	  print(ZEN_traceback)
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

   for pattern,func in pairs(defs) do
      if (type(func) ~= "function") then
         error("Zencode function missing: "..pattern, 2)
         return false
      end
	  if strcasecmp(tt,pattern) then
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
	  end
   end
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
end

function zencode:trace(src)
   -- take current line of zencode
   _G['ZEN_traceback'] = _G['ZEN_traceback']..
	  trim(src).."\n"
	  -- "    -> ".. src:gsub("^%s*", "") .."\n"
   -- act(src) TODO: print also debug when verbosity is high
end

-- trace function execution also on success
function zencode:ftrace(src)
   -- take current line of zencode
   _G['ZEN_traceback'] = _G['ZEN_traceback']..
	  "f   ZEN:"..trim(src).."\n"
   -- "    -> ".. src:gsub("^%s*", "") .."\n"
   -- act(src) TODO: print also debug when verbosity is high
end

-- log zencode warning in traceback
function zencode:wtrace(src)
   -- take current line of zencode
   _G['ZEN_traceback'] = _G['ZEN_traceback']..
	  "w   ZEN:"..trim(src).."\n"
   -- "    -> ".. src:gsub("^%s*", "") .."\n"
   -- act(src) TODO: print also debug when verbosity is high
end

function zencode:run()
   -- xxx(2,"Zencode MATCHES:")
   -- xxx(2,self.matches)
   for i,x in sort_ipairs(self.matches) do
	  IN = { } -- import global DATA from json
	  if DATA then
		 -- if plain array conjoin into associative
		 IN = JSON.decode(DATA) or { }
		 -- TODO: load the setup
		 IN.zenroom = nil

		 -- if _in and isarray(_in) then -- conjoin array
		 -- 	for i,c in ipairs(_in) do
		 -- 	   for k,v in pairs(c) do IN[k] = v end
		 -- 	end
		 -- else IN = _in or { } end
	  end
	  IN.KEYS = { } -- import global KEYS from json
	  if KEYS then IN.KEYS = JSON.decode(KEYS) or { } end
	  -- TODO: compare the setup raise error if different
	  IN.KEYS.zenroom = nil
	  ZEN:trace("->  "..trim(x.source))
	  ZEN.OK = true
      local ok, err = pcall(x.hook,table.unpack(x.args))
      if not ok or not ZEN.OK then
	  	 if err then ZEN:trace("[!] "..err) end
		 fatal(x.source) -- traceback print inside
	  end
   end
   ZEN:trace("--- Zencode execution completed")
   if type(OUT) == 'table' then
	  ZEN:trace("+++ Adding setup information to { OUT }")
	  OUT.zenroom = { }
	  OUT.zenroom.version = VERSION.original
	  OUT.zenroom.curve = CONF.curve
	  OUT.zenroom.scenario = ZEN.scenario
	  OUT.zenroom.encoding = CONF.encoding
	  ZEN:trace("<<< Encoding { OUT } to \"JSON\"")
	  print(JSON.encode(OUT))
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
