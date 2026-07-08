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
local schnorr = require('crypto_schnorr_signature')
if not schnorr then return nil end

local pbsch = {}
local S = SECP
local G = S.G()

-- Protocol metadata
pbsch.PROFILE   = "pbsch-v1-secp256k1"
pbsch.C_SIZE    = 33
pbsch.S_SIZE    = 33
pbsch.RAND_SIZE = 32
pbsch.MSG_SIZE  = 32

local function fail(message)
    error(message, 2)
end

local function octet_eq(a, b)
    return a and b and a:hex() == b:hex()
end

local function even_y(P)
    return P:compressed():hex():sub(1, 2) == "02"
end

local function normalize_bip340_secret(sk)
    if #sk ~= 32 then fail("secret key must be 32 bytes") end
    if not S.bip340_seckey_valid(sk) then fail("invalid BIP-340 secret key") end
    local d = sk
    local P = G * d
    if not even_y(P) then
        d = S.bip340_scalar_negate(d)
        P = G * d
    end
    return d, P:xonly()
end

local function lift_x(xonly, context)
    local ok, P = pcall(function() return S.bip340_lift_x(xonly) end)
    if not ok or not P then fail(context .. ": invalid x-only point") end
    return P
end

local function challenge(rx, px, message)
    local h = S.bip340_tagged_hash("BIP0340/challenge", rx .. px .. message)
    return S.bip340_challenge_reduce(h)
end

local function derive_valid_scalar(seed)
    local counter = 0
    local k = sha256(seed .. tostring(counter))
    while not S.bip340_seckey_valid(k) do
        counter = counter + 1
        k = sha256(seed .. tostring(counter))
    end
    return k
end

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
    if profile.sk and #profile.sk:str() ~= 32 then
        return false, "profile.sk must be a 32-byte BIP-340 secret key"
    end
    return true
end

-- ===========================================================================
-- Statement assembly
-- ===========================================================================

--- Assemble the RPBSch public statement: X || X' || C || S.
-- All inputs are OCTETs. Returns a 130-byte OCTET.
--
-- Prototype note: 2025-1992 defines the statement as also carrying R, c,
-- phi, and ck. The missing fields are tracked in the NIWI plan and must be
-- added when replacing the fast Lua RPBSch fixture with the real OR circuit.
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
-- This is the Lua profile's Pedersen message representative for
-- Cmt.Com(ck, (m, alpha, beta); rho). It binds all tuple fields but is not
-- the final straight-line extractable Cmt encoding from 2025-1992.
function pbsch.encode_c_msg(m, alpha, beta)
    assert(#m:str() == 32, "m must be 32 bytes")
    assert(#alpha:str() == 32, "alpha must be 32 bytes")
    assert(#beta:str() == 32, "beta must be 32 bytes")
    return sha256("PBSch/C/v1" .. m:str() .. alpha:str() .. beta:str())
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
    return sha256(tuple)
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
-- @param profile  { x = OCTET(32), x_prime = OCTET(32), sk = OCTET(32) optional }
-- @return session table
function pbsch.setup(profile)
    local ok, err = pbsch.validate_profile(profile)
    if not ok then error("pbsch.setup: " .. err) end
    local sk
    if profile.sk then
        local normalized_sk, pk = normalize_bip340_secret(profile.sk)
        if not octet_eq(pk, profile.x) then
            fail("pbsch.setup: profile.sk does not match profile.x")
        end
        sk = normalized_sk
    end
    return {
        X       = profile.x,
        X_prime = profile.x_prime,
        sk      = sk,
        deterministic = profile.deterministic == true,
        state   = "setup",
        retries = 0,
        max_retries = 10,
    }
end

--- Sign0: Signer generates ephemeral nonce R = r·G.
-- In deterministic test mode, r is derived from session + message.
-- @return R_x (32-byte OCTET, x-only)
function pbsch.sign0(session, message)
    assert(session.state == "setup",
           "sign0: expected state 'setup', got '" .. session.state .. "'")
    assert(#message:str() == 32, "message must be 32 bytes")

    session.message = message

    if session.deterministic then
        -- Test-only deterministic mode for reproducible vector scripts.
        local seed = "PBSch/sign0" .. session.X:str() .. session.X_prime:str()
                      .. message:str()
        session.r = derive_valid_scalar(seed)
    else
        repeat
            session.r = OCTET.random(32)
        until S.bip340_seckey_valid(session.r)
    end
    session.R_point = G * session.r
    session.R = session.R_point:xonly()

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

    local X = lift_x(session.X, "user1")
    local R_prime = session.R_point + (G * alpha) + (X * beta)
    if R_prime:isinf() then
        fail("user1: R prime is infinity; retry alpha/beta")
    end
    if not even_y(R_prime) then
        fail("user1: R prime must have even y; retry alpha/beta")
    end

    session.X_point = X
    session.R_prime_point = R_prime
    session.R_prime = R_prime:xonly()
    session.R_prime_parity = 0

    session.state = "user1"
    return session.R_prime
end

--- Sign2: Signer receives R', computes challenge c.
-- c = Hq(R'_x, X_x, m) + beta mod n
-- @return c (32-byte scalar OCTET)
function pbsch.sign2(session, R_prime_x)
    assert(session.state == "user1",
           "sign2: expected state 'user1', got '" .. session.state .. "'")
    assert(#R_prime_x:str() == 32, "R_prime_x must be 32 bytes")
    assert(session.sk, "sign2: session.sk is required for Lua PBSch signing")
    assert(octet_eq(R_prime_x, session.R_prime),
           "sign2: R_prime_x must match User1 output")

    local e = challenge(R_prime_x, session.X, session.message)
    session.e = e
    session.c = S.bip340_scalar_add(e, session.beta)
    session.signer_s = S.bip340_scalar_add(
        session.r,
        S.bip340_scalar_mul(session.c, session.sk)
    )

    session.state = "sign2"
    return session.c
end

--- User3: User derives final signature from c and alpha.
-- s' = s + alpha mod n, where signer response s = r + c*x.
-- @return sigma (64-byte BIP-340 signature: R_x || s)
function pbsch.user3(session)
    assert(session.state == "sign2",
           "user3: expected state 'sign2', got '" .. session.state .. "'")

    local left = G * session.signer_s
    local right = session.R_point + (session.X_point * session.c)
    if left:compressed():hex() ~= right:compressed():hex() then
        fail("user3: signer response does not satisfy sG = R + cX")
    end

    local s = S.bip340_scalar_add(session.signer_s, session.alpha)

    -- BIP-340 signature = x(R') || s'. The paper's blind-signature
    -- transcript carries full points; this compact Lua API keeps full points
    -- in-session and exposes only the x-only values needed by BIP-340 tests.
    local sigma = session.R_prime .. s

    session.s = s
    session.signature = sigma
    session.state = "finished"
    return sigma
end

--- Verify a completed PBSch signature using native BIP-340 verification.
-- @return true if valid
function pbsch.verify(session, sigma, message)
    if not session or not session.X or not sigma or not message then return false end
    local ok, verified = pcall(function()
        return schnorr.verify(session.X, message, sigma)
    end)
    return ok and verified == true
end

return pbsch
