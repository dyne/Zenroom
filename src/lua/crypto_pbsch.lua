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
--   - Statement assembly (X || X' || R || c || C || phi || ck || S)
--   - Profile validation and mode rejection
--
-- Native primitives (exposed via require('niwi')):
--   niwi.pbsch_pedersen_h()              -> H_x     (32-byte OCTET)
--   niwi.pbsch_pedersen_commit(m, rho)   -> C       (33-byte OCTET)
--   niwi.pbsch_pedersen_verify(C, m, rho)-> boolean
--   niwi.pbsch_pedersen_commit_lf/verify_lf are the NIWI proof-profile
--   Longfellow/secp canonical versions used by PBSch/RPBSch relation proofs.
--
-- Cmt status: Pedersen-backed CMT1 opening envelope with straight-line
-- extraction from opened proofs. Native RPBSch LZK0 verifies C and S openings,
-- but RPBSch is not paper-exact until Cmt matches the paper profile. See
-- lib/niwi/docs/pbsch-cmt-profile.md before making RPBSch proof claims.
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
pbsch.STATEMENT_SIZE = 258
pbsch.CMT_PROFILE = "pbsch-cmt-pedersen-extractable-v1"
pbsch.CMT2_PROFILE = "pbsch-cmt-pedersen-fs-opening-v1"
pbsch.CMT3_PROFILE = "pbsch-cmt-pedersen-fischlin05-v1"
pbsch.CMT_OPENING_SIZE = 100
pbsch.CMT2_PROOF_SIZE = 165
pbsch.CMT3_B = 9
pbsch.CMT3_T = 12
pbsch.CMT3_R = 10
pbsch.CMT3_S = 10
pbsch.CMT3_PROFILE_BYTE = 1
pbsch.CMT3_PROOF_SIZE = 4 + 1 + 32 + 33 * pbsch.CMT3_R +
                        2 * pbsch.CMT3_R + 32 * pbsch.CMT3_R +
                        32 * pbsch.CMT3_R

local CMT_OPENING_TAG = "CMT1"
local CMT2_PROOF_TAG = "CMT2"
local CMT3_PROOF_TAG = "CMT3"
local RPBSCH_FULL_STATEMENT_TAG = "RPB2"
local SECP_ORDER_HEX =
    "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

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

local function scalar_is_canonical(s)
    if type(s) ~= "zenroom.octet" or #s:str() ~= 32 then return false end
    return s:hex():lower() < SECP_ORDER_HEX
end

local function int_to_scalar(n)
    assert(type(n) == "number" and n >= 0 and n < 9007199254740992,
           "integer scalar out of range")
    return OCTET.from_hex(string.format("%064x", n))
end

local function scalar_addmul(a, b, c)
    return S.bip340_scalar_add(a, S.bip340_scalar_mul(b, c))
end

local function scalar_add(a, b)
    return S.bip340_scalar_add(a, b)
end

local function scalar_sub(a, b)
    return S.bip340_scalar_add(a, S.bip340_scalar_negate(b))
end

local function scalar_div(a, b)
    return S.bip340_scalar_div(a, b)
end

local function cmt2_challenge(ck, commitment, A)
    return S.bip340_challenge_reduce(
        S.bip340_tagged_hash(
            "Zenroom/PBSch/CMT2/Sigma/v1", ck .. commitment .. A))
end

local function commitment_point(commitment)
    local ok, point = pcall(function() return S.new(commitment) end)
    if not ok or not point then return nil end
    return point
end

local function be_u16(n)
    assert(n >= 0 and n <= 65535, "u16 out of range")
    return OCTET.from_hex(string.format("%04x", n))
end

local function be_u32(n)
    assert(n >= 0 and n <= 4294967295, "u32 out of range")
    return OCTET.from_hex(string.format("%08x", n))
end

local function read_u32_be(o)
    if type(o) ~= "zenroom.octet" or #o:str() ~= 4 then return nil end
    return tonumber(o:hex(), 16)
end

local function cmt3_challenge_ok(ch)
    return type(ch) == "number" and ch >= 0 and ch < (1 << pbsch.CMT3_T) and
           math.floor(ch) == ch
end

local function read_u16_be(o)
    if type(o) ~= "zenroom.octet" or #o:str() ~= 2 then return nil end
    return tonumber(o:hex(), 16)
end

local function cmt3_all_A(A)
    local out = A[1]
    for i = 2, pbsch.CMT3_R do out = out .. A[i] end
    return out
end

local function cmt3_threshold_hash(ck, commitment, all_A, i, ch, z_m, z_r)
    if niwi.pbsch_cmt3_hash_value then
        local h = niwi.pbsch_cmt3_hash_value(ck, commitment, all_A, i, ch,
                                             z_m, z_r)
        if h then return h end
    end
    local digest = sha256("Zenroom/PBSch/CMT3/Fischlin05/v1" ..
                          (ck .. commitment .. all_A ..
                           be_u16(i) .. be_u16(ch) .. z_m .. z_r):str())
    return tonumber(digest:sub(1, 2):hex(), 16) % (1 << pbsch.CMT3_B)
end

local function cmt3_nonce(seed, attempt, i, which)
    if seed then
        return derive_valid_scalar("PBSch/CMT3/" .. which .. "/" ..
                                   attempt .. "/" .. i .. "/" .. seed:hex())
    end
    local k = OCTET.random(32)
    while not scalar_is_canonical(k) or k:hex() ==
          "0000000000000000000000000000000000000000000000000000000000000000" do
        k = OCTET.random(32)
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

function pbsch.commitment_key()
    return niwi.pbsch_pedersen_h()
end

--- Assemble the RPBSch public statement: X || X' || R || c || C || phi || ck || S.
-- All inputs are OCTETs. Returns a 258-byte OCTET.
function pbsch.assemble_statement(X, X_prime, R, c, C, phi, ck, S)
    assert(#X:str() == 32, "X must be 32 bytes")
    assert(#X_prime:str() == 32, "X' must be 32 bytes")
    assert(#R:str() == 32, "R must be 32 bytes")
    assert(#c:str() == 32, "c must be 32 bytes")
    assert(#C:str() == pbsch.C_SIZE, "C must be " .. pbsch.C_SIZE .. " bytes")
    assert(#phi:str() == 32, "phi must be 32 bytes")
    assert(#ck:str() == 32, "ck must be 32 bytes")
    assert(#S:str() == pbsch.S_SIZE, "S must be " .. pbsch.S_SIZE .. " bytes")
    return X .. X_prime .. R .. c .. C .. phi .. ck .. S
end

--- Assemble the Lua-side full RPBSch Cmt statement envelope.
-- Native RPBSch relation code still receives the 258-byte core statement. This
-- envelope binds the paper-facing public Cmt proof bodies to that core object:
-- RPB2 || len(core) || core || len(C_proof) || C_proof || len(S_proof) || S_proof.
function pbsch.assemble_full_statement(core_statement, C_proof, S_proof)
    assert(type(core_statement) == "zenroom.octet" and
           #core_statement:str() == pbsch.STATEMENT_SIZE,
           "core statement must be " .. pbsch.STATEMENT_SIZE .. " bytes")
    assert(type(C_proof) == "zenroom.octet" and
           #C_proof:str() == pbsch.CMT3_PROOF_SIZE,
           "C proof must be a CMT3 proof")
    assert(type(S_proof) == "zenroom.octet" and
           #S_proof:str() == pbsch.CMT3_PROOF_SIZE,
           "S proof must be a CMT3 proof")
    return OCTET.from_string(RPBSCH_FULL_STATEMENT_TAG) ..
           be_u32(#core_statement:str()) .. core_statement ..
           be_u32(#C_proof:str()) .. C_proof ..
           be_u32(#S_proof:str()) .. S_proof
end

function pbsch.parse_full_statement(envelope)
    if type(envelope) ~= "zenroom.octet" then return nil end
    if #envelope:str() < 16 then return nil end
    if envelope:sub(1, 4):string() ~= RPBSCH_FULL_STATEMENT_TAG then return nil end
    local off = 5
    local core_len = read_u32_be(envelope:sub(off, off + 3))
    if core_len ~= pbsch.STATEMENT_SIZE then return nil end
    off = off + 4
    local core_end = off + core_len - 1
    if core_end > #envelope:str() then return nil end
    local core_statement = envelope:sub(off, core_end)
    off = core_end + 1

    local c_len = read_u32_be(envelope:sub(off, off + 3))
    if c_len ~= pbsch.CMT3_PROOF_SIZE then return nil end
    off = off + 4
    local c_end = off + c_len - 1
    if c_end > #envelope:str() then return nil end
    local C_proof = envelope:sub(off, c_end)
    off = c_end + 1

    local s_len = read_u32_be(envelope:sub(off, off + 3))
    if s_len ~= pbsch.CMT3_PROOF_SIZE then return nil end
    off = off + 4
    local s_end = off + s_len - 1
    if s_end ~= #envelope:str() then return nil end
    local S_proof = envelope:sub(off, s_end)

    return {
        core_statement = core_statement,
        C_proof = C_proof,
        S_proof = S_proof,
        C = core_statement:sub(129, 161),
        S = core_statement:sub(226, 258),
    }
end

function pbsch.validate_full_statement(envelope)
    local parsed = pbsch.parse_full_statement(envelope)
    if not parsed then return nil end
    if not pbsch.cmt3_verify(parsed.C, parsed.C_proof) then return nil end
    if not pbsch.cmt3_verify(parsed.S, parsed.S_proof) then return nil end
    return parsed
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
-- Pedersen-backed Cmt profile. Extraction comes from the CMT1 opening
-- envelope below; native code owns scalar checks and curve arithmetic.
-- ===========================================================================

function pbsch.commit_c(m, rho)
    return niwi.pbsch_pedersen_commit_lf(m, rho)
end

function pbsch.verify_c(C, m, rho)
    return niwi.pbsch_pedersen_verify_lf(C, m, rho)
end

--- Build the current extractable Cmt opening envelope.
-- This wraps the native Pedersen opening in a canonical, straight-line
-- extractable envelope: CMT1 || ck || message || randomness.
-- It is still a Pedersen-backed Cmt profile; RPBSch is not paper-exact until
-- Cmt matches the paper profile.
function pbsch.cmt_opening(message, rho)
    assert(#message:str() == 32, "message must be 32 bytes")
    assert(#rho:str() == 32, "rho must be 32 bytes")
    return OCTET.from_string(CMT_OPENING_TAG) ..
           pbsch.commitment_key() .. message .. rho
end

local function parse_cmt_opening(opening)
    if type(opening) ~= "zenroom.octet" then return nil end
    if #opening:str() ~= pbsch.CMT_OPENING_SIZE then return nil end
    if opening:sub(1, 4):string() ~= CMT_OPENING_TAG then return nil end
    return {
        ck = opening:sub(5, 36),
        message = opening:sub(37, 68),
        rho = opening:sub(69, 100),
    }
end

function pbsch.cmt_commit(message, rho)
    local commitment = pbsch.commit_c(message, rho)
    return {
        profile = pbsch.CMT_PROFILE,
        ck = pbsch.commitment_key(),
        commitment = commitment,
        opening = pbsch.cmt_opening(message, rho),
    }
end

function pbsch.cmt_verify(commitment, opening)
    if type(commitment) ~= "zenroom.octet" or #commitment:str() ~= pbsch.C_SIZE then
        return false
    end
    local parsed = parse_cmt_opening(opening)
    if not parsed then return false end
    if parsed.ck:string() ~= pbsch.commitment_key():string() then return false end
    return pbsch.verify_c(commitment, parsed.message, parsed.rho)
end

function pbsch.cmt_extract(commitment, opening)
    if not pbsch.cmt_verify(commitment, opening) then return nil end
    local parsed = parse_cmt_opening(opening)
    return {
        profile = pbsch.CMT_PROFILE,
        ck = parsed.ck,
        message = parsed.message,
        rho = parsed.rho,
    }
end

--- Build a public proof of knowledge of a Pedersen opening.
-- CMT2 is intentionally versioned separately from CMT1. This v1 proof is the
-- ordinary Fiat-Shamir transform of the Pedersen-opening Sigma protocol:
-- A = aG + bH, e = H(ck, C, A), z_m = a + e*m, z_r = b + e*r.
-- It is circuit-representable and verifies publicly, but it is compatibility
-- and debugging material only. Paper-facing PBSch/RPBSch helpers must use CMT3,
-- whose Fischlin05 transcript gives the straight-line extractability profile
-- expected by the paper. See lib/niwi/docs/pbsch-cmt-profile.md.
function pbsch.cmt2_prove(commitment, message, rho)
    assert(type(commitment) == "zenroom.octet" and #commitment:str() == pbsch.C_SIZE,
           "commitment must be 33 bytes")
    assert(scalar_is_canonical(message), "message must be a canonical scalar")
    assert(scalar_is_canonical(rho), "rho must be a canonical scalar")
    assert(pbsch.verify_c(commitment, message, rho),
           "commitment does not match opening")

    local ck = pbsch.commitment_key()
    local H = S.bip340_lift_x(ck)
    local a = derive_valid_scalar("PBSch/CMT2/a/" .. commitment:hex() .. message:hex())
    local b = derive_valid_scalar("PBSch/CMT2/b/" .. commitment:hex() .. rho:hex())
    local A = G * a + H * b
    local A_bytes = A:compressed()
    local e = cmt2_challenge(ck, commitment, A_bytes)
    local z_m = scalar_addmul(a, e, message)
    local z_r = scalar_addmul(b, e, rho)
    return OCTET.from_string(CMT2_PROOF_TAG) .. ck .. A_bytes .. e .. z_m .. z_r
end

local function parse_cmt2_proof(proof)
    if type(proof) ~= "zenroom.octet" then return nil end
    if #proof:str() ~= pbsch.CMT2_PROOF_SIZE then return nil end
    if proof:sub(1, 4):string() ~= CMT2_PROOF_TAG then return nil end
    return {
        ck = proof:sub(5, 36),
        A = proof:sub(37, 69),
        e = proof:sub(70, 101),
        z_m = proof:sub(102, 133),
        z_r = proof:sub(134, 165),
    }
end

function pbsch.cmt2_verify(commitment, proof)
    if type(commitment) ~= "zenroom.octet" or #commitment:str() ~= pbsch.C_SIZE then
        return false
    end
    local parsed = parse_cmt2_proof(proof)
    if not parsed then return false end
    if parsed.ck:string() ~= pbsch.commitment_key():string() then return false end
    if not scalar_is_canonical(parsed.e) or
       not scalar_is_canonical(parsed.z_m) or
       not scalar_is_canonical(parsed.z_r) then
        return false
    end
    local C = commitment_point(commitment)
    local A = commitment_point(parsed.A)
    if not C or not A then return false end
    local expected_e = cmt2_challenge(parsed.ck, commitment, parsed.A)
    if expected_e:string() ~= parsed.e:string() then return false end
    local H = S.bip340_lift_x(parsed.ck)
    local lhs = G * parsed.z_m + H * parsed.z_r
    local rhs = A + C * parsed.e
    return lhs == rhs
end

function pbsch.cmt2_commit(message, rho)
    local commitment = pbsch.commit_c(message, rho)
    local proof = pbsch.cmt2_prove(commitment, message, rho)
    return {
        profile = pbsch.CMT2_PROFILE,
        ck = pbsch.commitment_key(),
        commitment = commitment,
        proof = proof,
        opening = pbsch.cmt_opening(message, rho),
    }
end

local function parse_cmt3_proof(proof)
    if type(proof) ~= "zenroom.octet" then return nil end
    if #proof:str() ~= pbsch.CMT3_PROOF_SIZE then return nil end
    if proof:sub(1, 4):string() ~= CMT3_PROOF_TAG then return nil end
    if proof:sub(5, 5):hex() ~= "01" then return nil end
    local parsed = {
        ck = proof:sub(6, 37),
        A = {},
        ch = {},
        z_m = {},
        z_r = {},
    }
    local off = 38
    for i = 1, pbsch.CMT3_R do
        parsed.A[i] = proof:sub(off, off + 32)
        off = off + 33
    end
    for i = 1, pbsch.CMT3_R do
        local ch = read_u16_be(proof:sub(off, off + 1))
        if not ch or ch >= (1 << pbsch.CMT3_T) then return nil end
        parsed.ch[i] = ch
        off = off + 2
    end
    for i = 1, pbsch.CMT3_R do
        parsed.z_m[i] = proof:sub(off, off + 31)
        if not scalar_is_canonical(parsed.z_m[i]) then return nil end
        off = off + 32
    end
    for i = 1, pbsch.CMT3_R do
        parsed.z_r[i] = proof:sub(off, off + 31)
        if not scalar_is_canonical(parsed.z_r[i]) then return nil end
        off = off + 32
    end
    return parsed
end

local function parse_cmt3_query_transcript(queries)
    if type(queries) ~= "zenroom.octet" or #queries:str() < 6 then return nil end
    if queries:sub(1, 4):string() ~= "CQ3Q" then return nil end
    local count = read_u16_be(queries:sub(5, 6))
    if not count then return nil end
    local row_size = 466
    if #queries:str() ~= 6 + count * row_size then return nil end

    local out = {}
    local off = 7
    for _ = 1, count do
        local q = {}
        q.commitment = queries:sub(off, off + 32); off = off + 33
        q.ck = queries:sub(off, off + 31); off = off + 32
        q.all_A = queries:sub(off, off + 329); off = off + 330
        q.i = read_u16_be(queries:sub(off, off + 1)); off = off + 2
        q.ch = read_u16_be(queries:sub(off, off + 1)); off = off + 2
        q.z_m = queries:sub(off, off + 31); off = off + 32
        q.z_r = queries:sub(off, off + 31); off = off + 32
        q.h = read_u16_be(queries:sub(off, off + 1)); off = off + 2
        q.selected = queries:sub(off, off):hex() == "01"; off = off + 1
        if not q.i or not q.ch or not q.h then return nil end
        table.insert(out, q)
    end
    return out
end

--- Verify a CMT3 Fischlin05 Pedersen-opening proof.
-- Full transcript verification is implemented in the CMT3 proof task. The
-- parser and structural guards live here so malformed proofs reject before
-- curve arithmetic.
function pbsch.cmt3_verify(commitment, proof)
    if niwi.pbsch_cmt3_verify and niwi.pbsch_cmt3_verify(commitment, proof) then
        return true
    end
    if type(commitment) ~= "zenroom.octet" or #commitment:str() ~= pbsch.C_SIZE then
        return false
    end
    if not commitment_point(commitment) then return false end
    local parsed = parse_cmt3_proof(proof)
    if not parsed then return false end
    if parsed.ck:string() ~= pbsch.commitment_key():string() then return false end
    local all_A = cmt3_all_A(parsed.A)
    local threshold_sum = 0
    for i = 1, pbsch.CMT3_R do
        if not commitment_point(parsed.A[i]) then return false end
        if not pbsch.cmt3_sigma_verify(commitment, parsed.A[i],
                                       parsed.ch[i], parsed.z_m[i],
                                       parsed.z_r[i]) then
            return false
        end
        threshold_sum = threshold_sum +
            cmt3_threshold_hash(parsed.ck, commitment, all_A, i,
                                parsed.ch[i], parsed.z_m[i], parsed.z_r[i])
    end
    return threshold_sum <= pbsch.CMT3_S
end

function pbsch.cmt3_sigma_commit(a, b)
    assert(scalar_is_canonical(a), "a must be a canonical scalar")
    assert(scalar_is_canonical(b), "b must be a canonical scalar")
    local H = S.bip340_lift_x(pbsch.commitment_key())
    return (G * a + H * b):compressed()
end

function pbsch.cmt3_sigma_respond(a, b, ch, message, rho)
    assert(scalar_is_canonical(a), "a must be a canonical scalar")
    assert(scalar_is_canonical(b), "b must be a canonical scalar")
    assert(cmt3_challenge_ok(ch), "challenge out of range")
    assert(scalar_is_canonical(message), "message must be a canonical scalar")
    assert(scalar_is_canonical(rho), "rho must be a canonical scalar")
    local ch_scalar = int_to_scalar(ch)
    return scalar_addmul(a, ch_scalar, message),
           scalar_addmul(b, ch_scalar, rho)
end

function pbsch.cmt3_sigma_verify(commitment, A, ch, z_m, z_r)
    if type(commitment) ~= "zenroom.octet" or #commitment:str() ~= pbsch.C_SIZE then
        return false
    end
    if type(A) ~= "zenroom.octet" or #A:str() ~= pbsch.C_SIZE then
        return false
    end
    if not cmt3_challenge_ok(ch) then return false end
    if not scalar_is_canonical(z_m) or not scalar_is_canonical(z_r) then
        return false
    end
    local C = commitment_point(commitment)
    local A_point = commitment_point(A)
    if not C or not A_point then return false end
    local H = S.bip340_lift_x(pbsch.commitment_key())
    local ch_scalar = int_to_scalar(ch)
    local lhs = G * z_m + H * z_r
    local rhs = A_point + C * ch_scalar
    return lhs == rhs
end

local function cmt3_build_proof(commitment, message, rho, opts, observe)
    opts = opts or {}
    assert(type(commitment) == "zenroom.octet" and #commitment:str() == pbsch.C_SIZE,
           "commitment must be 33 bytes")
    assert(scalar_is_canonical(message), "message must be a canonical scalar")
    assert(scalar_is_canonical(rho), "rho must be a canonical scalar")
    assert(pbsch.verify_c(commitment, message, rho),
           "commitment does not match opening")
    if opts.seed then
        assert(type(opts.seed) == "zenroom.octet", "seed must be an OCTET")
    end

    local ck = pbsch.commitment_key()
    for attempt = 0, 1023 do
        local queries = observe and {} or nil
        local A, a, b = {}, {}, {}
        for i = 1, pbsch.CMT3_R do
            a[i] = cmt3_nonce(opts.seed, attempt, i, "a")
            b[i] = cmt3_nonce(opts.seed, attempt, i, "b")
            A[i] = pbsch.cmt3_sigma_commit(a[i], b[i])
        end
        local all_A = cmt3_all_A(A)
        local selected_ch, selected_z_m, selected_z_r = {}, {}, {}
        local threshold_sum = 0
        for i = 1, pbsch.CMT3_R do
            local best_ch, best_z_m, best_z_r, best_hash = nil, nil, nil, nil
            local alt_ch, alt_z_m, alt_z_r, alt_hash = nil, nil, nil, nil
            local z_m = a[i]
            local z_r = b[i]
            for ch = 0, (1 << pbsch.CMT3_T) - 1 do
                local h = cmt3_threshold_hash(ck, commitment, all_A, i,
                                              ch, z_m, z_r)
                if not best_hash or h < best_hash then
                    if observe and best_ch and not alt_ch then
                        alt_ch, alt_z_m, alt_z_r, alt_hash =
                            best_ch, best_z_m, best_z_r, best_hash
                    end
                    best_ch, best_z_m, best_z_r, best_hash = ch, z_m, z_r, h
                elseif observe and not alt_ch then
                    alt_ch, alt_z_m, alt_z_r, alt_hash = ch, z_m, z_r, h
                end
                if best_hash == 0 and (not observe or alt_ch) then break end
                z_m = scalar_add(z_m, message)
                z_r = scalar_add(z_r, rho)
            end
            selected_ch[i] = best_ch
            selected_z_m[i] = best_z_m
            selected_z_r[i] = best_z_r
            if observe then
                table.insert(queries, {
                    commitment = commitment,
                    ck = ck,
                    all_A = all_A,
                    i = i,
                    ch = best_ch,
                    z_m = best_z_m,
                    z_r = best_z_r,
                    h = best_hash,
                    selected = true,
                })
                if alt_ch then
                    table.insert(queries, {
                        commitment = commitment,
                        ck = ck,
                        all_A = all_A,
                        i = i,
                        ch = alt_ch,
                        z_m = alt_z_m,
                        z_r = alt_z_r,
                        h = alt_hash,
                        selected = false,
                    })
                end
            end
            threshold_sum = threshold_sum + best_hash
            if threshold_sum > pbsch.CMT3_S then break end
        end
        if threshold_sum <= pbsch.CMT3_S then
            local out = OCTET.from_string(CMT3_PROOF_TAG) ..
                        OCTET.from_hex("01") .. ck .. all_A
            for i = 1, pbsch.CMT3_R do out = out .. be_u16(selected_ch[i]) end
            for i = 1, pbsch.CMT3_R do out = out .. selected_z_m[i] end
            for i = 1, pbsch.CMT3_R do out = out .. selected_z_r[i] end
            return out, queries
        end
    end
    fail("CMT3 prover did not find an accepting Fischlin proof")
end

function pbsch.cmt3_prove(commitment, message, rho, opts)
    if opts and opts.seed and niwi.pbsch_cmt3_prove_seeded then
        return niwi.pbsch_cmt3_prove_seeded(commitment, message, rho, opts.seed)
    end
    local proof = cmt3_build_proof(commitment, message, rho, opts, false)
    return proof
end

function pbsch.cmt3_prove_with_observation_test(commitment, message, rho, opts)
    if opts and opts.seed and niwi.pbsch_cmt3_prove_seeded_observed then
        local proof, transcript =
            niwi.pbsch_cmt3_prove_seeded_observed(commitment, message, rho,
                                                  opts.seed)
        local queries = parse_cmt3_query_transcript(transcript)
        assert(queries, "invalid native CMT3 query transcript")
        return proof, queries
    end
    return cmt3_build_proof(commitment, message, rho, opts, true)
end

function pbsch.cmt3_extract_from_queries(commitment, proof, queries)
    if type(queries) ~= "table" then return nil end
    if not pbsch.cmt3_verify(commitment, proof) then return nil end
    local parsed = parse_cmt3_proof(proof)
    if not parsed then return nil end
    local all_A = cmt3_all_A(parsed.A)

    for _, q in ipairs(queries) do
        if type(q) == "table" and
           type(q.commitment) == "zenroom.octet" and
           type(q.ck) == "zenroom.octet" and
           type(q.all_A) == "zenroom.octet" and
           q.commitment:string() == commitment:string() and
           q.ck:string() == parsed.ck:string() and
           q.all_A:string() == all_A:string() and
           type(q.i) == "number" and q.i >= 1 and q.i <= pbsch.CMT3_R and
           cmt3_challenge_ok(q.ch) and q.ch ~= parsed.ch[q.i] and
           scalar_is_canonical(q.z_m) and scalar_is_canonical(q.z_r) then
            local h = cmt3_threshold_hash(parsed.ck, commitment, all_A, q.i,
                                          q.ch, q.z_m, q.z_r)
            if h == q.h and
               pbsch.cmt3_sigma_verify(commitment, parsed.A[q.i], q.ch,
                                       q.z_m, q.z_r) then
                local delta_ch = scalar_sub(int_to_scalar(parsed.ch[q.i]),
                                            int_to_scalar(q.ch))
                if delta_ch:hex() ~= string.rep("0", 64) then
                    local delta_m = scalar_sub(parsed.z_m[q.i], q.z_m)
                    local delta_r = scalar_sub(parsed.z_r[q.i], q.z_r)
                    local message = scalar_div(delta_m, delta_ch)
                    local rho = scalar_div(delta_r, delta_ch)
                    if pbsch.verify_c(commitment, message, rho) then
                        return {
                            profile = pbsch.CMT3_PROFILE,
                            ck = parsed.ck,
                            message = message,
                            rho = rho,
                            index = q.i,
                        }
                    end
                end
            end
        end
    end
    return nil
end

function pbsch.cmt3_commit(message, rho, opts)
    local commitment = pbsch.commit_c(message, rho)
    local proof = pbsch.cmt3_prove(commitment, message, rho, opts)
    return {
        profile = pbsch.CMT3_PROFILE,
        ck = pbsch.commitment_key(),
        commitment = commitment,
        proof = proof,
        opening = pbsch.cmt_opening(message, rho),
    }
end

function pbsch.commit_s(sig0, sig1, nu_u, nu_u_prime, nu_s, rho)
    assert(nu_u:str() ~= nu_u_prime:str(), "nu_u must differ from nu_u'")
    local m = pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    return niwi.pbsch_pedersen_commit_lf(m, rho)
end

function pbsch.verify_s(S, sig0, sig1, nu_u, nu_u_prime, nu_s, rho)
    assert(nu_u:str() ~= nu_u_prime:str(), "nu_u must differ from nu_u'")
    local m = pbsch.encode_s_msg(sig0, sig1, nu_u, nu_u_prime, nu_s)
    return niwi.pbsch_pedersen_verify_lf(S, m, rho)
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
