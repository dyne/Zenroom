local function newline_iter(text)
	s = trim(text) -- implemented in zen_io.c
	if s:sub(-1) ~= '\n' then
		s = s .. '\n'
	end
	return s:gmatch('(.-)\n') -- iterators return functions
end

local RSA = require'rsa'
local curr_fields = 0
local n
local e
local test = { }
for line in newline_iter(DATA) do
   if line:sub(1,1) ~= "#" then
    local rule = strtok(line)

    if #rule > 0 then
        if rule[1]:lower() == "n" then
            n = O.from_hex(rule[3])
        elseif rule[1]:lower() == "e" then
            e = O.from_hex(rule[3])
        elseif rule[1]:lower() == "msg" then
            test["msg"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "s" then
            test["s"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        end
      end
      
    if curr_fields == 2 then
	 -- Here starts the test
        local pk = n .. e
        assert(RSA.verify(pk, test.msg, test.s))


    
	 curr_fields = 0
	 test = { }
      end
   end
end
