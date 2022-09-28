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

local QP = require'qp'
local curr_fields = 0
local test = { }
for line in newline_iter(DATA) do
   if line:sub(1,1) ~= "#" then
      local rule = strtok(line)

      if #rule > 0 and rule[1]:lower() ~= "count" and rule[1]:lower() ~= "mlen" and rule[1]:lower() ~= "smlen" then
	 curr_fields = curr_fields+1
	 
	 test[rule[1]:lower()] = O.from_hex(rule[3])
      end
      
      if curr_fields == 5 then
	 -- Here starts the test
	 assert(test.pk == QP.sigpubgen(test.sk))
	 assert(QP.sigpubcheck(test.pk))
	 assert(QP.signature_check(test.sm:sub(1, QP.signature_len())))
	 assert(QP.verify(test.pk, test.sm:sub(1, QP.signature_len()), test.msg))
	 assert(test.msg == QP.verified_msg(test.pk, test.sm))

	 assert(test.sm == QP.signed_msg(test.sk, test.msg))
	 assert(test.sm:sub(1, QP.signature_len()) == QP.sign(test.sk, test.msg))

	 curr_fields = 0
	 test = { }
      end
   end
end
