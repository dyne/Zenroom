-- Lightweight RPBSch CMT3 boundary smoke test.
--
-- This intentionally avoids native NIWI proving. It checks that production
-- RPBSch Lua fixture material carries CMT3 public opening proofs and that the
-- adapter rejects mutated proof bytes before any native relation call.

local rpbsch = require'crypto_rpbsch'
local pbsch = require'crypto_pbsch'

assert(rpbsch, 'crypto_rpbsch module not loaded')
assert(pbsch, 'crypto_pbsch module not loaded')

local function flip_last_byte(octet)
  local s = octet:string()
  local last = s:byte(#s)
  return OCTET.from_string(s:sub(1, #s - 1) .. string.char(last ~ 1))
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

print('✓ RPBSch CMT3 smoke test passed')
