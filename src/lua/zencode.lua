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
local function xxx(n,s)
   if zencode.verbosity > n then
	  warn(s) end
end
function zencode:begin(verbosity)
   if verbosity > 0 then
      warn("Zencode debug verbosity: "..verbosity)
      self.verbosity = verbosity
   end
   _G.ZEN_traceback = "Zencode traceback:\n"
   self.current_step = self.given_steps
   return true
end

function zencode:step(text)
   if text == nil or text == '' then 
	  return false
   end
   -- case insensitive match of first word
   local prefix = text:match("(%w+)(.+)"):lower()
   xxx(1,"prefix: "..prefix)
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
   end
   if not defs then
      xxx(1,"no valid definitions found in parsed zencode")
      return false
   end
   for pattern,func in pairs(defs) do
      if (type(func) ~= "function") then
         error("invalid function matched to pattern: "..pattern)
         return false
      end
	  -- support simplified notation for arg match
	  local pat = string.gsub(pattern,"''","'(.-)'")
	  xxx(1,"pattern: "..pat)
      local res = string.match(text, pat)
      if res then
		 local args = {} -- handle multiple arguments in same string
		 for arg in string.gmatch(text,"'(.-)'") do
			xxx(1,"arg: "..arg)
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
   for first in self:newline(text) do
	  -- lowercase match
	  if first:match("(%w+)(.+)"):lower() == "scenario" then
		 local scenario = string.match(first, "'(.-)'")
		 require("zencode_"..scenario)
	  end
	  break
   end
   for line in self:newline(text) do
      -- xxx(0,line)
      self:step(line)
   end
end

function zencode:run()
   if self.verbosity > 1 then
      warn("Zencode MATCHES:")
      I.warn(self.matches)
   end
   for i,x in ipairs(self.matches) do
	   -- xxx(1,table.unpack(x))
	  -- protected call (doesn't exists on errors)
      -- local ok, err = pcall(x.hook,table.unpack(x.args))
      -- if not ok then error(err) end

	  _G['ZEN_traceback'] = _G['ZEN_traceback']..
		 "    -> ".. x.source:gsub("^%s*", "") .."\n"
	  IN = { } -- import global DATA from json
	  if DATA then IN = JSON.decode(DATA) end
	  IN.KEYS = { } -- import global KEYS from json
	  if KEYS then IN.KEYS = JSON.decode(KEYS) end
	  -- clean ACK and OUT tables
	  ACK = ACK or { }
	  OUT = OUT or { }
	  -- exec all hooks via unprotected call (quit on error)
      x.hook(table.unpack(x.args))
   end
end

function zencode.debug()
   error("Zencode debug states")
   I.print({IN = IN})
   I.print({ACK = ACK})
   I.print({OUT = OUT})
end

function zencode.assert(condition, errmsg)
   if condition then return true end
   error(errmsg) -- prints zencode backtrace
   assert(false)
end

zencode.validate = function(obj, objschema, errmsg)
   zencode.assert(type(obj) == 'table', "ZEN:validate called with an invalid object (not a table)")
   zencode.assert(type(objschema) == 'string', "ZEN:validate called with invalid schema (not a function)")
   -- sc = objschema
   -- zencode.assert(sc ~= nil, errmsg .. " - schema function '"..objschema.."' is not defined")
   -- zencode.assert(type(sc) == "function", errmsg .. " - schema '"..objschema.."' is not a function")
   zencode.assert(obj ~= nil,
				  "Object not found in schema validation - "..errmsg)
   if validate(obj, objschema, errmsg) then return true end
   error(errmsg)
   assert(false)
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

-- init schemas
zencode.schemas = { }
function zencode.add_schema(arr)
   for k,v in ipairs(arr) do
	  zencode.schemas[k] = v
   end
end
return zencode
