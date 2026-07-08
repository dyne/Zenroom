-- RPBSch fast fixture using real BIP-340 zkcc witnesses and NIWI extraction.
--
-- Vector source: fixed local seeds in crypto_rpbsch.fixture(), signed with
-- Zenroom's SECP/BIP340 implementation. These are not external paper vectors;
-- they are deterministic integration vectors for the current prototype.

local rpbsch = require'crypto_rpbsch'
local zkcc = require'crypto_zkcc'
local pbsch = require'crypto_pbsch'

assert(rpbsch, 'crypto_rpbsch module not loaded')
assert(zkcc, 'crypto_zkcc module not loaded')

local function flip_last_nibble(octet)
  local hex = octet:hex()
  local prefix = hex:sub(1, #hex - 1)
  local last = tonumber(hex:sub(#hex, #hex), 16)
  return OCTET.from_hex(prefix .. string.format("%x", (last ~ 1) & 0xf))
end

print('=== RPBSch BIP340 NIWI fixture ===')

local circuit = zkcc.bip340_circuit()
local fixture = rpbsch.fixture()
assert(#fixture.statement == 130, 'prototype statement must be X || X_prime || C || S')
assert(pbsch.verify_c(fixture.C, pbsch.encode_c_msg(fixture.m, fixture.alpha, fixture.beta),
                      fixture.rho_c), 'C opening rejected')
assert(pbsch.verify_s(fixture.S, fixture.sigma0, fixture.sigma1, fixture.nu_u,
                      fixture.nu_u_prime, fixture.nu_s, fixture.rho_s),
       'S opening rejected')

local branch1 = rpbsch.prove_branch(circuit, fixture, rpbsch.BRANCH_HONEST)
assert(branch1 and #branch1 == 1, 'branch 1 must produce one NIWI BIP340 proof')

local branch2 = rpbsch.prove_branch(circuit, fixture, rpbsch.BRANCH_TRAPDOOR)
assert(branch2 and #branch2 == 2, 'branch 2 must produce two NIWI BIP340 proofs')

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

local bad_selector_ok = pcall(function()
  rpbsch.prove_branch(circuit, fixture, 3)
end)
assert(bad_selector_ok == false, 'bad branch selector accepted')

local changed_statement = rpbsch.fixture()
changed_statement.statement = flip_last_nibble(changed_statement.statement)
assert(rpbsch.verify_record(circuit, changed_statement, branch1[1]) == false,
       'changed RPBSch statement accepted')

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
