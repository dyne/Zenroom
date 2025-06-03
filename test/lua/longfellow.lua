-- test the lib/longfellow-zk primitives in zenroom lua

ZK = require'crypto_longfellow'

print'ZK Circuit generation... please wait...'
local circ <const> = ZK.generate_circuit(1)
I.schema({system = circ.system:string(),
          circuit = circ})

-- calculate circuit hash and check that is same as zk_spec hash
assert( ZK.circuit_id(circ) == circ.hash )

-- test attributes
age_over_18 = {{ id = 'age_over_18', value = ZK.yes }}
not_over_18 = {{ id = 'age_over_18', value = ZK.no }}
familyname_mustermann = {{ id = 'family_name', value = 'Mustermann' }}
birthdate_1971_09_01 = {{ id = 'birth_date', value = '1971-09-01' }}
birthdate_1998_09_04 = {{ id = 'birth_date', value = '1998-09-04' }}
height_175 = {{ id = 'heighth', value = O.from_hex'18af' }} -- typo?!

-- successful
for i = 1, 3 do
    print''
    print('EXAMPLE: '..i)
    local example <const> = ZK.mdoc_example(i)
    I.schema({doc_type = example.doc_type:string(),
              example = example})
    print'=============='
    print'generate proof'
    proof = ZK.mdoc_prover(circ,
                           example.mdoc,
                           example.pkx,
                           example.pky,
                           example.transcript, -- goes into proof
                           age_over_18,
                           example.now)
    I.schema({proof=proof})
    print'============'
    print'verify proof'
    local res <const> = ZK.mdoc_verifier(circ,
                                         proof,
                                         example.pkx,
                                         example.pky,
                                         age_over_18,
                                         example.now,
                                         example.doc_type)
    print''
end

-- wrong witness
for i = 1, 3 do
    print''
    print('EXAMPLE: '..i)
    local example <const> = ZK.mdoc_example(i)
    I.schema({doc_type = example.doc_type:string(),
              example = example})
    print'=============='
    print'generate proof'
    proof = ZK.mdoc_prover(circ,
                           example.mdoc,
                           example.pkx,
                           example.pky,
                           example.transcript, -- goes into proof
                           not_over_18,
                           example.now)
    I.schema({proof=proof})
    print'============'
    print'verify proof'
    local res <const> = ZK.mdoc_verifier(circ,
                                         proof,
                                         example.pkx,
                                         example.pky,
                                         not_over_18,
                                         example.now,
                                         example.doc_type)
    print''
end


-- circ = LFZK.gen_circuit(2)
-- describe_circuit('v2',circ)

-- circ = LFZK.gen_circuit(3)
-- describe_circuit('v3',circ)

-- circ = LFZK.gen_circuit(4)
-- describe_circuit('v4',circ)
