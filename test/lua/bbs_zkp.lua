-- BBS ZKP test over large message disclosures
BBS = require 'crypto_bbs'

-- how many to test and how much increment
TOTAL = 20
STEP = 2
TOTAL = TOTAL + STEP -- off by one fix

-- BBS = require 'crypto_bbs'
B3 = BBS.ciphersuite'shake256'

function random_indexes(arr, num)
    local max = #arr
    local got = { }
    if num == max then
        for k,v in ipairs(arr) do
            table.insert(got,k)
        end
        return got
    end
    assert(num < max-1, "cannot generate disclosures, ratio too high: "..num.." of "..max)
    local pick
    for i=1,num do
        pick = random16() % max
        if pick == 0 then pick = 1 end
        while array_contains(got, pick) do
            pick = random16() % max
            if pick == 0 then pick = 1 end
        end
        table.insert(got, pick)
    end
    return got
end

function disclosed_messages(arr, indexes)
    local res = { }
    for k,v in pairs(indexes) do
        table.insert(res,arr[v])
    end
    return res
end


function keygen(ctx)
    local res = { sk = BBS.keygen(ctx) }
    res.pk = BBS.sk2pk(res.sk)
    return res
end

function sign(ctx, keys, obj)
    return BBS.sign(ctx, keys.sk, keys.pk, nil, obj)
end

function verify(ctx, pk, sig, obj)
    return BBS.verify(ctx, pk, sig, nil, obj)
end

function create_proof(ctx, pk, sig, arr, disc)
    return BBS.proof_gen(ctx, pk, sig, nil, HEAD, arr, disc)
end

function verify_proof(ctx, pk, proof, arr, disc)
    return BBS.proof_verify(ctx, pk, proof, nil, HEAD, arr, disc)
end

local messages = { }
for c=1,TOTAL,1 do
    table.insert(messages, O.random(64))
end

printerr "BBS ZKP prove+verify shake256 "
for i=STEP,TOTAL,STEP do
  local keys = keygen(B3)
  local signed = sign(B3, keys, messages)
  local indexes = random_indexes(messages,i)
  local proof = create_proof(B3, keys.pk, signed, messages, indexes)
  local disclosed = disclosed_messages(messages, indexes)
  assert( verify_proof(B3, keys.pk, proof, disclosed, indexes) )
end
