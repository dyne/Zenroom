-- Zenroom test for NIST's shabytetestvectors
-- https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Algorithm-Validation-Program/documents/shs/shabytetestvectors.zip

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

hash = HASH.new(KEYS)
local test = { }
local nr = 0
for line in newline_iter(DATA) do
   local rule = strtok(line)
   -- I.print(rule)
   if #rule > 0 then
	  if rule[1]:lower() == 'msg' then -- new check
		 if rule[3] ~= '00' then -- skip 00
			test = { msg = O.from_hex(rule[3]) }
		 end
	  elseif rule[1]:lower() == 'md' and test.msg then
		 nr = nr + 1
		 assert(hash:process(test.msg) == O.from_hex(rule[3]),
				'error with hash '..KEYS..' test vector nr '..nr)
		 -- print('OK\t'..KEYS..'\t'..nr..'\t('..#test.msg..' bytes)')
		 test = { }
		 -- test.msg = nil
	  end
   end
end
print(nr)
