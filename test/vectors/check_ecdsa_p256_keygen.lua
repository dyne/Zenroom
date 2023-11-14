local P256 = require('p256')

-- this is a simple rsp parser by jaromil@dyne.org
-- an rsp file must be loaded in DATA
-- public domain (and thanks for all the NIST)

local function newline_iter(text)
	s = trim(text) -- implemented in zen_io.c
	if s:sub(-1) ~= '\n' then
		s = s .. '\n'
	end
	return s:gmatch('(.-)\n') -- iterators return functions
end

local test = { }
local nr = 0

for line in newline_iter(DATA) do
    local rule = strtok(line)
   -- I.print(rule)
    if #rule > 0 then
		if rule[1]:lower() == 'd' then -- new check
			test["d"] = BIG.new(O.from_hex(rule[3]))
		elseif rule[1]:lower() == 'qx' then -- new check
			test["qx"] = O.from_hex(rule[3])
        elseif rule[1]:lower() == 'qy' and test.d and test.qx then -- new check
			test["qy"] = O.from_hex(rule[3])
            nr = nr + 1
            assert(I.spy(P256.pubgen(test.d)) == test.qx..test.qy, 'error with keyGen test vector nr '..nr)
		end
    end
end
print(nr)
