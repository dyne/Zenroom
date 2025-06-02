-- test the lib/longfellow-zk primitives in zenroom lua

function describe_circuit(ver, circuit)
    local size = #circuit
    print("circuit size: "..size)
    -- print(circuit:base64())
    -- local rand = O.random(size)
    -- local c_ham = circuit:hamming(rand)
    -- local r_ham = rand:hamming(O.random(size))
    -- print("circuit hamming distance from random:"..c_ham)
    -- print("total hamming distance in random:"..r_ham)
    -- print("difference: "..r_ham-c_ham)
    print("compressed circuit hash:")
    print(sha256(circuit):hex())
end
LFZK = require'longfellow'

example = LFZK.mdoc_example(1)
I.print(deepmap(O.to_string,example))

circ = LFZK.gen_circuit(1)
describe_circuit('v1',circ)

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
