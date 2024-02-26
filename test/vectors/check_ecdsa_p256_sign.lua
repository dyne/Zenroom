local P256 = require('es256')

-- this is a simple rsp parser by jaromil@dyne.org
-- an rsp file must be loaded in DATA
-- the kind of hash must be indicated in KEYS
-- public domain (and thanks for all the NIST)

local function newline_iter(text)
	s = trim(text) -- implemented in zen_io.c
	if s:sub(-1) ~= '\n' then
		s = s .. '\n'
	end
	return s:gmatch('(.-)\n') -- iterators return functions
end

local test = { }
local curr_fields = 0
local nr = 0

for line in newline_iter(DATA) do
    local rule = strtok(line)
    if #rule > 0 and rule[1] ~= "" and rule[1]:lower() ~= "count" and rule[1]:lower() ~= "mlen" and rule[1]:lower() ~= "smlen" then
        curr_fields = curr_fields+1

        test[rule[1]:lower()] = O.from_hex(rule[3])
    end
    if curr_fields == 7 then
        assert(test.qx .. test.qy == P256.pubgen(test.d))
        assert(P256.verify(test.qx .. test.qy, test.msg, test.r .. test.s))
        assert(test.r .. test.s == P256.sign(test.d, test.msg, test.k))
        curr_fields = 0
        test = {}
    end

end
print(nr)
