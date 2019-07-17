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
   schemas = { }
}

-- Zencode HEAP globals
IN = { } -- import global DATA from json
IN.KEYS = { } -- import global KEYS from json
ACK = ACK or { }
OUT = OUT or { }


-- ZEN:push(name, obj [,MEM])
--
-- moves 'obj' inside MEM.name
--
-- MEM += { name = obj }
function zencode:push(name, obj, where)
   WHERE = where or 'ACK'
   ZEN:trace("f   push() "..name.." "..type(obj).." "..WHERE)
   ZEN.assert(obj, "Object not found: ".. name)
   local MEM = _G[WHERE]
   ZEN.assert(MEM, "Memory not found: ".. WHERE)
   if MEM[name] then -- already existing, create an array
	  if type(MEM[name]) ~= "table" then
		 MEM[name] = { MEM[name] }
	  end
	  table.insert(MEM[name], obj)
   else
	  -- ZEN.assert(not MEM[name], "Cannot overwrite object: "..WHERE.."."..name)
	  MEM[name] = obj
   end
   _G[WHERE] = MEM
end

-- ZEN:mypush(name, obj [,MEM])
--
-- moves 'obj' inside MEM.whoami.name
--
-- MEM += { whoami += { name = obj } }
function zencode:mypush(name, obj, where)
   WHERE = where or 'ACK'
   ZEN:trace("f   mypush() "..name.." "..type(obj).." "..WHERE)
   ZEN.assert(_G['ACK'].whoami, "No identity specified")
   ZEN.assert(obj, "Object not found: ".. name)
   local MEM = _G[WHERE]
   ZEN.assert(MEM, "Memory not found: ".. WHERE)
   local me = MEM[ACK.whoami]
   if not me then me = { } end
   me[name] = obj
   MEM[ACK.whoami] = me
   _G[WHERE] = MEM
end

-- returns a flat associative table of all objects in MEM
function zencode:flatten(MEM)
   local flat = { }
   local function inner_flatten(arr)
	  for k,v in ipairs(arr) do
		 if type(v) == "table" then
			flat[k] = v
			inner_flatten(v)
		 elseif(type(k) == "string") then
			flat[k] = v
		 end
	  end
   end
   inner_flatten(_G[MEM])
   return flat
end

-- returns any object called 'what' found anywhere in WHERE
function zencode:find(what, where)
   WHERE = where or 'IN'
   ZEN:trace("f   find() "..what.." "..WHERE)
   local got = _G[WHERE][what]
   if not got then
	  local flat = zencode:flatten(WHERE)
	  got = flat[what]
   end
   ZEN.assert(got, "Data not found: "..what)
   return got
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
   _G.ZEN_traceback = "Zencode traceback:\n"
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
end
function zencode:run()
   -- xxx(2,"Zencode MATCHES:")
   -- xxx(2,self.matches)
   for i,x in ipairs(self.matches) do
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
