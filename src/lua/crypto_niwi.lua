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

-- NIWI Lua adapter — wraps lib/niwi native bindings.
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

local function validate_relation(opts)
    if not can_validate_relation(opts) then return end
    local ok_raw, raw_circuit = pcall(function() return opts.circuit:raw() end)
    local circuit = ok_raw and raw_circuit or opts.circuit
    local schema = opts.circuit.schema
    -- Relation validation is intentionally delegated to the existing zkcc
    -- prover until lib/niwi owns a native circuit evaluator. The generated
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
        return native.prove_envelope_unchecked(opts)
    end
    if relation_template(opts) == "bip340" then
        return native.prove_bip340_relation(native_opts(opts))
    end
    -- Passing live zkcc artifact/witness objects enables relation validation.
    -- Raw OCTETs are accepted as the low-level NIWI envelope API.
    validate_relation(opts)
    return native.prove_envelope_unchecked(native_opts(opts))
end

function Niwi.verify_circuit_niwi(opts)
    if type(opts) ~= "table" then
        return native.verify_envelope(opts)
    end
    local out = {}
    for k, v in pairs(opts) do out[k] = v end
    out.circuit = circuit_octet(opts)
    if opts.public_inputs then
        out.public_inputs = as_octet(opts.public_inputs, "public_octet",
                                     "public_inputs")
    end
    return native.verify_envelope(out)
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
        local out = {}
        for k, v in pairs(opts) do out[k] = v end
        if opts.public_inputs then
            out.public_inputs = as_octet(opts.public_inputs, "public_octet",
                                         "public_inputs")
        end
        return native.extract_from_gamma_unchecked_test(out)
    end
end

-- Expose explicit low-level names for tests and adapters that deliberately
-- operate on proof envelopes instead of relation-checked circuit objects.
Niwi.prove_envelope_unchecked = native.prove_envelope_unchecked
Niwi.prove_bip340_relation = native.prove_bip340_relation
Niwi.verify_envelope = native.verify_envelope
Niwi.prove_envelope_with_observation_unchecked_test =
    native.prove_envelope_with_observation_unchecked_test
Niwi.prove_bip340_relation_with_observation_test =
    native.prove_bip340_relation_with_observation_test
Niwi.extract_from_gamma_unchecked_test =
    native.extract_from_gamma_unchecked_test
Niwi.extract_bip340_relation_from_gamma_test =
    native.extract_bip340_relation_from_gamma_test

-- Protocol metadata
Niwi.PROTOCOL_VERSION = native.PROTOCOL_VERSION
Niwi.VERSION = native.PROTOCOL_VERSION  -- alias

return Niwi
