-- End-to-end zkcc artifact -> NIWI proof envelope smoke test.

local zkcc = require'crypto_zkcc'
local niwi = require'niwi'

print('=== zkcc NIWI smoke test ===')

local L = zkcc.logic("p256")
local z = L:eltw_input()
L:private_inputs()
local x = L:eltw_input()
local y = L:eltw_input()
L:assert_eq(L:add(x, y), z)

local artifact = L:compile(1)
local circuit = artifact:octet()

local function oct_u64(n)
  return OCTET.from_hex(string.format('%064x', n))
end

local witness = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = {
    [1] = oct_u64(10),
    [2] = oct_u64(3),
    [3] = oct_u64(7),
  },
}

local public_witness = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = {
    [1] = oct_u64(10),
  },
}

local proof = niwi.prove_circuit_niwi{
  circuit = circuit,
  inputs = witness:octet(),
  public_inputs = public_witness:public_octet(),
}
assert(type(proof) == "zenroom.octet", 'NIWI proof must be an octet')
assert(#proof > 0, 'NIWI proof must be non-empty')

local ok = niwi.verify_circuit_niwi{
  circuit = circuit,
  proof = proof,
  public_inputs = public_witness:public_octet(),
}
assert(ok == true, 'NIWI proof verification failed')

local wrong_public = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = {
    [1] = oct_u64(11),
  },
}
local wrong_ok = niwi.verify_circuit_niwi{
  circuit = circuit,
  proof = proof,
  public_inputs = wrong_public:public_octet(),
}
assert(wrong_ok == false, 'NIWI verification must reject wrong public input')

local observed_proof, gamma = niwi.prove_with_observation_test{
  circuit = circuit,
  inputs = witness:octet(),
  public_inputs = public_witness:public_octet(),
}
assert(niwi.verify_circuit_niwi{
  circuit = circuit,
  proof = observed_proof,
  public_inputs = public_witness:public_octet(),
}, 'observed NIWI proof verification failed')

local extracted = niwi.extract_from_gamma_test{
  proof = observed_proof,
  gamma = gamma,
  public_inputs = public_witness:public_octet(),
}
assert(extracted:string() == witness:octet():string(), 'extracted zkcc witness mismatch')

print('✓ NIWI proved, verified, and extracted a zkcc circuit witness')
