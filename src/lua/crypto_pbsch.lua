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
--
-- Native primitives (exposed via require('niwi')):
--   niwi.pbsch_pedersen_h()              -> H_x     (32-byte OCTET)
--   niwi.pbsch_pedersen_commit(m, rho)   -> C       (33-byte OCTET)
--   niwi.pbsch_pedersen_verify(C, m, rho)-> boolean
--
-- The native layer owns: secp256k1 arithmetic, BIP-340, circuit
-- constraints, NIWI proof objects.

local niwi = require('niwi')
if not niwi then return nil end

local pbsch = {}

-- Protocol metadata
pbsch.PROFILE   = "pbsch-v1-secp256k1"
pbsch.C_SIZE    = 33   -- compressed Pedersen point
pbsch.S_SIZE    = 33
pbsch.RAND_SIZE = 32
pbsch.MSG_SIZE  = 32

-- ===========================================================================
-- Tuple encoding (canonical, deterministic, must match circuit assumptions)
-- ===========================================================================

--- Encode Cmt-C tuple: (m, alpha, beta) -> a single 32-byte scalar.
-- The RPBSch circuit for branch 1 checks C == m·G + rho·H where m is
-- the message. alpha and beta are not bound into C; they are used in
-- the blinding equation R' = R + alpha·G + beta·X.
-- Returns: 32-byte OCTET (the message m, passed through)
function pbsch.encode_c_msg(m, alpha, beta)
    -- For v1: m is already a 32-byte scalar; alpha/beta are witness-only.
    -- Pass m through. Circuit verifies C = m·G + rho·H.
    return m
end

--- Encode Cmt-S tuple: (sig0, sig1, nu_u, nu_u', nu_s) -> 32-byte scalar.
-- The tuple is serialized canonically and hashed to a scalar.
-- This scalar is then committed via Pedersen.
-- Returns: 32-byte OCTET
function pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    -- Canonical serialization: concat all fields in order
    local tuple = sig0 .. sig1 .. nu_u .. nu_u_prime .. nu_s
    -- Hash to scalar via SHA-256
    return HASH.new('sha256'):process(tuple):final()
end

-- ===========================================================================
-- PBSch commitment operations (thin wrappers around native Pedersen)
-- ===========================================================================

--- Commit to C = (m, rho) via Pedersen.
-- @param m   32-byte message scalar (OCTET)
-- @param rho 32-byte randomness (OCTET)
-- @return 33-byte compressed Pedersen point (OCTET)
function pbsch.commit_c(m, rho)
    return niwi.pbsch_pedersen_commit(m, rho)
end

--- Verify a C commitment opening.
-- @param C   33-byte compressed point (OCTET)
-- @param m   32-byte message (OCTET)
-- @param rho 32-byte randomness (OCTET)
-- @return true if valid, false otherwise
function pbsch.verify_c(C, m, rho)
    return niwi.pbsch_pedersen_verify(C, m, rho)
end

--- Commit to S = (sig0, sig1, nu_u, nu_u', nu_s; rho) via Pedersen.
-- The tuple is hashed to a scalar m', then committed as m'·G + rho·H.
-- @param sig0      64-byte BIP-340 signature (OCTET)
-- @param sig1      64-byte BIP-340 signature (OCTET)
-- @param nu_u      32-byte scalar (OCTET)
-- @param nu_u_prime 32-byte scalar (OCTET, must != nu_u)
-- @param nu_s      32-byte message (OCTET)
-- @param rho       32-byte randomness (OCTET)
-- @return 33-byte compressed Pedersen point (OCTET)
function pbsch.commit_s(sig0, sig1, nu_u, nu_u_prime, nu_s, rho)
    local m = pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    return niwi.pbsch_pedersen_commit(m, rho)
end

--- Verify an S commitment opening.
-- @param S         33-byte compressed point (OCTET)
-- @param sig0      64-byte BIP-340 signature (OCTET)
-- @param sig1      64-byte BIP-340 signature (OCTET)
-- @param nu_u      32-byte scalar (OCTET)
-- @param nu_u_prime 32-byte scalar (OCTET, must != nu_u)
-- @param nu_s      32-byte message (OCTET)
-- @param rho       32-byte randomness (OCTET)
-- @return true if valid, false otherwise
function pbsch.verify_s(S, sig0, sig1, nu_u, nu_u_prime, nu_s, rho)
    local m = pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    return niwi.pbsch_pedersen_verify(S, m, rho)
end

-- ===========================================================================
-- PBSch state machine (Figure 4: Blind Schnorr with BIP-340)
-- ===========================================================================

--- Create a new PBSch session.
-- @param profile  table with { x = SECP pubkey OCTET, x_prime = SECP pubkey OCTET }
-- @return session table
function pbsch.setup(profile)
    if not profile or not profile.x or not profile.x_prime then
        error("pbsch.setup: x and x_prime required")
    end
    return {
        X       = profile.x,
        X_prime = profile.x_prime,
        state   = "setup",
        max_retries = 10,  -- for even-y R' retry
    }
end

--- Signer generates ephemeral nonce R = r·G.
-- @param session  PBSch session
-- @param message  32-byte message (OCTET)
-- @return R_x (32-byte OCTET, x-only even-y), signer state updated in-place
function pbsch.sign0(session, message)
    assert(session.state == "setup",
           "pbsch.sign0: session not in setup state")
    -- In a real implementation, r is random. For deterministic testing,
    -- derive from session + message.
    -- TODO: actual keygen + sign here.
    session.message = message
    session.state = "sign0"
    return OCTET.random(32)   -- placeholder R
end

return pbsch
