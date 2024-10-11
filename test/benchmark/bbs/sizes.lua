print 'BBS+ size benchmarks'
print ''

B3 = BBS.ciphersuite'shake256'

local kp = keygen(B3)

function create_index(count, max)
    local numbers = {}
    local uniqueNumbers = {}
    while #uniqueNumbers < count do
        local num = random16()%max
        if num == 0 then num=num+1 end
        if not numbers[num] then
            numbers[num] = true
            table.insert(uniqueNumbers, num)
        end
    end
    return uniqueNumbers
end


function test_bbs_credential_size(total, step, fraction, msgsize)
    local CREDS_T = { }
    local PROOF_T = { }
    local creds = { }
    printerr('Testing '..total..' credentials at step '..step
          ..' fraction '..fraction..' message size '..msgsize)
    for i=step,total+step,step do
        -- print('generate credentials: '..i)
        for c=1,i,1 do
            -- table.insert(creds, OCTET.random(random16()))
            table.insert(creds, OCTET.random(msgsize))
        end
        -- print'sign credentials'
        local signed = sign(B3, kp, creds)
        local subset = math.floor(i/fraction)
        if subset == 0 then subset=1 end
        -- print('generate indexes: '..i/2)
        local q = tostring(i)
        local indexes = create_index(subset,i)
        table.insert(CREDS_T,q)
        -- I.print(indexes)
        -- print('creds: generate proofs'
        local proof = create_proof(B3, kp.pk, signed, creds, indexes)
        -- print({proof=proof})
        table.insert(PROOF_T,#proof)
        -- print'present disclosures'
        -- local disclosed = disclosed_messages(creds, indexes)
        -- -- print'verify disclosed proofs'
        -- assert( verify_proof(B3, kp.pk, proof, disclosed, indexes) )
        printerr(q.." ")
        collectgarbage'collect'
    end
    print""
    return({CREDS = CREDS_T, PROOF = PROOF_T})
end

P = JSON.decode(DATA)


TEST_100_10_2 = test_bbs_credential_size(P.total,P.step,P.fraction,P.size)

print("CREDS \t PROOF")
for k,v in pairs(TEST_100_10_2.CREDS) do
    write(v)
    write(' \t ')
    write(TEST_100_10_2.PROOF[k])
    write('\n')
end
