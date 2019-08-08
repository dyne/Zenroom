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

local zencode = {
   given_steps = {},
   when_steps = {},
   then_steps = {},
   current_step = nil,
   id = 0,
   matches = {},
   verbosity = 0,
   schemas = { },
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


function zencode:ack(name, object)
   local obj = object or TMP[name]
   ZEN.assert(obj, "Object not found: ".. name)
   ZEN:trace("f   pick() "..name.." "..type(obj))
   if ACK[name] then -- already existing, create an array
	  if type(ACK[name]) ~= "table" then
		 ACK[name] = { ACK[name] }
	  end
	  table.insert(ACK[name], obj)
   else
	  ACK[name] = obj
   end
   -- delete the record from TMP if necessary
   if not object then TMP[name] = nil end
   return(ZEN.OK)
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
   return(ZEN.OK)
end

function zencode:validate(name)
   ZEN.assert(name, "Import error: schema name is nil")
   ZEN.assert(TMP[name], "Import error: object not found in TMP["..name.."]")
   local s = ZEN.schemas[name]
   ZEN.assert(s, "Import error: schema not found: "..name)
   ZEN.assert(type(s) == 'function', "Import error: schema is not a function: "..name)
   local res = s(TMP[name])
   ZEN.assert(res, "Schema validation failed: "..name)
   TMP[name] = res -- overwrite
   return(ZEN.OK)
end

function zencode:validate_recur(obj, name)
   ZEN.assert(name, "ZEN:validate_recur error: schema name is nil")
   ZEN.assert(obj, "ZEN:validate_recur error: object is nil")
   local s = ZEN.schemas[name]
   ZEN.assert(s, "ZEN:validate_recur error: schema not found: "..name)
   ZEN.assert(type(s) == 'function', "ZEN:validate_recur error: schema is not a function: "..name)
   local res = s(obj)
   ZEN.assert(res, "Schema validation failed: "..name)
   return(res)
end

-- returns any object called 'what' found anywhere inside IN.*
function zencode:pick(what)
   ZEN:trace("f   find() "..what)
   local got = IN.KEYS[what] -- try IN.KEYS
   if got then
      ZEN:trace("f   find() found IN.KEYS."..what)
	  goto gotit
   end
   -- try KEYS.*.what (TODO: exclude ACK.whoami)
   for k,v in pairs(IN.KEYS) do
      if type(v) == "table" and v[what] then
         got = v[what]
         ZEN:trace("f   find() found IN.KEYS."..k.."."..what)
         goto gotit
	  end
   end
   -- try IN
   got = IN[what]
   if got then
      ZEN:trace("f   find() found IN."..what)
      goto gotit
   end
   -- try IN.*.what (TODO: exclude KEYS and ACK.whoami)
   for k,v in pairs(IN) do
      if type(v) == "table" and v[what] then
         got = v[what]
         ZEN:trace("f   find() found IN."..k.."."..what)
         goto gotit
      end
   end
   -- fail: not found
   ZEN.assert(false, "Cannot find "..what.." anywhere")
   TMP[what] = nil
   ::gotit::
   TMP[what] = got
   return(ZEN.OK)
end

-- returns any object 'what' in IN.KEYS[ACK.whoami] or IN[ACK.whoami]
function zencode:pickmy(what)
   ZEN.assert(ACK.whoami, "No identity specified")
   ZEN:trace("f   pickmy() "..what.." as "..ACK.whoami)
   local me = IN.KEYS[ACK.whoami]
   local got = nil
   if me then
	  ZEN:trace("f   pickmy() found "..ACK.whoami.." in KEYS")
	  goto gotme
   end
   me = IN[ACK.whoami]
   if me then
	  ZEN:trace("f   pickmy() found "..ACK.whoami.." in HEAP root")
	  goto gotme
   end
   ZEN.assert(false, "Cannot find "..ACK.whoami.." anywhere")
   ::gotme::
   got = me[what]
   if got then goto gotit end -- easy
   for k,v in pairs(me) do -- search 1 deeper
      if type(v) == "table" and v[what] then
         got = v[what]
         ZEN:trace("f   pickmy() found IN."..k.."."..what)
         goto gotit
      end
   end
   ZEN.assert(got, "Cannot find "..what.." for "..ACK.whoami)   
   ::gotit::
   TMP[what] = got
   return(ZEN.OK)
end

-- debugging facility
function xxx(n,s)
   if zencode.verbosity >= n then
	  act(s) end
end
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
   -- first word
   local chomp = string.char(text:byte(1,1024))
   local prefix = chomp:match("(%w+)(.+)"):lower()
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
	  local scenario = string.match(text, "'(.-)'")
	  if scenario ~= "" then
		 require("zencode_"..scenario)
		 ZEN:trace("|   Scenario "..scenario)
	  end
   else -- defs = nil end
	    -- if not defs then
		 error("Zencode invalid: "..chomp)
		 return false
   end
   for pattern,func in pairs(defs) do
      if (type(func) ~= "function") then
         error("Zencode function missing: "..pattern)
         return false
      end
	  -- support simplified notation for arg match
	  local pat = string.gsub(pattern,"''","'(.-)'")
	  if string.match(text, pat) then
		 -- xxx(3,"EXEC: "..pat)
		 local args = {} -- handle multiple arguments in same string
		 for arg in string.gmatch(text,"'(.-)'") do
			-- xxx(3,"+arg: "..arg)
			arg = string.gsub(arg, ' ', '_')
			table.insert(args,arg)
		 end
		 self.id = self.id + 1
		 table.insert(self.matches,
					  { id = self.id,
						args = args,
						source = text,
						prefix = prefix,
						regexp = pat,
						hook = func       })
		 -- this is parsing, not execution, hence tracing isn't useful
		 -- _G['ZEN_traceback'] = _G['ZEN_traceback']..
		 -- 	"    -> ".. text:gsub("^%s*", "") .. " ("..#args.." args)\n"
	  end
   end
end


-- returns an iterator for newline termination
function zencode:newline_iter(text)
   s = trim(text) -- implemented in zen_io.c
   if s:sub(-1)~="\n" then s=s.."\n" end
   return s:gmatch("(.-)\n") -- iterators return functions
end

-- TODO: improve parsing for strings starting with newline, missing scenarios etc.
function zencode:parse(text)
   if  #text < 16 then
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
      if not ok then
		 ZEN:trace("[!] "..err)
		 ZEN:trace("---")
		 error(trim(x.source))
		 -- clean the traceback
		 _G['ZEN_traceback'] = ""
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
   I.print({ACK = ACK})
   I.print({OUT = OUT})
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

-- _G["Before"]   = before_step
-- _G["Given"]    = given_step
-- _G["When"]     = when_step
-- _G["Then"]     = then_step

return zencode
