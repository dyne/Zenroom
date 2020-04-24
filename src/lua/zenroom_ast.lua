-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2020 Dyne.org foundation
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

function zencode_iscomment(b)
   local x = string.char(b:byte(1))
   if x == '#' then
	  return true
   else return false
end end
function zencode_isempty(b)
   if b == nil or b == '' then
	   return true
   else return false
end end
-- returns an iterator for newline termination
function zencode_newline_iter(text)
   s = trim(text) -- implemented in zen_io.c
   if s:sub(-1)~="\n" then s=s.."\n" end
   return s:gmatch("(.-)\n") -- iterators return functions
end

function set_sentence(self, event, from, to, ctx)
   local reg = ctx.Z[self.current.."_steps"]
   ctx.Z.OK = false
   ZEN.assert(reg, "Steps register not found: "..self.current.."_steps")
   for pattern,func in pairs(reg) do
	  if (type(func) ~= "function") then
		 error("Zencode function missing: "..pattern, 2)
		 return false
	  end
	  -- TODO: optimize in c
	  -- remove '' contents, lower everything, expunge prefixes
	  local tt = string.gsub(trim(ctx.msg),"'(.-)'","''")
	  tt = string.gsub(tt:lower() ,"when " ,"", 1)
	  tt = string.gsub(tt,"then " ,"", 1)
	  tt = string.gsub(tt,"given ","", 1)
	  tt = string.gsub(tt,"and "  ,"", 1) -- TODO: expunge only first 'and'
	  tt = string.gsub(tt,"that " ,"", 1)
	  if strcasecmp(tt, pattern) then
		 local args = {} -- handle multiple arguments in same string
		 for arg in string.gmatch(ctx.msg,"'(.-)'") do
			-- xxx(2,"+arg: "..arg)
			arg = string.gsub(arg, ' ', '_')
			table.insert(args,arg)
		 end
		 ctx.Z.id = ctx.Z.id + 1
		 -- AST data prototype
		 table.insert(ctx.Z.AST,
					  { id = ctx.Z.id, -- ordered number
						args = args,  -- array of vars
						source = ctx.msg, -- source text
						section = self.current,
						hook = func       }) -- function
		 ctx.Z.OK = true
		 break
	  end
   end
   if not ctx.Z.OK and CONF.parser.strict_match then
	  debug_traceback()
   	  exitcode(1)
   	  error("Zencode pattern not found: "..trim(ctx.msg), 1)
   	  return false
   end
end


-- TODO: investigate use of lua-faces
function set_rule(text)
   local res = false
   local rule = strtok(text.msg) -- TODO: optimise in C (see zenroom_common)
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
	  text.Z.checks.version = res
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

   elseif rule[2] == 'output' and rule[3] then
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
      elseif strcasecmp(rule[3],'ast') then
		 CONF.output.AST = true
		 res = true
	  end

	  -- TODO: rule debug [ format | encoding ]

   elseif rule[2] == 'unknown' and rule[3] then
	  if rule[3] == 'ignore' then
		 CONF.parser.strict_match = false
		 res = true
	  end

   elseif rule[2] == 'set' and rule[4] then

      CONF[rule[3]] = tonumber(rule[4]) or rule[4]
      res = true and CONF[rule[3]]

   end
   if not res then error("Rule invalid: "..text.msg, 3)
   else act(text.msg) end
   return res
end


return zencode_parse
