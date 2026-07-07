-- PBSch Lua/native primitive and state-machine smoke tests.

local pbsch = require'crypto_pbsch'
local niwi = require'niwi'

assert(pbsch, 'crypto_pbsch module not loaded')
assert(niwi, 'niwi module not loaded')

local function oct(hex)
  return OCTET.from_hex(hex)
end

local function fill(byte, n)
  return oct(string.rep(byte, n))
end

print('=== PBSch vectors ===')

local h1 = niwi.pbsch_pedersen_h()
local h2 = niwi.pbsch_pedersen_h()
assert(type(h1) == 'zenroom.octet', 'H must be an octet')
assert(#h1 == 32, 'H must be 32 bytes')
assert(h1:string() == h2:string(), 'H derivation must be deterministic')

local m = fill('11', 32)
local rho = fill('22', 32)
local wrong_m = fill('12', 32)
local wrong_rho = fill('23', 32)

local C = pbsch.commit_c(m, rho)
assert(type(C) == 'zenroom.octet', 'C must be an octet')
assert(#C == pbsch.C_SIZE, 'C must be compressed secp256k1 point')
assert(pbsch.verify_c(C, m, rho) == true, 'valid C opening rejected')
assert(pbsch.verify_c(C, wrong_m, rho) == false, 'wrong C message accepted')
assert(pbsch.verify_c(C, m, wrong_rho) == false, 'wrong C randomness accepted')

local sig0 = fill('33', 64)
local sig1 = fill('44', 64)
local nu_u = fill('55', 32)
local nu_u_prime = fill('56', 32)
local nu_s = fill('66', 32)
local rho_s = fill('77', 32)

local S = pbsch.commit_s(sig0, sig1, nu_u, nu_u_prime, nu_s, rho_s)
assert(type(S) == 'zenroom.octet', 'S must be an octet')
assert(#S == pbsch.S_SIZE, 'S must be compressed secp256k1 point')
assert(pbsch.verify_s(S, sig0, sig1, nu_u, nu_u_prime, nu_s, rho_s) == true,
       'valid S opening rejected')
assert(pbsch.verify_s(S, sig0, sig1, nu_u, nu_u_prime, nu_s, wrong_rho) == false,
       'wrong S randomness accepted')

local same_nu_ok = pcall(function()
  pbsch.commit_s(sig0, sig1, nu_u, nu_u, nu_s, rho_s)
end)
assert(same_nu_ok == false, "equal nu_u and nu_u' must be rejected")

local X = fill('88', 32)
local X_prime = fill('99', 32)
local statement = pbsch.assemble_statement(X, X_prime, C, S)
assert(type(statement) == 'zenroom.octet', 'statement must be an octet')
assert(#statement == 130, 'statement must be X || X_prime || C || S')

local session = pbsch.setup{ x = X, x_prime = X_prime }
assert(session.state == 'setup', 'session must start in setup state')
local message = fill('aa', 32)
local R = pbsch.sign0(session, message)
assert(#R == 32 and session.state == 'sign0', 'sign0 must return 32-byte R')
local Rp = pbsch.user1(session, fill('ab', 32), fill('ac', 32))
assert(#Rp == 32 and session.state == 'user1', 'user1 must return 32-byte R prime')
local c = pbsch.sign2(session, Rp)
assert(#c == 32 and session.state == 'sign2', 'sign2 must return 32-byte challenge')
local sigma = pbsch.user3(session)
assert(#sigma == 64 and session.state == 'finished', 'user3 must return BIP340-sized signature')
assert(pbsch.verify(session, sigma, message) == true, 'placeholder verify must return true')

print('✓ PBSch primitive vectors passed')
