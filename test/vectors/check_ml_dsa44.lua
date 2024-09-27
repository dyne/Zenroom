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

      if #rule > 0 then
        if rule[1]:lower() == "xi" then
            test["xi"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "sk" then
            test["sk"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "pk" then
            test["pk"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "msg" then
            test["msg"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "sm" then
            test["sm"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1  

        elseif rule[1]:lower() == "ctx" then
            test["ctx"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1  
        end
      end
      
      if curr_fields == 6 then
	 -- Here starts the test
        local keys = QP.mldsa44_keypair(test.xi)
        assert(keys.private == test.sk)
        assert(keys.public == test.pk)
        assert(QP.mldsa44_pubgen(keys.private) == test.pk)
        local signature = QP.mldsa44_signature(keys.private, test.msg, test.ctx)
        assert(signature == test.sm:sub(1,2420))
        assert(QP.mldsa44_verify(keys.public, signature, test.msg, test.ctx))
        curr_fields = 0
        test = { }
      end
   end
end
