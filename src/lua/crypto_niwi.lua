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

-- NIWI Lua adapter — wraps lib/blindzap native bindings.
--
-- Production interface:
--   local niwi = require('crypto_niwi')
--   proof = niwi.prove_circuit_niwi{ circuit=..., inputs=... }
--   ok    = niwi.verify_circuit_niwi{ circuit=..., proof=..., public_inputs=... }
--   info  = niwi.niwi_profile()
--
-- This replaces the legacy niwi/niwi.lua wrapper that used only the
-- legacy zkcc prove_circuit/verify_circuit functions.
--
-- When the native niwi module is not available (e.g. built without ZKCC),
-- require('niwi') will return nil and callers should check.

local native = require('niwi')

if not native then
    return nil
end

local Niwi = {}
local zkcc_ok, zkcc = pcall(require, 'crypto_zkcc')
if not zkcc_ok then zkcc = nil end
local BIP340_RELATION_ARTIFACT = O.from_string("niwi/zkcc-bip340/v1")
local RPBSCH_RELATION_ARTIFACT = O.from_string("niwi/rpbsch-branch/v1")
local rpbsch_context = nil

local function is_octet(value)
    return type(value) == "zenroom.octet"
end

local function has_method(value, name)
    if value == nil or is_octet(value) then return false end
    local ok, method = pcall(function() return value[name] end)
    return ok and type(method) == "function"
end

local function raw_value(value)
    if value == nil or is_octet(value) then return value end
    if has_method(value, "raw") then
        local ok, raw = pcall(function() return value:raw() end)
        if ok and raw then return raw end
    end
    return value
end

local function as_octet(value, method_name, label)
    value = raw_value(value)
    if is_octet(value) then return value end
    if has_method(value, method_name) then
        return value[method_name](value)
    end
    error(label .. " must be an OCTET or expose :" .. method_name .. "()", 3)
end

local function relation_template(opts)
    if type(opts) ~= "table" or not opts.circuit then return nil end
    local schema = opts.circuit.schema
    return schema and schema.template or nil
end

local function circuit_octet(opts)
    if relation_template(opts) == "bip340" then
        return BIP340_RELATION_ARTIFACT
    end
    return as_octet(opts.circuit, "octet", "circuit")
end

local function native_opts(opts)
    local out = {}
    for k, v in pairs(opts) do out[k] = v end
    out.circuit = circuit_octet(opts)
    out.inputs = as_octet(opts.inputs, "octet", "inputs")
    if opts.public_inputs then
        out.public_inputs = as_octet(opts.public_inputs, "public_octet",
                                     "public_inputs")
    end
    return out
end

local function circuit_public_opts(opts)
    local out = {}
    for k, v in pairs(opts) do out[k] = v end
    out.circuit = circuit_octet(opts)
    if opts.public_inputs then
        out.public_inputs = as_octet(opts.public_inputs, "public_octet",
                                     "public_inputs")
    end
    return out
end

local function can_validate_relation(opts)
    return zkcc and relation_template(opts) ~= "bip340" and
           not is_octet(opts.circuit) and not is_octet(opts.inputs)
end

local function has_native_zkcc_relation(opts)
    return relation_template(opts) ~= "bip340" and
           type(native.prove_zkcc_relation) == "function" and
           type(native.verify_zkcc_relation) == "function" and
           not is_octet(opts.circuit) and not is_octet(opts.inputs)
end

local function proof_has_ligero_body(opts)
    if type(opts) ~= "table" or not opts.proof or not is_octet(opts.proof) then
        return false
    end
    return opts.proof:string():find("LIG0", 1, true) ~= nil
end

local function relation_backed_error()
    error("crypto_niwi: production API requires a relation-backed zkcc object", 3)
end

local function validate_relation(opts)
    if not can_validate_relation(opts) then return end
    local ok_raw, raw_circuit = pcall(function() return opts.circuit:raw() end)
    local circuit = ok_raw and raw_circuit or opts.circuit
    local schema = opts.circuit.schema
    -- Relation validation is intentionally delegated to the existing zkcc
    -- prover until lib/blindzap owns a native circuit evaluator. The generated
    -- legacy proof is discarded; this is only a witness-satisfaction gate.
    if schema and schema.template == "bip340" then
        zkcc.native.prove_circuit_bip340{
            circuit = circuit,
            inputs = opts.inputs,
            seed = opts.seed,
        }
        return
    end
    zkcc.prove_circuit{
        circuit = circuit,
        inputs = opts.inputs,
        seed = opts.seed,
    }
end

-- Production API
function Niwi.prove_circuit_niwi(opts)
    if type(opts) ~= "table" then
        error("prove_circuit_niwi: expected table argument", 2)
    end
    if relation_template(opts) == "bip340" then
        return native.prove_bip340_relation(native_opts(opts))
    end
    if has_native_zkcc_relation(opts) then
        return native.prove_zkcc_relation(native_opts(opts))
    end
    relation_backed_error()
end

function Niwi.verify_circuit_niwi(opts)
    if type(opts) ~= "table" then
        error("verify_circuit_niwi: expected table argument", 2)
    end
    if relation_template(opts) == "bip340" then
        return native.verify_bip340_relation(circuit_public_opts(opts))
    end
    if proof_has_ligero_body(opts) and type(native.verify_zkcc_relation) == "function" then
        return native.verify_zkcc_relation(circuit_public_opts(opts))
    end
    relation_backed_error()
