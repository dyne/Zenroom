local zencode = {
   given_steps = {},
   when_steps = {},
   then_steps = {},
   current_step = nil,
   id = 0,
   matches = {},
   verbosity = 0
}

-- debugging facility
local function x(n,s)
   if zencode.verbosity > n then
	  warn(s) end
end
function zencode:begin(verbosity)
   if verbosity > 0 then
      warn("Zencode debug verbosity: "..verbosity)
      self.verbosity = verbosity
   end
   self.current_step = self.given_steps
   return true
end

function zencode:step(text)
   if text == nil or text == '' then return false end
   -- case insensitive match of first word
   local prefix = text:match("(%w+)(.+)"):lower()
   x(1,"prefix: "..prefix)
   local defs -- parse in what phase are we
   -- TODO: use state machine
   if     prefix == 'given' then
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
   end
   if not defs then
      x(1,"no valid definitions found in parsed zencode")
      return false
   end
   for pattern,func in pairs(defs) do
      if (type(func) ~= "function") then
         error("invalid function matched to pattern: "..pattern)
         return false
      end
	  -- support simplified notation for arg match
	  local pat = string.gsub(pattern,"''","'(.-)'")
	  x(1,"pattern: "..pat)
      local res = string.match(text, pat)
      if res then
		 local args = {} -- handle multiple arguments in same string
		 for arg in string.gmatch(text,"'(.-)'") do
			x(1,"arg: "..arg)
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
	  end
   end
end


-- returns an iterator for newline termination
function zencode:newline(s)
   if s:sub(-1)~="\n" then s=s.."\n" end
   return s:gmatch("(.-)\n")
end

function zencode:parse(text)
   for line in self:newline(text) do
      x(0,line)
      self:step(line)
   end
end

function zencode:run()
   if self.verbosity > 1 then
      warn("Zencode MATCHES:")
      I.warn(self.matches)
   end
   for i,x in ipairs(self.matches) do
	  -- I.warn(table.unpack(x.args))

	  -- protected call (doesn't exists on errors)
      -- local ok, err = pcall(x.hook,table.unpack(x.args))
      -- if not ok then error(err) end

	  -- unprotected call
      x.hook(table.unpack(x.args))
   end
end


verbosity = 1
-- debugging facility
local function x(n,s)
   if verbosity > n then
	  warn(s) end
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
