warn 'BBS+ hamming benchmarks'

SAMPLES = os.getenv('BBS_HAMMING_SAMPLES')
if not SAMPLES then SAMPLES = 10 end
warn ('SAMPLES: '..SAMPLES)
B3 = BBS.ciphersuite'shake256'

local kp = keygen(B3)

local msg = { OCTET.random(512) }
local idx = { 1 }

local signed = sign(B3, kp, msg)

local prev = create_proof(B3, kp.pk, signed, msg, idx)
local bbs_hammings = { }
for i=1,SAMPLES do
    local proof = create_proof(B3, kp.pk, signed, msg, idx)
    table.insert(bbs_hammings, O.hamming(proof, prev))
end

-- save length of BBS proofs
local rlen = #prev
warn('BBS proof length: '..rlen)


-- use zenroom runtime seed
local prng_hammings = { }
for i=1,SAMPLES do
    table.insert(prng_hammings, O.hamming(O.random(rlen), O.random(rlen)))
end

-- static seed retrieved from third-party to measure the PRNG
-- hamming. To get a new one copy here by hand the output of:
-- `make random_org_seed`
warn 'static benchmark seed from random.org'
random_org = JSON.decode(KEYS)
random_seed(OCTET.from_hex(random_org.seed))

local extrng_hammings = { }
for i=1,SAMPLES do
    table.insert(extrng_hammings, O.hamming(O.random(rlen), O.random(rlen)))
end

warn 'random sequence from OpenSSL'
openssl = JSON.decode(DATA)
warn( 'SSL rand table length: '..table_size(openssl))
local openssl_hammings = { }
for i=1,SAMPLES*2,2 do
    -- I.warn({ i=i, l=openssl[i], r=openssl[i+1] })
    table.insert(openssl_hammings, O.hamming(
                     O.from_hex(openssl[i]), O.from_hex(openssl[i+1])))
end

print "BBS+ \t PRNG \t RORG \t OSSL"
for i=1,SAMPLES do
    print(bbs_hammings[i]..
          " \t "..prng_hammings[i]..
          " \t "..extrng_hammings[i]..
          " \t "..openssl_hammings[i]
    )
end


warn("Shannon "..prev:entropy())
