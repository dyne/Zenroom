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
        if rule[1]:lower() == "seed" then
            test["seed"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "sk" then
            test["sk"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "pk" then
            test["pk"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "message" then
            test["message"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "signature" then
            test["signature"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1  
        elseif rule[1]:lower() == "context" then
            test["context"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "testpassed" then
            test["passed"] = rule[3]
            curr_fields = curr_fields+1  
        end
      end
      
      if curr_fields == 3 and test.seed then
	 -- Here starts the test
        local keys = QP.mldsa44_keypair(test.seed)
        assert(keys.private == test.sk)
        assert(keys.public == test.pk)
        assert(QP.mldsa44_pubgen(keys.private) == test.pk)
        curr_fields = 0
        test = { }
      end
      if (curr_fields == 5 and not test.passed) or (curr_fields == 6 and test.passed == "true") then
           local signature = QP.mldsa44_signature(test.sk, test.message, test.context)
           assert(signature == test.signature)
           assert(QP.mldsa44_pubgen(test.sk) == test.pk)
           assert(QP.mldsa44_verify(test.pk, test.signature, test.message, test.context))
           curr_fields = 0
           test = { }
         end
         if curr_fields == 6 and test.passed == "false" then
            local signature = QP.mldsa44_signature(test.sk, test.message, test.context)
            assert(QP.mldsa44_pubgen(test.sk) == test.pk)
            assert(QP.mldsa44_verify(test.pk, signature, test.message, test.context))
            assert(QP.mldsa44_verify(test.pk, test.signature, test.message, test.context)== false)
            curr_fields = 0
            test = { }
          end    
   end
end
