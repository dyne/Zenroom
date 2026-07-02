-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2026 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--

-- PBSch cryptographic protocol layer (Lua).
--
-- This module owns:
--   - Canonical tuple encoding for C and S commitment messages
--   - PBSch commitment assembly (Cmt.Com) on top of native Pedersen
--   - Protocol message/state validation
--   - Figure 4 PBSch state machine orchestration
--   - Statement assembly (X || X' || C || S)
--   - Profile validation and mode rejection
--
-- Native primitives (exposed via require('niwi')):
--   niwi.pbsch_pedersen_h()              -> H_x     (32-byte OCTET)
--   niwi.pbsch_pedersen_commit(m, rho)   -> C       (33-byte OCTET)
--   niwi.pbsch_pedersen_verify(C, m, rho)-> boolean
--
-- The native layer owns: secp256k1 arithmetic, BIP-340 sign/verify,
-- circuit constraints, NIWI proof objects.

local niwi = require('niwi')
if not niwi then return nil end

local pbsch = {}

-- Protocol metadata
pbsch.PROFILE   = "pbsch-v1-secp256k1"
pbsch.C_SIZE    = 33
pbsch.S_SIZE    = 33
pbsch.RAND_SIZE = 32
pbsch.MSG_SIZE  = 32

-- ===========================================================================
-- Profile validation
-- ===========================================================================

function pbsch.validate_profile(profile)
    if not profile or type(profile) ~= "table" then
        return false, "profile must be a table"
    end
    if profile.profile and profile.profile ~= pbsch.PROFILE then
        return false, "unsupported profile: " .. tostring(profile.profile)
    end
    if not profile.x or #profile.x:str() ~= 32 then
        return false, "profile.x must be a 32-byte x-only public key"
    end
    if not profile.x_prime or #profile.x_prime:str() ~= 32 then
        return false, "profile.x_prime must be a 32-byte x-only public key"
    end
    return true
end

-- ===========================================================================
-- Statement assembly
-- ===========================================================================

--- Assemble the RPBSch public statement: X || X' || C || S.
-- All inputs are OCTETs. Returns a 130-byte OCTET.
function pbsch.assemble_statement(X, X_prime, C, S)
    assert(#X:str() == 32, "X must be 32 bytes")
    assert(#X_prime:str() == 32, "X' must be 32 bytes")
    assert(#C:str() == pbsch.C_SIZE, "C must be " .. pbsch.C_SIZE .. " bytes")
    assert(#S:str() == pbsch.S_SIZE, "S must be " .. pbsch.S_SIZE .. " bytes")
    return X .. X_prime .. C .. S
end

-- ===========================================================================
-- Tuple encoding (canonical, must match circuit assumptions)
-- ===========================================================================

--- Encode Cmt-C tuple: (m, alpha, beta) -> 32-byte scalar.
-- For v1: m passes through; alpha and beta are witness-only (used in
-- R' = R + alpha*G + beta*X, not in the commitment).
function pbsch.encode_c_msg(m, alpha, beta)
    return m
end

--- Encode Cmt-S tuple: (sig0, sig1, nu_u, nu_u', nu_s) -> 32-byte scalar.
-- Canonical concatenation of all fields, then SHA-256.
function pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    assert(#sig0:str() == 64, "sig0 must be 64 bytes")
    assert(#sig1:str() == 64, "sig1 must be 64 bytes")
    assert(#nu_u:str() == 32, "nu_u must be 32 bytes")
    assert(#nu_u_prime:str() == 32, "nu_u' must be 32 bytes")
    assert(#nu_s:str() == 32, "nu_s must be 32 bytes")
    local tuple = sig0 .. sig1 .. nu_u .. nu_u_prime .. nu_s
    return HASH.new('sha256'):process(tuple):final()
end

-- ===========================================================================
-- PBSch commitment operations (thin wrappers around native Pedersen)
-- ===========================================================================

function pbsch.commit_c(m, rho)
    return niwi.pbsch_pedersen_commit(m, rho)
end

function pbsch.verify_c(C, m, rho)
    return niwi.pbsch_pedersen_verify(C, m, rho)
end

function pbsch.commit_s(sig0, sig1, nu_u, nu_u_prime, nu_s, rho)
    assert(nu_u:str() ~= nu_u_prime:str(), "nu_u must differ from nu_u'")
    local m = pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    return niwi.pbsch_pedersen_commit(m, rho)
end

function pbsch.verify_s(S, sig0, sig1, nu_u, nu_u_prime, nu_s, rho)
    assert(nu_u:str() ~= nu_u_prime:str(), "nu_u must differ from nu_u'")
    local m = pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    return niwi.pbsch_pedersen_verify(S, m, rho)
end

-- ===========================================================================
-- PBSch state machine (Figure 4: Blind Schnorr with BIP-340)
-- ===========================================================================

--- Create a new PBSch session.
-- @param profile  { x = OCTET(32), x_prime = OCTET(32) }
-- @return session table
function pbsch.setup(profile)
    local ok, err = pbsch.validate_profile(profile)
    if not ok then error("pbsch.setup: " .. err) end
    return {
        X       = profile.x,
        X_prime = profile.x_prime,
        state   = "setup",
        retries = 0,
        max_retries = 10,
    }
end

--- Sign0: Signer generates ephemeral nonce R = r·G.
-- In deterministic test mode, r is derived from session + message.
-- @return R_x (32-byte OCTET, x-only even-y)
function pbsch.sign0(session, message)
    assert(session.state == "setup",
           "sign0: expected state 'setup', got '" .. session.state .. "'")
    assert(#message:str() == 32, "message must be 32 bytes")

    session.message = message

    -- r = SHA-256("PBSch/sign0" || X || X' || message)
    local seed = "PBSch/sign0" .. session.X:str() .. session.X_prime:str()
                  .. message:str()
    session.r = OCTET.from_string(HASH.new('sha256'):process(seed):final():str())

    -- R = r·G (TODO: needs native secp256k1 scalar mult exposed)
    -- For now placeholder; will be replaced when native SECP scalar mult
    -- is available through Lua bindings.
    session.R = OCTET.random(32)

    session.state = "sign0"
    return session.R
end

--- User1: User receives R, samples alpha and beta, computes R'.
-- Retries if R' has odd y.
-- @return R'_x (32-byte OCTET, x-only even-y)
function pbsch.user1(session, alpha, beta)
    assert(session.state == "sign0",
           "user1: expected state 'sign0', got '" .. session.state .. "'")
    assert(#alpha:str() == 32, "alpha must be 32 bytes")
    assert(#beta:str() == 32, "beta must be 32 bytes")

    session.alpha = alpha
    session.beta  = beta

    -- R' = R + alpha·G + beta·X  (TODO: needs native SECP point add/mul)
    -- For now placeholder.
    session.R_prime = OCTET.random(32)
    session.R_prime_parity = 0  -- even

    session.state = "user1"
    return session.R_prime
end

--- Sign2: Signer receives R', computes challenge c.
-- c = Hq(R'_x, X_x, m) + beta mod n  (TODO: needs BIP-340 challenge)
-- @return c (32-byte scalar OCTET)
function pbsch.sign2(session, R_prime_x)
    assert(session.state == "user1",
           "sign2: expected state 'user1', got '" .. session.state .. "'")
    assert(#R_prime_x:str() == 32, "R_prime_x must be 32 bytes")

    session.R_prime = R_prime_x

    -- c = Hq(R'_x, X_x, m) + beta mod n
    -- TODO: needs BIP-340 tagged_hash native binding
    session.c = OCTET.random(32)  -- placeholder

    session.state = "sign2"
    return session.c
end

--- User3: User derives final signature from c and alpha.
-- s = c + alpha mod n
-- @return sigma (64-byte BIP-340 signature: R_x || s)
function pbsch.user3(session)
    assert(session.state == "sign2",
           "user3: expected state 'sign2', got '" .. session.state .. "'")

    -- s = c + alpha mod n  (TODO: needs native scalar add mod n)
    local s = OCTET.random(32)  -- placeholder

    -- signature = R_x || s
    local sigma = session.R:str() .. s:str()

    session.state = "finished"
    return OCTET.from_string(sigma)
end

--- Verify a completed PBSch signature using native BIP-340 verification.
-- @return true if valid
function pbsch.verify(session, sigma, message)
    -- TODO: call native BIP-340 verify
    return true  -- placeholder
end

return pbsch
