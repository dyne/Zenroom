#!/usr/bin/env lua
-- End-to-end circuit -> proof -> verification test
-- NOTE: This requires prover/verifier bindings (zenroom-78q), witness builder (zenroom-swa),
--       and deterministic transcript/RNG seeding (zenroom-8a2).

local zkcc = require('zkcc')

local missing = {}
if not zkcc.prove_circuit then table.insert(missing, 'zkcc.prove_circuit (zenroom-78q)') end
if not zkcc.verify_circuit then table.insert(missing, 'zkcc.verify_circuit (zenroom-78q)') end
if not zkcc.build_witness_inputs then table.insert(missing, 'zkcc.build_witness_inputs (zenroom-swa)') end
if #missing > 0 then
  error('Full flow test prerequisites missing: ' .. table.concat(missing, ', '))
end

print('=== Full Flow Proof Test ===')

-- Build a simple circuit: public z, private x,y, assert z = x + y
local L = zkcc.create_logic()
local tmpl = L:get_circuit()
local z = L:eltw_input() -- public input
tmpl:private_input()      -- boundary between public/private
local x = L:eltw_input()  -- private input 0 (index 2)
local y = L:eltw_input()  -- private input 1 (index 3)
local sum = L:add(x, y)
L:assert_eq(sum, z)

local artifact = zkcc.build_circuit_artifact(tmpl, 1)
-- slot 0 is the reserved constant 1; report user-facing counts excluding it
local user_inputs = artifact.ninput - 1
local user_pub = artifact.npub_input - 1
local circuit_bytes = artifact:octet()
print(string.format('Circuit inputs: %d (public: %d)', user_inputs, user_pub))
print(string.format('Circuit size: depth=%d, wires=%d, quads=%d, bytes=%d',
  artifact.depth, artifact.nwires, artifact.nquad_terms, #circuit_bytes))
print('Circuit hash: '..sha256(circuit_bytes):hex())
-- Fixture values: x=3, y=7, z=10
local function oct_u64(n)
  return OCTET.from_hex(string.format('%064x', n))
end
local inputs = {
  -- input[0] is a reserved constant wire; actual inputs start at 1
  [1] = oct_u64(10), -- public z
  [2] = oct_u64(3),  -- private x
  [3] = oct_u64(7),  -- private y
}

-- Deterministic seed for RNG/transcript
local seed = OCTET.from_hex(string.rep('01', 32))

-- Build witness (fills full Dense vector for prover and public slice for verifier)
local witness = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = inputs,
}

-- Prove
local proof = zkcc.prove_circuit{
  circuit = artifact,
  inputs = witness,
  seed = seed,
}
assert(proof, 'Proof generation failed')
print('Proof size: '..#proof..' bytes')
-- Verify
local ok = zkcc.verify_circuit{
  circuit = artifact,
  proof = proof,
  public_inputs = witness,
  seed = seed,
}
assert(ok, 'Proof verification failed')

print('✓ Proof verified for z = x + y')
