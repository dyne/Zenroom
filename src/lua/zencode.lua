local zencode = {
   before_steps = {},
   given_steps = {},
   when_steps = {},
   then_steps = {},
   current_step = before_steps,
   id = 0,
   matches = {}
}

function zencode:begin(args)
   for i,hook in ipairs(self.before_steps) do
	  local ok, err = pcall(hook)
	  if not ok then error(err) return false end
   end
   self.current_step = self.given_steps
   return true
end

function zencode:step(text)
   if text == nil or text == '' then return false end
   local prefix = text:match("(%w+)(.+)"):lower()
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
   if not defs then return false end
   for pattern,func in pairs(defs) do
	  if type(func) == "function" then
		 local res = string.match(text, pattern)
		 if res then
			local args = {}	-- handle multiple arguments in same string
			for arg in string.gmatch(text,"'(%w+)'") do
			   table.insert(args,arg)
			end
			self.id = self.id + 1
			table.insert(self.matches,
						 { id = self.id,
						   args = args,
						   source = text,
						   prefix = prefix,
						   regexp = pattern,
						   hook = func       })
		 end
	  end
   end
end

function zencode:newline(s)
   if s:sub(-1)~="\n" then s=s.."\n" end
   return s:gmatch("(.-)\n")
end

function zencode:parse(text)
   for line in self:newline(addition) do
	  if line then
		 print(line)
		 self:step(line)
	  end
   end
end

function zencode:run()
   for i,x in pairs(self.matches) do
	  local ok, err = pcall(x.hook,table.unpack(x.args))
	  if not ok then error(err) end
   end
end
  
local before_step = function(text, fn)
   table.insert(zencode.before_steps, func)
end
local given_step = function(text, fn)
   zencode.given_steps[text] = fn
end
local when_step = function(text, fn)
   zencode.when_steps[text] = fn
end
local then_step = function(text, fn)
   zencode.then_steps[text] = fn
end

_G["Before"]   = before_step
_G["Given"]    = given_step
_G["When"]     = when_step
_G["Then"]     = then_step

return zencode
