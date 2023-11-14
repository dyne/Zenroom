local P256 = require('p256')

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
local nr = 0

for line in newline_iter(DATA) do
    local rule = strtok(line)
    I.spy(rule)
    if #rule > 0 then
        if rule[1]:lower() == 'msg' then -- new check
			test["msg"] = O.from_hex(rule[3])
		elseif rule[1]:lower() == 'qx' then -- new check
			test["qx"] = O.from_hex(rule[3])
        elseif rule[1]:lower() == 'qy' and test.qx then -- new check
			test["qy"] = O.from_hex(rule[3])
        elseif rule[1]:lower() == 'r' then
            test["r"] = O.from_hex(rule[3])
        elseif rule[1]:lower() == 's' and test.r then
            test["s"] = O.from_hex(rule[3])
        elseif rule[1]:lower() == 'result' then
            test["result"] = I.spy(rule[3])
            nr = nr + 1
            local pk = test.qx .. test.qy
            local sig = test.r .. test.s
            if test.result:lower() == "p" then
                assert(P256.verify(pk, sig, test.msg), "error with test vector ".. nr.." verification should NOT fail")
            else
                assert(not P256.verify(pk, sig, test.msg), "error with test vector ".. nr.." verification should fail")
            end
        end
    end
end
print(nr)
