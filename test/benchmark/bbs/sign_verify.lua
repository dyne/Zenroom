
-- how many to test and how much increment
TOTAL = 1000
STEP = 50
TOTAL = TOTAL + STEP -- off by one fix

-- BBS = require 'crypto_bbs'

-- B2 = BBS.ciphersuite'sha256'
B3 = BBS.ciphersuite'shake256'

-- printerr "sign+verify sha256 "
-- local SIGN_SHA256_T = { }
-- local VERIFY_SHA256_T = { }
-- for i=STEP,TOTAL,STEP do
--   printerr(i.." ")
--   local keys = keygen(B2)
--   local messages = { }
--   for c=1,i,1 do
--       table.insert(messages, O.random(512))
--   end
--   collectgarbage'collect'
--   collectgarbage'collect'

--   local start = os.clock()
--   local signed = sign(B2, keys, messages)
--   table.insert(SIGN_SHA256_T, os.clock() - start)

--   local start = os.clock()
--   assert( verify(B2, keys.pk, signed, messages) )
--   table.insert(VERIFY_SHA256_T, os.clock() - start)
-- end
-- collectgarbage'collect'
-- collectgarbage'collect'

printerr "sign+verify shake256 "
local SIGN_SHAKE256_T = { }
local VERIFY_SHAKE256_T = { }
for i=STEP,TOTAL,STEP do
  printerr(i.." ")
  local keys = keygen(B3)
  local messages = { }
  for c=1,i,1 do
      table.insert(messages, O.random(512))
  end
  collectgarbage'collect'
  collectgarbage'collect'

  local start = os.clock()
  local signed = sign(B3, keys, messages)
  table.insert(SIGN_SHAKE256_T, os.clock() - start)

  local start = os.clock()
  assert( verify(B3, keys.pk, signed, messages) )
  table.insert(VERIFY_SHAKE256_T, os.clock() - start)
end
collectgarbage'collect'
collectgarbage'collect'

print("SIGS \t SIGN \t VERIFY")
for i=1,(TOTAL/STEP),1 do
  write(i*STEP)
  -- write(' \t ')
  -- write(SIGN_SHA256_T[i])
  write(' \t ')
  write(SIGN_SHAKE256_T[i])
  write(' \t ')
  -- write(VERIFY_SHA256_T[i])
  -- write(' \t ')
  write(VERIFY_SHAKE256_T[i])
  write('\n')
end
