-- test the lib/longfellow-zk primitives in zenroom lua

function describe_circuit(ver, circuit)
    local size = #circuit
    print("circuit size: "..size)
    print("recalculated circuit id:")
    print(LFZK.circuit_id(circuit, ver):hex())
end
LFZK = require'longfellow'

example = LFZK.mdoc_example(1)

circ = LFZK.gen_circuit(1)
describe_circuit('1',circ)

print'generate proof'
proof = LFZK.mdoc_prove(circ,
                        example.mdoc,
                        example.pkx,
                        example.pky,
                        example.transcript,
                        {{id='age_over_18',value=O.from_hex'f5'}},
                        example.now, 1)

-- circ = LFZK.gen_circuit(2)
-- describe_circuit('v2',circ)

-- circ = LFZK.gen_circuit(3)
-- describe_circuit('v3',circ)

-- circ = LFZK.gen_circuit(4)
-- describe_circuit('v4',circ)
