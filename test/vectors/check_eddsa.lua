ED = require('ed')

local function newline_iter(text)
	s = trim(text) -- implemented in zen_io.c
	return s:gmatch('(.-)\n') -- iterators return functions
end

local nr = 0
for line in newline_iter(DATA) do
   nr = nr + 1
   print('############')
   local tokens = strtok(line, "[^:]*")
   I.spy(tokens)
   local sk = O.from_hex(tokens[1]:sub(1, 64))
   local pk = O.from_hex(tokens[2])
   assert(ED.pubgen(sk) == pk)
   local m = nil
   if tokens[3] ~= "" and tokens[4] then
      m = O.from_hex(tokens[3])
   else
      m = O.new()
   end
   print(nr)
   local sig = O.from_hex(tokens[4]:sub(1,128))
   
   assert(ED.sign(sk, m) == sig)
   assert(ED.verify(pk, sig, m))
end
