warn 'BBS+ Shannon entropy benchmarks'

SAMPLES = os.getenv('SAMPLES')
if not SAMPLES then SAMPLES = 10 end
warn ('SAMPLES: '..SAMPLES)
B3 = BBS.ciphersuite'shake256'
local kp = keygen(B3)

local msg = { OCTET.random(512) }
local idx = { 1 }
local signed = sign(B3, kp, msg)
local proof = create_proof(B3, kp.pk, signed, msg, idx)

local bbs_samples = { }
local Tbbs = 0
for i=1,SAMPLES do
    local proof = create_proof(B3, kp.pk, signed, msg, idx)
    local f = proof:entropy()
    table.insert(bbs_samples, f)
    Tbbs = Tbbs + f
end

local prng_samples = { }
local Tprng = 0
for i=1,SAMPLES do
    local f = O.random(272):entropy()
    table.insert(prng_samples, f)
    Tprng = Tprng + f
end

local rorg_samples = { }
local rorg = JSON.decode(KEYS)
random_seed(O.from_hex(rorg.seed))
local Trorg = 0
for i=1,SAMPLES do
    local f = O.random(272):entropy()
    table.insert(rorg_samples, f)
    Trorg = Trorg + f
end

local ossl_samples = { }
local ossl = JSON.decode(DATA)
local Tossl = 0
for i=1,SAMPLES do
    local f = O.from_hex(ossl[i]):entropy()
    table.insert(ossl_samples, f)
    Tossl = Tossl + f
end

print "BBS+ \t PRNG \t RORG \t OSSL"
for i=1,SAMPLES do
    print(bbs_samples[i]..' \t '..prng_samples[i]..' \t '..rorg_samples[i]..' \t '..ossl_samples[i])
end

I.warn({BBS_Average=Tbbs/SAMPLES,
        PRNG_Average=Tprng/SAMPLES,
        RORG_Average=Trorg/SAMPLES,
        OSSL_Average=Tossl/SAMPLES})
