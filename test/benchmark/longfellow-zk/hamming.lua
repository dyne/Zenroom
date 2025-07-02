warn 'LFZK hamming benchmarks'

SAMPLES = os.getenv('LF_HAMMING_SAMPLES')
if not SAMPLES then SAMPLES = 10 end
warn ('SAMPLES: '..SAMPLES)

ZK = require'crypto_longfellow'

local circ
if DATA then
    -- to speed up tests:
    -- ./zenroom test/lua/longfellow.lua -a longfellow_circuit1.b64
    -- generate circuit with lua and stdout redirected to files
    -- ZK = require'crypto_longfellow'
    -- print(ZK.generate_circuit(1).compressed:base64())
    local sz <const> = #CONTEXT
    printerr('ZK Circuit found in CONTEXT: '..sz..' bytes')
    circ = { compressed = O.from_base64(trim(CONTEXT)),
             zkspec = BIG.new(1) }
else -- live generation is sloow..
    printerr'ZK Circuit generation... please wait...'
    circ = ZK.generate_circuit(1)
    I.schema({system = circ.system:string(),
              circuit = circ})
    -- calculate circuit hash and check that is same as zk_spec hash
    assert( ZK.circuit_id(circ) == circ.hash )
end

-- use Sprind-Funke as reference
attributes = {{ id = 'family_name', value = 'Mustermann' }}

local example <const> = ZK.mdoc_example(4) -- sprind funke

local prev, proof
local rlen = 322000

prev = ZK.mdoc_prover(circ, example.mdoc, example.pkx, example.pky,
    example.transcript, attributes, example.now)

local sampled_hammings = { }

for i=1,SAMPLES do

    proof = ZK.mdoc_prover(circ, example.mdoc, example.pkx,
        example.pky, example.transcript, attributes, example.now)

    table.insert(sampled_hammings, O.hamming(proof.zk:chop(rlen),prev.zk:chop(rlen)))
    prev = proof
end


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


print "longfellow-zk \t PRNG \t RORG"
for i=1,SAMPLES do
    print(sampled_hammings[i]..
          " \t "..prng_hammings[i]..
          " \t "..extrng_hammings[i]
    )
end

