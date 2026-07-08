-- BIP340 NIWI native relation regression.

local zkcc = require'crypto_zkcc'

print('=== BIP340 NIWI native relation ===')

local circuit = zkcc.bip340_circuit()
local sig = OCTET.from_hex(
  'E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215' ..
  '25F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0')
local pk = OCTET.from_hex(
  'F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9')
local msg = OCTET.from_hex(
  '0000000000000000000000000000000000000000000000000000000000000000')

local built = zkcc.witness.bip340_compute_inputs(circuit, sig, pk, msg)
local niwi = require'crypto_niwi'
local proof, gamma = niwi.prove_with_observation_test{
  circuit = circuit,
  inputs = built.inputs,
  public_inputs = built.public_inputs,
}
assert(type(proof) == 'zenroom.octet' and #proof > 0, 'proof must be non-empty')
assert(type(gamma) == 'zenroom.octet' and #gamma > 0, 'gamma must be non-empty')

assert(niwi.verify_circuit_niwi{
  circuit = circuit,
  proof = proof,
  public_inputs = built.public_inputs,
}, 'BIP340 NIWI proof must verify')

local extracted = niwi.extract_from_gamma_test{
  circuit = circuit,
  proof = proof,
  gamma = gamma,
  public_inputs = built.public_inputs,
}
assert(extracted:string() == built.inputs:octet():string(),
       'native relation extraction returned wrong witness')

local witness_octet = built.inputs:octet()
local witness_hex = witness_octet:hex()
local last = tonumber(witness_hex:sub(#witness_hex, #witness_hex), 16)
local tampered = OCTET.from_hex(
  witness_hex:sub(1, #witness_hex - 1) .. string.format('%x', last ~ 1))
local bad_ok = pcall(function()
  niwi.prove_bip340_relation{
    circuit = O.from_string('niwi/zkcc-bip340/v1'),
    inputs = tampered,
    public_inputs = built.public_inputs:public_octet(),
  }
end)
assert(bad_ok == false, 'native BIP340 relation must reject tampered witness')

print('✓ BIP340 NIWI native relation proved, extracted, and rejected tampering')
