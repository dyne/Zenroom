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
   verbosity = 0
}

-- Zencode HEAP globals
IN = { } -- import global DATA from json
IN.KEYS = { } -- import global KEYS from json
ACK = ACK or { }
OUT = OUT or { }

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

-- fail when nothing found
function zencode:find(WHERE,what)
   zencode:trace('zenroom:find')
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
   local chomp = string.char(text:byte(1,4096))
   local prefix = chomp:match("(%w+)(.+)"):lower()
   local defs -- parse in what phase are we
   -- TODO: use state machine
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
		 ZEN:trace("   | Scenario "..scenario)
	  end
   end
   if not defs then
		 error("Zencode invalid: "..text)
		 error(_G.ZEN_traceback)
		 return false
   end
   for pattern,func in pairs(defs) do
      if (type(func) ~= "function") then
         error("Zencode function missing: "..pattern)
		 error(_G.ZEN_traceback)
         return false
      end
	  -- support simplified notation for arg match
	  local pat = string.gsub(pattern,"''","'(.-)'")
      local res = string.match(text, pat)
      if res then
		 act("EXEC: "..pat)
		 local args = {} -- handle multiple arguments in same string
		 for arg in string.gmatch(text,"'(.-)'") do
			act("+arg: "..arg)
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
		 _G['ZEN_traceback'] = _G['ZEN_traceback']..
			"    -> ".. text:gsub("^%s*", "") .. " ("..#args.." args)\n"
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
	  "    -> ".. src:gsub("^%s*", "") .."\n"
end
function zencode:run()
   -- xxx(2,"Zencode MATCHES:")
   -- xxx(2,self.matches)
   for i,x in ipairs(self.matches) do
	  IN = { } -- import global DATA from json
	  if DATA then IN = JSON.decode(DATA) end
	  IN.KEYS = { } -- import global KEYS from json
	  if KEYS then IN.KEYS = JSON.decode(KEYS) end
	  -- clean ACK and OUT tables
	  ACK = ACK or { }
	  OUT = OUT or { }
	  -- unprotected call (quit on error):
      --   x.hook(table.unpack(x.args))
	  -- protected call (doesn't exits on errors)
      local ok, err = pcall(x.hook,table.unpack(x.args))
      if not ok then
		 error(err)
		 -- error(_G.ZEN_traceback)
	  end
   end
   if type(OUT) == 'table' then print(JSON.encode(OUT)) end
end

function zencode.debug()
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
   error(errmsg) -- prints zencode backtrace
   assert(false, "Execution aborted.")
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
