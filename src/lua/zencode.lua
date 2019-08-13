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
   scenario = nil;
   OK = true -- set false by asserts
}

-- Zencode HEAP globals
IN = { }         -- Given processing, import global DATA from json
IN.KEYS = { }    -- Given processing, import global KEYS from json
TMP = TMP or { } -- Given processing, temp buffer for ack*->validate->push*
ACK = ACK or { } -- When processing,  destination for push*
OUT = OUT or { } -- print out

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
   ZEN.assert(type(obj) == "table", "ZEN:pick object is not a table")
   ZEN.assert(type(what) == "string", "ZEN:pick object index is not a string")
   local got = obj[what]
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
-- @return true or false
function zencode:validate(name)
   ZEN.assert(name, "ZEN:validate error: argument is nil")
   ZEN.assert(TMP, "ZEN:validate error: TMP is nil")
   ZEN.assert(TMP.schema, "ZEN:validate error: TMP.schema is nil")
   ZEN.assert(TMP.schema == name, "ZEN:validate() TMP does not contain "..name)
   local got = TMP.data -- inside_pick(TMP,name)
   ZEN.assert(TMP.data, "ZEN:validate error: data not found in TMP for schema "..name)
   local s = ZEN.schemas[TMP.schema]
   ZEN.assert(s, "ZEN:validate error: "..name.." schema not found")
   ZEN.assert(type(s) == 'function', "ZEN:validate error: schema is not a function for "..name)
   ZEN:ftrace("validate "..name)
   local res = s(TMP.data) -- ignore root
   ZEN.assert(res, "ZEN:validate error: schema validation failed for "..name)
   TMP.valid = res -- overwrite
   assert(ZEN.OK)
   ZEN:ftrace("validation passed for "..name)
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

---
-- Final step inside the <b>Given</b> block towards the <b>When</b>:
-- pass on a data structure into the ACK memory space, ready for
-- processing.  It must follow @{pick} and optionally @{validate}.
--
-- @function ZEN:ack(name, object)
-- @param name string descriptor of the data object
function zencode:ack(name)
   ZEN:validate(name) -- never ACK anything if not validated
   local obj = TMP.valid
   local t
   ZEN.assert(obj, "No valid object found: ".. name)
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
   -- delete the record from TMP
   TMP = nil
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
-- Compare equality of two data objects (TODO)
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
-- Convert a generic data element to the desired format (argument name
-- provided as string), or use CONF.encoding when called without
-- argument
--
-- @function ZEN:convert(object, format)
-- @param object data element to be converted
-- @param format string descriptor of format to convert to
-- @return object converted to format
function zencode:convert(object, format)
   local fun = format or CONF.encoding
   if format == "string" then
	  fun = str -- from zenroom_octet.lua
   end
   ZEN.assert(fun, "Conversion format not found")
   ZEN.assert(type(fun) == "function",
			  "Conversion format is not a function: "..type(fun))
   return fun(object)
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
   if prefix == 'given' then
      self.current_step = self.given_steps
      defs = self.current_step
   elseif prefix == 'when'  then
      self.current_step = self.when_steps
      defs = self.current_step
   elseif prefix == 'then'  then
      self.current_step = self.then_steps
      defs = self.current_step
   elseif prefix == 'and'   then
      defs = self.current_step
   elseif prefix == 'scenario' then
      self.current_step = self.given_steps
      defs = self.current_step
	  ZEN.scenario = string.match(text, "'(.-)'")
	  if ZEN.scenario ~= "" then
		 require("zencode_"..ZEN.scenario)
		 ZEN:trace("|   Scenario "..ZEN.scenario)
	  end
   else -- defs = nil end
	    -- if not defs then
		 error("Zencode invalid: "..text)
		 return false
   end

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
         error("Zencode function missing: "..pattern)
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
						-- prefix = prefix,
						-- regexp = pattern,
						hook = func       })
		 -- this is parsing, not execution: tracing isn't useful
		 -- _G['ZEN_traceback'] = _G['ZEN_traceback']..
		 -- "-> "..text:gsub("^%s*", "").." ("..#args.." args)\n"
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

function zencode:run()
   -- xxx(2,"Zencode MATCHES:")
   -- xxx(2,self.matches)
   for i,x in sort_ipairs(self.matches) do
	  IN = { } -- import global DATA from json
	  if DATA then IN = JSON.decode(DATA) end
	  IN.KEYS = { } -- import global KEYS from json
	  if KEYS then IN.KEYS = JSON.decode(KEYS) end
	  ZEN:trace("->  "..trim(x.source))
      local ok, err = pcall(x.hook,table.unpack(x.args))
      if not ok or not ZEN.OK then
	  	 ZEN:trace("[!] "..err)
	  	 ZEN:trace("---")
	  	 error(trim(x.source)) -- prints ZEN_traceback
	  	 -- clean the traceback
	  	 _G['ZEN_traceback'] = ""
		 assert(false)
	  end
   end
   ZEN:trace("--- Zencode execution completed")
   if type(OUT) == 'table' then
	  ZEN:trace("<<< Encoding { OUT } to \"JSON\"")
	  print(JSON.encode(OUT))
	  ZEN:trace(">>> Encoding successful")
   end
end

function zencode.debug()
   -- TODO: print to stderr
   print(" _______")
   print("|  DEBUG:")
   -- one print after another to sort deterministic
   I.print({IN = IN})
   I.print({TMP = TMP})
   I.print({ACK = ACK})
   I.print({OUT = OUT})
   I.print({Schemas = ZEN.schemas})
end

function zencode.debug_json()
   write(JSON.encode({ IN = IN,
					   ACK = ACK,
					   OUT = OUT }))
end

function zencode.assert(condition, errmsg)
   if condition then return true end
   -- ZEN.debug() -- prints all data in memory
   ZEN:trace("ERR "..errmsg)
   ZEN.OK = false
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
