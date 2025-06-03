-- test the lib/longfellow-zk primitives in zenroom lua

ZK = require'crypto_longfellow'

example = ZK.mdoc_example(1)
I.schema({example = example})

circ = ZK.generate_circuit(1)
print(ZK.circuit_id(circ))

-- single
attributes = {
    {
        id = 'age_over_18',
        value = ZK.yes
    }
}

print'generate proof'
proof = ZK.mdoc_prover(circ,
                       example.mdoc,
                       example.pkx,
                       example.pky,
                       example.transcript, -- goes into proof
                       attributes,
                       example.now)
I.schema({proof=proof})
print'verify proof'
assert( ZK.mdoc_verifier(circ,
                         proof,
                         example.pkx,
                         example.pky,
                         attributes,
                         example.now,
                         example.doc_type
) )

-- circ = LFZK.gen_circuit(2)
-- describe_circuit('v2',circ)

-- circ = LFZK.gen_circuit(3)
-- describe_circuit('v3',circ)

-- circ = LFZK.gen_circuit(4)
-- describe_circuit('v4',circ)
