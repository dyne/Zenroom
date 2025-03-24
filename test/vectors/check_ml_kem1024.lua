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
        if rule[1]:lower() == "z" then
            test["z"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "m" then
            test["m"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "d" then
            test["d"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "ek" then
            test["ek"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "dk" then
            test["dk"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "k" then
            test["k"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        elseif rule[1]:lower() == "c" then
            test["c"] = O.from_hex(rule[3])
            curr_fields = curr_fields+1
        end
      end
      if curr_fields == 4 then

	 -- Here starts the test
        if (test.d) then
            assert(test.ek == QP.mlkem_keygen(test.d,test.z, "mlkem1024").public, "mlkem1024")
            print("pk ok")
            assert(test.dk == QP.mlkem_keygen(test.d, test.z, "mlkem1024").private, "mlkem1024")
            print("sk ok")
            assert(test.ek == QP.mlkem_pubgen(test.dk, "mlkem1024"), "mlkem1024")
            print("pubgen ok")
            end
        if (test.m) then
            assert(test.k == QP.mlkem_enc(test.ek, test.m, "mlkem1024").secret, "mlkem1024")
            print( "secret ok")
            assert(test.c == QP.mlkem_enc(test.ek, test.m, "mlkem1024").cipher, "mlkem1024")
            print("cipher ok")
        end
        if (test.dk and test.k) then
            assert(test.k == QP.mlkem_dec(test.dk,test.c, "mlkem1024"), "mlkem1024")
            print("dec ok")
        end
        curr_fields = 0
        test = { }
      end
   end
end

