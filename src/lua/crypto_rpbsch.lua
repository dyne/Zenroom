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
-- RPBSch branch-relation glue.
--
-- This module keeps orchestration and witness serialization readable in Lua,
-- while native lib/niwi validates branch statements, C/S openings, and the
-- embedded BIP-340 witnesses. Production native proofs now carry checked LZK0
-- bodies with a fixed-shape private OR selector. The remaining paper-exact
-- gap is the Cmt profile, which is still Pedersen-backed CMT1.

local pbsch = require'crypto_pbsch'
local zkcc = require'crypto_zkcc'
local niwi = require'crypto_niwi'
local schnorr = require'crypto_schnorr_signature'

if not pbsch or not zkcc or not niwi or not schnorr then return nil end

local rpbsch = {}
local Secp = SECP

rpbsch.BRANCH_HONEST = 1
rpbsch.BRANCH_TRAPDOOR = 2

local function oct(hex)
    return OCTET.from_hex(hex)
end

local function hash32(tag, bytes)
    return sha256(tag .. bytes)
end

local function u32_be(n)
    assert(n >= 0 and n <= 4294967295, "u32 out of range")
    return OCTET.from_hex(string.format("%08x", n))
end

local function assert_octet_len(name, value, len)
    assert(type(value) == "zenroom.octet", name .. " must be an OCTET")
    assert(#value:str() == len, name .. " must be " .. len .. " bytes")
end

--- Hash the paper's Schnorr message tuple (nu_s, nu_u) to BIP-340 bytes.
-- The paper signs tuple messages. Zenroom BIP-340 signs byte strings, so this
-- fixture uses a domain-separated 32-byte representative.
function rpbsch.tuple_message(nu_s, nu_u)
    assert_octet_len("nu_s", nu_s, 32)
    assert_octet_len("nu_u", nu_u, 32)
    return hash32("Zenroom/RPBSch/tuple-message/v1", (nu_s .. nu_u):str())
end

local function valid_branch(branch)
    return branch == rpbsch.BRANCH_HONEST or branch == rpbsch.BRANCH_TRAPDOOR
end

local function require_branch(branch)
    if not valid_branch(branch) then
        error("rpbsch: branch selector must be 1 (honest) or 2 (trapdoor)", 3)
    end
end

local function build_bip340_inputs(circuit, sig, pk, msg)
    if not schnorr.verify(pk, msg, sig) then
        return nil, "invalid BIP-340 signature"
    end
    if zkcc.witness.bip340_compute_full_challenge_inputs and #msg == 32 then
        return zkcc.witness.bip340_compute_full_challenge_inputs(sig, pk, msg)
    end
    return zkcc.witness.bip340_compute_inputs(circuit, sig, pk, msg)
end

local function statement_phi(f)
    return hash32("Zenroom/RPBSch/phi/v1",
                  (f.m .. f.alpha .. f.beta .. f.nu_s ..
                   f.nu_u .. f.nu_u_prime):str())
end

local function statement_octets(f)
    return pbsch.assemble_statement(f.X, f.X_prime, f.R, f.c, f.C,
                                    f.phi, f.ck, f.S)
end

local function has_branch_relation_fields(f)
    return f and type(f.X) == "zenroom.octet" and
           type(f.X_prime) == "zenroom.octet" and
           type(f.R) == "zenroom.octet" and
           type(f.c) == "zenroom.octet" and
           type(f.C) == "zenroom.octet" and
           type(f.phi) == "zenroom.octet" and
           type(f.ck) == "zenroom.octet" and
           type(f.S) == "zenroom.octet" and
           type(f.statement) == "zenroom.octet" and
           type(f.m) == "zenroom.octet" and
           type(f.alpha) == "zenroom.octet" and
           type(f.beta) == "zenroom.octet" and
           type(f.rho_c) == "zenroom.octet" and
           type(f.rho_s) == "zenroom.octet" and
           type(f.nu_s) == "zenroom.octet" and
           type(f.nu_u) == "zenroom.octet" and
           type(f.nu_u_prime) == "zenroom.octet" and
           type(f.sigma0) == "zenroom.octet" and
           type(f.sigma1) == "zenroom.octet"
end

--- Validate the current branch relation profile around PBSch commitments.
-- This is intentionally branch-circuit level: it verifies the public
-- statement shape and the C/S commitment openings before accepting the
-- branch's BIP-340 NIWI proof.  Selector composition remains a later step.
function rpbsch.validate_branch_relation(fixture)
    if not has_branch_relation_fields(fixture) then return false end
    if not fixture.ck or fixture.ck:string() ~= pbsch.commitment_key():string() then
        return false
    end
    if fixture.phi:string() ~= statement_phi(fixture):string() then
        return false
    end
    if fixture.statement:string() ~= statement_octets(fixture):string() then
        return false
    end
    if not pbsch.verify_c(fixture.C,
                          pbsch.encode_c_msg(fixture.m, fixture.alpha, fixture.beta),
                          fixture.rho_c) then
        return false
    end
    if not pbsch.verify_s(fixture.S, fixture.sigma0, fixture.sigma1,
                          fixture.nu_u, fixture.nu_u_prime, fixture.nu_s,
                          fixture.rho_s) then
        return false
    end
    return true
end

--- Build a deterministic two-branch fixture.
-- Test-vector source: locally generated with Zenroom's SECP/BIP340 primitives
-- from fixed secret keys, fixed messages, and fixed aux randomness.
function rpbsch.fixture()
    local sk = oct("0000000000000000000000000000000000000000000000000000000000000003")
    local sk_prime = oct("B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA56A784D9045190CFEF")
    local aux0 = oct("0000000000000000000000000000000000000000000000000000000000000000")
    local aux1 = oct("0000000000000000000000000000000000000000000000000000000000000001")
    local aux2 = oct("0000000000000000000000000000000000000000000000000000000000000002")

    local X = schnorr.pubgen(sk)
    local X_prime = schnorr.pubgen(sk_prime)
    local m = hash32("Zenroom/RPBSch/message/v1", "message")
    local alpha = hash32("Zenroom/RPBSch/alpha/v1", "alpha")
    local beta = hash32("Zenroom/RPBSch/beta/v1", "beta")
    local rho_c = hash32("Zenroom/RPBSch/rho-c/v1", "rho-c")
    local rho_s = hash32("Zenroom/RPBSch/rho-s/v1", "rho-s")
    local nu_s = hash32("Zenroom/RPBSch/nu-s/v1", "nu-s")
    local nu_u = hash32("Zenroom/RPBSch/nu-u/v1", "nu-u")
    local nu_u_prime = hash32("Zenroom/RPBSch/nu-u-prime/v1", "nu-u-prime")

    local msg0 = rpbsch.tuple_message(nu_s, nu_u)
    local msg1 = rpbsch.tuple_message(nu_s, nu_u_prime)
    local sigma = schnorr.sign(sk, m, aux0)
    local sigma0 = schnorr.sign(sk_prime, msg0, aux1)
    local sigma1 = schnorr.sign(sk_prime, msg1, aux2)

    local C = pbsch.commit_c(pbsch.encode_c_msg(m, alpha, beta), rho_c)
    local S_commit = pbsch.commit_s(sigma0, sigma1, nu_u, nu_u_prime, nu_s, rho_s)
    local R = OCTET.from_hex(sigma:hex():sub(1, 64))
    local c = Secp.bip340_challenge_reduce(
        Secp.bip340_tagged_hash("BIP0340/challenge", R .. X .. m))
    local ck = pbsch.commitment_key()
    local phi = statement_phi{
        m = m, alpha = alpha, beta = beta,
        nu_s = nu_s, nu_u = nu_u, nu_u_prime = nu_u_prime,
    }
    local statement = pbsch.assemble_statement(X, X_prime, R, c, C, phi, ck, S_commit)

    return {
        X = X, X_prime = X_prime,
        m = m, alpha = alpha, beta = beta,
        rho_c = rho_c, rho_s = rho_s,
        R = R, c = c, C = C, phi = phi, ck = ck, S = S_commit,
        statement = statement,
        nu_s = nu_s, nu_u = nu_u, nu_u_prime = nu_u_prime,
        sigma = sigma, sigma0 = sigma0, sigma1 = sigma1,
        msg0 = msg0, msg1 = msg1,
    }
end

--- Return the BIP-340 checks that stand in for one RPBSch branch.
-- Branch 1 has one signature under X on m. Branch 2 has two signatures under
-- X' on messages sharing nu_s and using different suffixes.
function rpbsch.branch_checks(fixture, branch)
    require_branch(branch)
    if branch == rpbsch.BRANCH_HONEST then
        return {
            {
                label = "honest-final-signature",
                pk = fixture.X,
                msg = fixture.m,
                sig = fixture.sigma,
            },
        }
    end
    return {
        {
            label = "trapdoor-signature-0",
            pk = fixture.X_prime,
            msg = fixture.msg0,
            sig = fixture.sigma0,
        },
        {
            label = "trapdoor-signature-1",
            pk = fixture.X_prime,
            msg = fixture.msg1,
            sig = fixture.sigma1,
        },
    }
end

--- Build serialized zkcc witness/public input bytes for a branch.
function rpbsch.branch_witnesses(circuit, fixture, branch)
    require_branch(branch)
    local ok_raw, raw = pcall(function() return circuit:raw() end)
    local witness_circuit = ok_raw and raw or circuit
    local out = {}
    for _, check in ipairs(rpbsch.branch_checks(fixture, branch)) do
        local built, err = build_bip340_inputs(witness_circuit, check.sig, check.pk, check.msg)
        if not built then
            return nil, err
        end
        out[#out + 1] = {
            label = check.label,
            witness_inputs = built.inputs,
            witness = built.inputs:octet(),
            public_inputs = built.public_inputs,
            public_inputs_octet = built.public_inputs:public_octet(),
        }
    end
    return out
end

--- Serialize the native RPBSch branch witness.
-- Layout:
--   "RPB1" || branch:u32 ||
--   m || alpha || beta || rho_c || rho_s || nu_s || nu_u || nu_u' ||
--   sigma || sigma0 || sigma1 ||
--   check_count:u32 || repeated(pub_len:u32 || pub || witness_len:u32 || witness)
function rpbsch.branch_relation_witness(circuit, fixture, branch)
    require_branch(branch)
    local witnesses, err = rpbsch.branch_witnesses(circuit, fixture, branch)
    if not witnesses then return nil, err end
    if branch == rpbsch.BRANCH_HONEST then
        local padding, padding_err =
            rpbsch.branch_witnesses(circuit, fixture, rpbsch.BRANCH_TRAPDOOR)
        if not padding then return nil, padding_err end
        witnesses[#witnesses + 1] = padding[1]
    end
    local out = OCTET.from_string("RPB1") ..
                u32_be(branch) ..
                fixture.m .. fixture.alpha .. fixture.beta ..
                fixture.rho_c .. fixture.rho_s ..
                fixture.nu_s .. fixture.nu_u .. fixture.nu_u_prime ..
                fixture.sigma .. fixture.sigma0 .. fixture.sigma1 ..
                u32_be(#witnesses)
    for _, item in ipairs(witnesses) do
        out = out ..
              u32_be(#item.public_inputs_octet:str()) ..
              item.public_inputs_octet ..
              u32_be(#item.witness:str()) ..
              item.witness
    end
    return out
end

function rpbsch.prove_branch_relation(circuit, fixture, branch)
    local witness, err = rpbsch.branch_relation_witness(circuit, fixture, branch)
    if not witness then return nil, err end
    return niwi.prove_rpbsch_relation{
        circuit = niwi.rpbsch_relation_artifact(),
        inputs = witness,
        public_inputs = fixture.statement,
    }
end

function rpbsch.prove_branch_relation_with_observation_test(circuit, fixture, branch)
    local witness, err = rpbsch.branch_relation_witness(circuit, fixture, branch)
    if not witness then return nil, err end
    return niwi.prove_rpbsch_relation_with_observation_test{
        circuit = niwi.rpbsch_relation_artifact(),
        inputs = witness,
        public_inputs = fixture.statement,
    }
end

function rpbsch.verify_branch_relation(proof, statement)
    return niwi.verify_rpbsch_relation{
        circuit = niwi.rpbsch_relation_artifact(),
        proof = proof,
        public_inputs = statement,
    }
end

function rpbsch.extract_branch_relation(proof, gamma, statement)
    return niwi.extract_rpbsch_relation_from_gamma_test{
        circuit = niwi.rpbsch_relation_artifact(),
        proof = proof,
        gamma = gamma,
        public_inputs = statement,
    }
end

--- Prove one RPBSch branch through the older per-BIP340 NIWI fixture.
function rpbsch.prove_branch(circuit, fixture, branch)
    require_branch(branch)
    local witnesses, err = rpbsch.branch_witnesses(circuit, fixture, branch)
    if not witnesses then
        return nil, err
    end

    local records = {}
    for _, item in ipairs(witnesses) do
        local proof, gamma = niwi.prove_with_observation_test{
            circuit = circuit,
            inputs = item.witness_inputs,
            public_inputs = item.public_inputs,
        }
        records[#records + 1] = {
            branch = branch,
            label = item.label,
            circuit = circuit,
            statement = fixture.statement,
            proof = proof,
            gamma = gamma,
            public_inputs = item.public_inputs_octet,
            expected_witness = item.witness,
        }
    end
    return records
end

--- Verify a branch proof record and bind it to the shared RPBSch statement.
-- The current branch profile validates statement shape plus C/S openings
-- before verifying the older per-BIP340 NIWI proof records. Production native
-- RPBSch proofs use checked LZK0; these record helpers stay as readable
-- regression fixtures.
function rpbsch.verify_record(circuit, fixture, record)
    if not record or not valid_branch(record.branch) then
        return false
    end
    if not rpbsch.validate_branch_relation(fixture) then
        return false
    end
    if record.statement:string() ~= fixture.statement:string() then
        return false
    end
    return niwi.verify_circuit_niwi{
        circuit = circuit,
        proof = record.proof,
        public_inputs = record.public_inputs,
    }
end

--- Extract and return the branch witness bytes from the observed Gamma.
function rpbsch.extract_record(record)
    return niwi.extract_from_gamma_test{
        circuit = record.circuit,
        proof = record.proof,
        gamma = record.gamma,
        public_inputs = record.public_inputs,
    }
end

--- Validate a candidate BIP-340 branch check without entering zkcc bindings.
function rpbsch.valid_signature(check)
    return schnorr.verify(check.pk, check.msg, check.sig)
end

--- Validate the deterministic final PBSch signature used by the fixture.
-- Fast prototype: this is a direct BIP-340 signature under X on m. The full
-- PBSch implementation must derive it through the blind nonce/challenge flow.
function rpbsch.valid_final_signature(fixture)
    return schnorr.verify(fixture.X, fixture.m, fixture.sigma)
end

--- Build the current end-to-end PBSch smoke fixture.
-- Returns real C/S commitments, a real BIP-340 final signature, and an NIWI
-- proof for the honest RPBSch branch. This is intentionally a fixture, not the
-- final Figure 4 state machine.
function rpbsch.end_to_end_fixture()
    local circuit = zkcc.bip340_circuit()
    local fixture = rpbsch.fixture()
    local records = rpbsch.prove_branch(circuit, fixture, rpbsch.BRANCH_HONEST)
    if not records then
        return nil, "failed to prove honest RPBSch branch"
    end
    return {
        circuit = circuit,
        fixture = fixture,
        proof_records = records,
    }
end

return rpbsch
