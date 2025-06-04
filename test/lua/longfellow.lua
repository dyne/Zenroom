-- This file is part of zenroom
-- used to test the lib/longfellow-zk primitives in zenroom lua

ZK = require'crypto_longfellow'

local one_claim_prover_t = { }
local one_claim_verify_t = { }

local circ
if DATA then
    -- to speed up tests:
    -- ./zenroom test/lua/longfellow.lua -a longfellow_circuit1.b64
    -- generate circuit with lua and stdout redirected to files
    -- ZK = require'crypto_longfellow'
    -- print(ZK.generate_circuit(1).compressed:base64())
    local sz <const> = #DATA
    printerr('ZK Circuit found in DATA: '..sz..' bytes')
    circ = { compressed = O.from_base64(trim(DATA)),
             zkspec = BIG.new(1) }
else -- live generation is sloow..
    printerr'ZK Circuit generation... please wait...'
    circ = ZK.generate_circuit(1)
    I.schema({system = circ.system:string(),
              circuit = circ})
    -- calculate circuit hash and check that is same as zk_spec hash
    assert( ZK.circuit_id(circ) == circ.hash )
end

-- test attributes
age_over_18 = {{ id = 'age_over_18', value = ZK.yes }}
not_over_18 = {{ id = 'age_over_18', value = ZK.no }}
familyname_mustermann = {{ id = 'family_name', value = 'Mustermann' }}
birthdate_1971_09_01 = {{ id = 'birth_date', value = '1971-09-01' }}
birthdate_1998_09_04 = {{ id = 'birth_date', value = '1998-09-04' }}
height_175 = {{ id = 'height', value = O.from_hex'18af' }}

function run_test(circuit, example, attributes)
    printerr''
    printerr'================'
    printerr(example.doc_type)
    printerr(attributes[1].id..' = '..attributes[1].value)
    local start = os.clock()
    local proof <const> = ZK.mdoc_prover(circuit, example.mdoc,
        example.pkx, example.pky, example.transcript, attributes,
        example.now)
    assert(proof)
    table.insert(one_claim_prover_t, os.clock() - start)
    start = os.clock()
    assert( ZK.mdoc_verifier(circuit, proof, example.pkx, example.pky,
                             example.transcript, attributes,
                             example.now, example.doc_type) )
    table.insert(one_claim_verify_t, os.clock() - start)
end

-- first three simple age_over_18 tests need to be successful
printerr'~~~~~~~~~~~~~~~~~~'
printerr'Canonical examples'
printerr''
for i = 1, 3 do
    local canontest <const> = ZK.mdoc_example(i)
    run_test(circ, canontest, age_over_18)
end

printerr'~~~~~~~~~~~~~~~~~~~~~'
printerr'Sprind-Funke examples'
-- Sprind-Funke mdoc example that includes family_name,
-- birth_date, issue_date, height, and age_over_18.
local sprind_funke <const> = ZK.mdoc_example(4)
run_test(circ, sprind_funke, familyname_mustermann)
run_test(circ, sprind_funke, birthdate_1971_09_01)
run_test(circ, sprind_funke, height_175)

printerr'~~~~~~~~~~~~~~~~~~~~~~'
printerr'Google IDPass example'
-- Test Google IDPass which uses a different docType.
local google_idpass <const> = ZK.mdoc_example(5)
run_test(circ, google_idpass, birthdate_1998_09_04)

printerr'~~~~~~~~~~~~~~~~~~~~~~~~~'
printerr'Website explainer example'
local website_explainer <const> = ZK.mdoc_example(6)
run_test(circ, website_explainer, age_over_18)


-- wrong witness errors at prover
for i = 1, 3 do
    local example <const> = ZK.mdoc_example(i)
    printerr'should fail generate proof'
    assert(not ZK.mdoc_prover(circ,
                           example.mdoc,
                           example.pkx,
                           example.pky,
                           example.transcript,
                           not_over_18,
                           example.now) )
    print''
end

printerr'============='
printerr'ALL TESTS OK!'

print(JSON.encode(one_claim_prover_t))
print(JSON.encode(one_claim_verify_t))

-- circ = LFZK.gen_circuit(2)
-- describe_circuit('v2',circ)

-- circ = LFZK.gen_circuit(3)
-- describe_circuit('v3',circ)

-- circ = LFZK.gen_circuit(4)
-- describe_circuit('v4',circ)
