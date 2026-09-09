-- PBSch fast end-to-end smoke.
--
-- This test uses deterministic local vectors from crypto_rpbsch.fixture().
-- It is intentionally not a paper-complete Figure 4 blind-signing session:
-- crypto_pbsch still has placeholder nonce/challenge algebra. The test covers
-- the currently implemented end-to-end pieces with real primitives.

local pbsch = require'crypto_pbsch'
local rpbsch = require'crypto_rpbsch'

assert(pbsch, 'crypto_pbsch module not loaded')
assert(rpbsch, 'crypto_rpbsch module not loaded')

local function flip_last_nibble(octet)
  local hex = octet:hex()
  local prefix = hex:sub(1, #hex - 1)
  local last = tonumber(hex:sub(#hex, #hex), 16)
  return OCTET.from_hex(prefix .. string.format("%x", (last ~ 1) & 0xf))
end

print('=== PBSch end-to-end smoke ===')

local session = rpbsch.end_to_end_fixture()
assert(session, 'end-to-end fixture failed')

local fixture = session.fixture
assert(rpbsch.valid_final_signature(fixture), 'final BIP340 signature rejected')
assert(pbsch.verify_c(fixture.C, pbsch.encode_c_msg(fixture.m, fixture.alpha, fixture.beta),
                      fixture.rho_c), 'C opening rejected')
assert(pbsch.verify_s(fixture.S, fixture.sigma0, fixture.sigma1, fixture.nu_u,
                      fixture.nu_u_prime, fixture.nu_s, fixture.rho_s),
       'S opening rejected')

local record = session.proof_records[1]
assert(rpbsch.verify_record(session.circuit, fixture, record),
       'honest RPBSch proof rejected')
local extracted = rpbsch.extract_record(record)
assert(extracted:string() == record.expected_witness:string(),
       'honest RPBSch witness extraction mismatch')

local bad_fixture = rpbsch.fixture()
bad_fixture.sigma = flip_last_nibble(bad_fixture.sigma)
assert(rpbsch.valid_final_signature(bad_fixture) == false,
       'bad final BIP340 signature accepted')

local api_session = pbsch.setup{ x = fixture.X, x_prime = fixture.X_prime }
local wrong_user1_ok = pcall(function()
  pbsch.user1(api_session, fixture.alpha, fixture.beta)
end)
assert(wrong_user1_ok == false, 'out-of-order user1 accepted')

local wrong_sign2_ok = pcall(function()
  pbsch.sign2(api_session, fixture.X)
end)
assert(wrong_sign2_ok == false, 'out-of-order sign2 accepted')

print('✓ PBSch end-to-end smoke passed')