end
Niwi.niwi_profile         = native.niwi_profile

-- Test-only API (available only in DEBUG/test builds)
if native.prove_envelope_with_observation_unchecked_test then
    function Niwi.prove_with_observation_test(opts)
        if type(opts) ~= "table" then
            return native.prove_envelope_with_observation_unchecked_test(opts)
        end
        if relation_template(opts) == "bip340" then
            return native.prove_bip340_relation_with_observation_test(
                native_opts(opts))
        end
        if has_native_zkcc_relation(opts) and
           type(native.prove_zkcc_relation_with_observation_test) == "function" then
            return native.prove_zkcc_relation_with_observation_test(native_opts(opts))
        end
        validate_relation(opts)
        return native.prove_envelope_with_observation_unchecked_test(native_opts(opts))
    end
end
if native.extract_from_gamma_unchecked_test then
    function Niwi.extract_from_gamma_test(opts)
        if type(opts) ~= "table" then
            return native.extract_from_gamma_unchecked_test(opts)
        end
        if relation_template(opts) == "bip340" then
            local out = circuit_public_opts(opts)
            out.proof = as_octet(opts.proof, "octet", "proof")
            out.gamma = as_octet(opts.gamma, "octet", "gamma")
            return native.extract_bip340_relation_from_gamma_test(out)
        end
        if proof_has_ligero_body(opts) and opts.circuit and
           type(native.extract_zkcc_relation_from_gamma_test) == "function" then
            local out = circuit_public_opts(opts)
            out.proof = as_octet(opts.proof, "octet", "proof")
            out.gamma = as_octet(opts.gamma, "octet", "gamma")
            return native.extract_zkcc_relation_from_gamma_test(out)
        end
        local out = {}
        for k, v in pairs(opts) do out[k] = v end
        if opts.public_inputs then
            out.public_inputs = as_octet(opts.public_inputs, "public_octet",
                                         "public_inputs")
        end
        return native.extract_from_gamma_unchecked_test(out)
    end
end

Niwi.prove_zkcc_relation = native.prove_zkcc_relation
Niwi.verify_zkcc_relation = native.verify_zkcc_relation
Niwi.prove_bip340_relation = native.prove_bip340_relation
Niwi.verify_bip340_relation = native.verify_bip340_relation
Niwi.rpbsch_relation_artifact = function() return RPBSCH_RELATION_ARTIFACT end
function Niwi.prepare_rpbsch_relation()
    if not rpbsch_context then
        rpbsch_context = native.prepare_rpbsch_relation(RPBSCH_RELATION_ARTIFACT)
    end
    return rpbsch_context
end

function Niwi.prove_rpbsch_relation_prepared(context, inputs, public_inputs)
    return native.prove_rpbsch_relation_prepared(context, inputs, public_inputs)
end

function Niwi.verify_rpbsch_relation_prepared(context, proof, public_inputs)
    return native.verify_rpbsch_relation_prepared(context, proof, public_inputs)
end

local function is_canonical_rpbsch_artifact(circuit)
    return is_octet(circuit) and circuit:string() == RPBSCH_RELATION_ARTIFACT:string()
end

function Niwi.prove_rpbsch_relation(opts)
    if type(opts) ~= "table" then
        error("prove_rpbsch_relation: expected table argument", 2)
    end
    if not is_canonical_rpbsch_artifact(opts.circuit) then
        return native.prove_rpbsch_relation(opts)
    end
    return native.prove_rpbsch_relation_prepared(
        Niwi.prepare_rpbsch_relation(),
        as_octet(opts.inputs, "octet", "inputs"),
        as_octet(opts.public_inputs, "public_octet", "public_inputs"))
end

function Niwi.verify_rpbsch_relation(opts)
    if type(opts) ~= "table" then
        error("verify_rpbsch_relation: expected table argument", 2)
    end
    if not is_canonical_rpbsch_artifact(opts.circuit) then
        return native.verify_rpbsch_relation(opts)
    end
    return native.verify_rpbsch_relation_prepared(
        Niwi.prepare_rpbsch_relation(),
        as_octet(opts.proof, "octet", "proof"),
        as_octet(opts.public_inputs, "public_octet", "public_inputs"))
end
Niwi.prove_envelope_with_observation_unchecked_test =
    native.prove_envelope_with_observation_unchecked_test
Niwi.prove_zkcc_relation_with_observation_test =
    native.prove_zkcc_relation_with_observation_test
Niwi.prove_bip340_relation_with_observation_test =
    native.prove_bip340_relation_with_observation_test
Niwi.prove_rpbsch_relation_with_observation_test =
    native.prove_rpbsch_relation_with_observation_test
Niwi.extract_zkcc_relation_from_gamma_test =
    native.extract_zkcc_relation_from_gamma_test
Niwi.extract_bip340_relation_from_gamma_test =
    native.extract_bip340_relation_from_gamma_test
Niwi.extract_rpbsch_relation_from_gamma_test =
    native.extract_rpbsch_relation_from_gamma_test

-- Protocol metadata
Niwi.PROTOCOL_VERSION = native.PROTOCOL_VERSION
Niwi.VERSION = native.PROTOCOL_VERSION  -- alias

return Niwi
