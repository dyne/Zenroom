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
        if rule[1]:lower() == "message" then
            test["message"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "sk" then
            test["sk"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "signature" then
            test["signature"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "pk" then
            test["pk"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        end
      end
      
      if curr_fields == 3 then
	 -- Here starts the test
    if (test.sk) then
    assert(test.signature == QP.mldsa44_signature(test.sk,test.message))
    print("sk ok")
    end
    if (test.pk) then
        assert(QP.mldsa44_verify(test.pk, test.signature, test.message))
        print("pk ok")
    end
	 curr_fields = 0
	 test = { }
      end
   end
end
