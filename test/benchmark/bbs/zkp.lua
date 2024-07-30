-- BBS zkp benchmark

-- how many to test and how much increment
TOTAL = 1000
STEP = 50
TOTAL = TOTAL + STEP -- off by one fix

-- BBS = require 'crypto_bbs'
B3 = BBS.ciphersuite'shake256'


printerr "zkp prove+verify shake256 "
local PROVE_T = { }
local VERIFY_T = { }
for i=STEP,TOTAL,STEP do
  printerr(i.." ")

  local messages = { }
  for c=1,i,1 do
      table.insert(messages, O.random(64))
  end

  local keys = keygen(B3)
  local signed = sign(B3, keys, messages)
  local indexes = random_indexes(messages,i/2)
  collectgarbage'collect'
  collectgarbage'collect'

  local start = os.clock()
  local proof = create_proof(B3, keys.pk, signed, messages, indexes)
  table.insert(PROVE_T, os.clock() - start)

  local disclosed = disclosed_messages(messages, indexes)
  local start = os.clock()
  assert( verify_proof(B3, keys.pk, proof, disclosed, indexes) )
  table.insert(VERIFY_T, os.clock() - start)

  collectgarbage'collect'
  collectgarbage'collect'

end

print("DISCLOSURES \t PROVE \t VERIFY")
for i=1,(TOTAL/STEP),1 do
  write(i*STEP)
  -- write(' \t ')
  -- write(SIGN_SHA256_T[i])
  write(' \t ')
  write(PROVE_T[i])
  write(' \t ')
  -- write(VERIFY_SHA256_T[i])
  -- write(' \t ')
  write(VERIFY_T[i])
  write('\n')
end
