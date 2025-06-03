-- test the lib/longfellow-zk primitives in zenroom lua

ZK = require'crypto_longfellow'

example = I.spy(ZK.mdoc_example(1))

circ = ZK.generate_circuit(1)
print(ZK.circuit_id(circ))

print'generate proof'
proof = ZK.mdoc_prover(circ,
                      example.mdoc,
                      example.pkx,
                      example.pky,
                      example.transcript,
                      {{id='age_over_18',value=O.from_hex'f5'}},
                      example.now)

-- circ = LFZK.gen_circuit(2)
-- describe_circuit('v2',circ)

-- circ = LFZK.gen_circuit(3)
-- describe_circuit('v3',circ)

-- circ = LFZK.gen_circuit(4)
-- describe_circuit('v4',circ)
