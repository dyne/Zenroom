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

local mayo = require'mayo'
local curr_fields = 0
local test = { }
for line in newline_iter(DATA) do
   if line:sub(1,1) ~= "#" then
      local rule = strtok(line)

      if #rule > 0 and rule[1] ~= "" and rule[1]:lower() ~= "count" and rule[1]:lower() ~= "mlen" and rule[1]:lower() ~= "smlen" then
     curr_fields = curr_fields+1
     
     test[rule[1]:lower()] = O.from_hex(rule[3])
      end
      
      if curr_fields == 5 then
     -- Here starts the test
     assert(mayo.pubcheck(test.pk))
     assert(mayo.signature_check(test.sm:sub(1, mayo.signature_len())))
     assert(mayo.verify(test.pk, test.sm:sub(1, mayo.signature_len()), test.msg))
     assert(test.msg == mayo.verified_msg(test.pk, test.sm))
    
     -- These test are different from the dilithium ones because of the way the signature is generated (deterministically in dilithium, non-deterministically in mayo)
     -- Here we only check verify works
     local new_sig = mayo.sign(test.sk, test.msg)
     assert(mayo.verify(test.pk, new_sig, test.msg))

     curr_fields = 0
     test = { }
      end
   end
end
