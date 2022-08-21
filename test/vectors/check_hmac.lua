-- Zenroom test for NIST's hmac bytetestvectors

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
   I.print(rule)
   if #rule > 0 then
      if rule[1]:lower() == 'tlen' then -- new check
	 test = { tlen = tonumber(rule[3]) }
      elseif rule[1]:lower() == 'key' then -- new check
	 test.key = O.from_hex(rule[3])
      elseif rule[1]:lower() == 'msg' and test.key then
	 test.msg = O.from_hex(rule[3])
      elseif rule[1]:lower() == 'mac' and test.key then
	 test.mac = O.from_hex(rule[3])
	 nr = nr + 1
	 I.print(test)
	 local res = hash:hmac(test.key, test.msg)
	 assert(res:chop(test.tlen) == test.mac,
		'error with HMAC '..KEYS..' test vector nr '..nr)
	 print('OK\t'..KEYS..'\t'..nr..'\t('..test.key:hex()..')')
	 test = { }
      end
      end
end
print(nr)
