-- BIP340 NIWI native relation regression.

local zkcc = require'crypto_zkcc'

print('=== BIP340 NIWI native relation ===')

local circuit = zkcc.bip340_circuit()

local valid_vectors = {
  {
    name = 'official vector 0',
    pk = 'F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9',
    msg = '0000000000000000000000000000000000000000000000000000000000000000',
    sig = 'E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215' ..
          '25F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0',
  },
  {
    name = 'official vector 1',
    pk = 'DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659',
    msg = '243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89',
    sig = '6896BD60EEAE296DB48A229FF71DFE071BDE413E6D43F917DC8DCF8C78DE3341' ..
          '8906D11AC976ABCCB20B091292BFF4EA897EFCB639EA871CFA95F6DE339E4B0A',
  },
  {
    name = 'official vector 2',
    pk = 'DD308AFEC5777E13121FA72B9CC1B7CC0139715309B086C960E18FD969774EB8',
    msg = '7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C',
    sig = '5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1B' ..
          'AB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7',
  },
  {
    name = 'official vector 3',
    pk = '25D1DFF95105F5253C4022F628A996AD3A0D95FBF21D468A1B33F8C160D8F517',
    msg = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
    sig = '7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC9' ..
          '7582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3',
  },
  {
    name = 'official vector 4',
    pk = 'D69C3509BB99E412E68B0FE8544E72837DFA30746D8BE2AA65975F29D22DC7B9',
    msg = '4DF3C3F68FCC83B27E9D42C90431A72499F17875C81A599B566C9889B9696703',
    sig = '00000000000000000000003B78CE563F89A0ED9414F5AA28AD0D96D6795F9C6' ..
          '376AFB1548AF603B3EB45C9F8207DEE1060CB71C04E80F593060B07D28308D7F4',
  },
  {
    name = 'official vector 15 empty message',
    pk = '778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117',
    msg = '',
    sig = '71535DB165ECD9FBBC046E5FFAEA61186BB6AD436732FCCC25291A55895464CF60' ..
          '69CE26BF03466228F19A3A62DB8A649F2D560FAC652827D1AF0574E427AB63',
  },
  {
    name = 'official vector 16 one-byte message',
    pk = '778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117',
    msg = '11',
    sig = '08A20A0AFEF64124649232E0693C583AB1B9934AE63B4C3511F3AE1134C6A30' ..
          '3EA3173BFEA6683BD101FA5AA5DBC1996FE7CACFC5A577D33EC14564CEC2BACBF',
  },
  {
    name = 'official vector 17 seventeen-byte message',
    pk = '778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117',
    msg = '0102030405060708090A0B0C0D0E0F1011',
    sig = '5130F39A4059B43BC7CAC09A19ECE52B5D8699D1A71E3C52DA9AFDB6B50AC370' ..
          'C4A482B77BF960F8681540E25B6771ECE1E5A37FD80E5A51897C5566A97EA5A5',
  },
  {
    name = 'official vector 18 one-hundred-byte message',
    pk = '778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117',
    msg = '9999999999999999999999999999999999999999999999999999999999999999' ..
          '9999999999999999999999999999999999999999999999999999999999999999' ..
          '9999999999999999999999999999999999999999999999999999999999999999' ..
          '99999999',
    sig = '403B12B0D8555A344175EA7EC746566303321E5DBFA8BE6F091635163ECA79A85' ..
          '85ED3E3170807E7C03B720FC54C7B23897FCBA0E9D0B4A06894CFD249F22367',
  },
}

local function from_hex_or_empty(hex)
  if hex == '' then return OCTET.empty() end
  return OCTET.from_hex(hex)
end

local function flip_last_nibble(oct)
  local hex = oct:hex()
  local last = tonumber(hex:sub(#hex, #hex), 16)
  return OCTET.from_hex(hex:sub(1, #hex - 1) .. string.format('%x', last ~ 1))
end

local first_built = nil
local built_vectors = {}

for _, vec in ipairs(valid_vectors) do
  local sig = OCTET.from_hex(vec.sig)
  local pk = OCTET.from_hex(vec.pk)
  local msg = from_hex_or_empty(vec.msg)
  local built = zkcc.witness.bip340_compute_inputs(circuit, sig, pk, msg)
  built_vectors[#built_vectors + 1] = { name = vec.name, built = built }
  first_built = first_built or built
end

local niwi = require'crypto_niwi'

for _, vec in ipairs(built_vectors) do
  local built = vec.built

  local proof, gamma = niwi.prove_with_observation_test{
    circuit = circuit,
    inputs = built.inputs,
    public_inputs = built.public_inputs,
  }
  assert(type(proof) == 'zenroom.octet' and #proof > 0,
         vec.name .. ': proof must be non-empty')
  assert(type(gamma) == 'zenroom.octet' and #gamma > 0,
         vec.name .. ': gamma must be non-empty')

  assert(niwi.verify_circuit_niwi{
    circuit = circuit,
    proof = proof,
    public_inputs = built.public_inputs,
  }, vec.name .. ': BIP340 NIWI proof must verify')

  local extracted = niwi.extract_from_gamma_test{
    circuit = circuit,
    proof = proof,
    gamma = gamma,
    public_inputs = built.public_inputs,
  }
  assert(extracted:string() == built.inputs:octet():string(),
         vec.name .. ': native relation extraction returned wrong witness')
end

local built = first_built

local bad_public = flip_last_nibble(built.public_inputs:public_octet())
local bad_public_ok = pcall(function()
  niwi.prove_bip340_relation{
    circuit = O.from_string('niwi/zkcc-bip340/v1'),
    inputs = built.inputs:octet(),
    public_inputs = bad_public,
  }
end)
assert(bad_public_ok == false, 'native BIP340 relation must reject changed public e')

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
