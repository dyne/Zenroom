-- Lightweight RPBSch CMT3 boundary smoke test.
--
-- This intentionally avoids native NIWI proving. It checks that production
-- RPBSch Lua fixture material carries CMT3 public opening proofs and that the
-- adapter rejects mutated proof bytes before any native relation call.

local rpbsch = require'crypto_rpbsch'
local pbsch = require'crypto_pbsch'
local niwi = require'niwi'

assert(rpbsch, 'crypto_rpbsch module not loaded')
assert(pbsch, 'crypto_pbsch module not loaded')
assert(niwi and niwi.rpbsch_validate_full_statement,
       'native RPBSch full statement validator not available')

local function flip_last_byte(octet)
  local hex = octet:hex()
  local last = tonumber(hex:sub(-2), 16)
  return OCTET.from_hex(hex:sub(1, -3) .. string.format('%02x', last ~ 1))
end

local fixture = rpbsch.fixture()

assert(pbsch.cmt3_verify(fixture.C, fixture.C_proof),
       'RPBSch C proof is not a valid CMT3 proof')
assert(pbsch.cmt3_verify(fixture.S, fixture.S_proof),
       'RPBSch S proof is not a valid CMT3 proof')
assert(not pbsch.cmt2_verify(fixture.C, fixture.C_proof),
       'RPBSch C proof unexpectedly verifies as CMT2')
assert(not pbsch.cmt2_verify(fixture.S, fixture.S_proof),
       'RPBSch S proof unexpectedly verifies as CMT2')
assert(rpbsch.validate_branch_relation(fixture),
       'valid RPBSch CMT3 fixture rejected')

local bad_c = rpbsch.fixture()
bad_c.C_proof = flip_last_byte(bad_c.C_proof)
assert(not rpbsch.validate_branch_relation(bad_c),
       'mutated C CMT3 proof accepted')

local bad_s = rpbsch.fixture()
bad_s.S_proof = flip_last_byte(bad_s.S_proof)
assert(not rpbsch.validate_branch_relation(bad_s),
       'mutated S CMT3 proof accepted')

local full_statement = pbsch.assemble_full_statement(
  fixture.statement, fixture.C_proof, fixture.S_proof)
local parsed = pbsch.parse_full_statement(full_statement)
assert(parsed and parsed.core_statement:string() == fixture.statement:string(),
       'full statement parse failed')
assert(parsed.C:string() == fixture.C:string(), 'full statement C mismatch')
assert(parsed.S:string() == fixture.S:string(), 'full statement S mismatch')
local validated = pbsch.validate_full_statement(full_statement)
assert(validated and validated.core_statement:string() == fixture.statement:string(),
       'valid full statement rejected')
local native_validated = niwi.rpbsch_validate_full_statement(full_statement)
assert(native_validated and
       native_validated.core_statement:string() == fixture.statement:string(),
       'native valid full statement rejected')
assert(native_validated.C:string() == fixture.C:string(),
       'native full statement C mismatch')
assert(native_validated.S:string() == fixture.S:string(),
       'native full statement S mismatch')
assert(not pbsch.validate_full_statement(
         full_statement:sub(1, #full_statement:str() - 1)),
       'truncated full statement accepted')
assert(not niwi.rpbsch_validate_full_statement(
         full_statement:sub(1, #full_statement:str() - 1)),
       'native truncated full statement accepted')

local swapped = pbsch.assemble_full_statement(
  fixture.statement, fixture.S_proof, fixture.C_proof)
assert(not pbsch.validate_full_statement(swapped),
       'swapped C/S CMT3 proofs accepted')
assert(not niwi.rpbsch_validate_full_statement(swapped),
       'native swapped C/S CMT3 proofs accepted')

local changed_core = pbsch.assemble_full_statement(
  flip_last_byte(fixture.statement), fixture.C_proof, fixture.S_proof)
assert(not pbsch.validate_full_statement(changed_core),
       'changed core statement accepted')
assert(not niwi.rpbsch_validate_full_statement(changed_core),
       'native changed core statement accepted')

local mismatched = rpbsch.fixture()
mismatched.C_proof = fixture.S_proof
local mismatched_envelope = pbsch.assemble_full_statement(
  mismatched.statement, mismatched.C_proof, mismatched.S_proof)
assert(not pbsch.validate_full_statement(mismatched_envelope),
       'proof/core mismatch accepted')
assert(not niwi.rpbsch_validate_full_statement(mismatched_envelope),
       'native proof/core mismatch accepted')

print('✓ RPBSch CMT3 smoke test passed')
