--[[
Arithmetic progression sum check using named_logic + apply().

Proves: 2 * sum = n * (first + last) where last = first + step * (n - 1)
without ever touching positional indices. Inputs can be declared in any
order; apply() sorts them deterministically (alphabetically by name).
--]]

local zkcc = require'crypto_zkcc'

print('=== Arithmetic progression: closed-form sum ===')

-- Declare inputs in a deliberately shuffled order
local L = zkcc.named_logic()
local count = L:pub('count')   -- number of terms (public)
local step  = L:priv('step')   -- common difference (private)
local sum   = L:pub('sum')     -- claimed total (public)
local first = L:priv('first')  -- first term (private)

-- Materialize wires (sorted by name, public → private → full)
L:apply()

-- Helpers
local one = L:konst(L:elt(1))   -- constant wire
local two = L:elt(2)            -- field element (scalar)

-- last = first + step * (count - 1)
local last = L:add(first, L:mul(step, L:sub(count, one)))

-- 2 * sum == n * (first + last)
local lhs = L:ax(two, sum)
local rhs = L:mul(count, L:add(first, last))
L:assert_eq(lhs, rhs)

-- Compile circuit
local artifact = L:compile(1)

-- Helper to make 32-byte OCTETs from small integers
local function oct_u64(n)
    return OCTET.from_hex(string.format('%064x', n))
end

-- Concrete witness values
local values = {
    first = 7,
    step = 3,
    count = 40,
}
values.sum = values.count * (2 * values.first + (values.count - 1) * values.step) // 2

-- Named input maps (order irrelevant)
local inputs = {
    sum = oct_u64(values.sum),
    step = oct_u64(values.step),
    first = oct_u64(values.first),
    count = oct_u64(values.count),
}

local seed = OCTET.from_hex(string.rep('05', 32))

local witness = zkcc.build_witness_inputs{
    circuit = artifact,
    inputs = inputs,
}

local proof = zkcc.prove_circuit{
    circuit = artifact,
    inputs = witness,
    seed = seed,
}
assert(proof, 'Proof generation failed')

local public_witness = zkcc.build_witness_inputs{
    circuit = artifact,
    public_inputs = {
        sum = inputs.sum,
        count = inputs.count,
    },
}

local ok = zkcc.verify_circuit{
    circuit = artifact,
    proof = proof,
    public_inputs = public_witness,
    seed = seed,
}
assert(ok, 'Proof verification failed')

print('✓ Verified arithmetic progression sum with named inputs + apply()')
