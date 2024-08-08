
-- how many to test and how much increment
TOTAL = 1000
STEP = 50
TOTAL = TOTAL + STEP -- off by one fix

-- BBS = require 'crypto_bbs'

B2 = BBS.ciphersuite'sha256'
B3 = BBS.ciphersuite'shake256'

printerr "keygen sha256 "
local KEYGEN_SHA256_T = { }
for i=10,TOTAL,STEP do
  printerr(i.." ")
  local start = os.clock()
  for c=1,i,1 do keygen(B2) end
  table.insert(KEYGEN_SHA256_T, os.clock() - start)
end
collectgarbage'collect'
collectgarbage'collect'

printerr "keygen shake256 "
local KEYGEN_SHAKE256_T = { }
for i=10,TOTAL,STEP do
  printerr(i.." ")
  local start = os.clock()
  for c=1,i,1 do keygen(B3) end
  table.insert(KEYGEN_SHAKE256_T, os.clock() - start)
end
collectgarbage'collect'
collectgarbage'collect'

print("KEYS \t SHA256 \t SHAKE256")
for i=1,(TOTAL/STEP),1 do
  write(i*STEP)
  write(' \t ')
  write(KEYGEN_SHA256_T[i])
  write(' \t ')
  write(KEYGEN_SHAKE256_T[i])
  write('\n')
end
