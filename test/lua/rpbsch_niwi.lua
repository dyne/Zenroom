-- RPBSch fast fixture using real BIP-340 zkcc witnesses and NIWI extraction.
--
-- Vector source: fixed local seeds in crypto_rpbsch.fixture(), signed with
-- Zenroom's SECP/BIP340 implementation. These are not external paper vectors;
-- they are deterministic integration vectors for the current prototype.

local rpbsch = require'crypto_rpbsch'
local zkcc = require'crypto_zkcc'
local pbsch = require'crypto_pbsch'
local niwi = require'crypto_niwi'

assert(rpbsch, 'crypto_rpbsch module not loaded')
assert(zkcc, 'crypto_zkcc module not loaded')

local function flip_last_nibble(octet)
  local hex = octet:hex()
  local prefix = hex:sub(1, #hex - 1)
  local last = tonumber(hex:sub(#hex, #hex), 16)
  return OCTET.from_hex(prefix .. string.format("%x", (last ~ 1) & 0xf))
end

local function contains_tag(octet, tag)
  return octet:string():find(tag, 1, true) ~= nil
end

local function flip_last_byte(octet)
  local s = octet:string()
  local last = s:byte(#s)
  return OCTET.from_string(s:sub(1, #s - 1) .. string.char(last ~ 1))
end

print('=== RPBSch BIP340 NIWI fixture ===')

local circuit = zkcc.bip340_circuit()
local fixture = rpbsch.fixture()
local prepared_context = rpbsch.prepare_relation_context()
assert(prepared_context == rpbsch.prepare_relation_context(),
       'RPBSch prepared relation context must be cached per Lua VM')
assert(#fixture.statement == 258,
       'statement must be X || X_prime || R || c || C || phi || ck || S')
assert(pbsch.verify_c(fixture.C, pbsch.encode_c_msg(fixture.m, fixture.alpha, fixture.beta),
                      fixture.rho_c), 'C opening rejected')
assert(pbsch.cmt3_verify(fixture.C, fixture.C_proof),
       'C CMT3 public opening proof rejected')
assert(pbsch.verify_s(fixture.S, fixture.sigma0, fixture.sigma1, fixture.nu_u,
                      fixture.nu_u_prime, fixture.nu_s, fixture.rho_s),
       'S opening rejected')
assert(pbsch.cmt3_verify(fixture.S, fixture.S_proof),
       'S CMT3 public opening proof rejected')

local branch1 = rpbsch.prove_branch(circuit, fixture, rpbsch.BRANCH_HONEST)
assert(branch1 and #branch1 == 1, 'branch 1 must produce one NIWI BIP340 proof')
assert(#branch1[1].public_inputs == 96,
       'RPBSch branch 1 must use full challenge-bound BIP340 public inputs')

local branch2 = rpbsch.prove_branch(circuit, fixture, rpbsch.BRANCH_TRAPDOOR)
assert(branch2 and #branch2 == 2, 'branch 2 must produce two NIWI BIP340 proofs')
assert(#branch2[1].public_inputs == 96 and #branch2[2].public_inputs == 96,
       'RPBSch branch 2 must use full challenge-bound BIP340 public inputs')

for _, record in ipairs(branch1) do
  assert(rpbsch.verify_record(circuit, fixture, record), record.label .. ' rejected')
  local extracted = rpbsch.extract_record(record)
  assert(extracted:string() == record.expected_witness:string(),
         record.label .. ' extracted witness mismatch')
end

for _, record in ipairs(branch2) do
  assert(rpbsch.verify_record(circuit, fixture, record), record.label .. ' rejected')
  local extracted = rpbsch.extract_record(record)
  assert(extracted:string() == record.expected_witness:string(),
         record.label .. ' extracted witness mismatch')
end

local native_witness1 = rpbsch.branch_relation_witness(
  circuit, fixture, rpbsch.BRANCH_HONEST)
local prepared_proof1 = rpbsch.prove_branch_relation(
  circuit, fixture, rpbsch.BRANCH_HONEST)
local prepared_proof2 = rpbsch.prove_branch_relation(
  circuit, fixture, rpbsch.BRANCH_HONEST)
assert(rpbsch.verify_branch_relation(prepared_proof1, fixture.statement),
       'first prepared RPBSch branch relation rejected')
assert(rpbsch.verify_branch_relation(prepared_proof2, fixture.statement),
       'second prepared RPBSch branch relation rejected')
local native_proof1, native_gamma1 =
  rpbsch.prove_branch_relation_with_observation_test(
    circuit, fixture, rpbsch.BRANCH_HONEST)
assert(rpbsch.verify_branch_relation(native_proof1, fixture.statement),
       'native RPBSch branch 1 relation rejected')
local native_extracted1 =
  rpbsch.extract_branch_relation(native_proof1, native_gamma1, fixture.statement)
assert(native_extracted1:string() == native_witness1:string(),
       'native RPBSch branch 1 extracted witness mismatch')
assert(contains_tag(native_proof1, 'LIG0'),
       'native RPBSch proof must carry current native LIG0 scaffold')
assert(contains_tag(native_proof1, 'LZK0'),
       'native RPBSch proof must carry checked LZK0 body')
assert(rpbsch.verify_branch_relation(flip_last_byte(native_proof1),
                                     fixture.statement) == false,
       'mutated RPBSch LZK0/native proof accepted')

local native_witness2 = rpbsch.branch_relation_witness(
  circuit, fixture, rpbsch.BRANCH_TRAPDOOR)
local native_proof2, native_gamma2 =
  rpbsch.prove_branch_relation_with_observation_test(
    circuit, fixture, rpbsch.BRANCH_TRAPDOOR)
assert(rpbsch.verify_branch_relation(native_proof2, fixture.statement),
       'native RPBSch branch 2 relation rejected')
local native_extracted2 =
  rpbsch.extract_branch_relation(native_proof2, native_gamma2, fixture.statement)
assert(native_extracted2:string() == native_witness2:string(),
       'native RPBSch branch 2 extracted witness mismatch')
assert(contains_tag(native_proof2, 'LIG0'),
       'native RPBSch proof must carry current native LIG0 scaffold')
assert(contains_tag(native_proof2, 'LZK0'),
       'native RPBSch proof must carry checked LZK0 body')
assert(#native_witness1:str() == #native_witness2:str(),
       'native RPBSch witness size leaks selector')
-- The checked Longfellow body uses randomized proof compression, so exact
-- serialized proof byte length is not a stable selector-leak regression.
assert(contains_tag(native_proof1, 'LZK0') and contains_tag(native_proof2, 'LZK0'),
       'native RPBSch checked proof body missing')

local invalid_selector_witness = OCTET.from_hex(
  native_witness1:hex():sub(1, 8) .. '00000003' ..
  native_witness1:hex():sub(17))
local invalid_selector_ok = pcall(function()
  niwi.prove_rpbsch_relation{
    circuit = niwi.rpbsch_relation_artifact(),
    inputs = invalid_selector_witness,
    public_inputs = fixture.statement,
  }
end)
assert(invalid_selector_ok == false, 'native RPBSch accepted invalid selector')

local bad_selector_ok = pcall(function()
  rpbsch.prove_branch(circuit, fixture, 3)
end)
assert(bad_selector_ok == false, 'bad branch selector accepted')

local changed_statement = rpbsch.fixture()
changed_statement.statement = flip_last_nibble(changed_statement.statement)
assert(rpbsch.verify_record(circuit, changed_statement, branch1[1]) == false,
       'changed RPBSch statement accepted')
assert(rpbsch.verify_branch_relation(native_proof1, changed_statement.statement) == false,
       'native RPBSch accepted changed statement')

local bad_c_opening = rpbsch.fixture()
bad_c_opening.rho_c = flip_last_nibble(bad_c_opening.rho_c)
assert(rpbsch.verify_record(circuit, bad_c_opening, branch1[1]) == false,
       'changed C opening accepted')
local bad_c_native_ok = pcall(function()
  rpbsch.prove_branch_relation(circuit, bad_c_opening, rpbsch.BRANCH_HONEST)
end)
assert(bad_c_native_ok == false, 'native RPBSch accepted changed C opening')

local bad_c_proof = rpbsch.fixture()
bad_c_proof.C_proof = flip_last_byte(bad_c_proof.C_proof)
assert(rpbsch.verify_record(circuit, bad_c_proof, branch1[1]) == false,
       'changed C CMT3 public opening proof accepted')
local bad_c_proof_native_ok = pcall(function()
  rpbsch.prove_branch_relation(circuit, bad_c_proof, rpbsch.BRANCH_HONEST)
end)
assert(bad_c_proof_native_ok == false,
       'native RPBSch wrapper accepted changed C CMT3 public opening proof')

local bad_s_opening = rpbsch.fixture()
bad_s_opening.rho_s = flip_last_nibble(bad_s_opening.rho_s)
assert(rpbsch.verify_record(circuit, bad_s_opening, branch1[1]) == false,
       'changed S opening accepted')
local bad_s_native_ok = pcall(function()
  rpbsch.prove_branch_relation(circuit, bad_s_opening, rpbsch.BRANCH_HONEST)
end)
assert(bad_s_native_ok == false, 'native RPBSch accepted changed S opening')

local bad_s_proof = rpbsch.fixture()
bad_s_proof.S_proof = flip_last_byte(bad_s_proof.S_proof)
assert(rpbsch.verify_record(circuit, bad_s_proof, branch1[1]) == false,
       'changed S CMT3 public opening proof accepted')
local bad_s_proof_native_ok = pcall(function()
  rpbsch.prove_branch_relation(circuit, bad_s_proof, rpbsch.BRANCH_HONEST)
end)
assert(bad_s_proof_native_ok == false,
       'native RPBSch wrapper accepted changed S CMT3 public opening proof')

local bad_ck = rpbsch.fixture()
bad_ck.ck = flip_last_nibble(bad_ck.ck)
bad_ck.statement = pbsch.assemble_statement(bad_ck.X, bad_ck.X_prime,
                                            bad_ck.R, bad_ck.c, bad_ck.C,
                                            bad_ck.phi, bad_ck.ck, bad_ck.S)
assert(rpbsch.verify_record(circuit, bad_ck, branch1[1]) == false,
       'changed commitment key accepted')

local bad_phi = rpbsch.fixture()
bad_phi.phi = flip_last_nibble(bad_phi.phi)
bad_phi.statement = pbsch.assemble_statement(bad_phi.X, bad_phi.X_prime,
                                             bad_phi.R, bad_phi.c, bad_phi.C,
                                             bad_phi.phi, bad_phi.ck, bad_phi.S)
assert(rpbsch.verify_record(circuit, bad_phi, branch1[1]) == false,
       'changed phi accepted')

local swapped_keys = rpbsch.fixture()
swapped_keys.X, swapped_keys.X_prime = swapped_keys.X_prime, swapped_keys.X
swapped_keys.statement = pbsch.assemble_statement(swapped_keys.X,
                                                  swapped_keys.X_prime,
                                                  swapped_keys.R,
                                                  swapped_keys.c,
                                                  swapped_keys.C,
                                                  swapped_keys.phi,
                                                  swapped_keys.ck,
                                                  swapped_keys.S)
assert(rpbsch.verify_record(circuit, swapped_keys, branch1[1]) == false,
       'swapped X/X_prime accepted')

local bad_c_statement = rpbsch.fixture()
bad_c_statement.C = flip_last_nibble(bad_c_statement.C)
bad_c_statement.statement = pbsch.assemble_statement(
  bad_c_statement.X, bad_c_statement.X_prime, bad_c_statement.R,
  bad_c_statement.c, bad_c_statement.C, bad_c_statement.phi,
  bad_c_statement.ck, bad_c_statement.S)
assert(rpbsch.verify_record(circuit, bad_c_statement, branch1[1]) == false,
       'changed C accepted')

local bad_s_statement = rpbsch.fixture()
bad_s_statement.S = flip_last_nibble(bad_s_statement.S)
bad_s_statement.statement = pbsch.assemble_statement(
  bad_s_statement.X, bad_s_statement.X_prime, bad_s_statement.R,
  bad_s_statement.c, bad_s_statement.C, bad_s_statement.phi,
  bad_s_statement.ck, bad_s_statement.S)
assert(rpbsch.verify_record(circuit, bad_s_statement, branch1[1]) == false,
       'changed S accepted')

local missing_relation_field = rpbsch.fixture()
missing_relation_field.phi = nil
assert(rpbsch.verify_record(circuit, missing_relation_field, branch1[1]) == false,
       'missing relation field accepted')

local bad_public_record = {
  branch = branch1[1].branch,
  label = branch1[1].label,
  statement = branch1[1].statement,
  proof = branch1[1].proof,
  public_inputs = branch2[1].public_inputs,
}
assert(rpbsch.verify_record(circuit, fixture, bad_public_record) == false,
       'changed BIP340 public inputs accepted')

local bad_sig_check = rpbsch.branch_checks(fixture, rpbsch.BRANCH_HONEST)[1]
bad_sig_check.sig = flip_last_nibble(bad_sig_check.sig)
assert(rpbsch.valid_signature(bad_sig_check) == false,
       'bad BIP340 signature accepted by RPBSch helper')

print('✓ RPBSch branches proved, verified, and extracted through NIWI')
